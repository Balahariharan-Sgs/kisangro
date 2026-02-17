import 'package:flutter/foundation.dart';
import 'package:kisangro/models/product_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collection/collection.dart';
import 'package:kisangro/services/product_service.dart';
import 'database_helper.dart';

class WishlistItem extends ChangeNotifier {
  final String cus_id;
  final int pro_id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String category;
  final String selectedUnitSize;
  final double pricePerUnit;

  WishlistItem({
    required this.cus_id,
    required this.pro_id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.category,
    required this.selectedUnitSize,
    required this.pricePerUnit,
  });

  Map<String, dynamic> toJson() {
    return {
      'cus_id': cus_id,
      'pro_id': pro_id,
      'title': title,
      'subtitle': subtitle,
      'imageUrl': imageUrl,
      'category': category,
      'selectedUnitSize': selectedUnitSize,
      'pricePerUnit': pricePerUnit,
    };
  }

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      cus_id: json['cus_id'] as String,
      pro_id: json['pro_id'] as int,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      imageUrl: json['imageUrl'] as String,
      category: json['category'] as String,
      selectedUnitSize: json['selectedUnitSize'] as String,
      pricePerUnit: json['pricePerUnit'] as double,
    );
  }
}

class WishlistModel extends ChangeNotifier {
  final List<WishlistItem> _items = [];
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  int? _cusId;
  Future<void>? _loadFuture;
  bool _isInitialized = false;

  static const String _apiUrl = 'https://erpsmart.in/total/api/m_api/';
  static const String _cid = '85788578';
  static const String _ln = '322334';
  static const String _lt = '233432';
  static const String _deviceId = '122334';

  List<WishlistItem> get items => List.unmodifiable(_items);
  bool get isInitialized => _isInitialized;

  WishlistModel() {
    _loadFuture = _initializeWishlist();
  }

  Future<void> _initializeWishlist() async {
    await _loadCusId();
    if (_cusId != null) {
      await _loadWishlistFromApiAndSyncDb();
    } else {
      await _loadWishlistItemsFromDb();
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _loadCusId() async {
    final prefs = await SharedPreferences.getInstance();
    _cusId = prefs.getInt('cus_id');
    print("dxbdvhjxbvjxh$_cusId");
  }


  Future<void> _ensureLoaded() async {
    if (_loadFuture != null) await _loadFuture;
  }

  Future<void> _loadWishlistItemsFromDb() async {
    try {
      _items.clear();
      final items = await _dbHelper.getWishlistItems(_cusId?.toString() ?? 'guest');
      _items.addAll(items);
    } catch (e) {
      debugPrint('Error loading wishlist from DB: $e');
      _items.clear();
    }
  }

  Future<void> _loadWishlistFromApiAndSyncDb() async {
    try {
      final response = await _callWishlistApi('1019'); // Fetch wishlist type
      if (response['error'] == false && response['data'] is List) {
        // First get current local items
        List<WishlistItem> localItems;
        try {
          localItems = await _dbHelper.getWishlistItems(_cusId.toString());
        } catch (e) {
          debugPrint('Error loading local wishlist items: $e');
          localItems = [];
        }

        // Clear only if API has items (don't clear if API returns empty)
        if (response['data'].isNotEmpty) {
          try {
            await _dbHelper.clearWishlist(_cusId.toString());
          } catch (e) {
            debugPrint('Error clearing wishlist: $e');
          }
        }

        _items.clear();

        for (var item in response['data']) {
          try {
            final product = ProductService.getProductById(item['pro_id'].toString());
            if (product != null) {
              final wishlistItem = WishlistItem(
                cus_id: _cusId.toString(),
                pro_id: product.selectedUnit.proId,
                title: product.title,
                subtitle: product.subtitle,
                imageUrl: product.imageUrl,
                category: product.category,
                selectedUnitSize: product.selectedUnit.size,
                pricePerUnit: product.sellingPricePerSelectedUnit ?? 0.0,
              );

              // Only add if not already in local items (prevent duplicates)
              if (!localItems.any((local) => local.pro_id == wishlistItem.pro_id)) {
                try {
                  await _dbHelper.insertWishlistItem(wishlistItem);
                } catch (e) {
                  debugPrint('Error inserting wishlist item: $e');
                }
              }

              _items.add(wishlistItem);
            } else {
              // If product not found in ProductService, create a basic item
              final wishlistItem = WishlistItem(
                cus_id: _cusId.toString(),
                pro_id: int.parse(item['pro_id'].toString()),
                title: item['pro_name'] ?? 'Unknown Product',
                subtitle: item['technical_name'] ?? '',
                imageUrl: item['image'] ?? '',
                category: item['cat_id']?.toString() ?? '',
                selectedUnitSize: 'Unit', // Default size
                pricePerUnit: 0.0, // Default price
              );

              // Only add if not already in local items (prevent duplicates)
              if (!localItems.any((local) => local.pro_id == wishlistItem.pro_id)) {
                try {
                  await _dbHelper.insertWishlistItem(wishlistItem);
                } catch (e) {
                  debugPrint('Error inserting wishlist item: $e');
                }
              }

              _items.add(wishlistItem);
            }
          } catch (e) {
            debugPrint('Error processing wishlist item: $e');
          }
        }

        // Add back any local items that weren't in the API response
        for (var localItem in localItems) {
          if (!_items.any((item) => item.pro_id == localItem.pro_id)) {
            _items.add(localItem);
            try {
              await _dbHelper.insertWishlistItem(localItem);
            } catch (e) {
              debugPrint('Error re-inserting local wishlist item: $e');
            }
          }
        }
      } else {
        // If API returns empty or error, load from local DB
        await _loadWishlistItemsFromDb();
      }
    } catch (e) {
      debugPrint('Error loading wishlist from API: $e');
      // Fallback to local database
      await _loadWishlistItemsFromDb();
    }
  }

  Future<Map<String, dynamic>> _callWishlistApi(String type, {String? pro_id, String? pro_name}) async {
    debugPrint('Calling wishlist API with typeee: $type, pro_id: $pro_id, _cusId: ${_cusId.toString()}');
    final body = {
      'cid': _cid,
      'type': type,
      'ln': _ln,
      'lt': _lt,
      'device_id': _deviceId,
      'cus_id': _cusId.toString(),
      if (pro_id != null) 'pro_id': pro_id,
      if (pro_name != null) 'pro_name': pro_name,
    };

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      ).timeout(const Duration(seconds: 10));

      debugPrint('Wishlist API response: ${response.statusCode}, body: ${response.body}');

      return json.decode(response.body.substring(response.body.indexOf('{')));
    } catch (e) {
      debugPrint('Error calling wishlist API: $e');
      rethrow;
    }
  }

  Future<bool> toggleItem(Product product) async {
    await _ensureLoaded();
    if (_cusId == null) {
      debugPrint('Cannot toggle wishlist - no customer ID');
      return false;
    }

    final targetProId = product.selectedUnit.proId;
    final isInWishlist = _items.any((item) => item.pro_id == targetProId);

    try {
      // Debug current state
      debugPrint('Current wishlist items before toggle: ${_items.map((i) => i.pro_id).toList()}');
      debugPrint('Toggling product ${product.title} (ID: $targetProId) - currently ${isInWishlist ? 'in' : 'not in'} wishlist');

      // Ensure we have complete product data
      Product? effectiveProduct = product;
      if (product.sellingPricePerSelectedUnit == null || product.sellingPricePerSelectedUnit == 0.0) {
        debugPrint('Refreshing product data for ${product.title}');
        effectiveProduct = ProductService.getProductById(targetProId.toString());
        if (effectiveProduct == null) {
          debugPrint('Failed to refresh product data');
          return isInWishlist;
        }
      }

      // API call
      final response = await _callWishlistApi(
        '1016',
        pro_id: targetProId.toString(),
        pro_name: effectiveProduct.title,
      );

      // Handle string "false" vs boolean false
      final apiSuccess = response['error'] == false || response['error']?.toString().toLowerCase() == 'false';

      if (apiSuccess) {
        // Refresh the wishlist from API to ensure consistency
        await _loadWishlistFromApiAndSyncDb();
        notifyListeners();

        // Return the new state (opposite of previous state)
        return !isInWishlist;
      } else {
        debugPrint('API returned error: ${response['message']}');
        return isInWishlist;
      }
    } catch (e) {
      debugPrint('Wishlist toggle error: $e');
      // Fallback to local operation
      if (isInWishlist) {
        _items.removeWhere((item) => item.pro_id == targetProId);
        await _dbHelper.deleteWishlistItem(_cusId.toString(), targetProId);
      } else {
        final newItem = WishlistItem(
          cus_id: _cusId.toString(),
          pro_id: targetProId,
          title: product.title,
          subtitle: product.subtitle,
          imageUrl: product.imageUrl,
          category: product.category,
          selectedUnitSize: product.selectedUnit.size,
          pricePerUnit: product.sellingPricePerSelectedUnit ??
              product.pricePerSelectedUnit ?? 0.0,
        );
        _items.add(newItem);
        await _dbHelper.insertWishlistItem(newItem);
      }
      notifyListeners();
      return !isInWishlist;
    }
  }

  bool containsItem(int proId) {
    return _cusId != null && _items.any((item) => item.pro_id == proId);
  }

  Future<void> refresh() async {
    if (_cusId != null) {
      await _loadWishlistFromApiAndSyncDb();
    } else {
      await _loadWishlistItemsFromDb();
    }
    notifyListeners();
  }
}