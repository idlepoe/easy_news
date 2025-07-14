import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'src/presentation/app.dart';
import 'src/data/services/fcm_service.dart';
import 'src/data/services/fcm_background_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);

  // Firebase 초기화
  await Firebase.initializeApp();

  // FCM 백그라운드 핸들러 등록
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // FCM 서비스 초기화
  final fcmService = FCMService();
  await fcmService.initialize();
  fcmService.handleForegroundMessage();
  fcmService.handleBackgroundMessage();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(child: const App());
  }
}
