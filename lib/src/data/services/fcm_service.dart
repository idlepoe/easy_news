import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final Logger _logger = Logger();

  /// FCM 초기화
  Future<void> initialize() async {
    try {
      // 알림 권한 요청
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: true,
          );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        _logger.i('FCM 알림 권한이 허용되었습니다.');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        _logger.i('FCM 임시 알림 권한이 허용되었습니다.');
      } else {
        _logger.w('FCM 알림 권한이 거부되었습니다.');
      }

      // FCM 토큰 가져오기
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        _logger.i('FCM Token: $token');
      }

      // 토큰 갱신 리스너
      _firebaseMessaging.onTokenRefresh.listen((String token) {
        _logger.i('FCM Token 갱신: $token');
      });
    } catch (e) {
      _logger.e('FCM 초기화 실패: $e');
    }
  }

  /// summary3lines 토픽 구독
  Future<bool> subscribeToSummary3Lines() async {
    try {
      await _firebaseMessaging.subscribeToTopic('summary3lines');
      _logger.i('summary3lines 토픽 구독 완료');
      return true;
    } catch (e) {
      _logger.e('summary3lines 토픽 구독 실패: $e');
      return false;
    }
  }

  /// summary3lines 토픽 구독 해제
  Future<bool> unsubscribeFromSummary3Lines() async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic('summary3lines');
      _logger.i('summary3lines 토픽 구독 해제 완료');
      return true;
    } catch (e) {
      _logger.e('summary3lines 토픽 구독 해제 실패: $e');
      return false;
    }
  }

  /// 포그라운드 메시지 처리
  void handleForegroundMessage() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _logger.i('포그라운드 메시지 수신: ${message.notification?.title}');

      if (kDebugMode) {
        print('Message data: ${message.data}');
        print('Message notification: ${message.notification?.title}');
        print('Message notification: ${message.notification?.body}');
      }
    });
  }

  /// 백그라운드 메시지 처리
  void handleBackgroundMessage() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _logger.i('백그라운드 메시지에서 앱 열림: ${message.notification?.title}');

      if (kDebugMode) {
        print('Message data: ${message.data}');
      }
    });
  }
}
