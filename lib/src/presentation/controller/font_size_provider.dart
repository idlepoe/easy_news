import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/fcm_service.dart';

const _fontSizeKey = 'font_size';
const defaultFontSize = 16.0;
const fontSizeOptions = [12.0, 14.0, 16.0, 18.0, 20.0];

class FontSizeNotifier extends StateNotifier<double> {
  FontSizeNotifier() : super(defaultFontSize) {
    _loadFontSize();
  }

  Future<void> _loadFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getDouble(_fontSizeKey);
    if (value != null && fontSizeOptions.contains(value)) {
      state = value;
    }
  }

  Future<void> setFontSize(double size) async {
    state = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, size);
  }
}

final fontSizeProvider = StateNotifierProvider<FontSizeNotifier, double>(
  (ref) => FontSizeNotifier(),
);

// 뉴스 본문 표시 방식
enum NewsBodyDisplayType { description, summary, summary3lines, easySummary }

const _newsBodyDisplayKey = 'news_body_display_type';
const _popularNewsNotifyKey = 'popular_news_notify';

class NewsBodyDisplayNotifier extends StateNotifier<NewsBodyDisplayType> {
  NewsBodyDisplayNotifier() : super(NewsBodyDisplayType.easySummary) {
    _loadType();
  }

  Future<void> _loadType() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_newsBodyDisplayKey);
    if (value != null) {
      state = NewsBodyDisplayType.values.firstWhere(
        (e) => e.name == value,
        orElse: () => NewsBodyDisplayType.easySummary,
      );
    }
  }

  Future<void> setType(NewsBodyDisplayType type) async {
    state = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_newsBodyDisplayKey, type.name);
  }
}

final newsBodyDisplayProvider =
    StateNotifierProvider<NewsBodyDisplayNotifier, NewsBodyDisplayType>(
      (ref) => NewsBodyDisplayNotifier(),
    );

class PopularNewsNotifyNotifier extends StateNotifier<bool> {
  final FCMService _fcmService = FCMService();

  PopularNewsNotifyNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_popularNewsNotifyKey) ?? false;

    // 기존에 알림이 켜져 있었다면 토픽 구독 처리
    if (state) {
      await _fcmService.subscribeToSummary3Lines();
    }
  }

  Future<void> setNotify(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_popularNewsNotifyKey, value);

    // FCM 토픽 구독/해제 처리
    if (value) {
      await _fcmService.subscribeToSummary3Lines();
    } else {
      await _fcmService.unsubscribeFromSummary3Lines();
    }
  }
}

final popularNewsNotifyProvider =
    StateNotifierProvider<PopularNewsNotifyNotifier, bool>(
      (ref) => PopularNewsNotifyNotifier(),
    );
