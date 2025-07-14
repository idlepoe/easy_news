// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'news.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_News _$NewsFromJson(Map<String, dynamic> json) => _News(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      link: json['link'] as String,
      mediaUrl: json['mediaUrl'] as String,
      category: json['category'] as String,
      pubDate: DateTime.parse(json['pubDate'] as String),
      summary: json['summary'] as String?,
      summary3lines: json['summary3lines'] as String?,
      easySummary: json['easySummary'] as String?,
      entities: (json['entities'] as List<dynamic>?)
          ?.map((e) => NewsEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
      viewCount: (json['viewCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$NewsToJson(_News instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'link': instance.link,
      'mediaUrl': instance.mediaUrl,
      'category': instance.category,
      'pubDate': instance.pubDate.toIso8601String(),
      'summary': instance.summary,
      'summary3lines': instance.summary3lines,
      'easySummary': instance.easySummary,
      'entities': instance.entities,
      'viewCount': instance.viewCount,
    };
