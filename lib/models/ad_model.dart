// ad_model.dart
import 'package:json_annotation/json_annotation.dart';

part 'ad_model.g.dart';

@JsonSerializable()
class Ad {
  @JsonKey(name: 'ad_id')
  final int adId;
  
  @JsonKey(name: 'ad_name')
  final String adName;
  
  @JsonKey(name: 'ad')
  final String banner;

  Ad({
    required this.adId,
    required this.adName,
    required this.banner,
  });

  factory Ad.fromJson(Map<String, dynamic> json) => _$AdFromJson(json);
  Map<String, dynamic> toJson() => _$AdToJson(this);
}