import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;

class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  // Custom cache manager with longer cache duration
  static final CustomCacheManager _cacheManager = CustomCacheManager();
  
  // In-memory cache for faster access
  static final Map<String, Image> _memoryCache = {};
  static final Map<String, Uint8List> _bytesCache = {};
  
  // Cache settings
  static const int _maxMemoryCacheSize = 100;
  static final List<String> _cacheOrder = [];

  /// Get cached image or fetch and cache it
  Future<Image> getCachedImage(String url, {
    BoxFit fit = BoxFit.contain,
    double? width,
    double? height,
  }) async {
    // Check memory cache first
    if (_memoryCache.containsKey(url)) {
      return _memoryCache[url]!;
    }

    // Check if we have bytes cached
    if (_bytesCache.containsKey(url)) {
      final image = Image.memory(
        _bytesCache[url]!,
        fit: fit,
        width: width,
        height: height,
      );
      _addToMemoryCache(url, image);
      return image;
    }

    // Download and cache
    try {
      final file = await _cacheManager.getSingleFile(url);
      final bytes = await file.readAsBytes();
      
      _addToBytesCache(url, bytes);
      
      final image = Image.memory(
        bytes,
        fit: fit,
        width: width,
        height: height,
      );
      
      _addToMemoryCache(url, image);
      return image;
    } catch (e) {
      print('Error caching image $url: $e');
      // Return network image as fallback
      return Image.network(
        url,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) => 
            Image.asset('assets/placeholder.png', fit: fit),
      );
    }
  }

  void _addToMemoryCache(String url, Image image) {
    // Manage cache size
    if (_cacheOrder.length >= _maxMemoryCacheSize) {
      final oldest = _cacheOrder.removeAt(0);
      _memoryCache.remove(oldest);
    }
    
    _cacheOrder.add(url);
    _memoryCache[url] = image;
  }

  void _addToBytesCache(String url, Uint8List bytes) {
    _bytesCache[url] = bytes;
  }

  /// Preload images for a list of products
  Future<void> preloadImages(List<String> urls) async {
    for (final url in urls) {
      if (!_bytesCache.containsKey(url) && url.startsWith('http')) {
        try {
          final file = await _cacheManager.getSingleFile(url);
          final bytes = await file.readAsBytes();
          _addToBytesCache(url, bytes);
        } catch (e) {
          print('Error preloading $url: $e');
        }
      }
    }
  }

  /// Clear caches
  void clearCache() {
    _memoryCache.clear();
    _bytesCache.clear();
    _cacheOrder.clear();
    _cacheManager.emptyCache();
  }
}

class CustomCacheManager extends CacheManager {
  static const String key = 'customImageCache';
  
  static final CustomCacheManager _instance = CustomCacheManager._internal();
  factory CustomCacheManager() => _instance;
  
  CustomCacheManager._internal() : super(
    Config(
      key,
      stalePeriod: const Duration(days: 30), // Cache for 30 days
      maxNrOfCacheObjects: 300, // Max 300 images
      repo: JsonCacheInfoRepository(databaseName: '${key}Cache.db'),
      fileService: HttpFileService(httpClient: http.Client()),
    ),
  );
}