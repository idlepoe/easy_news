// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'news_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

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

  /// Serializes this NewsEntity to a JSON map.
  Map<String, dynamic> toJson();

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

  @JsonKey(includeFromJson: false, includeToJson: false)
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
@JsonSerializable()
class _NewsEntity implements NewsEntity {
  const _NewsEntity(
      {required this.text, required this.type, required this.description});
  factory _NewsEntity.fromJson(Map<String, dynamic> json) =>
      _$NewsEntityFromJson(json);

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
  Map<String, dynamic> toJson() {
    return _$NewsEntityToJson(
      this,
    );
  }

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

  @JsonKey(includeFromJson: false, includeToJson: false)
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
