import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:countdown_app/services/app_firebase_service.dart';
import 'storage_service.dart';
import 'ad_service.dart';

enum PromoType { premium, giftEffect, testMode, admin }

class PromoCode {
  final String code;
  final DateTime expirationDate; // UTC time
  final String description;
  final PromoType type;
  final String? unlockedEffectId;

  const PromoCode({
    required this.code,
    required this.expirationDate,
    required this.description,
    this.type = PromoType.premium,
    this.unlockedEffectId,
  });

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
    if (cleanCode.length < 5) {
      return const PromoResult(success: false, message: 'Mã không hợp lệ (quá ngắn)!');
    }


    // --- ANTI SPAM CHECK ---
    final storage = StorageService();
    final lockUntil = await storage.getPromoLockUntil();
    if (lockUntil != null) {
      if (DateTime.now().isBefore(lockUntil)) {
        final minutesLeft = lockUntil.difference(DateTime.now()).inMinutes + 1;
        return PromoResult(
            success: false,
            message: 'Bạn nhập sai quá nhiều. Vui lòng thử lại sau $minutesLeft phút!');
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
          return const PromoResult(success: false, message: 'Bạn đã sử dụng mã này rồi!');
        }

        // 1.2 Kiểm tra hạn sử dụng (nếu có)
        if (firestoreData['expirationDate'] != null) {
          final expirationTimestamp = firestoreData['expirationDate']; // Giả sử là Timestamp
          final expirationDate = expirationTimestamp.toDate();
          final networkTime = await getNetworkTime();
          if (networkTime.isAfter(expirationDate)) {
            return const PromoResult(success: false, message: 'Mã này đã hết hạn!');
          }
        }

        // 1.3 Kiểm tra giới hạn số lượt sử dụng (nếu có)
        if (firestoreData['maxUsage'] != null) {
          final int maxUsage = firestoreData['maxUsage'];
          final int usedCount = firestoreData['usedCount'] ?? 0;
          if (usedCount >= maxUsage) {
            return const PromoResult(success: false, message: 'Mã này đã đạt giới hạn số lần sử dụng!');
          }
        }

        // 1.4 Áp dụng phần thưởng
        final String type = firestoreData['type'] ?? '';
        final String description = firestoreData['description'] ?? 'Quà tặng từ server';
        final String? effectId = firestoreData['unlockedEffectId'];

        if (type == 'premium') {
          await StorageService().setPremium(true);
          AdService.isPremium = true;
        } else if (type == 'giftEffect' && effectId != null) {
          await StorageService().unlockFeature('${effectId}_effect_unlocked');
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
          message: '🎉 Kích hoạt thành công $description!',
          isAdmin: type == 'admin',
          matchedCode: PromoCode(
            code: cleanCode,
            expirationDate: firestoreData['expirationDate']?.toDate() ?? _epoch,
            description: description,
            type: type == 'premium' 
                ? PromoType.premium 
                : (type == 'testMode' ? PromoType.testMode : (type == 'admin' ? PromoType.admin : PromoType.giftEffect)),
            unlockedEffectId: effectId,
          ),
        );
      }
    } catch (e) {
      debugPrint('Firestore check failed: $e');
      return const PromoResult(success: false, message: 'Lỗi hệ thống. Vui lòng thử lại sau!');
    }

    // Xử lý khi mã không tồn tại trên Firebase
    int attempts = await storage.getFailedPromoAttempts() + 1;
    await storage.setFailedPromoAttempts(attempts);
    if (attempts >= 3) {
      await storage.setPromoLockUntil(DateTime.now().add(const Duration(minutes: 10)));
      return const PromoResult(
          success: false, message: 'Bạn nhập sai quá 3 lần. Tính năng bị khóa 10 phút!');
    }
    return const PromoResult(success: false, message: 'Mã kích hoạt hoặc Gift Code không hợp lệ!');
  }

  static final DateTime _epoch = DateTime.utc(1970);
}
