import 'package:freezed_annotation/freezed_annotation.dart';

part 'news.freezed.dart';

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
  }) = _News;
}

@freezed
abstract class NewsEntity with _$NewsEntity {
  const factory NewsEntity({
    required String text,
    required String type,
    required String description,
  }) = _NewsEntity;
}
