import 'package:kisangro/models/product_model.dart';
import 'package:kisangro/services/image_cache_service.dart';
import 'package:kisangro/services/product_service.dart';

class ImagePreloaderService {
  static final ImagePreloaderService _instance = ImagePreloaderService._internal();
  factory ImagePreloaderService() => _instance;
  ImagePreloaderService._internal();

  final Set<String> _preloadedUrls = {};
  
  /// Preload images for a list of products
  Future<void> preloadProductImages(List<dynamic> products) async {
    final urlsToPreload = <String>[];
    
    for (final product in products) {
      String? imageUrl;
      
      if (product is Map) {
        imageUrl = product['image'] ?? product['product_img'];
      } else if (product is Product) {
        imageUrl = product.imageUrl;
      }
      
      if (imageUrl != null && 
          imageUrl.isNotEmpty && 
          imageUrl.startsWith('http') &&
          !_preloadedUrls.contains(imageUrl)) {
        urlsToPreload.add(imageUrl);
        _preloadedUrls.add(imageUrl);
      }
    }
    
    if (urlsToPreload.isNotEmpty) {
      await ImageCacheService().preloadImages(urlsToPreload);
    }
  }
  
  /// Preload images for category products when navigating
  Future<void> preloadCategoryImages(String categoryId) async {
    try {
      final result = await ProductService.fetchProductsByCategory(
        categoryId,
        offset: 0,
        limit: 20, // Preload first 20 products
      );
      
      final products = result['products'] as List<Product>;
      await preloadProductImages(products);
    } catch (e) {
      print('Error preloading category images: $e');
    }
  }
  
  /// Clear preloaded URLs tracking
  void clearTracking() {
    _preloadedUrls.clear();
  }
}