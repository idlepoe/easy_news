import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'news_entity.dart';

part 'news.freezed.dart';
part 'news.g.dart';

@freezed
abstract class News with _$News {
  const factory News({
    required String id,
    required String title,
    required String description,
    required String link,
    required String mediaUrl,
    required String category,
    required DateTime pubDate,
    String? summary,
    String? summary3lines,
    String? easySummary,
    List<NewsEntity>? entities,
    int? viewCount,
  }) = _News;

  factory News.fromJson(Map<String, dynamic> json) => _$NewsFromJson(json);
}
