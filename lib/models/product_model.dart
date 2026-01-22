import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
part 'product_model.g.dart';

// Represents a single available size/unit option for a product.
@JsonSerializable()
class ProductSize {
  final int proId; // Unique ID for this specific size/unit of the product
  final String size;
  final double price; // This maps to 'mrp' from the API
  final double? sellingPrice; // New field for 'selling_price'

  ProductSize({
    required this.proId,
    required this.size,
    required this.price,
    this.sellingPrice,
  });

  // Factory constructor to create a ProductSize from JSON
  factory ProductSize.fromJson(Map<String, dynamic> json) {
    debugPrint('ProductSize.fromJson: Raw JSON for size: $json');
    final int parsedProId = (json['pro_id'] as num?)?.toInt() ?? 0; // Ensure pro_id is parsed
    final double parsedPrice = (json['mrp'] as num?)?.toDouble() ?? 0.0;
    final double? parsedSellingPrice = (json['selling_price'] as num?)?.toDouble();
    final String parsedSize = (json['size'] as String?)?.trim() ?? 'Unit';

    if (parsedProId == 0) {
      debugPrint('Warning: ProductSize JSON had missing or zero pro_id, defaulting to 0. Full JSON: $json');
    }
    if (parsedSize.isEmpty) {
      debugPrint('Warning: ProductSize JSON had empty size, defaulting to "Unit". Full JSON: $json');
    }

    return ProductSize(
      proId: parsedProId,
      size: parsedSize,
      price: parsedPrice,
      sellingPrice: parsedSellingPrice,
    );
  }

  // Convert ProductSize to JSON for caching.
  // The keys here are updated to be consistent with the keys in `fromJson`
  // and the API response (`mrp` instead of `price`).
  Map<String, dynamic> toJson() {
    return {
      'pro_id': proId,
      'size': size,
      'mrp': price, // Use 'mrp' to match the key expected by fromJson
      'selling_price': sellingPrice, // Use 'selling_price' to match fromJson
    };
  }

  // Override == and hashCode for proper comparison in Sets (now includes proId for uniqueness)
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ProductSize &&
              runtimeType == other.runtimeType &&
              proId == other.proId && // Compare by proId for uniqueness
              size == other.size; // Also compare by size for robustness

  @override
  int get hashCode => proId.hashCode ^ size.hashCode; // Hash code based on proId and size
}

@JsonSerializable()
// Represents a single product in the application.
class Product extends ChangeNotifier {
  final String _mainProductId; // A stable ID for the product itself (e.g., from pro_name + category)
  final String title;
  final String subtitle;
  final String imageUrl;
  final String category; // Added category
  final List<ProductSize> availableSizes; // List of available sizes with their prices
  ProductSize _selectedUnit; // Private variable for selected unit (now a ProductSize object)

  Product({
    required String mainProductId, // A stable identifier for the product group
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.category,
    required List<ProductSize> availableSizes,
    int? initialSelectedUnitProId, // Pass the pro_id of the initially selected unit
  })  : _mainProductId = mainProductId,
        availableSizes = availableSizes.isEmpty
            ? [ProductSize(proId: 0, size: 'Unit', price: 0.0, sellingPrice: 0.0)] // Default if empty
            : availableSizes,
        _selectedUnit = _resolveSelectedUnit(initialSelectedUnitProId, availableSizes.isEmpty // Pass the potentially defaulted list
            ? [ProductSize(proId: 0, size: 'Unit', price: 0.0, sellingPrice: 0.0)]
            : availableSizes) {
    debugPrint('Product created: MainID=$_mainProductId, Title=$title, Category=$category, Initial Selected Unit ProId=${_selectedUnit.proId}, Available Sizes=${this.availableSizes.map((s) => '${s.size}(${s.proId}): ${s.price}').toList()}, Price Per Selected Unit: ${pricePerSelectedUnit}');
  }

  // Helper method to resolve selectedUnit
  static ProductSize _resolveSelectedUnit(int? proId, List<ProductSize> sizes) {
    if (sizes.isEmpty) {
      debugPrint('Warning: _resolveSelectedUnit called with empty sizes list. Defaulting to dummy unit.');
      return ProductSize(proId: 0, size: 'Unit', price: 0.0, sellingPrice: 0.0);
    }
    // Check if the provided proId is valid and exists in the sizes list
    if (proId != null && sizes.any((s) => s.proId == proId)) {
      final resolved = sizes.firstWhere((s) => s.proId == proId);
      debugPrint('Resolved selected unit to: ${resolved.size} (ProId: ${resolved.proId})');
      return resolved;
    }
    // If proId is null or not found, return the first available size.
    debugPrint('Provided proId "$proId" not found or null. Defaulting to first available size: ${sizes.first.size} (ProId: ${sizes.first.proId})');
    return sizes.first;
  }

  // Factory constructor to create a Product from JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    // Manually parse the list of ProductSize objects
    final List<ProductSize> parsedAvailableSizes = (json['availableSizes'] as List<dynamic>?)
        ?.map((e) => ProductSize.fromJson(e as Map<String, dynamic>))
        .toList() ??
        [];

    // Determine the initial selected unit's pro_id from JSON if available, otherwise use default logic
    int? initialSelectedUnitProId;
    if (json.containsKey('selectedUnitProId')) {
      initialSelectedUnitProId = (json['selectedUnitProId'] as num?)?.toInt();
    } else if (parsedAvailableSizes.isNotEmpty) {
      initialSelectedUnitProId = parsedAvailableSizes.first.proId;
    }

    return Product(
      mainProductId: json['mainProductId'] as String, // Assuming mainProductId is stored in JSON
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      imageUrl: json['imageUrl'] as String,
      category: json['category'] as String,
      availableSizes: parsedAvailableSizes,
      initialSelectedUnitProId: initialSelectedUnitProId,
    );
  }

  // Convert Product to JSON for caching
  Map<String, dynamic> toJson() {
    return {
      'mainProductId': _mainProductId,
      'title': title,
      'subtitle': subtitle,
      'imageUrl': imageUrl,
      'category': category,
      'availableSizes': availableSizes.map((s) => s.toJson()).toList(),
      'selectedUnitProId': _selectedUnit.proId, // Store the pro_id of the selected unit
    };
  }

  // The 'id' of the Product now dynamically returns the pro_id of the selected unit.
  // This is the unique identifier for cart/wishlist operations for a specific size.
  String get id => _selectedUnit.proId.toString();
  String get mainProductId => _mainProductId; // A stable ID for the product group

  ProductSize get selectedUnit => _selectedUnit;

  // Setter for selected unit (updates the state and notifies listeners)
  set selectedUnit(ProductSize newUnit) {
    if (_selectedUnit.proId != newUnit.proId) {
      if (availableSizes.any((s) => s.proId == newUnit.proId)) {
        _selectedUnit = newUnit;
        notifyListeners(); // Notify consumers when selectedUnit changes
        debugPrint('Selected unit for product "$title" changed to: ${newUnit.size} (ProId: ${newUnit.proId})');
      } else {
        debugPrint('Attempted to set invalid selectedUnit: ${newUnit.size} (ProId: ${newUnit.proId}) for product "$title". Available: ${availableSizes.map((s) => '${s.size}(${s.proId})').toList()}');
      }
    }
  }

  // Getter to dynamically get the price based on the selected unit (mrp)
  double? get pricePerSelectedUnit {
    return _selectedUnit.price;
  }

  // Getter to dynamically get the selling price based on the selected unit
  double? get sellingPricePerSelectedUnit {
    return _selectedUnit.sellingPrice;
  }

  // Method to create a copy of the product, potentially with new values.
  Product copyWith({
    String? mainProductId,
    String? title,
    String? subtitle,
    String? imageUrl,
    String? category,
    List<ProductSize>? availableSizes,
    ProductSize? selectedUnit, // Now takes a ProductSize object
  }) {
    final newAvailableSizes = availableSizes ?? this.availableSizes;
    final resolvedSelectedUnit = selectedUnit ?? _selectedUnit; // Use provided or current selected unit

    return Product(
      mainProductId: mainProductId ?? _mainProductId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      availableSizes: newAvailableSizes,
      initialSelectedUnitProId: resolvedSelectedUnit.proId, // Pass the pro_id of the resolved unit
    );
  }
}
