// lib/models/deal_model.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

part 'deal_model.g.dart'; // This line tells build_runner to generate deal_model.g.dart

@JsonSerializable()
class Deal {
  final int dealId;
  final String dealName;
  final String startDate;
  final String endDate;
  final String banner; // URL for the deal banner image
  final int proId; // This is the specific pro_id for the product size in the deal
  final String productName;
  final String size; // Can be empty string
  final double? mrp; // Can be empty string in API, so nullable double
  final double? sellingPrice; // Can be empty string in API, so nullable double
  final String productImg; // URL for the individual product image in the deal

  Deal({
    required this.dealId,
    required this.dealName,
    required this.startDate,
    required this.endDate,
    required this.banner,
    required this.proId,
    required this.productName,
    required this.size,
    this.mrp,
    this.sellingPrice,
    required this.productImg,
  });

  factory Deal.fromJson(Map<String, dynamic> json) {
    // Helper function to parse double from dynamic, handling empty strings and nulls
    double? parseDouble(dynamic value) {
      if (value == null || value.toString().isEmpty) {
        return null; // Return null if value is null or empty string
      }
      if (value is num) {
        return value.toDouble();
      }
      return double.tryParse(value.toString());
    }

    // Helper to resolve relative URLs to absolute URLs
    String resolveImageUrl(String? relativePath) {
      if (relativePath == null || relativePath.isEmpty) {
        return ''; // Return empty string for invalid/empty paths
      }
      if (relativePath.startsWith('http://') || relativePath.startsWith('https://')) {
        return relativePath; // Already an absolute URL
      }
      // Assuming the base URL is 'https://sgserp.in/erp/' for relative paths like '../uploads/'
      if (relativePath.startsWith('../')) {
        return relativePath.replaceFirst('../', 'https://sgserp.in/erp/');
      }
      return relativePath; // Return as is if it's not a relative path we recognize
    }

    return Deal(
      dealId: json['deal_id'] as int,
      dealName: json['deal_name'] as String,
      startDate: json['start_date'] as String,
      endDate: json['end_date'] as String,
      banner: resolveImageUrl(json['banner'] as String? ?? ''), // Ensure banner is resolved
      proId: (json['pro_id'] as num).toInt(), // pro_id is now int
      productName: json['product_name'] as String,
      size: json['size'] as String? ?? '',
      mrp: parseDouble(json['mrp']),
      sellingPrice: parseDouble(json['selling_price']),
      productImg: resolveImageUrl(json['product_img'] as String? ?? ''), // Ensure productImg is resolved
    );
  }

  Map<String, dynamic> toJson() => _$DealToJson(this);
}
