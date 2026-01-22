// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductSize _$ProductSizeFromJson(Map<String, dynamic> json) => ProductSize(
  proId: (json['proId'] as num).toInt(),
  size: json['size'] as String,
  price: (json['price'] as num).toDouble(),
  sellingPrice: (json['sellingPrice'] as num?)?.toDouble(),
);

Map<String, dynamic> _$ProductSizeToJson(ProductSize instance) =>
    <String, dynamic>{
      'proId': instance.proId,
      'size': instance.size,
      'price': instance.price,
      'sellingPrice': instance.sellingPrice,
    };

Product _$ProductFromJson(Map<String, dynamic> json) => Product(
    mainProductId: json['mainProductId'] as String,
    title: json['title'] as String,
    subtitle: json['subtitle'] as String,
    imageUrl: json['imageUrl'] as String,
    category: json['category'] as String,
    availableSizes:
        (json['availableSizes'] as List<dynamic>)
            .map((e) => ProductSize.fromJson(e as Map<String, dynamic>))
            .toList(),
  )
  ..selectedUnit = ProductSize.fromJson(
    json['selectedUnit'] as Map<String, dynamic>,
  );

Map<String, dynamic> _$ProductToJson(Product instance) => <String, dynamic>{
  'title': instance.title,
  'subtitle': instance.subtitle,
  'imageUrl': instance.imageUrl,
  'category': instance.category,
  'availableSizes': instance.availableSizes,
  'mainProductId': instance.mainProductId,
  'selectedUnit': instance.selectedUnit,
};
