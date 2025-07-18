import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';

typedef MessageCallback = void Function(RemoteMessage message);

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final Logger _logger = Logger();

  MessageCallback? _onMessageOpenedApp;
  MessageCallback? _onMessage;

  /// FCM 초기화
  Future<void> initialize() async {
    try {
      _logger.i('FCM 서비스 초기화 시작');

      // 로컬 알림 초기화
      await _initializeLocalNotifications();

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

      _logger.i('FCM 서비스 초기화 완료');
    } catch (e) {
      _logger.e('FCM 초기화 실패: $e');
    }
  }

  /// 로컬 알림 초기화
  Future<void> _initializeLocalNotifications() async {
    try {
      _logger.i('로컬 알림 초기화 시작');

      // Android 설정
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@drawable/ic_notification_removebg');

      // iOS 설정
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      // 초기화 설정
      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
          );

      // 플러그인 초기화
      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          _logger.i('로컬 알림 클릭: payload=${response.payload}, id=${response.id}');
          // 여기서 네비게이션 처리 가능
        },
      );

      // Android 알림 채널 생성
      await _createNotificationChannels();

      _logger.i('로컬 알림 초기화 완료');
    } catch (e) {
      _logger.e('로컬 알림 초기화 실패: $e');
    }
  }

  /// Android 알림 채널 생성
  Future<void> _createNotificationChannels() async {
    try {
      _logger.i('Android 알림 채널 생성 시작');

      // 뉴스 요약 알림 채널
      const AndroidNotificationChannel newsSummaryChannel =
          AndroidNotificationChannel(
            'news_summary',
            '뉴스 요약',
            description: '뉴스 3줄 요약 알림',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
            showBadge: true,
          );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(newsSummaryChannel);

      _logger.i('Android 알림 채널 생성 완료');
    } catch (e) {
      _logger.e('Android 알림 채널 생성 실패: $e');
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

  /// 메시지 콜백 설정
  void setMessageCallbacks({
    MessageCallback? onMessage,
    MessageCallback? onMessageOpenedApp,
  }) {
    _logger.i(
      'FCM 메시지 콜백 설정: onMessage=${onMessage != null}, onMessageOpenedApp=${onMessageOpenedApp != null}',
    );
    _onMessage = onMessage;
    _onMessageOpenedApp = onMessageOpenedApp;
  }

  /// 포그라운드 메시지 처리
  void handleForegroundMessage() {
    _logger.i('포그라운드 메시지 핸들러 설정');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      _logger.i('=== 포그라운드 메시지 수신 ===');
      _logger.i('메시지 ID: ${message.messageId}');
      _logger.i('제목: ${message.notification?.title}');
      _logger.i('내용: ${message.notification?.body}');
      _logger.i('데이터: ${message.data}');
      _logger.i('발송 시간: ${message.sentTime}');
      _logger.i('Android 이미지: ${message.notification?.android?.imageUrl}');
      _logger.i('=== 포그라운드 메시지 처리 완료 ===');

      if (kDebugMode) {
        print('=== 포그라운드 메시지 수신 ===');
        print('Message data: ${message.data}');
        print('Message notification: ${message.notification?.title}');
        print('Message notification: ${message.notification?.body}');
        print('Message image: ${message.notification?.android?.imageUrl}');
        print('=== 포그라운드 메시지 처리 완료 ===');
      }

      // 포그라운드에서는 FCM의 기본 알림만 사용 (로컬 알림 제거)
      // FCM이 자동으로 포그라운드 알림을 표시하도록 설정

      // 콜백 실행
      if (_onMessage != null) {
        _logger.i('포그라운드 메시지 콜백 실행');
        _onMessage!.call(message);
      } else {
        _logger.w('포그라운드 메시지 콜백이 설정되지 않았습니다.');
      }
    });
  }

  /// 백그라운드 메시지 처리
  void handleBackgroundMessage() {
    // _logger.i('백그라운드 메시지 핸들러 설정');

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // _logger.i('=== 백그라운드 메시지에서 앱 열림 ===');
      // _logger.i('메시지 ID: ${message.messageId}');
      // _logger.i('제목: ${message.notification?.title}');
      // _logger.i('내용: ${message.notification?.body}');
      // _logger.i('데이터: ${message.data}');
      // _logger.i('발송 시간: ${message.sentTime}');
      // _logger.i('Android 이미지: ${message.notification?.android?.imageUrl}');
      // _logger.i('=== 백그라운드 메시지 처리 완료 ===');

      if (kDebugMode) {
        print('=== 백그라운드 메시지에서 앱 열림 ===');
        print('Message data: ${message.data}');
        print('Message image: ${message.notification?.android?.imageUrl}');
        print('=== 백그라운드 메시지 처리 완료 ===');
      }

      // 콜백 실행
      if (_onMessageOpenedApp != null) {
        _logger.i('백그라운드 메시지 콜백 실행');
        _onMessageOpenedApp!.call(message);
      } else {
        _logger.w('백그라운드 메시지 콜백이 설정되지 않았습니다.');
      }
    });
  }

  /// 앱이 종료된 상태에서 알림으로 앱을 열었을 때 처리
  Future<void> handleInitialMessage() async {
    _logger.i('초기 메시지 처리 시작');

    final RemoteMessage? initialMessage = await _firebaseMessaging
        .getInitialMessage();

    if (initialMessage != null) {
      _logger.i('=== 앱 종료 상태에서 알림으로 앱 열림 ===');
      _logger.i('메시지 ID: ${initialMessage.messageId}');
      _logger.i('제목: ${initialMessage.notification?.title}');
      _logger.i('내용: ${initialMessage.notification?.body}');
      _logger.i('데이터: ${initialMessage.data}');
      _logger.i('발송 시간: ${initialMessage.sentTime}');
      _logger.i(
        'Android 이미지: ${initialMessage.notification?.android?.imageUrl}',
      );
      _logger.i('=== 초기 메시지 처리 완료 ===');

      if (kDebugMode) {
        print('=== 앱 종료 상태에서 알림으로 앱 열림 ===');
        print('Initial message data: ${initialMessage.data}');
        print(
          'Initial message image: ${initialMessage.notification?.android?.imageUrl}',
        );
        print('=== 초기 메시지 처리 완료 ===');
      }

      // 콜백 실행
      if (_onMessageOpenedApp != null) {
        _logger.i('초기 메시지 콜백 실행');
        _onMessageOpenedApp!.call(initialMessage);
      } else {
        _logger.w('초기 메시지 콜백이 설정되지 않았습니다.');
      }
    } else {
      _logger.i('초기 메시지가 없습니다.');
    }
  }
}
