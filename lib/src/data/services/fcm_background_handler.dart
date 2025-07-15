import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// FCM 백그라운드 메시지 처리 핸들러
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (kDebugMode) {
      print('=== FCM 백그라운드 메시지 처리 시작 ===');
      print('메시지 ID: ${message.messageId}');
      print('제목: ${message.notification?.title}');
      print('내용: ${message.notification?.body}');
      print('데이터: ${message.data}');
      print('발송 시간: ${message.sentTime}');
      print('=== FCM 백그라운드 메시지 처리 완료 ===');
    }

    // 백그라운드에서는 단순히 로깅만 수행
    // 실제 네비게이션은 onMessageOpenedApp에서 처리됨
  } catch (error) {
    if (kDebugMode) {
      print('FCM 백그라운드 메시지 처리 중 오류: $error');
    }
  }
}
