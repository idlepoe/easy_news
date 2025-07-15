import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'src/presentation/app.dart';
import 'src/data/services/fcm_service.dart';
import 'src/data/services/fcm_background_handler.dart';
import 'src/presentation/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('=== 앱 시작 ===');

  await initializeDateFormatting('ko_KR', null);
  print('날짜 포맷 초기화 완료');

  // Firebase 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Firebase 초기화 완료');

  // FCM 백그라운드 핸들러 등록
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  print('FCM 백그라운드 핸들러 등록 완료');

  // FCM 서비스 초기화
  final fcmService = FCMService();
  await fcmService.initialize();
  print('FCM 서비스 초기화 완료');

  // 알림 서비스 초기화 (FCM 서비스 초기화 후)
  final notificationService = NotificationService();
  notificationService.initialize();
  print('알림 서비스 초기화 완료');

  // FCM 메시지 핸들러 설정 (알림 서비스 초기화 후)
  fcmService.handleForegroundMessage();
  fcmService.handleBackgroundMessage();
  print('FCM 메시지 핸들러 설정 완료');

  print('=== 앱 초기화 완료, 앱 실행 ===');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(child: const App());
  }
}
