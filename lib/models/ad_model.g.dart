// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ad_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Ad _$AdFromJson(Map<String, dynamic> json) => Ad(
  adId: (json['Ad_id'] as num).toInt(),
  adName: json['Ad_name'] as String,
  banner: json['ad'] as String,
);

Map<String, dynamic> _$AdToJson(Ad instance) => <String, dynamic>{
  'Ad_id': instance.adId,
  'Ad_name': instance.adName,
  'ad': instance.banner,
};
