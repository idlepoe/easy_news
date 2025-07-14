// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'news_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NewsEntity _$NewsEntityFromJson(Map<String, dynamic> json) => _NewsEntity(
      text: json['text'] as String,
      type: json['type'] as String,
      description: json['description'] as String,
    );

Map<String, dynamic> _$NewsEntityToJson(_NewsEntity instance) =>
    <String, dynamic>{
      'text': instance.text,
      'type': instance.type,
      'description': instance.description,
    };
