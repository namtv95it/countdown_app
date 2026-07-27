import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:countdown_app/services/app_firebase_service.dart';
import 'storage_service.dart';
import 'ad_service.dart';
import 'localization_service.dart';

enum PromoType { premium, giftEffect, testMode, admin }

class PromoCode {
  final String code;
  final DateTime expirationDate; // ngày mã hết hạn để nhập (UTC)
  final String description;
  final String? descriptionEn;
  final PromoType type;
  final String? unlockedEffectId;
  final DateTime? activationExpiryDate; // ngày người dùng hết quyền (nếu có thời hạn)
  final num? durationDays; // số ngày hiệu lực

  const PromoCode({
    required this.code,
    required this.expirationDate,
    required this.description,
    this.descriptionEn,
    this.type = PromoType.premium,
    this.unlockedEffectId,
    this.activationExpiryDate,
    this.durationDays,
  });

  String get localizedDescription {
    final isEn = LocalizationService.languageNotifier.value == 'en';
    if (isEn && descriptionEn != null && descriptionEn!.isNotEmpty) {
      return descriptionEn!;
    }
    return description;
  }

  bool isExpired(DateTime currentNetworkTime) {
    return currentNetworkTime.isAfter(expirationDate);
  }
}

class PromoResult {
  final bool success;
  final String message;
  final PromoCode? matchedCode;
  final bool isAdmin;

  const PromoResult({
    required this.success,
    required this.message,
    this.matchedCode,
    this.isAdmin = false,
  });
}

class PromoService {
  /// Epoch fallback date for matched codes with missing date
  static final DateTime _epoch = DateTime.utc(1970);

  /// Lấy thời gian chuẩn từ máy chủ Internet (chống đổi ngày giờ trên điện thoại)
  static Future<DateTime> getNetworkTime() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 4);
      final request = await client.getUrl(Uri.parse('https://worldtimeapi.org/api/timezone/Etc/UTC'));
      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final json = jsonDecode(body);
        if (json['datetime'] != null) {
          return DateTime.parse(json['datetime']).toUtc();
        }
      }
    } catch (_) {}

    try {
      // Đọc Date Header từ Google Server
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 4);
      final request = await client.headUrl(Uri.parse('https://www.google.com'));
      final response = await request.close();
      final dateHeader = response.headers.value(HttpHeaders.dateHeader);
      if (dateHeader != null) {
        return HttpDate.parse(dateHeader).toUtc();
      }
    } catch (_) {}

    // Fallback nếu mất kết nối mạng
    return DateTime.now().toUtc();
  }

  /// Kiểm tra và áp dụng mã kích hoạt / gift code
  static Future<PromoResult> redeemCode(String inputCode) async {
    final cleanCode = inputCode.trim().toUpperCase();
    final isEn = LocalizationService.languageNotifier.value == 'en';

    if (cleanCode.length < 5) {
      return PromoResult(
        success: false, 
        message: isEn ? 'Invalid code (too short)!' : 'Mã không hợp lệ (quá ngắn)!',
      );
    }

    // --- ANTI SPAM CHECK ---
    final storage = StorageService();
    final lockUntil = await storage.getPromoLockUntil();
    if (lockUntil != null) {
      if (DateTime.now().isBefore(lockUntil)) {
        final minutesLeft = lockUntil.difference(DateTime.now()).inMinutes + 1;
        return PromoResult(
            success: false,
            message: isEn
                ? 'Too many failed attempts. Please try again after $minutesLeft minutes!'
                : 'Bạn nhập sai quá nhiều. Vui lòng thử lại sau $minutesLeft phút!');
      } else {
        // Hết thời gian khóa, reset lại
        await storage.setPromoLockUntil(null);
        await storage.setFailedPromoAttempts(0);
      }
    }

    // 1. Kiểm tra trên Firestore trước
    try {
      final firestoreData = await AppFirebaseService().checkPromoCode(cleanCode);
      if (firestoreData != null) {
        final docId = firestoreData['_docId'] as String;

        // 1.1 Kiểm tra đã nhập ở máy này chưa (chỉ áp dụng cho mã thông thường)
        final String typeEarly = firestoreData['type'] ?? '';
        final bool isHiddenFeatureCode = typeEarly == 'testMode' || typeEarly == 'admin';
        if (!isHiddenFeatureCode && await StorageService().isPromoCodeUsed(cleanCode)) {
          return PromoResult(
            success: false, 
            message: isEn ? 'You have already used this code!' : 'Bạn đã sử dụng mã này rồi!',
          );
        }

        // 1.2 Kiểm tra hạn sử dụng (nếu có)
        if (firestoreData['expirationDate'] != null) {
          final expirationTimestamp = firestoreData['expirationDate'];
          final expirationDate = expirationTimestamp.toDate();
          final networkTime = await getNetworkTime();
          if (networkTime.isAfter(expirationDate)) {
            return PromoResult(
              success: false, 
              message: isEn ? 'This code has expired!' : 'Mã này đã hết hạn!',
            );
          }
        }

        // 1.3 Kiểm tra giới hạn số lượt sử dụng (nếu có)
        if (firestoreData['maxUsage'] != null) {
          final int maxUsage = firestoreData['maxUsage'];
          final int usedCount = firestoreData['usedCount'] ?? 0;
          if (usedCount >= maxUsage) {
            return PromoResult(
              success: false, 
              message: isEn ? 'This code has reached its usage limit!' : 'Mã này đã đạt giới hạn số lần sử dụng!',
            );
          }
        }

        // 1.4 Áp dụng phần thưởng
        final String type = firestoreData['type'] ?? '';
        final String description = firestoreData['description'] ?? 'Quà tặng từ server';
        final String? descriptionEn = firestoreData['descriptionEn'];
        final String? effectId = firestoreData['unlockedEffectId'];
        
        final displayDesc = (isEn && descriptionEn != null && descriptionEn.isNotEmpty) ? descriptionEn : description;

        // Tính toán thời hạn (nếu có)
        final num? durationDays = firestoreData['durationDays'] as num?;
        DateTime? expiryDate;
        if (durationDays != null && durationDays > 0) {
          expiryDate = DateTime.now().add(Duration(milliseconds: (durationDays * 86400000).toInt()));
        }

        if (type == 'premium') {
          final isAlreadyPremium = await StorageService().getIsPremium();
          if (isAlreadyPremium) {
            final currentExpiry = await StorageService().getPremiumExpiry();
            if (currentExpiry == null) {
              return PromoResult(
                success: false,
                message: isEn 
                    ? 'Your account is already Lifetime Premium!' 
                    : 'Tài khoản của bạn đã là Premium vĩnh viễn!',
              );
            } else if (durationDays != null && durationDays > 0) {
              // Cộng dồn thời hạn: Lấy thời hạn hiện tại cộng thêm số ngày của mã mới
              expiryDate = currentExpiry.add(Duration(milliseconds: (durationDays * 86400000).toInt()));
            } else {
              // Nâng cấp lên vĩnh viễn
              expiryDate = null;
            }
          }
          await StorageService().setPremium(true, expiryDate);
          AdService.isPremium = true;
        } else if (type == 'giftEffect' && effectId != null) {
          await StorageService().unlockFeature('${effectId}_effect_unlocked', expiryDate);
          await StorageService().setSelectedEffect(effectId);
        } else if (type == 'testMode') {
          await StorageService().setTestModeUnlocked(true);
        } else if (type == 'admin') {
          await StorageService().setIsAdminUnlocked(true);
          await StorageService().setTestModeUnlocked(true);
        }

        // 1.5 Cập nhật Database và Local
        // Mã kích hoạt tính năng ẩn (testMode, admin) không lưu lịch sử để có thể dùng lại
        if (!isHiddenFeatureCode) {
          await AppFirebaseService().incrementPromoUsage(docId);
          await StorageService().markPromoCodeAsUsed(cleanCode);
        }
        await storage.setFailedPromoAttempts(0); // Thành công thì reset

        return PromoResult(
          success: true,
          message: isEn ? '🎉 Activated successfully: $displayDesc!' : '🎉 Kích hoạt thành công $description!',
          isAdmin: type == 'admin',
          matchedCode: PromoCode(
            code: cleanCode,
            expirationDate: firestoreData['expirationDate']?.toDate() ?? _epoch,
            description: description,
            descriptionEn: descriptionEn,
            type: type == 'premium' 
                ? PromoType.premium 
                : (type == 'testMode' ? PromoType.testMode : (type == 'admin' ? PromoType.admin : PromoType.giftEffect)),
            unlockedEffectId: effectId,
            activationExpiryDate: expiryDate,
            durationDays: durationDays,
          ),
        );
      }
    } catch (e) {
      debugPrint('Firestore check failed: $e');
      return PromoResult(
        success: false, 
        message: isEn ? 'System error. Please try again later!' : 'Lỗi hệ thống. Vui lòng thử lại sau!',
      );
    }

    // Xử lý khi mã không tồn tại trên Firebase
    int attempts = await storage.getFailedPromoAttempts() + 1;
    await storage.setFailedPromoAttempts(attempts);
    if (attempts >= 3) {
      await storage.setPromoLockUntil(DateTime.now().add(const Duration(minutes: 10)));
      return PromoResult(
          success: false, 
          message: isEn
              ? 'Too many failed attempts. Feature locked for 10 minutes!'
              : 'Bạn nhập sai quá 3 lần. Tính năng bị khóa 10 phút!');
    }
    return PromoResult(
      success: false, 
      message: isEn ? 'Invalid activation or gift code!' : 'Mã kích hoạt hoặc Gift Code không hợp lệ!',
    );
  }
}
