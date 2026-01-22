// lib/models/ad_model.dart
import 'package:json_annotation/json_annotation.dart';

part 'ad_model.g.dart'; // This line tells build_runner to generate ad_model.g.dart

@JsonSerializable()
class Ad {
  @JsonKey(name: 'Ad_id') // Map 'Ad_id' from JSON to adId
  final int adId;
  @JsonKey(name: 'Ad_name') // Map 'Ad_name' from JSON to adName
  final String adName;
  @JsonKey(name: 'ad') // Map 'ad' from JSON to banner (assuming 'ad' is the banner URL field)
  final String banner; // This is the new field for the image URL
  // Assuming there's no direct 'url' field in the provided snippet,
  // but if there were, it would be mapped here.
  // For now, I'll remove 'url' as it's not in the provided snippet's JSON structure.
  // If your API provides a separate URL for the ad link, you'd add it back.

  Ad({
    required this.adId,
    required this.adName,
    required this.banner,
  });

  factory Ad.fromJson(Map<String, dynamic> json) {
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

    // Use the @JsonKey annotations for direct mapping.
    // The resolveImageUrl is applied to the 'ad' field to get the 'banner'.
    return Ad(
      adId: json['Ad_id'] as int,
      adName: json['Ad_name'] as String,
      banner: resolveImageUrl(json['ad'] as String?), // Map 'ad' to 'banner' and resolve URL
    );
  }

  Map<String, dynamic> toJson() => _$AdToJson(this);
}
