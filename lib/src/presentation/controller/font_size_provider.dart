import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class NewsBodyDisplayNotifier extends StateNotifier<NewsBodyDisplayType> {
  NewsBodyDisplayNotifier() : super(NewsBodyDisplayType.description) {
    _loadType();
  }

  Future<void> _loadType() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_newsBodyDisplayKey);
    if (value != null) {
      state = NewsBodyDisplayType.values.firstWhere(
        (e) => e.name == value,
        orElse: () => NewsBodyDisplayType.description,
      );
    }
  }

  Future<void> setType(NewsBodyDisplayType type) async {
    state = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_newsBodyDisplayKey, type.name);
  }
}

final newsBodyDisplayProvider = StateNotifierProvider<NewsBodyDisplayNotifier, NewsBodyDisplayType>(
  (ref) => NewsBodyDisplayNotifier(),
);
