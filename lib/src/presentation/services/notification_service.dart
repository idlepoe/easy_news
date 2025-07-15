import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import '../../data/services/fcm_service.dart';
import '../../domain/entity/news.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final Logger _logger = Logger();
  final FCMService _fcmService = FCMService();

  // 전역 네비게이터 키
  static final GlobalKey<NavigatorState> _navigatorKey =
      GlobalKey<NavigatorState>();

  // 네비게이터 키 getter
  static GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  /// 알림 서비스 초기화
  void initialize() {
    _logger.i('=== 알림 서비스 초기화 시작 ===');

    _fcmService.setMessageCallbacks(
      onMessage: _handleForegroundMessage,
      onMessageOpenedApp: _handleBackgroundMessage,
    );

    // 앱이 종료된 상태에서 알림으로 열렸을 때 처리
    _handleInitialMessage();

    _logger.i('=== 알림 서비스 초기화 완료 ===');
  }

  /// 앱이 종료된 상태에서 알림으로 앱을 열었을 때 처리
  Future<void> _handleInitialMessage() async {
    try {
      _logger.i('초기 메시지 처리 시작');

      final RemoteMessage? initialMessage = await FirebaseMessaging.instance
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

        // 앱이 완전히 로드될 때까지 기다린 후 네비게이션 실행
        Future.delayed(const Duration(seconds: 3), () {
          _logger.i('초기 메시지 네비게이션 지연 실행');
          _processMessage(initialMessage);
        });
      } else {
        _logger.i('초기 메시지가 없습니다.');
      }
    } catch (e) {
      _logger.e('초기 메시지 처리 중 오류: $e');
    }
  }

  /// 포그라운드 메시지 처리 (앱이 실행 중일 때)
  void _handleForegroundMessage(RemoteMessage message) {
    _logger.i('=== 포그라운드 메시지 처리 시작 ===');
    _logger.i('메시지 ID: ${message.messageId}');
    _logger.i('제목: ${message.notification?.title}');
    _logger.i('내용: ${message.notification?.body}');
    _logger.i('데이터: ${message.data}');
    _logger.i('발송 시간: ${message.sentTime}');
    _logger.i('Android 이미지: ${message.notification?.android?.imageUrl}');
    _logger.i('=== 포그라운드 메시지 처리 완료 ===');

    // 포그라운드에서는 FCM의 기본 알림만 사용
    // 사용자가 알림을 탭하면 자동으로 백그라운드 메시지 핸들러가 호출됨
  }

  /// 백그라운드 메시지 처리 (알림을 탭해서 앱을 열었을 때)
  void _handleBackgroundMessage(RemoteMessage message) {
    _logger.i('=== 백그라운드 메시지 처리 시작 ===');
    _logger.i('메시지 ID: ${message.messageId}');
    _logger.i('제목: ${message.notification?.title}');
    _logger.i('내용: ${message.notification?.body}');
    _logger.i('데이터: ${message.data}');
    _logger.i('발송 시간: ${message.sentTime}');
    _logger.i('Android 이미지: ${message.notification?.android?.imageUrl}');
    _logger.i('=== 백그라운드 메시지 처리 완료 ===');

    // 즉시 메시지 처리 (지연 제거)
    _logger.i('백그라운드 메시지 즉시 처리');
    _processMessage(message);
  }

  /// 메시지 처리 공통 함수
  void _processMessage(RemoteMessage message) {
    try {
      _logger.i('=== 메시지 처리 공통 함수 시작 ===');

      final String? newsId = message.data['newsId'];
      final String? type = message.data['type'];
      final String? title = message.data['title'];
      final String? summary = message.data['summary'];
      final String? imageUrl = message.data['imageUrl'];

      _logger.i('newsId: $newsId');
      _logger.i('type: $type');
      _logger.i('title: $title');
      _logger.i('summary: $summary');
      _logger.i('imageUrl: $imageUrl');

      if (newsId != null && newsId.isNotEmpty) {
        _logger.i('newsId가 유효합니다. 네비게이션 실행');
        _navigateToNewsDetail(newsId);
      } else {
        _logger.w('newsId가 없거나 비어있습니다.');
        _logger.w('전체 데이터: ${message.data}');
      }

      _logger.i('=== 메시지 처리 공통 함수 완료 ===');
    } catch (e) {
      _logger.e('메시지 처리 중 오류: $e');
      _logger.e('스택 트레이스: ${StackTrace.current}');
    }
  }

  /// 뉴스 상세 화면으로 이동
  void _navigateToNewsDetail(String newsId) {
    try {
      _logger.i('=== 뉴스 상세 화면 이동 시도 ===');
      _logger.i('newsId: $newsId');

      // 임시 News 객체 생성 (상세 화면에서 실제 데이터를 로드)
      final tempNews = News(
        id: newsId,
        title: '로딩 중...',
        description: '',
        link: '',
        mediaUrl: '',
        category: '',
        pubDate: DateTime.now(),
        entities: [],
        viewCount: 0,
      );

      _logger.i('임시 News 객체 생성 완료');

      // go_router를 사용하여 네비게이션
      final context = _navigatorKey.currentContext;
      if (context != null) {
        _logger.i('Context 찾음, 네비게이션 실행');

        // go_router의 push 대신 go 사용 (더 안정적)
        context.go('/news/$newsId', extra: tempNews);
        _logger.i('뉴스 상세 화면으로 이동 완료: $newsId');
      } else {
        _logger.w('Context를 찾을 수 없습니다. 잠시 후 다시 시도합니다.');
        _logger.w(
          'navigatorKey.currentContext: ${_navigatorKey.currentContext}',
        );

        // 1초 후 다시 시도
        Future.delayed(const Duration(seconds: 1), () {
          _logger.i('Context 재시도');
          _navigateToNewsDetail(newsId);
        });
      }

      _logger.i('=== 뉴스 상세 화면 이동 시도 완료 ===');
    } catch (e) {
      _logger.e('뉴스 상세 화면 이동 실패: $e');
      _logger.e('스택 트레이스: ${StackTrace.current}');

      // 오류 발생 시 2초 후 다시 시도
      Future.delayed(const Duration(seconds: 2), () {
        try {
          _logger.i('네비게이션 재시도');
          final tempNews = News(
            id: newsId,
            title: '로딩 중...',
            description: '',
            link: '',
            mediaUrl: '',
            category: '',
            pubDate: DateTime.now(),
            entities: [],
            viewCount: 0,
          );
          final context = _navigatorKey.currentContext;
          if (context != null) {
            context.go('/news/$newsId', extra: tempNews);
            _logger.i('뉴스 상세 화면 이동 재시도 성공: $newsId');
          } else {
            _logger.e('재시도에서도 Context를 찾을 수 없습니다.');
          }
        } catch (retryError) {
          _logger.e('뉴스 상세 화면 이동 재시도 실패: $retryError');
        }
      });
    }
  }
}
