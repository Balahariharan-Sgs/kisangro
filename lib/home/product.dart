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
import 'package:collection/collection.dart'; // For firstWhereOrNull
import 'package:kisangro/home/product_size_selection_bottom_sheet.dart';
import 'package:kisangro/common/common_app_bar.dart';

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
  // Make _currentSelectedUnit nullable initially, and initialize in initState
  ProductSize? _currentSelectedUnit; // Changed type to ProductSize?
  late final List<String> imageAssets; // Will hold the main product image (repeated for carousel)
  VideoPlayerController? _videoController;
  Future<void>? _initializeVideoPlayerFuture;
  bool _videoLoadError = false;
  int _quantity = 1; // Added quantity counter

  List<Product> similarProducts = [];
  List<Product> topSellingProducts = [];

  final Color primaryColor = const Color(0xFFF37021);
  final Color themeOrange = const Color(0xffEB7720);
  final Color redColor = const Color(0xFFDC2F2F);
  // Removed backgroundColor as it will be determined by theme

  // Helper method to determine if a URL is valid for network image or if it's a local asset
  String _getEffectiveImageUrl(String rawImageUrl) {
    if (rawImageUrl.isEmpty || rawImageUrl == 'https://sgserp.in/erp/api/' || (Uri.tryParse(rawImageUrl)?.isAbsolute != true && !rawImageUrl.startsWith('assets/'))) {
      return ProductService.getRandomValidImageUrl(); // Use a random valid API image or local placeholder
    }
    return rawImageUrl;
  }

  bool get _isOrderedProduct => widget.orderedProduct != null;
  String get _displayTitle => _isOrderedProduct ? widget.orderedProduct!.title : widget.product!.title;
  String get _displaySubtitle => _isOrderedProduct ? widget.orderedProduct!.description : widget.product!.subtitle;
  String get _displayImageUrl => _isOrderedProduct ? widget.orderedProduct!.imageUrl : widget.product!.imageUrl;
  String get _displayCategory => _isOrderedProduct ? widget.orderedProduct!.category : widget.product!.category;

  double? get _displayMrpPerSelectedUnit {
    if (_isOrderedProduct) {
      return widget.orderedProduct!.price;
    } else {
      return _currentSelectedUnit?.price; // Use price from ProductSize
    }
  }

  double? get _displaySellingPricePerSelectedUnit {
    if (_isOrderedProduct) {
      return widget.orderedProduct!.price; // For ordered products, selling price is the price
    } else {
      return _currentSelectedUnit?.sellingPrice; // Use sellingPrice from ProductSize
    }
  }

  String get _displayUnitSizeDescription {
    if (_isOrderedProduct) {
      return 'Ordered Unit: ${widget.orderedProduct!.unit}';
    } else {
      return 'Unit: ${_currentSelectedUnit?.size ?? 'N/A'}'; // Use .size property
    }
  }

  Product _currentProductForActions() {
    if (_isOrderedProduct) {
      // FIX 1: Ensure proId is passed when creating ProductSize from OrderedProduct
      final int proId = int.tryParse(widget.orderedProduct!.id) ?? 0;
      return Product(
        mainProductId: widget.orderedProduct!.id,
        title: widget.orderedProduct!.title,
        subtitle: widget.orderedProduct!.description,
        imageUrl: widget.orderedProduct!.imageUrl,
        category: widget.orderedProduct!.category,
        availableSizes: [
          ProductSize(
            proId: proId, // Pass proId
            size: widget.orderedProduct!.unit,
            price: widget.orderedProduct!.price,
            sellingPrice: widget.orderedProduct!.price,
          )
        ],
        initialSelectedUnitProId: proId, // Set initialSelectedUnitProId
      );
    } else {
      // Ensure _currentSelectedUnit is not null before passing to copyWith
      // If _currentSelectedUnit is null (shouldn't happen after initState),
      // fallback to the product's default selected unit.
      return widget.product!.copyWith(selectedUnit: _currentSelectedUnit ?? widget.product!.selectedUnit); // Pass ProductSize object
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize _currentSelectedUnit based on whether it's an ordered product or a regular product
    if (_isOrderedProduct) {
      final int proId = int.tryParse(widget.orderedProduct!.id) ?? 0;
      _currentSelectedUnit = ProductSize(
        proId: proId,
        size: widget.orderedProduct!.unit,
        price: widget.orderedProduct!.price,
        sellingPrice: widget.orderedProduct!.price,
      );
    } else {
      _currentSelectedUnit = widget.product!.selectedUnit; // This is already a ProductSize object
    }

    // Use the _displayImageUrl (which applies fallback logic) for the carousel
    String mainDisplayImage = _getEffectiveImageUrl(_displayImageUrl);
    imageAssets = [mainDisplayImage, mainDisplayImage, mainDisplayImage]; // Repeat for carousel effect

    _videoController = VideoPlayerController.asset('assets/video.mp4');
    _initializeVideoPlayerFuture = _videoController!.initialize().then((_) {
      setState(() {
        _videoLoadError = false;
      });
    }).catchError((error) {
      setState(() {
        _videoLoadError = true;
      });
    });
    _videoController!.setLooping(true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSimilarProducts();
      _loadTopSellingProducts();
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _loadSimilarProducts() {
    final currentProductCategory = _currentProductForActions().category;
    final productsInSameCategory = ProductService.getProductsByCategoryName(currentProductCategory);

    setState(() {
      similarProducts = productsInSameCategory
          .where((p) => p.mainProductId != _currentProductForActions().mainProductId) // Compare by mainProductId
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

  // Add to cart with API integration
  Future<void> _addToCart(BuildContext context) async {
    final cart = Provider.of<CartModel>(context, listen: false);

    // Ensure _currentSelectedUnit is not null before using it
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

  // Increment quantity
  void _incrementQuantity() {
    setState(() {
      _quantity++;
    });
  }

  // Decrement quantity
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

    // Define colors based on theme
    final Color backgroundColor = isDarkMode ? Colors.black : const Color(0xFFFFF8F5);
    final Color gradientStartColor = isDarkMode ? Colors.black : const Color(0xffFFD9BD);
    final Color gradientEndColor = isDarkMode ? Colors.black : const Color(0xffFFFFFF);
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color subtitleColor = isDarkMode ? Colors.white70 : Colors.black87;
    final Color greyTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey;
    final Color dividerColor = isDarkMode ? Colors.grey[700]! : Colors.white; // Using white for light mode divider as per original
    final Color carouselBackgroundColor = isDarkMode ? Colors.grey[800]! : Colors.white70;
    final Color deliveryContainerColor = isDarkMode ? Colors.grey[900]! : Colors.white;
    final Color deliveryBorderColor = isDarkMode ? Colors.grey[700]! : const Color(0xFFDADADA);
    final Color quantityBorderColor = isDarkMode ? Colors.grey[600]! : Colors.grey.shade400;
    final Color orangeColor = const Color(0xffEB7720);

    return Scaffold(
      backgroundColor: backgroundColor, // Apply theme color
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
            colors: [gradientStartColor, gradientEndColor], // Apply theme colors
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
                    color: carouselBackgroundColor, // Apply theme color
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: CarouselSlider.builder(
                    itemCount: imageAssets.length,
                    itemBuilder: (context, index, realIndex) {
                      final imageUrl = imageAssets[index]; // This already comes from _getEffectiveImageUrl
                      final bool isNetworkImage = imageUrl.startsWith('http');
                      return isNetworkImage
                          ? Image.network(
                        imageUrl, // Use the already effective URL
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Image.asset(
                          'assets/placeholder.png', // Fallback to local placeholder if network image fails
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
                // Share button positioned at top-right
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Share functionality coming soon!', style: GoogleFonts.poppins())),
                      );
                    },
                    icon: Icon(Icons.share, color: greyTextColor, size: 28), // Apply theme color
                    splashRadius: 24,
                  ),
                ),
                // Wishlist icon positioned below the share button
                Positioned(
                  top: 48, // Positioned below the share button (8 + 40 for the button height)
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
            Text(_displayTitle, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)), // Apply theme color
            Text(_displaySubtitle, style: GoogleFonts.poppins(fontSize: 14, color: subtitleColor)), // Apply theme color
            Text(_displayCategory, style: GoogleFonts.poppins(fontSize: 14, color: greyTextColor)), // Apply theme color
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
                            _currentSelectedUnit = productSize; // FIX 3: Assign the ProductSize object
                          });
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: _currentSelectedUnit?.proId == productSize.proId ? themeOrange : Colors.transparent, // Compare by proId
                          side: BorderSide(color: themeOrange),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: Text(
                          productSize.size,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _currentSelectedUnit?.proId == productSize.proId ? Colors.white : themeOrange, // Compare by proId
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

            // Quantity selector for non-ordered products
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
                    color: greyTextColor, // Apply theme color
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
            Text(_displayUnitSizeDescription, style: GoogleFonts.poppins(fontSize: 14, color: subtitleColor)), // Apply theme color
            const SizedBox(height: 8),
            Text(
              _isOrderedProduct
                  ? 'Total for ordered quantity: ₹ ${((_displayMrpPerSelectedUnit ?? 0.0) * widget.orderedProduct!.quantity).toStringAsFixed(2)}'
                  : 'Price for ${_currentSelectedUnit?.size ?? 'N/A'}: ₹ ${((_displaySellingPricePerSelectedUnit ?? _displayMrpPerSelectedUnit ?? 0.0) * _quantity).toStringAsFixed(2)}', // Use .size and multiply by quantity
              style: GoogleFonts.poppins(color: subtitleColor), // Apply theme color
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
                        textStyle: GoogleFonts.poppins(color: primaryColor) // Ensure text color is set
                    ),
                    child: Text('Put in Cart', style: GoogleFonts.poppins(color: primaryColor)), // Explicitly set text color
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Ensure _currentSelectedUnit is not null before using it
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
            Divider(color: dividerColor, thickness: 3), // Apply theme color
            const SizedBox(height: 20),
            _buildHeaderSection('Cancellation Policy', isDarkMode), // Pass isDarkMode
            const SizedBox(height: 8),
            _buildDottedText('Upto 5 days returnable', isDarkMode), // Pass isDarkMode
            _buildDottedText('Wrong product received', isDarkMode), // Pass isDarkMode
            _buildDottedText('Damaged product received', isDarkMode), // Pass isDarkMode
            const SizedBox(height: 20),
            Divider(color: dividerColor, thickness: 3), // Apply theme color
            const SizedBox(height: 20),
            _buildHeaderSection('About Product', isDarkMode), // Pass isDarkMode
            const SizedBox(height: 8),
            Text(
              '$_displaySubtitle\n\nAbamectin 1.9% EC is a broad-spectrum insecticide and acaricide, effective against a wide range of mites and insects, particularly those that are motile or sucking, working through contact and stomach action, and also exhibiting translaminar activity.',
              style: GoogleFonts.poppins(fontSize: 14, color: subtitleColor), // Apply theme color
            ),
            const SizedBox(height: 12),
            _buildHeaderSection('Target Pests', isDarkMode), // Pass isDarkMode
            const SizedBox(height: 8),
            _buildDottedText('Yellow mites, red mites, spotted mites, leaf miners, sucking insects', isDarkMode), // Pass isDarkMode
            const SizedBox(height: 12),
            _buildHeaderSection('Target Crops', isDarkMode), // Pass isDarkMode
            const SizedBox(height: 8),
            _buildDottedText('Grapes, roses, brinjal, chili, tea, cotton, ornamental plants', isDarkMode), // Pass isDarkMode
            const SizedBox(height: 12),
            _buildHeaderSection('Dosage', isDarkMode), // Pass isDarkMode
            const SizedBox(height: 8),
            _buildDottedText('1 ml per liter of water (200 ml per acre)', isDarkMode), // Pass isDarkMode
            const SizedBox(height: 12),
            _buildHeaderSection('Available Pack', isDarkMode), // Pass isDarkMode
            const SizedBox(height: 8),
            _buildDottedText('50, 100, 250, 500, 1000 ml', isDarkMode), // Pass isDarkMode
            const SizedBox(height: 15),
            Divider(color: dividerColor, thickness: 3), // Apply theme color
            const SizedBox(height: 20),
            _buildHeaderSection('Tutorial Video', isDarkMode), // Pass isDarkMode
            const SizedBox(height: 8),
            FutureBuilder(
              future: _initializeVideoPlayerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (_videoLoadError) {
                    return Container(
                      height: 200,
                      color: isDarkMode ? Colors.red.shade900 : Colors.red.shade100, // Apply theme color
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, color: isDarkMode ? Colors.red.shade300 : Colors.red, size: 40), // Apply theme color
                            const SizedBox(height: 10),
                            Text(
                              'Could not load video. Check asset path or file format.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(color: isDarkMode ? Colors.red.shade300 : Colors.red, fontSize: 14), // Apply theme color
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
                                bufferedColor: isDarkMode ? Colors.grey[600]! : Colors.grey, // Apply theme color
                                backgroundColor: isDarkMode ? Colors.white38 : Colors.white54, // Apply theme color
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
                    color: isDarkMode ? Colors.grey[800] : Colors.grey.shade300, // Apply theme color
                    child: Center(child: CircularProgressIndicator(color: themeOrange)),
                  );
                }
              },
            ),
            SizedBox(height: 20,),
            Divider(color: dividerColor, thickness: 3), // Apply theme color
            const SizedBox(height: 20),
            _buildHeaderSection("Browse Similar Products", isDarkMode), // Pass isDarkMode
            SizedBox(
              height: 280, // Reduced height for more compact cards
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: similarProducts.length,
                padding: const EdgeInsets.only(left: 0, right: 12),
                itemBuilder: (context, index) {
                  final product = similarProducts[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      left: index == 0 ? 1.0 : 0, // Add left padding only for first item
                      right: 1.0,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        // When a similar product is tapped, navigate to a new ProductDetailPage
                        // and ensure it's wrapped with a ChangeNotifierProvider for that specific product.
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
                      // Wrap _buildProductTile with a ChangeNotifierProvider for the product
                      child: ChangeNotifierProvider<Product>.value(
                        value: product,
                        child: _buildProductTile(context, product, isDarkMode, index), // Pass index for margin calculation
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Divider(color: dividerColor, thickness: 3), // Apply theme color
            const SizedBox(height: 20),
            _buildHeaderSection("Top Selling Products", isDarkMode), // Pass isDarkMode
            SizedBox(
              height: 280, // Reduced height for more compact cards
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: topSellingProducts.length,
                padding: const EdgeInsets.only(left: 0, right: 12),
                itemBuilder: (context, index) {
                  final product = topSellingProducts[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      left: index == 0 ? 1.0 : 0, // Add left padding only for first item
                      right: 1.0,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        // When a top selling product is tapped, navigate to a new ProductDetailPage
                        // and ensure it's wrapped with a ChangeNotifierProvider for that specific product.
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
                      // Wrap _buildProductTile with a ChangeNotifierProvider for the product
                      child: ChangeNotifierProvider<Product>.value(
                        value: product,
                        child: _buildProductTile(context, product, isDarkMode, index), // Pass index for margin calculation
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

  Widget _buildHeaderSection(String title, bool isDarkMode) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(
      title,
      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: isDarkMode ? Colors.white : Colors.black), // Apply theme color
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
            child: Icon(Icons.circle, size: 6, color: isDarkMode ? Colors.white : Colors.black), // Apply theme color
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: GoogleFonts.poppins(fontSize: 14, color: isDarkMode ? Colors.white70 : Colors.black87)), // Apply theme color
          ),
        ],
      ),
    );
  }

  // This _buildProductTile is used for similar and top-selling products.
  Widget _buildProductTile(BuildContext context, Product product, bool isDarkMode, int index) {
    final themeOrange = const Color(0xffEB7720);
    final redColor = const Color(0xFFDC2F2F);
    final Color cardBackgroundColor = isDarkMode ? Colors.grey[900]! : Colors.white;
    final Color borderColor = isDarkMode ? Colors.grey[700]! : Colors.grey.shade300;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color greyTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey;

    // Consume the product here to react to its selectedUnit changes
    return Consumer<Product>(
      builder: (context, product, child) {
        // Ensure effectiveAvailableSizes is never empty.
        final List<ProductSize> effectiveAvailableSizes = product.availableSizes.isNotEmpty
            ? product.availableSizes
            : [ProductSize(proId: 0, size: 'Unit', price: 0.0, sellingPrice: 0.0)]; // FIX 1: Add proId

        // Resolve the selected unit for the dropdown
        // Find the ProductSize object that matches the currently selected unit's proId
        ProductSize currentSelectedUnit = effectiveAvailableSizes.firstWhere(
              (sizeOption) => sizeOption.proId == product.selectedUnit.proId, // Compare by proId
          orElse: () => effectiveAvailableSizes.first, // Fallback to first if not found
        );

        final double? currentMrp = currentSelectedUnit.price; // Use price from currentSelectedUnit
        final double? currentSellingPrice = currentSelectedUnit.sellingPrice; // Use sellingPrice from currentSelectedUnit

        return Container(
          width: 140, // Reduced width for more compact cards
          margin: EdgeInsets.only(
            left: index == 0 ? 0 : 8, // Add left margin for all except first card
            right: 8,
          ),
          decoration: BoxDecoration(
            color: cardBackgroundColor, // Apply theme color
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor), // Apply theme color
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 90, // Reduced height for image
                width: double.infinity,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(6.0), // Reduced padding
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
                padding: const EdgeInsets.all(6.0), // Reduced padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: textColor), // Smaller font
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2), // Reduced spacing
                    Text(
                      product.subtitle,
                      style: GoogleFonts.poppins(fontSize: 10, color: textColor), // Smaller font
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4), // Reduced spacing
                    Row(
                      children: [
                        Text(
                          '₹ ${currentMrp?.toStringAsFixed(2) ?? 'N/A'}',
                          style: GoogleFonts.poppins(
                            fontSize: 10, // Smaller font
                            color: greyTextColor, // Apply theme color
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
                              style: GoogleFonts.poppins(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600), // Smaller font
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2), // Reduced spacing
                    Text('Unit: ${currentSelectedUnit.size}', // FIX 2: Use .size property
                        style: GoogleFonts.poppins(fontSize: 9, color: themeOrange)), // Smaller font
                    const SizedBox(height: 6), // Reduced spacing
                    // REPLACED DROPDOWN WITH SIZE SELECTION CONTAINER (like homepage)
                    Container(
                      height: 30, // Reduced height
                      padding: const EdgeInsets.symmetric(horizontal: 6), // Reduced padding
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
                              style: GoogleFonts.poppins(fontSize: 10, color: textColor), // Smaller font
                            ),
                            Icon(Icons.arrow_drop_down, color: textColor, size: 16), // Smaller icon
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6), // Reduced spacing
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Consumer<WishlistModel>(
                          builder: (context, wishlist, child) {
                            final bool isFavorite = wishlist.containsItem(currentSelectedUnit.proId); // FIX 4: Use proId
                            return IconButton(
                              onPressed: () async {
                                final success = await wishlist.toggleItem(product);
                                if (success != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isFavorite
                                            ? '${product.title} removed from wishlist!'
                                            : '${product.title} added to wishlist!',
                                        style: GoogleFonts.poppins(),
                                      ),
                                      backgroundColor: isFavorite ? redColor : Colors.blue,
                                    ),
                                  );
                                }
                              },
                              icon: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: isFavorite ? themeOrange : greyTextColor, // Apply theme color - orange when selected
                                size: 18, // Smaller icon
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            );
                          },
                        ),
                        const SizedBox(width: 8), // Added space between wishlist and add button
                        // REPLACED CART ICON WITH ADD BUTTON
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final cart = Provider.of<CartModel>(context, listen: false);
                              try {
                                await cart.addItem(product);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${product.title} (${product.selectedUnit.size}) added to cart!',
                                      style: GoogleFonts.poppins(),
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Failed to add to cart: $e',
                                      style: GoogleFonts.poppins(),
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeOrange,
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), // Reduced padding
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            child: Text(
                              "Add",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 10, // Smaller font
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
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
                      // Update the product's selected unit
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