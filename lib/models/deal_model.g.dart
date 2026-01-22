// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deal_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Deal _$DealFromJson(Map<String, dynamic> json) => Deal(
  dealId: (json['dealId'] as num).toInt(),
  dealName: json['dealName'] as String,
  startDate: json['startDate'] as String,
  endDate: json['endDate'] as String,
  banner: json['banner'] as String,
  proId: (json['proId'] as num).toInt(),
  productName: json['productName'] as String,
  size: json['size'] as String,
  mrp: (json['mrp'] as num?)?.toDouble(),
  sellingPrice: (json['sellingPrice'] as num?)?.toDouble(),
  productImg: json['productImg'] as String,
);

Map<String, dynamic> _$DealToJson(Deal instance) => <String, dynamic>{
  'dealId': instance.dealId,
  'dealName': instance.dealName,
  'startDate': instance.startDate,
  'endDate': instance.endDate,
  'banner': instance.banner,
  'proId': instance.proId,
  'productName': instance.productName,
  'size': instance.size,
  'mrp': instance.mrp,
  'sellingPrice': instance.sellingPrice,
  'productImg': instance.productImg,
};
