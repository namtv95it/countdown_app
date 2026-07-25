import '../services/app_firebase_service.dart';

/// Cấu hình Banner mặc định (hiển thị khi offline hoặc chưa load được từ Firebase)
final StartupBanner defaultBanner = StartupBanner(
  isActive: false, // Tắt banner mặc định để không hiển thị banner placeholder
  items: [],
);
