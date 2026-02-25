import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:kisangro/home/myorder.dart';
import 'package:kisangro/home/noti.dart';
import 'package:kisangro/home/theme_mode_provider.dart';
import 'package:kisangro/menu/wishlist.dart';
import 'package:kisangro/payment/payment1.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:video_player/video_player.dart';
import 'package:kisangro/models/product_model.dart';
import 'package:kisangro/models/cart_model.dart';
import 'package:kisangro/models/wishlist_model.dart';
import 'package:kisangro/home/bottom.dart';
import 'package:kisangro/models/order_model.dart';
import 'package:kisangro/home/cart.dart';
import 'package:kisangro/services/product_service.dart';
import '../models/address_model.dart';
import 'package:collection/collection.dart';
import 'package:kisangro/home/product_size_selection_bottom_sheet.dart';
import 'package:kisangro/common/common_app_bar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class ProductDetailPage extends StatefulWidget {
  final Product? product;
  final OrderedProduct? orderedProduct;

  const ProductDetailPage({
    Key? key,
    this.product,
    this.orderedProduct,
  }) : assert(product != null || orderedProduct != null, 'Either product or orderedProduct must be provided'),
        assert(!(product != null && orderedProduct != null), 'Only one of product or orderedProduct should be provided'),
        super(key: key);

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int activeIndex = 0;
  ProductSize? _currentSelectedUnit;
  late final List<String> imageAssets;
  VideoPlayerController? _videoController;
  YoutubePlayerController? _youtubeController;
  Future<void>? _initializeVideoPlayerFuture;
  bool _videoLoadError = false;
  int _quantity = 1;

  List<Product> similarProducts = [];
  List<Product> topSellingProducts = [];

  final Color primaryColor = const Color(0xFFF37021);
  final Color themeOrange = const Color(0xffEB7720);
  final Color redColor = const Color(0xFFDC2F2F);

  // API response data
  Map<String, dynamic>? _apiProductData;
  bool _isLoading = true;
  String? _errorMessage;

  // Helper method to determine if a URL is valid for network image or if it's a local asset
  String _getEffectiveImageUrl(String rawImageUrl) {
    if (rawImageUrl.isEmpty || rawImageUrl == 'https://sgserp.in/erp/api/' || (Uri.tryParse(rawImageUrl)?.isAbsolute != true && !rawImageUrl.startsWith('assets/'))) {
      return ProductService.getRandomValidImageUrl();
    }
    return rawImageUrl;
  }

  bool get _isOrderedProduct => widget.orderedProduct != null;
String get _displayTitle => _isOrderedProduct 
    ? widget.orderedProduct!.title 
    : (_apiProductData != null && _apiProductData!['product_name'] != null && _apiProductData!['product_name'].toString().isNotEmpty
        ? _apiProductData!['product_name'] 
        : widget.product!.title);

String get _displaySubtitle => _isOrderedProduct 
    ? widget.orderedProduct!.description 
    : (_apiProductData != null && _apiProductData!['product_description'] != null && _apiProductData!['product_description'].toString().isNotEmpty
        ? _apiProductData!['product_description'] 
        : widget.product!.subtitle);

String get _displayImageUrl => _isOrderedProduct 
    ? widget.orderedProduct!.imageUrl 
    : (_apiProductData != null && _apiProductData!['image'] != null && _apiProductData!['image'].toString().isNotEmpty 
        ? _apiProductData!['image'] 
        : widget.product!.imageUrl);

String get _displayCancellationPolicy => _apiProductData != null && _apiProductData!['cancellation_policy'] != null && _apiProductData!['cancellation_policy'].toString().isNotEmpty
    ? _apiProductData!['cancellation_policy'] 
    : 'Upto 5 days returnable';

String get _displayTargetPests => _apiProductData != null && _apiProductData!['target_pests'] != null && _apiProductData!['target_pests'].toString().isNotEmpty
    ? _apiProductData!['target_pests'] 
    : 'Yellow mites, red mites, spotted mites, leaf miners, sucking insects';

String get _displayTargetCrops => _apiProductData != null && _apiProductData!['target_crops'] != null && _apiProductData!['target_crops'].toString().isNotEmpty
    ? _apiProductData!['target_crops'] 
    : 'Grapes, roses, brinjal, chili, tea, cotton, ornamental plants';

String get _displayDosage => _apiProductData != null && _apiProductData!['dosage'] != null && _apiProductData!['dosage'].toString().isNotEmpty
    ? _apiProductData!['dosage'] 
    : '1 ml per liter of water (200 ml per acre)';

String get _displayAvailablePack => _apiProductData != null && _apiProductData!['available_pack'] != null && _apiProductData!['available_pack'].toString().isNotEmpty
    ? _apiProductData!['available_pack'] 
    : '50, 100, 250, 500, 1000 ml';

String get _displayVideoUrl => _apiProductData != null && _apiProductData!['video'] != null && _apiProductData!['video'].toString().isNotEmpty
    ? _apiProductData!['video'] 
    : '';
  double? get _displayMrpPerSelectedUnit {
    if (_isOrderedProduct) {
      return widget.orderedProduct!.price;
    } else {
      return _currentSelectedUnit?.price;
    }
  }

  double? get _displaySellingPricePerSelectedUnit {
    if (_isOrderedProduct) {
      return widget.orderedProduct!.price;
    } else {
      return _currentSelectedUnit?.sellingPrice;
    }
  }

  String get _displayUnitSizeDescription {
        if (_isOrderedProduct) {
          return 'Ordered Unit: ${widget.orderedProduct!.unit}';
        } else {
          return 'Unit: ${_currentSelectedUnit?.size ?? 'N/A'}';
        }
      }
  
  String get _displayCategory {
      if (_isOrderedProduct) {
        return widget.orderedProduct!.category;
      } else {
        return widget.product!.category;
      }
    }

  Product _currentProductForActions() {
    if (_isOrderedProduct) {
      final int proId = int.tryParse(widget.orderedProduct!.id) ?? 0;
      return Product(
        mainProductId: widget.orderedProduct!.id,
        title: widget.orderedProduct!.title,
        subtitle: widget.orderedProduct!.description,
        imageUrl: widget.orderedProduct!.imageUrl,
        category: widget.orderedProduct!.category,
        availableSizes: [
          ProductSize(
            proId: proId,
            size: widget.orderedProduct!.unit,
            price: widget.orderedProduct!.price,
            sellingPrice: widget.orderedProduct!.price,
          )
        ],
        initialSelectedUnitProId: proId,
      );
    } else {
      return widget.product!.copyWith(selectedUnit: _currentSelectedUnit ?? widget.product!.selectedUnit);
    }
  }

Future<void> _fetchProductDetails() async {
  if (_isOrderedProduct) {
    setState(() {
      _isLoading = false;
    });
    return;
  }

  try {
    // Get the mainProductId
    String mainProductId = widget.product?.mainProductId ?? '0';
    String proId = '0';
    
    print('Original mainProductId: $mainProductId');
    
    // First, try to get the selected unit's pro_id directly from the product
    // This is more reliable as it comes from the selected unit
    if (widget.product?.selectedUnit != null) {
      proId = widget.product!.selectedUnit.proId.toString();
      print('Using selected unit proId: $proId');
    } else {
      // If no selected unit, try to extract from mainProductId
      // Format might be like "d_7_null" or "d_55_null" or "AURA 505_8_null"
      if (mainProductId.contains('_')) {
        final parts = mainProductId.split('_');
        print('Split parts: $parts');
        
        // Look for the numeric part - usually the second part or any numeric part
        for (var part in parts) {
          // Try to parse as int, if successful and it's not "null"
          final parsed = int.tryParse(part);
          if (parsed != null && part.toLowerCase() != 'null') {
            proId = part;
            print('Found numeric proId: $proId from part: $part');
            break;
          }
        }
        
        // If still not found, try the second part as fallback
        if (proId == '0' && parts.length > 1 && parts[1].toLowerCase() != 'null') {
          proId = parts[1];
          print('Using second part as proId: $proId');
        }
      }
    }
    
    // Final fallback
    if (proId == '0') {
      proId = mainProductId;
      print('Using full mainProductId as fallback: $proId');
    }
    
    print('Final proId to send to API: $proId');
    
    final response = await http.post(
      Uri.parse('https://erpsmart.in/total/api/m_api/'),
      body: {
        'cid': '85788578',
        'type': '1018',
        'ln': '145',
        'lt': '145',
        'device_id': '12345',
        'pro_id': proId,
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      print('Product Response for pro_id $proId: $jsonResponse');
      
      if (jsonResponse['status'] == 'success' && jsonResponse['data'] != null) {
        setState(() {
          _apiProductData = jsonResponse['data'];
          _isLoading = false;
        });
        
        _initializeVideo();
      } else {
        print('API returned error or no data, using local product data');
        setState(() {
          _apiProductData = {
            'product_id': proId,
            'product_name': widget.product?.title ?? 'Product',
            'product_description': widget.product?.subtitle ?? '',
            'product_feature': 'Premium quality product',
            'image': widget.product?.imageUrl ?? '',
            'cancellation_policy': 'Upto 5 days returnable',
            'target_pests': 'Yellow mites, red mites, spotted mites, leaf miners, sucking insects',
            'target_crops': 'Grapes, roses, brinjal, chili, tea, cotton, ornamental plants',
            'dosage': 'As per requirement',
            'available_pack': _getAvailablePackFromSizes(),
            'video': '',
          };
          _isLoading = false;
        });
        
        _initializeVideo();
      }
    } else {
      print('Server error: ${response.statusCode}, using local product data');
      setState(() {
        _apiProductData = {
          'product_id': proId,
          'product_name': widget.product?.title ?? 'Product',
          'product_description': widget.product?.subtitle ?? '',
          'product_feature': 'Premium quality product',
          'image': widget.product?.imageUrl ?? '',
          'cancellation_policy': 'Upto 5 days returnable',
          'target_pests': 'Yellow mites, red mites, spotted mites, leaf miners, sucking insects',
          'target_crops': 'Grapes, roses, brinjal, chili, tea, cotton, ornamental plants',
          'dosage': 'As per requirement',
          'available_pack': _getAvailablePackFromSizes(),
          'video': '',
        };
        _isLoading = false;
      });
      
      _initializeVideo();
    }
  } catch (e) {
    print('Error in _fetchProductDetails: $e');
    setState(() {
      _apiProductData = {
        'product_id': widget.product?.selectedUnit?.proId.toString() ?? '0',
        'product_name': widget.product?.title ?? 'Product',
        'product_description': widget.product?.subtitle ?? '',
        'product_feature': 'Premium quality product',
        'image': widget.product?.imageUrl ?? '',
        'cancellation_policy': 'Upto 5 days returnable',
        'target_pests': 'Yellow mites, red mites, spotted mites, leaf miners, sucking insects',
        'target_crops': 'Grapes, roses, brinjal, chili, tea, cotton, ornamental plants',
        'dosage': 'As per requirement',
        'available_pack': _getAvailablePackFromSizes(),
        'video': '',
      };
      _isLoading = false;
    });
    
    _initializeVideo();
  }
}


// Helper method to generate available pack string from product sizes
String _getAvailablePackFromSizes() {
  if (!_isOrderedProduct && widget.product?.availableSizes != null) {
    final sizes = widget.product!.availableSizes
        .where((size) => size.size.isNotEmpty && size.size != 'Unit')
        .map((size) => size.size)
        .toList();
    
    if (sizes.isNotEmpty) {
      return sizes.join(', ');
    }
  }
  return '50, 100, 250, 500, 1000 ml';
}
// Add this new method to load product sizes
Future<void> _loadProductSizes(String proId) async {
  try {
    // Try to fetch product sizes from a different endpoint if available
    final response = await http.post(
      Uri.parse('https://erpsmart.in/total/api/m_api/'),
      body: {
        'cid': '85788578',
        'type': '1019', // Different type for sizes
        'ln': '145',
        'lt': '145',
        'device_id': '12345',
        'pro_id': proId,
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      print('Product sizes response: $jsonResponse');
      
      if (jsonResponse['status'] == 'success' && jsonResponse['data'] != null) {
        // Update the product with sizes from API
        // You'll need to implement this based on your API response structure
      }
    }
  } catch (e) {
    print('Error loading product sizes: $e');
  }
}

void _initializeVideo() {
  // Dispose existing controllers
  _videoController?.dispose();
  _youtubeController?.dispose();
  
  String videoUrl = _displayVideoUrl;
  
  if (videoUrl.isNotEmpty) {
    if (videoUrl.contains('youtube.com') || videoUrl.contains('youtu.be') || videoUrl.contains('youtube.com/shorts')) {
      // Handle YouTube video including shorts
      String? videoId;
      if (videoUrl.contains('shorts/')) {
        // Extract ID from shorts URL: https://youtube.com/shorts/9344J2QRTVI
        final uri = Uri.parse(videoUrl);
        final pathSegments = uri.pathSegments;
        if (pathSegments.isNotEmpty && pathSegments.last.isNotEmpty) {
          videoId = pathSegments.last.split('?').first;
        }
      } else {
        videoId = YoutubePlayer.convertUrlToId(videoUrl);
      }
      
      if (videoId != null) {
        _youtubeController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: false,
            mute: false,
          ),
        );
        setState(() {
          _videoLoadError = false;
        });
      } else {
        setState(() {
          _videoLoadError = true;
        });
      }
    } else {
      // Handle direct video file
      _videoController = VideoPlayerController.network(videoUrl);
      _initializeVideoPlayerFuture = _videoController!.initialize().then((_) {
        setState(() {
          _videoLoadError = false;
        });
      }).catchError((error) {
        print('Video initialization error: $error');
        setState(() {
          _videoLoadError = true;
        });
      });
      _videoController!.setLooping(true);
    }
  } else {
    // No video URL provided, set error state or hide video section
    setState(() {
      _videoLoadError = true;
    });
  }
}

@override
void initState() {
  super.initState();
  
  if (_isOrderedProduct) {
    final int proId = int.tryParse(widget.orderedProduct!.id) ?? 0;
    _currentSelectedUnit = ProductSize(
      proId: proId,
      size: widget.orderedProduct!.unit,
      price: widget.orderedProduct!.price,
      sellingPrice: widget.orderedProduct!.price,
    );
  } else {
    _currentSelectedUnit = widget.product!.selectedUnit;
    // Print for debugging
    print('Product mainProductId: ${widget.product!.mainProductId}');
    print('Selected unit proId: ${widget.product!.selectedUnit.proId}');
    print('Selected unit size: ${widget.product!.selectedUnit.size}');
  }

  // Fetch product details from API
  _fetchProductDetails();

  // Initialize with placeholder or product image
  String mainDisplayImage = _getEffectiveImageUrl(_displayImageUrl);
  imageAssets = [mainDisplayImage, mainDisplayImage, mainDisplayImage];

  WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadSimilarProducts();
    _loadTopSellingProducts();
  });
}
  @override
  void dispose() {
    _videoController?.dispose();
    _youtubeController?.dispose();
    super.dispose();
  }

  void _loadSimilarProducts() {
    final currentProductCategory = _currentProductForActions().category;
    final productsInSameCategory = ProductService.getProductsByCategoryName(currentProductCategory);

    setState(() {
      similarProducts = productsInSameCategory
          .where((p) => p.mainProductId != _currentProductForActions().mainProductId)
          .take(6)
          .toList();
      if (similarProducts.length < 6) {
        final allProducts = ProductService.getAllProducts();
        final otherProducts = allProducts
            .where((p) => p.mainProductId != _currentProductForActions().mainProductId && !similarProducts.any((sp) => sp.mainProductId == p.mainProductId))
            .take(6 - similarProducts.length)
            .toList();
        similarProducts.addAll(otherProducts);
      }
    });
  }

  void _loadTopSellingProducts() {
    final allProducts = ProductService.getAllProducts();
    setState(() {
      topSellingProducts = allProducts.reversed.take(6).toList();
    });
  }

  Future<void> _addToCart(BuildContext context) async {
    final cart = Provider.of<CartModel>(context, listen: false);

    if (_currentSelectedUnit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a unit for the product.', style: GoogleFonts.poppins())),
      );
      return;
    }

    try {
      await cart.addItem(_currentProductForActions(), quantity: _quantity);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_currentProductForActions().title} (${_currentProductForActions().selectedUnit.size}) x$_quantity added to cart!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add to cart: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _incrementQuantity() {
    setState(() {
      _quantity++;
    });
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartModel>(context, listen: false);
    final wishlist = Provider.of<WishlistModel>(context, listen: false);
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    final Color backgroundColor = isDarkMode ? Colors.black : const Color(0xFFFFF8F5);
    final Color gradientStartColor = isDarkMode ? Colors.black : const Color(0xffFFD9BD);
    final Color gradientEndColor = isDarkMode ? Colors.black : const Color(0xffFFFFFF);
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color subtitleColor = isDarkMode ? Colors.white70 : Colors.black87;
    final Color greyTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey;
    final Color dividerColor = isDarkMode ? Colors.grey[700]! : Colors.white;
    final Color carouselBackgroundColor = isDarkMode ? Colors.grey[800]! : Colors.white70;
    final Color deliveryContainerColor = isDarkMode ? Colors.grey[900]! : Colors.white;
    final Color deliveryBorderColor = isDarkMode ? Colors.grey[700]! : const Color(0xFFDADADA);
    final Color quantityBorderColor = isDarkMode ? Colors.grey[600]! : Colors.grey.shade400;
    final Color orangeColor = const Color(0xffEB7720);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: CustomAppBar(
          title: 'Loading...',
          showBackButton: true,
          showMenuButton: false,
          showWhatsAppIcon: false,
          isMyOrderActive: false,
          isWishlistActive: false,
          isNotiActive: false,
          isDetailPage: true,
        ),
        body: Center(
          child: CircularProgressIndicator(color: themeOrange),
        ),
      );
    }

    if (_errorMessage != null && !_isOrderedProduct) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: CustomAppBar(
          title: 'Error',
          showBackButton: true,
          showMenuButton: false,
          showWhatsAppIcon: false,
          isMyOrderActive: false,
          isWishlistActive: false,
          isNotiActive: false,
          isDetailPage: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: redColor, size: 60),
              const SizedBox(height: 16),
              Text(
                'Failed to load product details',
                style: GoogleFonts.poppins(fontSize: 18, color: textColor),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: GoogleFonts.poppins(fontSize: 14, color: subtitleColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchProductDetails,
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                child: Text('Retry', style: GoogleFonts.poppins(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: CustomAppBar(
        title: _displayTitle,
        showBackButton: true,
        showMenuButton: false,
        showWhatsAppIcon: false,
        isMyOrderActive: false,
        isWishlistActive: false,
        isNotiActive: false,
        isDetailPage: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [gradientStartColor, gradientEndColor],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Stack(
              children: [
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: carouselBackgroundColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: CarouselSlider.builder(
                    itemCount: imageAssets.length,
                    itemBuilder: (context, index, realIndex) {
                      final imageUrl = imageAssets[index];
                      final bool isNetworkImage = imageUrl.startsWith('http');
                      return isNetworkImage
                          ? Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Image.asset(
                          'assets/placeholder.png',
                          fit: BoxFit.contain,
                        ),
                      )
                          : Image.asset(imageUrl, fit: BoxFit.contain);
                    },
                    options: CarouselOptions(
                      height: 200,
                      autoPlay: false,
                      enableInfiniteScroll: false,
                      onPageChanged: (index, reason) => setState(() => activeIndex = index),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Share functionality coming soon!', style: GoogleFonts.poppins())),
                      );
                    },
                    icon: Icon(Icons.share, color: greyTextColor, size: 28),
                    splashRadius: 24,
                  ),
                ),
                Positioned(
                  top: 48,
                  right: 8,
                  child: Consumer<WishlistModel>(
                    builder: (context, wishlist, child) {
                      final Product productForActions = _currentProductForActions();
                      final bool isFavorite = wishlist.containsItem(productForActions.selectedUnit.proId);
                      return IconButton(
                        onPressed: () async {
                          final success = await wishlist.toggleItem(productForActions);
                          if (success != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isFavorite
                                      ? '${productForActions.title} removed from wishlist!'
                                      : '${productForActions.title} added to wishlist!',
                                  style: GoogleFonts.poppins(),
                                ),
                                backgroundColor: isFavorite ? redColor : Colors.blue,
                              ),
                            );
                          }
                        },
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? redColor : greyTextColor,
                          size: 28,
                        ),
                        splashRadius: 24,
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            Center(
              child: AnimatedSmoothIndicator(
                activeIndex: activeIndex,
                count: imageAssets.length,
                effect: ExpandingDotsEffect(
                  activeDotColor: primaryColor,
                  dotHeight: 5,
                  dotWidth: 8,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(_displayTitle, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
            Text(_displaySubtitle, style: GoogleFonts.poppins(fontSize: 14, color: subtitleColor)),
            Text(_displayCategory, style: GoogleFonts.poppins(fontSize: 14, color: greyTextColor)),
            const SizedBox(height: 10),
            if (!_isOrderedProduct)
              SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: widget.product!.availableSizes.map((productSize) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _currentSelectedUnit = productSize;
                          });
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: _currentSelectedUnit?.proId == productSize.proId ? themeOrange : Colors.transparent,
                          side: BorderSide(color: themeOrange),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: Text(
                          productSize.size,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _currentSelectedUnit?.proId == productSize.proId ? Colors.white : themeOrange,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ordered Unit: ${widget.orderedProduct!.unit}',
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: themeOrange),
                  ),
                  Text(
                    'Quantity: ${widget.orderedProduct!.quantity}',
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: themeOrange),
                  ),
                ],
              ),

            if (!_isOrderedProduct)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  children: [
                    Text("Quantity: ", style: GoogleFonts.poppins(fontSize: 16, color: textColor)),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: _decrementQuantity,
                      child: Container(
                        decoration: BoxDecoration(
                          color: orangeColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(Icons.remove, size: 16, color: Colors.white),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: quantityBorderColor),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('$_quantity',
                            style: GoogleFonts.poppins(fontSize: 16, color: textColor)),
                      ),
                    ),
                    InkWell(
                      onTap: _incrementQuantity,
                      child: Container(
                        decoration: BoxDecoration(
                          color: orangeColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(Icons.add, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  'M.R.P.: ₹ ${_displayMrpPerSelectedUnit?.toStringAsFixed(2) ?? 'N/A'}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: greyTextColor,
                    decoration: (_displaySellingPricePerSelectedUnit != null && _displaySellingPricePerSelectedUnit != _displayMrpPerSelectedUnit)
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                if (_displaySellingPricePerSelectedUnit != null && _displaySellingPricePerSelectedUnit != _displayMrpPerSelectedUnit)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      'Our Price: ₹ ${_displaySellingPricePerSelectedUnit?.toStringAsFixed(2) ?? 'N/A'}',
                      style: GoogleFonts.poppins(fontSize: 18, color: themeOrange, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            Text(_displayUnitSizeDescription, style: GoogleFonts.poppins(fontSize: 14, color: subtitleColor)),
            const SizedBox(height: 8),
            Text(
              _isOrderedProduct
                  ? 'Total for ordered quantity: ₹ ${((_displayMrpPerSelectedUnit ?? 0.0) * widget.orderedProduct!.quantity).toStringAsFixed(2)}'
                  : 'Price for ${_currentSelectedUnit?.size ?? 'N/A'}: ₹ ${((_displaySellingPricePerSelectedUnit ?? _displayMrpPerSelectedUnit ?? 0.0) * _quantity).toStringAsFixed(2)}',
              style: GoogleFonts.poppins(color: subtitleColor),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _addToCart(context),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: BorderSide(color: primaryColor),
                        textStyle: GoogleFonts.poppins(color: primaryColor)
                    ),
                    child: Text('Put in Cart', style: GoogleFonts.poppins(color: primaryColor)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentSelectedUnit == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please select a unit for the product.', style: GoogleFonts.poppins())),
                        );
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => delivery(product: _currentProductForActions()),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                    child: Text('Buy Now', style: GoogleFonts.poppins(color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Divider(color: dividerColor, thickness: 3),
            const SizedBox(height: 20),
            _buildHeaderSection('Cancellation Policy', isDarkMode),
            const SizedBox(height: 8),
            _buildDottedText(_displayCancellationPolicy, isDarkMode),
            const SizedBox(height: 20),
            Divider(color: dividerColor, thickness: 3),
            const SizedBox(height: 20),
            _buildHeaderSection('About Product', isDarkMode),
            const SizedBox(height: 8),
            Text(
              '$_displaySubtitle\n\n${_apiProductData != null ? _apiProductData!['product_feature'] ?? '' : ''}',
              style: GoogleFonts.poppins(fontSize: 14, color: subtitleColor),
            ),
            const SizedBox(height: 12),
            _buildHeaderSection('Target Pests', isDarkMode),
            const SizedBox(height: 8),
            _buildDottedText(_displayTargetPests, isDarkMode),
            const SizedBox(height: 12),
            _buildHeaderSection('Target Crops', isDarkMode),
            const SizedBox(height: 8),
            _buildDottedText(_displayTargetCrops, isDarkMode),
            const SizedBox(height: 12),
            _buildHeaderSection('Dosage', isDarkMode),
            const SizedBox(height: 8),
            _buildDottedText(_displayDosage, isDarkMode),
            const SizedBox(height: 12),
            _buildHeaderSection('Available Pack', isDarkMode),
            const SizedBox(height: 8),
            _buildDottedText(_displayAvailablePack, isDarkMode),
            const SizedBox(height: 15),
            Divider(color: dividerColor, thickness: 3),
            const SizedBox(height: 20),
            _buildHeaderSection('Tutorial Video', isDarkMode),
            const SizedBox(height: 8),
            _buildVideoPlayer(isDarkMode),
            SizedBox(height: 20,),
            Divider(color: dividerColor, thickness: 3),
            const SizedBox(height: 20),
            _buildHeaderSection("Browse Similar Products", isDarkMode),
            SizedBox(
              height: 240,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: similarProducts.length,
                padding: const EdgeInsets.only(left: 0, right: 12),
                itemBuilder: (context, index) {
                  final product = similarProducts[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      left: index == 0 ? 1.0 : 0,
                      right: 1.0,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChangeNotifierProvider<Product>.value(
                              value: product,
                              child: ProductDetailPage(product: product),
                            ),
                          ),
                        );
                      },
                      child: ChangeNotifierProvider<Product>.value(
                        value: product,
                        child: _buildProductTile(context, product, isDarkMode, index),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Divider(color: dividerColor, thickness: 3),
            const SizedBox(height: 20),
            _buildHeaderSection("Top Selling Products", isDarkMode),
            SizedBox(
              height: 240,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: topSellingProducts.length,
                padding: const EdgeInsets.only(left: 0, right: 12),
                itemBuilder: (context, index) {
                  final product = topSellingProducts[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      left: index == 0 ? 1.0 : 0,
                      right: 1.0,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChangeNotifierProvider<Product>.value(
                              value: product,
                              child: ProductDetailPage(product: product),
                            ),
                          ),
                        );
                      },
                      child: ChangeNotifierProvider<Product>.value(
                        value: product,
                        child: _buildProductTile(context, product, isDarkMode, index),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(bool isDarkMode) {
    if (_youtubeController != null) {
      return YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: _youtubeController!,
          showVideoProgressIndicator: true,
          progressIndicatorColor: themeOrange,
          onReady: () {
            // Controller is ready
          },
        ),
        builder: (context, player) {
          return Column(
            children: [
              player,
              const SizedBox(height: 8),
              // No VideoProgressIndicator for YouTube as it's already shown in the player
            ],
          );
        },
      );
    }

    return FutureBuilder(
      future: _initializeVideoPlayerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (_videoLoadError || _videoController == null) {
            return Container(
              height: 200,
              color: isDarkMode ? Colors.red.shade900 : Colors.red.shade100,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, color: isDarkMode ? Colors.red.shade300 : Colors.red, size: 40),
                    const SizedBox(height: 10),
                    Text(
                      'Could not load video. Check URL or file format.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: isDarkMode ? Colors.red.shade300 : Colors.red, fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(_videoController!),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _videoController!.value.isPlaying ? _videoController!.pause() : _videoController!.play();
                      });
                    },
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                      child: Center(
                        child: Icon(
                          _videoController!.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                          color: Colors.white,
                          size: 70,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: VideoProgressIndicator(
                      _videoController!,
                      allowScrubbing: true,
                      colors: VideoProgressColors(
                        playedColor: themeOrange,
                        bufferedColor: isDarkMode ? Colors.grey[600]! : Colors.grey,
                        backgroundColor: isDarkMode ? Colors.white38 : Colors.white54,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        } else {
          return Container(
            height: 200,
            color: isDarkMode ? Colors.grey[800] : Colors.grey.shade300,
            child: Center(child: CircularProgressIndicator(color: themeOrange)),
          );
        }
      },
    );
  }

  Widget _buildHeaderSection(String title, bool isDarkMode) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(
      title,
      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: isDarkMode ? Colors.white : Colors.black),
    ),
  );

  Widget _buildDottedText(String text, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0, left: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Icon(Icons.circle, size: 6, color: isDarkMode ? Colors.white : Colors.black),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: GoogleFonts.poppins(fontSize: 14, color: isDarkMode ? Colors.white70 : Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _buildProductTile(BuildContext context, Product product, bool isDarkMode, int index) {
    final themeOrange = const Color(0xffEB7720);
    final redColor = const Color(0xFFDC2F2F);
    final Color cardBackgroundColor = isDarkMode ? Colors.grey[900]! : Colors.white;
    final Color borderColor = isDarkMode ? Colors.grey[700]! : Colors.grey.shade300;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color greyTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey;

    return Consumer<Product>(
      builder: (context, product, child) {
        final List<ProductSize> effectiveAvailableSizes = product.availableSizes.isNotEmpty
            ? product.availableSizes
            : [ProductSize(proId: 0, size: 'Unit', price: 0.0, sellingPrice: 0.0)];

        ProductSize currentSelectedUnit = effectiveAvailableSizes.firstWhere(
              (sizeOption) => sizeOption.proId == product.selectedUnit.proId,
          orElse: () => effectiveAvailableSizes.first,
        );

        final double? currentMrp = currentSelectedUnit.price;
        final double? currentSellingPrice = currentSelectedUnit.sellingPrice;

        return Container(
          width: 140,
          margin: EdgeInsets.only(
            left: index == 0 ? 0 : 8,
            right: 8,
          ),
          decoration: BoxDecoration(
            color: cardBackgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 90,
                width: double.infinity,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: _getEffectiveImageUrl(product.imageUrl).startsWith('http')
                        ? Image.network(
                      _getEffectiveImageUrl(product.imageUrl),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        'assets/placeholder.png',
                        fit: BoxFit.contain,
                      ),
                    )
                        : Image.asset(
                      _getEffectiveImageUrl(product.imageUrl),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: textColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.subtitle,
                      style: GoogleFonts.poppins(fontSize: 10, color: textColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '₹ ${currentMrp?.toStringAsFixed(2) ?? 'N/A'}',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: greyTextColor,
                            decoration: (currentSellingPrice != null && currentSellingPrice != currentMrp)
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                        if (currentSellingPrice != null && currentSellingPrice != currentMrp)
                          Padding(
                            padding: const EdgeInsets.only(left: 4.0),
                            child: Text(
                              '₹ ${currentSellingPrice.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('Unit: ${currentSelectedUnit.size}',
                        style: GoogleFonts.poppins(fontSize: 9, color: themeOrange)),
                    const SizedBox(height: 6),
                    Container(
                      height: 30,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: themeOrange),
                        borderRadius: BorderRadius.circular(6),
                        color: isDarkMode ? Colors.grey[800] : Colors.white,
                      ),
                      child: InkWell(
                        onTap: () {
                          _showSizeSelectionBottomSheet(context, product, isDarkMode);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              currentSelectedUnit.size,
                              style: GoogleFonts.poppins(fontSize: 10, color: textColor),
                            ),
                            Icon(Icons.arrow_drop_down, color: textColor, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSizeSelectionBottomSheet(BuildContext context, Product product, bool isDarkMode) {
    final Color backgroundColor = isDarkMode ? Colors.grey[900]! : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color selectedColor = isDarkMode ? themeOrange.withOpacity(0.3) : themeOrange.withOpacity(0.2);

    showModalBottomSheet(
      context: context,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[600]! : Colors.grey[400]!,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select Size',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: product.availableSizes.map((sizeOption) {
                  final bool isSelected = product.selectedUnit.proId == sizeOption.proId;
                  return GestureDetector(
                    onTap: () {
                      product.selectedUnit = sizeOption;
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? selectedColor : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? themeOrange : (isDarkMode ? Colors.grey[600]! : Colors.grey[400]!),
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        sizeOption.size,
                        style: GoogleFonts.poppins(
                          color: isSelected ? themeOrange : textColor,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}