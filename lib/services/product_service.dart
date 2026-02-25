import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:math'; // Import for Random
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:kisangro/models/product_model.dart';
import 'package:kisangro/models/ad_model.dart'; // NEW: Import ad_model.dart
import 'package:kisangro/models/deal_model.dart'; // NEW: Import deal_model.dart
import 'package:collection/collection.dart'; // Import for firstWhereOrNull

class ProductService extends ChangeNotifier {
  static List<Product> _allProducts =
      []; // Stores all unique products (by their generated ID)
  static List<Map<String, String>> _allCategories = [];
  static List<String> _validImageUrls =
      []; // List to store valid API image URLs
  static final Random _random =
      Random(); // Random instance for selecting image URLs

  // NEW: Wishlist variables
  static List<String> _wishlistProductIds = [];
  static const String _wishlistKey = 'wishlist_products';

  static const String _productApiUrl = 'https://erpsmart.in/total/api/m_api/';
  // UPDATED API PARAMETERS
  static const String _cid = '85788578'; // Consistent CID
  static const String _ln = '123';
  static const String _lt = '123';
  static const String _deviceId = '123';
  static const String _productsCacheKey = 'cached_products';
  static const String _categoriesCacheKey = 'cached_categories';
  static const String _cacheTimestampKey = 'cache_timestamp';
  static const Duration _cacheDuration = Duration(hours: 24);

  // NEW: Wishlist initialization
  static Future<void> _initWishlist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wishlistJson = prefs.getString(_wishlistKey);
      if (wishlistJson != null) {
        _wishlistProductIds = List<String>.from(json.decode(wishlistJson));
        debugPrint(
          'ProductService: Loaded ${_wishlistProductIds.length} items from wishlist',
        );
      }
    } catch (e) {
      debugPrint('ProductService: Error loading wishlist: $e');
    }
  }

  // NEW: Save wishlist to SharedPreferences
  static Future<void> _saveWishlist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_wishlistKey, json.encode(_wishlistProductIds));
    } catch (e) {
      debugPrint('ProductService: Error saving wishlist: $e');
    }
  }

  // NEW: Add product to wishlist
  static Future<void> addToWishlist(String productId) async {
    if (!_wishlistProductIds.contains(productId)) {
      _wishlistProductIds.add(productId);
      await _saveWishlist();
      debugPrint('ProductService: Added product $productId to wishlist');
    }
  }

  // NEW: Remove product from wishlist
  static Future<void> removeFromWishlist(String productId) async {
    if (_wishlistProductIds.contains(productId)) {
      _wishlistProductIds.remove(productId);
      await _saveWishlist();
      debugPrint('ProductService: Removed product $productId from wishlist');
    }
  }

  // NEW: Check if product is in wishlist
  static bool isInWishlist(String productId) {
    return _wishlistProductIds.contains(productId);
  }

  // NEW: Get all wishlist products
  static List<Product> getWishlistProducts() {
    return _allProducts
        .where(
          (product) =>
              _wishlistProductIds.contains(product.mainProductId) ||
              product.availableSizes.any(
                (size) => _wishlistProductIds.contains(size.proId.toString()),
              ),
        )
        .toList();
  }

  // NEW: Toggle product in wishlist
  static Future<void> toggleWishlist(String productId) async {
    if (isInWishlist(productId)) {
      await removeFromWishlist(productId);
    } else {
      await addToWishlist(productId);
    }
  }

  // Check network connectivity
  Future<bool> _hasNetwork() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      debugPrint('ProductService: Error checking network: $e');
      return false;
    }
  }

  // Check if cache is valid
  Future<bool> _isCacheValid(SharedPreferences prefs) async {
    final timestamp = prefs.getString(_cacheTimestampKey);
    if (timestamp == null) return false;
    final cacheTime = DateTime.parse(timestamp);
    return DateTime.now().difference(cacheTime) < _cacheDuration;
  }

  // Save to cache
  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final productsJson = _allProducts.map((p) => p.toJson()).toList();
      await prefs.setString(_productsCacheKey, json.encode(productsJson));
      await prefs.setString(_categoriesCacheKey, json.encode(_allCategories));
      await prefs.setString(
        _cacheTimestampKey,
        DateTime.now().toIso8601String(),
      );
      debugPrint(
        'ProductService: Cached ${_allProducts.length} products and ${_allCategories.length} categories.',
      );
    } catch (e) {
      debugPrint('ProductService: Error saving to cache: $e');
    }
  }

  // Load from cache
  Future<bool> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final productsJson = prefs.getString(_productsCacheKey);
      final categoriesJson = prefs.getString(_categoriesCacheKey);

      if (productsJson == null || categoriesJson == null) {
        debugPrint('ProductService: No cache found.');
        return false;
      }

      if (!await _isCacheValid(prefs)) {
        debugPrint('ProductService: Cache expired.');
        return false;
      }

      final List<dynamic> productsData = json.decode(productsJson);
      final List<dynamic> categoriesData = json.decode(categoriesJson);

      _allProducts =
          productsData
              .map((data) => Product.fromJson(data as Map<String, dynamic>))
              .toList();
      _allCategories = categoriesData.cast<Map<String, String>>();

      // Populate _validImageUrls from cached products
      _validImageUrls.clear();
      for (var product in _allProducts) {
        if (isValidImageUrl(product.imageUrl)) {
          // Use the new helper method
          _validImageUrls.add(product.imageUrl);
        }
      }

      debugPrint(
        'ProductService: Loaded ${_allProducts.length} products and ${_allCategories.length} categories from cache. Found ${_validImageUrls.length} valid image URLs.',
      );
      return true;
    } catch (e) {
      debugPrint('ProductService: Error loading from cache: $e');
      return false;
    }
  }

  // Initialize method to handle API disconnection and initial data loading
  Future<void> initialize() async {
    debugPrint('ProductService: Initializing...');
    await _initWishlist(); // NEW: Initialize wishlist
    if (await _loadFromCache()) {
      debugPrint('ProductService: Using cached data.');
      // If cache is valid, still attempt to update in background if network is present
      if (await _hasNetwork()) {
        _fetchAndUpdateCache(); // Non-blocking background update
      }
      return;
    }

    // If no valid cache, proceed with network fetch or dummy fallback
    if (!await _hasNetwork()) {
      debugPrint('ProductService: No network. Loading dummy data.');
      _loadDummyCategoriesFallback();
      _loadDummyProductsFallback();
      await _saveToCache(); // Save dummy data to cache
      notifyListeners();
      return;
    }

    try {
      debugPrint('ProductService: Network available. Fetching from APIs...');
      await loadCategoriesFromApi(); // Load categories first
      await _fetchProductsForAllCategories(); // Then load products for all categories
      await _saveToCache(); // Cache the fetched data
      notifyListeners();
      debugPrint('ProductService: Initial API fetch and caching complete.');
    } catch (e) {
      debugPrint(
        'ProductService: API failed during initialization: $e. Loading dummy data.',
      );
      _loadDummyCategoriesFallback();
      _loadDummyProductsFallback();
      await _saveToCache(); // Save dummy data to cache
      notifyListeners();
    }
  }

  // Background fetch to update cache (called after initial load if network is present)
  Future<void> _fetchAndUpdateCache() async {
    if (!await _hasNetwork()) {
      debugPrint(
        'ProductService: No network for background fetch. Skipping cache update.',
      );
      return;
    }
    try {
      debugPrint('ProductService: Performing background cache update...');
      await loadCategoriesFromApi(); // Refresh categories
      await _fetchProductsForAllCategories(); // Refresh products for all categories
      await _saveToCache(); // Save refreshed data
      notifyListeners(); // Notify UI of refreshed data
      debugPrint('ProductService: Background cache update completed.');
    } catch (e) {
      debugPrint('ProductService: Background fetch failed: $e');
    }
  }

  // NEW: Method to fetch products for ALL categories and populate _allProducts
  static Future<void> _fetchProductsForAllCategories() async {
    debugPrint('ProductService: Starting _fetchProductsForAllCategories...');
    _allProducts.clear();
    _validImageUrls.clear();
    final Set<String> seenProductMainIds = {}; // For main product IDs
    final Set<int> seenProIds = {}; // For individual product size IDs

    if (_allCategories.isEmpty) {
      debugPrint(
        'ProductService: Categories not loaded yet. Calling loadCategoriesFromApi...',
      );
      await loadCategoriesFromApi();
      if (_allCategories.isEmpty) {
        debugPrint(
          'ProductService: Categories still empty after attempting to load.',
        );
        return;
      }
    }

    for (var category in _allCategories) {
      final String categoryId = category['cat_id']!;
      debugPrint(
        'ProductService: Fetching products for category: ${category['label']} (ID: $categoryId)',
      );
      try {
        final Map<String, dynamic> result = await fetchProductsByCategory(
          categoryId,
          offset: 0,
          limit: 999999999,
        );
        final List<Product> fetchedCategoryProducts = result['products'];
        debugPrint(
          'ProductService: Received ${fetchedCategoryProducts.length} products for category ID $categoryId.',
        );

        for (var product in fetchedCategoryProducts) {
          // Check for duplicate mainProductId AND individual proIds
          if (!seenProductMainIds.contains(product.mainProductId)) {
            seenProductMainIds.add(product.mainProductId);

            // Also check each size's proId for uniqueness
            final List<ProductSize> uniqueSizes = [];
            for (var size in product.availableSizes) {
              if (!seenProIds.contains(size.proId)) {
                seenProIds.add(size.proId);
                uniqueSizes.add(size);
              } else {
                debugPrint(
                  'ProductService: Skipping duplicate size (proId: ${size.proId}) for product ${product.title}',
                );
              }
            }

            if (uniqueSizes.isNotEmpty) {
              // Create product with only unique sizes
              final uniqueProduct = product.copyWith(
                availableSizes: uniqueSizes,
              );
              _allProducts.add(uniqueProduct);

              if (isValidImageUrl(product.imageUrl)) {
                _validImageUrls.add(product.imageUrl);
              }
            }
          } else {
            debugPrint(
              'ProductService: Skipping duplicate product (mainProductId: ${product.mainProductId})',
            );
          }
        }
      } catch (e) {
        debugPrint(
          'ProductService: Error fetching products for category $categoryId: $e',
        );
      }
    }
    debugPrint(
      'ProductService: Finished _fetchProductsForAllCategories. Total products: ${_allProducts.length}',
    );
  }

  // This method fetches products for a single category and returns them.
  // It now accepts offset and limit for pagination.
  static Future<Map<String, dynamic>> fetchProductsByCategory(
    String categoryId, {
    int offset = 0,
    int limit = 10,
  }) async {
    debugPrint(
      'ProductService: Fetching products for category ID: $categoryId',
    );
    List<Product> products = [];
    bool hasMore = false;
    final Set<String> seenProductMainIds = {};
    final Set<int> seenProIds = {};

    try {
      final requestBody = {
        'cid': _cid,
        'type': '2057',
        'ln': _ln,
        'lt': _lt,
        'device_id': _deviceId,
        'cat_id': categoryId,
        'offset': offset.toString(),
        'limit': limit.toString(),
      };

      final response = await http
          .post(
            Uri.parse(_productApiUrl),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: requestBody,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        print(
          'ProductService: Response for category $categoryId: $responseData',
        );

        if (responseData['status'] == 'success' &&
            responseData['data'] is List) {
          final List<dynamic> rawApiProductsData = responseData['data'];

          for (var item in rawApiProductsData) {
            String productName =
                item['pro_name'] as String? ?? 'Unknown Product';
            String technicalName =
                item['technical_name'] as String? ?? 'No Description';
            String categoryName =
                item['category_name'] as String? ?? 'Uncategorized';
            String imageUrl = item['image'] as String? ?? '';

            // Generate a more unique mainProductId
            String productMainId =
                '${productName}_${categoryId}_${item['pro_id']}';

            final Set<ProductSize> uniqueSizes = {};
            int? initialSelectedUnitProId;

            if (item.containsKey('sizes') && item['sizes'] is List) {
              for (var sizeJson in (item['sizes'] as List)) {
                try {
                  final parsedSize = ProductSize.fromJson(
                    sizeJson as Map<String, dynamic>,
                  );
                  if (!seenProIds.contains(parsedSize.proId)) {
                    seenProIds.add(parsedSize.proId);
                    uniqueSizes.add(parsedSize);
                    if (initialSelectedUnitProId == null) {
                      initialSelectedUnitProId = parsedSize.proId;
                    }
                  }
                } catch (e) {
                  debugPrint('Error parsing size: $e');
                }
              }
            }

            // Fallback for products without sizes
            if (uniqueSizes.isEmpty) {
              final int fallbackProId = (item['pro_id'] as num?)?.toInt() ?? 0;
              if (!seenProIds.contains(fallbackProId)) {
                seenProIds.add(fallbackProId);
                uniqueSizes.add(
                  ProductSize(
                    proId: fallbackProId,
                    size: 'Unit',
                    price: (item['mrp'] as num?)?.toDouble() ?? 0.0,
                    sellingPrice: (item['selling_price'] as num?)?.toDouble(),
                  ),
                );
                initialSelectedUnitProId = fallbackProId;
              }
            }

            if (uniqueSizes.isNotEmpty &&
                !seenProductMainIds.contains(productMainId)) {
              seenProductMainIds.add(productMainId);
              products.add(
                Product(
                  mainProductId: productMainId,
                  title: productName,
                  subtitle: technicalName,
                  imageUrl: imageUrl,
                  category: categoryName,
                  availableSizes: uniqueSizes.toList(),
                  initialSelectedUnitProId: initialSelectedUnitProId,
                ),
              );
            }
          }
          hasMore = rawApiProductsData.length == limit;
        }
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
    }

    return {'products': products, 'hasMore': hasMore};
  }

  // Static method to load all general products from API (type 1041)
  // This method is now primarily for initial loading of general products,
  // but _fetchProductsForAllCategories will be the main way to populate _allProducts.
  // static Future<void> loadProductsFromApi() async {
  //   debugPrint(
  //     'ProductService: Starting loadProductsFromApi (Type 1013 only) - this now supplements _allProducts.',
  //   );

  //   final List<Product> fetchedGeneralProducts = [];
  //   final Set<String> seenProductMainIds =
  //       {}; // To track unique products by main ID

  //   // --- Fetch general products (type=1013) ---
  //   debugPrint('ProductService: Fetching products of type 1013...');
  //   try {
  //     final requestBody1013 = {
  //       'cid': _cid,
  //       'type': '1013',
  //       'ln': _ln,
  //       'lt': _lt,
  //       'device_id': _deviceId,
  //     };

  //     final response1013 = await http
  //         .post(
  //           Uri.parse(_productApiUrl),
  //           headers: {
  //             'Content-Type': 'application/x-www-form-urlencoded',
  //             'Accept': 'application/json',
  //           },
  //           body: requestBody1013,
  //         )
  //         .timeout(const Duration(seconds: 30));

  //     debugPrint(
  //       'ProductService: Response Status Code (type=1013): ${response1013.statusCode}',
  //     );
  //     debugPrint(
  //       'ProductService: Raw Response Body (type=1013): ${response1013.body}',
  //     );

  //     if (response1013.statusCode == 200) {
  //       final Map<String, dynamic> responseData = json.decode(
  //         response1013.body,
  //       );
  //       if (responseData['status'] == 'success' &&
  //           responseData['data'] is List) {
  //         final List<dynamic> rawApiProductsData = responseData['data'];
  //         for (var item in rawApiProductsData) {
  //           debugPrint('ProductService: Processing type 1013 item: $item');
  //           String productName = item['pro_name'] as String? ?? 'No Title';
  //           String technicalName =
  //               item['technical_name'] as String? ?? 'No Description';
  //           String categoryName =
  //               item['category_name'] as String? ?? 'Uncategorized';
  //           String imageUrl = item['image'] as String? ?? '';

  //           // Generate a stable mainProductId for the product group
  //           String productMainId =
  //               '${productName.replaceAll(' ', '_').toLowerCase()}_${categoryName.replaceAll(' ', '_').toLowerCase()}';

  //           // Add valid image URLs to the list
  //           if (isValidImageUrl(imageUrl)) {
  //             _validImageUrls.add(imageUrl);
  //           }

  //           final Set<ProductSize> uniqueSizes = {};
  //           int?
  //           initialSelectedUnitProId; // To store the pro_id of the first size

  //           if (item.containsKey('sizes') &&
  //               item['sizes'] is List &&
  //               (item['sizes'] as List).isNotEmpty) {
  //             for (var sizeJson in (item['sizes'] as List)) {
  //               try {
  //                 final parsedSize = ProductSize.fromJson(
  //                   sizeJson as Map<String, dynamic>,
  //                 );
  //                 uniqueSizes.add(parsedSize);
  //                 if (initialSelectedUnitProId == null) {
  //                   initialSelectedUnitProId =
  //                       parsedSize
  //                           .proId; // Set the first pro_id as initial selected
  //                 }
  //               } catch (e) {
  //                 debugPrint(
  //                   'ProductService: Error parsing ProductSize from JSON for product ${item['pro_name']}: $e. JSON: $sizeJson',
  //                 );
  //               }
  //             }
  //           } else {
  //             // Handle cases where 'sizes' array is empty or missing, and 'mrp'/'selling_price' might be null
  //             final double fallbackMrp =
  //                 (item['mrp'] as num?)?.toDouble() ?? 0.0;
  //             final double? fallbackSellingPrice =
  //                 (item['selling_price'] as num?)?.toDouble();
  //             final int fallbackProId =
  //                 (item['pro_id'] as num?)?.toInt() ??
  //                 0; // Use the main pro_id as fallback
  //             debugPrint(
  //               'ProductService: No "sizes" array for product ${item['pro_name']}. Using fallback MRP: $fallbackMrp, Selling Price: $fallbackSellingPrice, ProId: $fallbackProId',
  //             );
  //             final fallbackSize = ProductSize(
  //               proId: fallbackProId,
  //               size: 'Unit',
  //               price: fallbackMrp,
  //               sellingPrice: fallbackSellingPrice,
  //             );
  //             uniqueSizes.add(fallbackSize);
  //             initialSelectedUnitProId = fallbackProId;
  //           }
  //           List<ProductSize> availableSizes = uniqueSizes.toList();

  //           final product = Product(
  //             mainProductId:
  //                 productMainId, // Use the generated composite ID for the main Product object
  //             title: productName,
  //             subtitle: technicalName,
  //             imageUrl: imageUrl,
  //             category: categoryName,
  //             availableSizes: availableSizes,
  //             initialSelectedUnitProId: initialSelectedUnitProId,
  //           );

  //           // Only add if the mainProductId hasn't been seen before
  //           if (!seenProductMainIds.contains(product.mainProductId)) {
  //             seenProductMainIds.add(product.mainProductId);
  //             fetchedGeneralProducts.add(product);
  //           }
  //         }
  //         debugPrint(
  //           'ProductService: Added ${fetchedGeneralProducts.length} unique products (by mainProductId) from type 1013.',
  //         );
  //       } else {
  //         debugPrint(
  //           'ProductService: API response format invalid or status not success for type=1013. Response: $responseData',
  //         );
  //       }
  //     } else {
  //       debugPrint(
  //         'ProductService: Failed to load products for type=1013. Status code: ${response1013.statusCode}. Response: ${response1013.body}',
  //       );
  //     }
  //   } on TimeoutException catch (e) {
  //     debugPrint('ProductService: Request for type 1013 timed out: $e');
  //   } on http.ClientException catch (e) {
  //     debugPrint('ProductService: Network error for type 1013: $e');
  //   } catch (e) {
  //     debugPrint(
  //       'ProductService: Unexpected error fetching type 1013 products: $e',
  //     );
  //   }

  //   // This method now adds to _allProducts, but _fetchProductsForAllCategories is the main populator.
  //   // We should ensure no duplicates if both are used.
  //   for (var product in fetchedGeneralProducts) {
  //     // Add to _allProducts only if it's not already present by its mainProductId
  //     if (!_allProducts.any((p) => p.mainProductId == product.mainProductId)) {
  //       _allProducts.add(product);
  //     }
  //   }
  //   debugPrint(
  //     'ProductService: Finished loadProductsFromApi (Type 1013). Total products in _allProducts after this: ${_allProducts.length}. Total valid image URLs: ${_validImageUrls.length}',
  //   );
  // }




  /// NEW: Static method to fetch advertisement data from API (type 2014)
 /// NEW: Static method to fetch advertisement data from API (type 1020)
static Future<List<Ad>> fetchAds() async {
  debugPrint(
    'ProductService: Attempting to load Ads data from API via POST (type=1020): $_productApiUrl',
  );
  List<Ad> ads = [];
  try {
    final prefs = await SharedPreferences.getInstance();

    double? latitude = prefs.getDouble('latitude');
    double? longitude = prefs.getDouble('longitude');
    String? deviceId = prefs.getString('device_id');

    final requestBody = {
      'cid': _cid,
      'type': '1020',
      'ln': latitude?.toString() ?? '1',
      'lt': longitude?.toString() ?? '1',
      'device_id': deviceId ?? '1',
    };

    final response = await http
        .post(
          Uri.parse(_productApiUrl),
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Accept': 'application/json',
          },
          body: requestBody,
        )
        .timeout(const Duration(seconds: 30));

    debugPrint(
      'ProductService: Response Status Code (type=1020): ${response.statusCode}',
    );
    debugPrint(
      'ProductService: Raw Response Body (type=1020): ${response.body}',
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      if (responseData['error'] == false && responseData['deals'] is List) {
        final List<dynamic> rawAdsData = responseData['deals'];
        for (var item in rawAdsData) {
          // Create Ad object matching your actual Ad model
          ads.add(Ad(
            adId: (item['ad_id'] as num).toInt(),
            adName: item['ad_name'] as String,
            banner: item['ad'] as String,
          ));
        }
        debugPrint(
          'ProductService: Successfully parsed ${ads.length} ads from API (type=1020).',
        );
      } else {
        debugPrint(
          'ProductService: API response for Ads (type=1020) invalid or error: ${responseData['message']}. Response: $responseData. Returning empty list.',
        );
      }
    } else {
      debugPrint(
        'ProductService: Failed to load Ads (type=1020). Status code: ${response.statusCode}. Response: ${response.body}. Returning empty list.',
      );
    }
  } on TimeoutException catch (_) {
    debugPrint(
      'ProductService: Request for Ads (type=1020) timed out. Returning empty list.',
    );
  } on http.ClientException catch (e) {
    debugPrint(
      'ProductService: Network error for Ads (type=1020): $e. Returning empty list.',
    );
  } catch (e) {
    debugPrint(
      'ProductService: Unexpected error fetching Ads (type=1020): $e. Returning empty list.',
    );
  }
  return ads;
}
  
  
  
  /// NEW: Static method to fetch Deals of the Day data from API (type 2013)
/// NEW: Static method to fetch Deals of the Day data from API (type 1021)
/// NEW: Static method to fetch Deals of the Day data from API (type 1021)
static Future<List<Deal>> fetchDealsOfTheDay() async {
  debugPrint(
    'ProductService: Attempting to load Deals of the Day data from API via POST (type=1021): $_productApiUrl',
  );
  List<Deal> deals = [];
  try {
    final prefs = await SharedPreferences.getInstance();

    double? latitude = prefs.getDouble('latitude');
    double? longitude = prefs.getDouble('longitude');
    String? deviceId = prefs.getString('device_id');

    final requestBody = {
      'cid': _cid,
      'type': '1021',
      'lt': latitude?.toString() ?? '1',
      'ln': longitude?.toString() ?? '1',
      'device_id': deviceId ?? '1',
    };

    final response = await http
        .post(
          Uri.parse(_productApiUrl),
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Accept': 'application/json',
          },
          body: requestBody,
        )
        .timeout(const Duration(seconds: 30));

    debugPrint(
      'ProductService: Response Status Code (type=1021): ${response.statusCode}',
    );
    debugPrint(
      'ProductService: Raw Response Body (type=1021): ${response.body}',
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      if (responseData['error'] == false && responseData['deals'] is List) {
        final List<dynamic> rawDealsData = responseData['deals'];
        
        for (var dealItem in rawDealsData) {
          // Extract the deal-level information
          final int dealId = dealItem['deal_id'] as int? ?? 0;
          final String dealName = dealItem['deal_name'] as String? ?? '';
          
          // Fix banner URL - add .jpg extension if missing
          String bannerUrl = dealItem['banner'] as String? ?? '';
          if (bannerUrl.isNotEmpty && !bannerUrl.contains('.')) {
            bannerUrl = bannerUrl + '.jpg'; // Add default extension
          }
          
          final String startDate = dealItem['start_date'] as String? ?? '';
          final String endDate = dealItem['end_date'] as String? ?? '';
          final String startTime = dealItem['start_time'] as String? ?? '';
          final String endTime = dealItem['end_time'] as String? ?? '';
          
          // Check if there are products in this deal
          if (dealItem.containsKey('products') && dealItem['products'] is List) {
            final List<dynamic> productsList = dealItem['products'];
            
            // Create a separate Deal object for each product in the products array
            for (var productItem in productsList) {
              // Extract product information
              final int productId = (productItem['product_id'] as num?)?.toInt() ?? 0;
              final String productName = productItem['product_name'] as String? ?? '';
              
              // Fix product image URL
              String productImgUrl = productItem['product_img'] as String? ?? '';
              if (productImgUrl.isEmpty) {
                // If product image is empty, use a placeholder or the banner as fallback
                productImgUrl = 'assets/placeholder.png';
              } else if (!productImgUrl.startsWith('http')) {
                // If relative URL, construct absolute URL
                if (productImgUrl.startsWith('../')) {
                  productImgUrl = productImgUrl.replaceFirst('../', 'https://erpsmart.in/total/');
                } else {
                  productImgUrl = 'https://erpsmart.in/total/' + productImgUrl;
                }
              }
              
              final String dealPrice = productItem['deal_price'] as String? ?? '0';
              final String originalPrice = productItem['original_price'] as String? ?? '0';
              final String discountPercent = productItem['discount_percent'] as String? ?? '0%';
              
              // Parse prices, removing any '%' symbols if present
              double parsePrice(String priceStr) {
                if (priceStr.isEmpty) return 0.0;
                // Remove any '%' symbols and trim
                String cleaned = priceStr.replaceAll('%', '').trim();
                return double.tryParse(cleaned) ?? 0.0;
              }
              
              // Create a Deal object for this product
              // Using the product's data for product-specific fields
              // and deal-level data for deal-specific fields
              final Map<String, dynamic> flatDealJson = {
                'deal_id': dealId,
                'deal_name': dealName,
                'start_date': startDate,
                'end_date': endDate,
                'banner': bannerUrl, // Now with proper extension
                'pro_id': productId, // Use product_id as pro_id
                'product_name': productName,
                'size': 'Unit', // Default size since not in response
                'mrp': parsePrice(originalPrice),
                'selling_price': parsePrice(dealPrice),
                'product_img': productImgUrl,
              };
              
              try {
                final deal = Deal.fromJson(flatDealJson);
                deals.add(deal);
              } catch (e) {
                debugPrint('ProductService: Error creating Deal object: $e');
              }
            }
          }
        }
        debugPrint(
          'ProductService: Successfully parsed ${deals.length} deals from API (type=1021).',
        );
      } else {
        debugPrint(
          'ProductService: API response for Deals (type=1021) invalid or error: ${responseData['message']}. Response: $responseData. Returning empty list.',
        );
      }
    } else {
      debugPrint(
        'ProductService: Failed to load Deals (type=1021). Status code: ${response.statusCode}. Response: ${response.body}. Returning empty list.',
      );
    }
  } on TimeoutException catch (_) {
    debugPrint(
      'ProductService: Request for Deals (type=1021) timed out. Returning empty list.',
    );
  } on http.ClientException catch (e) {
    debugPrint(
      'ProductService: Network error for Deals (type=1021): $e. Returning empty list.',
    );
  } catch (e) {
    debugPrint(
      'ProductService: Unexpected error fetching Deals (type=1021): $e. Returning empty list.',
    );
  }
  return deals;
}

  // Method to get a random valid image URL
  static String getRandomValidImageUrl() {
    if (_validImageUrls.isNotEmpty) {
      return _validImageUrls[_random.nextInt(_validImageUrls.length)];
    }
    return 'assets/placeholder.png'; // Fallback to local placeholder if no valid API images are found
  }

  static Future<void> loadCategoriesFromApi() async {
    debugPrint(
      'ProductService: Attempting to load CATEGORIES data from API via POST (type=1014): $_productApiUrl',
    );

    try {
      final prefs = await SharedPreferences.getInstance();

      double? latitude = prefs.getDouble('latitude');
      double? longitude = prefs.getDouble('longitude');
      String? deviceId = prefs.getString('device_id');

      final requestBody = {
        'cid': _cid, // Use the consistent CID
        'type': '1014',
        'lt': latitude?.toString() ?? '1',
        'ln': longitude?.toString() ?? '1',
        'device_id': deviceId ?? '1',
      };

      final response = await http
          .post(
            Uri.parse(_productApiUrl),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: requestBody,
          )
          .timeout(const Duration(seconds: 30));

      debugPrint(
        'ProductService: Response from server for loadCategoriesFromApi: ${response.body}',
      );
      debugPrint(
        'ProductService: Response Status Code (type=1014): ${response.statusCode}',
      );

      _allCategories.clear();

      if (response.statusCode == 200) {
        final Map<String, dynamic> apiResponse = json.decode(response.body);

        if (apiResponse['status'] == 'success' && apiResponse['data'] is List) {
          // Define the map for category names to asset paths
          Map<String, String> categoryIconMap = {
            'INSECTICIDE': 'assets/grid1.png',
            'FUNGICIDE': 'assets/grid2.png',
            'HERBICIDE': 'assets/grid3.png',
            'PLANT GROWTH REGULATOR': 'assets/grid4.png',
            'ORGANIC BIOSTIMULANT': 'assets/grid5.png',
            'LIQUID FERTILIZER':
                'assets/grid7.png', // Assuming grid7.png is for Liquid Fertilizer
            'MICRONUTRIENTS ':
                'assets/micro.png', // Note the space in 'MICRONUTRIENTS '
            'BIO FERTILISER':
                'assets/grid10.png', // Assuming grid10.png is for Bio Fertiliser
            // Add other categories and their icons as needed based on your assets folder
            // Ensure you have these assets in your project's assets/ folder
          };

          for (var item in apiResponse['data'] as List) {
            String categoryName =
                (item['category'] as String)
                    .trim(); // Trim to remove leading/trailing spaces
            _allCategories.add({
              'cat_id': item['cat_id'].toString(),
              'icon':
                  categoryIconMap[categoryName] ??
                  'assets/placeholder_category.png', // Fallback icon
              'label': categoryName,
            });
          }
          debugPrint(
            'ProductService: Successfully parsed ${_allCategories.length} categories from API (type=1014).',
          );
        } else {
          debugPrint(
            'ProductService: Failed to load categories from API (type=1014): Invalid data format. Response: $apiResponse. Falling back to dummy categories.',
          );
          _loadDummyCategoriesFallback();
        }
      } else {
        debugPrint(
          'ProductService: Failed to load categories from API (type=1014). Status code: ${response.statusCode}. Response: ${response.body}. Falling back to dummy categories.',
        );
        _loadDummyCategoriesFallback();
      }
    } on TimeoutException catch (_) {
      debugPrint(
        'ProductService: Request (type=1014) timed out. Loading dummy categories.',
      );
      _loadDummyCategoriesFallback();
    } on http.ClientException catch (e) {
      debugPrint(
        'ProductService: Network error for type 1014: $e. Loading dummy categories.',
      );
    } catch (e) {
      debugPrint(
        'ProductService: Unexpected error fetching categories for type 1014: $e. Loading dummy categories.',
      );
    }
  }

  // This method is no longer used for determining product categories from API response
  // as category_name is directly available in the 1041 API response.
  // It is kept for backward compatibility with dummy data or if category_name is ever null.
  static String _determineCategory(String proNameLower) {
    if (proNameLower.contains('insecticide') ||
        proNameLower.contains('buggone') ||
        proNameLower.contains('pestguard')) {
      return 'INSECTICIDE';
    } else if (proNameLower.contains('fungicide') ||
        proNameLower.contains('aurastar') ||
        proNameLower.contains('azeem') ||
        proNameLower.contains('valax') ||
        proNameLower.contains('stabinil') ||
        proNameLower.contains('orbiter') ||
        proNameLower.contains('aurastin') ||
        proNameLower.contains('benura') ||
        proNameLower.contains('hello') ||
        proNameLower.contains('capzola') ||
        proNameLower.contains('runner') ||
        proNameLower.contains('panonil') ||
        proNameLower.contains('kurazet') ||
        proNameLower.contains('aurobat') ||
        proNameLower.contains('scara') ||
        proNameLower.contains('hexaura') ||
        proNameLower.contains('auralaxil') ||
        proNameLower.contains('rio gold') ||
        proNameLower.contains('aura m 45') ||
        proNameLower.contains('intac') ||
        proNameLower.contains('whita') ||
        proNameLower.contains('proconzo') ||
        proNameLower.contains('aura sulfa') ||
        proNameLower.contains('cembra') ||
        proNameLower.contains('tridot') ||
        proNameLower.contains('alastor') ||
        proNameLower.contains('tebuconz') ||
        proNameLower.contains('valimin')) {
      return 'FUNGICIDE';
    } else if (proNameLower.contains('herbicide') ||
        proNameLower.contains('weed killer')) {
      return 'HERBICIDE';
    } else if (proNameLower.contains('plant growth regulator') ||
        proNameLower.contains('new super growth') ||
        proNameLower.contains('growth') ||
        proNameLower.contains('promoter') ||
        proNameLower.contains('flourish')) {
      return 'PLANT GROWTH REGULATOR';
    } else if (proNameLower.contains('organic biostimulant') ||
        proNameLower.contains('bio-growth')) {
      return 'ORGANIC BIOSTIMULANT';
    } else if (proNameLower.contains('liquid fertilizer') ||
        proNameLower.contains('ferra')) {
      return 'LIQUID FERTILIZER';
    } else if (proNameLower.contains('micronutrient') ||
        proNameLower.contains('zinc') ||
        proNameLower.contains('bora')) {
      return 'MICRONUTRIENTS';
    } else if (proNameLower.contains('bio fertiliser') ||
        proNameLower.contains('aura vam') ||
        proNameLower.contains('soil rich')) {
      return 'BIO FERTILISER';
    } else {
      return 'Uncategorized';
    }
  }

  static void _loadDummyProductsFallback() {
    debugPrint(
      'ProductService: Loading static dummy product data for fallback.',
    );
    _allProducts.clear();
    final List<Map<String, dynamic>> dummyProductsData = [
      {
        "image": "assets/Valaxa.png",
        "pro_name": "AURA VAM (Dummy)",
        "technical_name": "Vermiculate Based Granular (Dummy)",
        "category_name": "BIO FERTILISER", // Added category_name for dummy
        "pro_id": 1001, // Dummy main pro_id
        "sizes": [
          {
            "pro_id": 100101,
            "size": "500 GRM",
            "mrp": 500.0,
            "selling_price": 450.0,
          },
          {
            "pro_id": 100102,
            "size": "1 KG",
            "mrp": 900.0,
            "selling_price": 800.0,
          },
          {
            "pro_id": 100103,
            "size": "5 KG",
            "mrp": 4000.0,
            "selling_price": 3500.0,
          },
        ],
      },
      {
        "image": "assets/hyfen.png",
        "pro_name": "RAPI FERRA (Dummy)",
        "technical_name": "EDTA Chelated Ferrous 12 % (Dummy)",
        "category_name": "MICRONUTRIENTS", // Added category_name for dummy
        "pro_id": 1002, // Dummy main pro_id
        "sizes": [
          {
            "pro_id": 100201,
            "size": "500 GRM",
            "mrp": 600.0,
            "selling_price": 550.0,
          },
          {
            "pro_id": 100202,
            "size": "1 KG",
            "mrp": 1100.0,
            "selling_price": 1000.0,
          },
          {
            "pro_id": 100203,
            "size": "5 KG",
            "mrp": 5000.0,
            "selling_price": 4500.0,
          },
        ],
      },
      {
        "image": "assets/Oxyfen.png",
        "pro_name": "BUGGONE (Dummy)",
        "technical_name": "Powerful Insecticide (Dummy)",
        "category_name": "INSECTICIDE", // Added category_name for dummy
        "pro_id": 1003, // Dummy main pro_id
        "sizes": [
          {
            "pro_id": 100301,
            "size": "100 ML",
            "mrp": 900.0,
            "selling_price": 850.0,
          },
          {
            "pro_id": 100302,
            "size": "250 ML",
            "mrp": 1500.0,
            "selling_price": 1400.0,
          },
        ],
      },
      {
        "image": "assets/Valaxa.png",
        "pro_name": "AURASTAR Fungicide (Dummy)",
        "technical_name": "Systemic fungicide (Dummy)",
        "category_name": "FUNGICIDE", // Added category_name for dummy
        "pro_id": 1004, // Dummy main pro_id
        "sizes": [
          {
            "pro_id": 100401,
            "size": "250 ML",
            "mrp": 950.0,
            "selling_price": 900.0,
          },
          {
            "pro_id": 100402,
            "size": "500 ML",
            "mrp": 1550.0,
            "selling_price": 1450.0,
          },
        ],
      },
      {
        "image": "assets/hyfen.png",
        "pro_name": "FLOURISH Promoter (Dummy)",
        "technical_name": "Promotes flowering (Dummy)",
        "category_name":
            "PLANT GROWTH REGULATOR", // Added category_name for dummy
        "pro_id": 1005, // Dummy main pro_id
        "sizes": [
          {
            "pro_id": 100501,
            "size": "500 ML",
            "mrp": 1100.0,
            "selling_price": 1000.0,
          },
          {
            "pro_id": 100502,
            "size": "1 L",
            "mrp": 2000.0,
            "selling_price": 1800.0,
          },
        ],
      },
    ];

    

    final seenProductMainIds = <String>{};
    final List<Product> productsToProcess = [];

    for (var item in dummyProductsData) {
      String productName = item['pro_name'] as String? ?? 'Unknown Product';
      String technicalName =
          item['technical_name'] as String? ?? 'No Description';
      String categoryName = item['category_name'] as String? ?? 'Uncategorized';
      String imageUrl = item['image'] as String? ?? '';

      String productMainId =
          '${productName.replaceAll(' ', '_').toLowerCase()}_${categoryName.replaceAll(' ', '_').toLowerCase()}';

      final Set<ProductSize> uniqueSizes = {};
      int? initialSelectedUnitProId;

      if (item.containsKey('sizes') &&
          item['sizes'] is List &&
          (item['sizes'] as List).isNotEmpty) {
        for (var sizeJson in (item['sizes'] as List)) {
          try {
            final parsedSize = ProductSize.fromJson(
              sizeJson as Map<String, dynamic>,
            );
            uniqueSizes.add(parsedSize);
            if (initialSelectedUnitProId == null) {
              initialSelectedUnitProId = parsedSize.proId;
            }
          } catch (e) {
            debugPrint(
              'ProductService: Error parsing ProductSize from JSON for dummy product ${item['pro_name']}: $e. JSON: $sizeJson',
            );
          }
        }
      } else {
        final double fallbackMrp = (item['mrp'] as num?)?.toDouble() ?? 0.0;
        final double? fallbackSellingPrice =
            (item['selling_price'] as num?)?.toDouble();
        final int fallbackProId = (item['pro_id'] as num?)?.toInt() ?? 0;
        final fallbackSize = ProductSize(
          proId: fallbackProId,
          size: 'Unit',
          price: fallbackMrp,
          sellingPrice: fallbackSellingPrice,
        );
        uniqueSizes.add(fallbackSize);
        initialSelectedUnitProId = fallbackProId;
      }
      List<ProductSize> availableSizes = uniqueSizes.toList();

      final product = Product(
        mainProductId: productMainId,
        title: productName,
        subtitle: technicalName,
        imageUrl: imageUrl,
        category: categoryName,
        availableSizes: availableSizes,
        initialSelectedUnitProId: initialSelectedUnitProId,
      );

      if (!seenProductMainIds.contains(product.mainProductId)) {
        seenProductMainIds.add(product.mainProductId);
        productsToProcess.add(product);
      }
    }
    _allProducts = productsToProcess;
    _validImageUrls.clear();
    for (var product in _allProducts) {
      if (isValidImageUrl(product.imageUrl)) {
        _validImageUrls.add(product.imageUrl);
      }
    }
    debugPrint(
      'ProductService: Successfully loaded ${_allProducts.length} unique dummy products. Found ${_validImageUrls.length} valid image URLs from dummy data.',
    );
  }

  static void _loadDummyCategoriesFallback() {
    debugPrint(
      'ProductService: Loading static dummy category data for fallback.',
    );
    _allCategories.clear();
    _allCategories = [
      {'cat_id': '14', 'icon': 'assets/grid1.png', 'label': 'INSECTICIDE'},
      {'cat_id': '15', 'icon': 'assets/grid2.png', 'label': 'FUNGICIDE'},
      {'cat_id': '16', 'icon': 'assets/grid3.png', 'label': 'HERBICIDE'},
      {
        'cat_id': '17',
        'icon': 'assets/grid4.png',
        'label': 'PLANT GROWTH REGULATOR',
      },
      {
        'cat_id': '18',
        'icon': 'assets/grid5.png',
        'label': 'ORGANIC BIOSTIMULANT',
      },
      {
        'cat_id': '19',
        'icon': 'assets/grid6.png',
        'label': 'LIQUID FERTILIZER',
      },
      {
        'cat_id': '20',
        'icon': 'assets/micro.png',
        'label': 'MICRONUTRIENTS ',
      }, // Note the space
      {'cat_id': '22', 'icon': 'assets/grid10.png', 'label': 'BIO FERTILISER'},
      {
        'cat_id': '99',
        'icon': 'assets/placeholder_category.png',
        'label': 'SPECIALTY PRODUCT',
      },
    ];
    debugPrint(
      'ProductService: Successfully loaded ${_allCategories.length} dummy categories.',
    );
  }

  static List<Product> getAllProducts() {
    return List.from(_allProducts);
  }

  static List<Product> getProductsByCategoryName(String category) {
    return _allProducts
        .where((product) => product.category == category)
        .toList();
  }

  // MODIFIED: getProductById to find a product by any of its ProductSize proIds
  static Product? getProductById(String id) {
    try {
      final int targetProId = int.parse(id);

      // First try to find exact match by size proId
      for (var product in _allProducts) {
        final matchingSize = product.availableSizes.firstWhereOrNull(
          (size) => size.proId == targetProId,
        );

        if (matchingSize != null) {
          return product.copyWith(selectedUnit: matchingSize);
        }
      }

      // If not found by size, try main product ID
      if (targetProId < 10000) {
        // Assuming main product IDs are < 10000
        final product = _allProducts.firstWhereOrNull(
          (p) => p.mainProductId.contains('_${targetProId}'),
        );

        if (product != null) {
          return product.copyWith(selectedUnit: product.availableSizes.first);
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error finding product by ID: $e');
      return null;
    }
  }

  static List<Map<String, String>> getAllCategories() {
    return List.from(_allCategories);
  }

  static String? getCategoryIdByName(String categoryName) {
    try {
      final category = _allCategories.firstWhere(
        (cat) => cat['label'] == categoryName,
      );
      return category['cat_id'];
    } catch (e) {
      debugPrint(
        'ProductService: Category ID not found for name: $categoryName. Error: $e',
      );
      return null;
    }
  }

  static List<Product> searchProductsLocally(String query) {
    if (query.isEmpty) {
      return [];
    }
    final lowerCaseQuery = query.toLowerCase();
    return _allProducts.where((product) {
      return product.title.toLowerCase().contains(lowerCaseQuery) ||
          product.subtitle.toLowerCase().contains(lowerCaseQuery) ||
          product.category.toLowerCase().contains(lowerCaseQuery);
    }).toList();
  }

  // Helper method to check if a URL is valid and absolute for image loading
  static bool isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      return false;
    }
    // Check if it's a valid absolute URL AND not just the base API path as a placeholder
    // Also explicitly check for the base API URL without a proper image path
    return Uri.tryParse(url)?.isAbsolute == true && !url.endsWith('erp/api/');
  }
}
