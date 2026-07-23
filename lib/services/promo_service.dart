import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:countdown_app/services/app_firebase_service.dart';
import 'storage_service.dart';
import 'ad_service.dart';

enum PromoType { premium, giftEffect, testMode }

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

  const PromoResult({
    required this.success,
    required this.message,
    this.matchedCode,
  });
}

class PromoService {
  /// Danh sách các mã kích hoạt Premium & Gift Code
  static final List<PromoCode> validCodes = [
    // Mã Premium
    PromoCode(
      code: 'PREMIUM2026',
      expirationDate: DateTime.utc(2026, 12, 31, 23, 59, 59),
      description: 'VIP Premium 2026',
    ),
    PromoCode(
      code: 'VIP',
      expirationDate: DateTime.utc(2027, 6, 30, 23, 59, 59),
      description: 'VIP 2027',
    ),
    PromoCode(
      code: 'CAPTAIN999',
      expirationDate: DateTime.utc(2026, 12, 31, 23, 59, 59),
      description: 'Captain VIP',
    ),
    PromoCode(
      code: 'PROMO2026',
      expirationDate: DateTime.utc(2026, 9, 30, 23, 59, 59),
      description: 'Khuyến Mãi 2026',
    ),
    PromoCode(
      code: 'HETHAN',
      expirationDate: DateTime.utc(2025, 1, 1, 0, 0, 0),
      description: 'Mã Hết Hạn',
    ),
    PromoCode(
      code: 'NAMTVTEST',
      expirationDate: DateTime.utc(2030, 12, 31, 23, 59, 59),
      description: 'Chế độ Cài Đặt Ẩn',
      type: PromoType.testMode,
    ),
    
    // Gift Code mở hiệu ứng đặc biệt (Phát triển sẵn)
    PromoCode(
      code: 'GIFTSNOW',
      expirationDate: DateTime.utc(2027, 12, 31, 23, 59, 59),
      description: 'Hiệu ứng Tuyết Rơi',
      type: PromoType.giftEffect,
      unlockedEffectId: 'snow',
    ),
    PromoCode(
      code: 'GIFTHEART',
      expirationDate: DateTime.utc(2027, 12, 31, 23, 59, 59),
      description: 'Hiệu ứng Trái Tim',
      type: PromoType.giftEffect,
      unlockedEffectId: 'hearts',
    ),
    PromoCode(
      code: 'GIFTSTAR',
      expirationDate: DateTime.utc(2027, 12, 31, 23, 59, 59),
      description: 'Hiệu ứng Ngôi Sao',
      type: PromoType.giftEffect,
      unlockedEffectId: 'stars',
    ),
    PromoCode(
      code: 'GIFTFIREWORKS',
      expirationDate: DateTime.utc(2027, 12, 31, 23, 59, 59),
      description: 'Hiệu ứng Pháo Hoa',
      type: PromoType.giftEffect,
      unlockedEffectId: 'fireworks',
    ),
  ];

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
    if (cleanCode.isEmpty) {
      return const PromoResult(success: false, message: 'Vui lòng nhập gift code!');
    }

    // 1. Kiểm tra trên Firestore trước
    try {
      final firestoreData = await AppFirebaseService().checkPromoCode(cleanCode);
      if (firestoreData != null) {
        final docId = firestoreData['_docId'] as String;

        // 1.1 Kiểm tra đã nhập ở máy này chưa
        if (await StorageService().isPromoCodeUsed(cleanCode)) {
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
        }

        // 1.5 Cập nhật Database và Local
        await AppFirebaseService().incrementPromoUsage(docId);
        await StorageService().markPromoCodeAsUsed(cleanCode);

        return PromoResult(
          success: true,
          message: '🎉 Kích hoạt thành công $description!',
        );
      }
    } catch (e) {
      debugPrint('Firestore check failed, falling back to local codes: $e');
    }

    // 2. Dự phòng: Kiểm tra mã cục bộ (như cũ)
    final matched = validCodes.firstWhere(
      (c) => c.code.toUpperCase() == cleanCode,
      orElse: () => PromoCode(code: '', expirationDate: _epoch, description: ''),
    );

    if (matched.code.isEmpty) {
      return const PromoResult(success: false, message: 'Mã kích hoạt hoặc Gift Code không hợp lệ!');
    }

    // Lấy thời gian từ máy chủ Internet
    final networkTime = await getNetworkTime();

    if (matched.isExpired(networkTime)) {
      final expDay = matched.expirationDate.day.toString().padLeft(2, '0');
      final expMonth = matched.expirationDate.month.toString().padLeft(2, '0');
      final expYear = matched.expirationDate.year;
      return PromoResult(
        success: false,
        message: 'Mã "$cleanCode" đã hết hạn vào ngày $expDay/$expMonth/$expYear!',
      );
    }

    // Áp dụng quyền lợi dựa theo loại mã
    if (matched.type == PromoType.premium) {
      await StorageService().setPremium(true);
      AdService.isPremium = true;
    } else if (matched.type == PromoType.giftEffect && matched.unlockedEffectId != null) {
      await StorageService().unlockFeature('${matched.unlockedEffectId}_effect_unlocked');
      await StorageService().setSelectedEffect(matched.unlockedEffectId!);
    } else if (matched.type == PromoType.testMode) {
      await StorageService().setTestModeUnlocked(true);
    }

    return PromoResult(
      success: true,
      message: '🎉 Kích hoạt thành công ${matched.description}!',
      matchedCode: matched,
    );
  }

  static final DateTime _epoch = DateTime.utc(1970);
}
