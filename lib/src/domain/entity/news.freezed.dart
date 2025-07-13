// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'news.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$News {
  String get id;
  String get title;
  String get description;
  String get link;
  String get mediaUrl;
  String get category;
  DateTime get pubDate;
  String? get summary;
  String? get summary3lines;
  String? get easySummary;
  List<NewsEntity>? get entities;

  /// Create a copy of News
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $NewsCopyWith<News> get copyWith =>
      _$NewsCopyWithImpl<News>(this as News, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is News &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.link, link) || other.link == link) &&
            (identical(other.mediaUrl, mediaUrl) ||
                other.mediaUrl == mediaUrl) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.pubDate, pubDate) || other.pubDate == pubDate) &&
            (identical(other.summary, summary) || other.summary == summary) &&
            (identical(other.summary3lines, summary3lines) ||
                other.summary3lines == summary3lines) &&
            (identical(other.easySummary, easySummary) ||
                other.easySummary == easySummary) &&
            const DeepCollectionEquality().equals(other.entities, entities));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      description,
      link,
      mediaUrl,
      category,
      pubDate,
      summary,
      summary3lines,
      easySummary,
      const DeepCollectionEquality().hash(entities));

  @override
  String toString() {
    return 'News(id: $id, title: $title, description: $description, link: $link, mediaUrl: $mediaUrl, category: $category, pubDate: $pubDate, summary: $summary, summary3lines: $summary3lines, easySummary: $easySummary, entities: $entities)';
  }
}

/// @nodoc
abstract mixin class $NewsCopyWith<$Res> {
  factory $NewsCopyWith(News value, $Res Function(News) _then) =
      _$NewsCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String title,
      String description,
      String link,
      String mediaUrl,
      String category,
      DateTime pubDate,
      String? summary,
      String? summary3lines,
      String? easySummary,
      List<NewsEntity>? entities});
}

/// @nodoc
class _$NewsCopyWithImpl<$Res> implements $NewsCopyWith<$Res> {
  _$NewsCopyWithImpl(this._self, this._then);

  final News _self;
  final $Res Function(News) _then;

  /// Create a copy of News
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? link = null,
    Object? mediaUrl = null,
    Object? category = null,
    Object? pubDate = null,
    Object? summary = freezed,
    Object? summary3lines = freezed,
    Object? easySummary = freezed,
    Object? entities = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      link: null == link
          ? _self.link
          : link // ignore: cast_nullable_to_non_nullable
              as String,
      mediaUrl: null == mediaUrl
          ? _self.mediaUrl
          : mediaUrl // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _self.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      pubDate: null == pubDate
          ? _self.pubDate
          : pubDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      summary: freezed == summary
          ? _self.summary
          : summary // ignore: cast_nullable_to_non_nullable
              as String?,
      summary3lines: freezed == summary3lines
          ? _self.summary3lines
          : summary3lines // ignore: cast_nullable_to_non_nullable
              as String?,
      easySummary: freezed == easySummary
          ? _self.easySummary
          : easySummary // ignore: cast_nullable_to_non_nullable
              as String?,
      entities: freezed == entities
          ? _self.entities
          : entities // ignore: cast_nullable_to_non_nullable
              as List<NewsEntity>?,
    ));
  }
}

/// @nodoc

class _News implements News {
  const _News(
      {required this.id,
      required this.title,
      required this.description,
      required this.link,
      required this.mediaUrl,
      required this.category,
      required this.pubDate,
      this.summary,
      this.summary3lines,
      this.easySummary,
      final List<NewsEntity>? entities})
      : _entities = entities;

  @override
  final String id;
  @override
  final String title;
  @override
  final String description;
  @override
  final String link;
  @override
  final String mediaUrl;
  @override
  final String category;
  @override
  final DateTime pubDate;
  @override
  final String? summary;
  @override
  final String? summary3lines;
  @override
  final String? easySummary;
  final List<NewsEntity>? _entities;
  @override
  List<NewsEntity>? get entities {
    final value = _entities;
    if (value == null) return null;
    if (_entities is EqualUnmodifiableListView) return _entities;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  /// Create a copy of News
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$NewsCopyWith<_News> get copyWith =>
      __$NewsCopyWithImpl<_News>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _News &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.link, link) || other.link == link) &&
            (identical(other.mediaUrl, mediaUrl) ||
                other.mediaUrl == mediaUrl) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.pubDate, pubDate) || other.pubDate == pubDate) &&
            (identical(other.summary, summary) || other.summary == summary) &&
            (identical(other.summary3lines, summary3lines) ||
                other.summary3lines == summary3lines) &&
            (identical(other.easySummary, easySummary) ||
                other.easySummary == easySummary) &&
            const DeepCollectionEquality().equals(other._entities, _entities));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      description,
      link,
      mediaUrl,
      category,
      pubDate,
      summary,
      summary3lines,
      easySummary,
      const DeepCollectionEquality().hash(_entities));

  @override
  String toString() {
    return 'News(id: $id, title: $title, description: $description, link: $link, mediaUrl: $mediaUrl, category: $category, pubDate: $pubDate, summary: $summary, summary3lines: $summary3lines, easySummary: $easySummary, entities: $entities)';
  }
}

/// @nodoc
abstract mixin class _$NewsCopyWith<$Res> implements $NewsCopyWith<$Res> {
  factory _$NewsCopyWith(_News value, $Res Function(_News) _then) =
      __$NewsCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      String description,
      String link,
      String mediaUrl,
      String category,
      DateTime pubDate,
      String? summary,
      String? summary3lines,
      String? easySummary,
      List<NewsEntity>? entities});
}

/// @nodoc
class __$NewsCopyWithImpl<$Res> implements _$NewsCopyWith<$Res> {
  __$NewsCopyWithImpl(this._self, this._then);

  final _News _self;
  final $Res Function(_News) _then;

  /// Create a copy of News
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? link = null,
    Object? mediaUrl = null,
    Object? category = null,
    Object? pubDate = null,
    Object? summary = freezed,
    Object? summary3lines = freezed,
    Object? easySummary = freezed,
    Object? entities = freezed,
  }) {
    return _then(_News(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      link: null == link
          ? _self.link
          : link // ignore: cast_nullable_to_non_nullable
              as String,
      mediaUrl: null == mediaUrl
          ? _self.mediaUrl
          : mediaUrl // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _self.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      pubDate: null == pubDate
          ? _self.pubDate
          : pubDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      summary: freezed == summary
          ? _self.summary
          : summary // ignore: cast_nullable_to_non_nullable
              as String?,
      summary3lines: freezed == summary3lines
          ? _self.summary3lines
          : summary3lines // ignore: cast_nullable_to_non_nullable
              as String?,
      easySummary: freezed == easySummary
          ? _self.easySummary
          : easySummary // ignore: cast_nullable_to_non_nullable
              as String?,
      entities: freezed == entities
          ? _self._entities
          : entities // ignore: cast_nullable_to_non_nullable
              as List<NewsEntity>?,
    ));
  }
}

/// @nodoc
mixin _$NewsEntity {
  String get text;
  String get type;
  String get description;

  /// Create a copy of NewsEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $NewsEntityCopyWith<NewsEntity> get copyWith =>
      _$NewsEntityCopyWithImpl<NewsEntity>(this as NewsEntity, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is NewsEntity &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @override
  int get hashCode => Object.hash(runtimeType, text, type, description);

  @override
  String toString() {
    return 'NewsEntity(text: $text, type: $type, description: $description)';
  }
}

/// @nodoc
abstract mixin class $NewsEntityCopyWith<$Res> {
  factory $NewsEntityCopyWith(
          NewsEntity value, $Res Function(NewsEntity) _then) =
      _$NewsEntityCopyWithImpl;
  @useResult
  $Res call({String text, String type, String description});
}

/// @nodoc
class _$NewsEntityCopyWithImpl<$Res> implements $NewsEntityCopyWith<$Res> {
  _$NewsEntityCopyWithImpl(this._self, this._then);

  final NewsEntity _self;
  final $Res Function(NewsEntity) _then;

  /// Create a copy of NewsEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? text = null,
    Object? type = null,
    Object? description = null,
  }) {
    return _then(_self.copyWith(
      text: null == text
          ? _self.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _NewsEntity implements NewsEntity {
  const _NewsEntity(
      {required this.text, required this.type, required this.description});

  @override
  final String text;
  @override
  final String type;
  @override
  final String description;

  /// Create a copy of NewsEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$NewsEntityCopyWith<_NewsEntity> get copyWith =>
      __$NewsEntityCopyWithImpl<_NewsEntity>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _NewsEntity &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @override
  int get hashCode => Object.hash(runtimeType, text, type, description);

  @override
  String toString() {
    return 'NewsEntity(text: $text, type: $type, description: $description)';
  }
}

/// @nodoc
abstract mixin class _$NewsEntityCopyWith<$Res>
    implements $NewsEntityCopyWith<$Res> {
  factory _$NewsEntityCopyWith(
          _NewsEntity value, $Res Function(_NewsEntity) _then) =
      __$NewsEntityCopyWithImpl;
  @override
  @useResult
  $Res call({String text, String type, String description});
}

/// @nodoc
class __$NewsEntityCopyWithImpl<$Res> implements _$NewsEntityCopyWith<$Res> {
  __$NewsEntityCopyWithImpl(this._self, this._then);

  final _NewsEntity _self;
  final $Res Function(_NewsEntity) _then;

  /// Create a copy of NewsEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? text = null,
    Object? type = null,
    Object? description = null,
  }) {
    return _then(_NewsEntity(
      text: null == text
          ? _self.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
