// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'news_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NewsModel _$NewsModelFromJson(Map<String, dynamic> json) => _NewsModel(
      id: json['id'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String,
      link: json['link'] as String,
      mediaUrl: json['mediaUrl'] as String,
    );

Map<String, dynamic> _$NewsModelToJson(_NewsModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'summary': instance.summary,
      'link': instance.link,
      'mediaUrl': instance.mediaUrl,
    };
