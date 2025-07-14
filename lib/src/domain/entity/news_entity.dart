import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'news_entity.freezed.dart';
part 'news_entity.g.dart';

@freezed
abstract class NewsEntity with _$NewsEntity {
  const factory NewsEntity({
    required String text,
    required String type,
    required String description,
  }) = _NewsEntity;

  factory NewsEntity.fromJson(Map<String, dynamic> json) =>
      _$NewsEntityFromJson(json);
}
