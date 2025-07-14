import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// FCM 백그라운드 메시지 처리 핸들러
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('백그라운드 메시지 처리: ${message.messageId}');
    print('제목: ${message.notification?.title}');
    print('내용: ${message.notification?.body}');
    print('데이터: ${message.data}');
  }
}
