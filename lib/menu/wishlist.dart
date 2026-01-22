import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart'; // For firstWhereOrNull
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shimmer/shimmer.dart';

import 'package:kisangro/models/product_model.dart';
import 'package:kisangro/models/wishlist_model.dart';
import 'package:kisangro/models/cart_model.dart';
import 'package:kisangro/home/myorder.dart';
import 'package:kisangro/home/noti.dart';
import 'package:kisangro/home/cart.dart';
import 'package:kisangro/services/product_service.dart';
import 'package:kisangro/home/bottom.dart';
import '../common/common_app_bar.dart';
import '../home/theme_mode_provider.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWishlist();
  }

  Future<void> _initializeWishlist() async {
    final wishlist = Provider.of<WishlistModel>(context, listen: false);
    await wishlist.refresh();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getEffectiveImageUrl(String rawImageUrl) {
    if (rawImageUrl.isEmpty ||
        rawImageUrl == 'https://sgserp.in/erp/api/' ||
        (Uri.tryParse(rawImageUrl)?.isAbsolute != true && !rawImageUrl.startsWith('assets/'))) {
      return ProductService.getRandomValidImageUrl();
    }
    return rawImageUrl;
  }

  Future<void> _moveToCart(WishlistItem wishlistItem, BuildContext context) async {
    final cart = Provider.of<CartModel>(context, listen: false);
    final wishlist = Provider.of<WishlistModel>(context, listen: false);

    try {
      final product = ProductService.getProductById(wishlistItem.pro_id.toString());
      if (product != null) {
        final selectedSize = product.availableSizes.firstWhereOrNull(
                (size) => size.proId == wishlistItem.pro_id
        );

        if (selectedSize != null) {
          product.selectedUnit = selectedSize;
          await cart.addItem(product.copyWith());
          await wishlist.toggleItem(product);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${wishlistItem.title} moved to cart!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // If size not found, try to add with the first available size
          if (product.availableSizes.isNotEmpty) {
            product.selectedUnit = product.availableSizes.first;
            await cart.addItem(product.copyWith());
            await wishlist.toggleItem(product);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${wishlistItem.title} moved to cart with available size!'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('No sizes available for ${wishlistItem.title}'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        // If product not found in ProductService, show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product details not available for ${wishlistItem.title}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to move to cart: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildShimmerItem(bool isDarkMode) {
    final Color baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final Color highlightColor = isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;
    final Color cardColor = isDarkMode ? Colors.grey[850]! : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              width: 100,
              color: Colors.white,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 120,
                    height: 12,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 80,
                    height: 12,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 60,
                    height: 12,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 40,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color cardColor = isDarkMode ? Colors.grey[800]! : Colors.white;
    final Color borderColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;
    const Color orangeColor = Color(0xFFF76C00);
    final Color backgroundColor = isDarkMode ? Colors.black : Colors.grey[100]!;
    final Color gradientStartColor = isDarkMode ? Colors.black : const Color(0xffFFD9BD);
    final Color gradientEndColor = isDarkMode ? Colors.black : const Color(0xffFFFFFF);
    final Color containerColor = isDarkMode ? Colors.grey[850]! : const Color(0xffffecdc);
    final Color greyTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final Color infoIconColor = isDarkMode ? Colors.grey[600]! : Colors.grey[400]!;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const Bot(initialIndex: 0)),
                (Route<dynamic> route) => false,
          );
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: CustomAppBar(
          title: "Wishlist",
          showBackButton: true,
          showMenuButton: false,
          scaffoldKey: _scaffoldKey,
          isMyOrderActive: false,
          isWishlistActive: true,
          isNotiActive: false,
          isDetailPage: false,
        ),
        body: Container(
          height: double.infinity,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [gradientStartColor, gradientEndColor],
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                color: containerColor,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/apple.png',
                      width: 60,
                      height: 60,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "The best thing starts as a wish",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: orangeColor,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Image.asset(
                      'assets/wish.gif',
                      width: 60,
                      height: 60,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Consumer<WishlistModel>(
                  builder: (context, wishlist, child) {
                    if (_isLoading) {
                      return ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: 5, // Number of shimmer placeholders
                        itemBuilder: (context, index) {
                          return _buildShimmerItem(isDarkMode);
                        },
                      );
                    }

                    if (wishlist.items.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.favorite_border,
                              size: 80,
                              color: infoIconColor,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Your wishlist is empty!',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                color: greyTextColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Add products you love to your wishlist.',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: greyTextColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        setState(() => _isLoading = true);
                        await wishlist.refresh();
                        if (mounted) {
                          setState(() => _isLoading = false);
                        }
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: wishlist.items.length,
                        itemBuilder: (context, index) {
                          final wishlistItem = wishlist.items[index];
                          final effectiveImageUrl = _getEffectiveImageUrl(wishlistItem.imageUrl);
                          final isNetworkImage = effectiveImageUrl.startsWith('http');

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cardColor,
                              border: Border.all(color: borderColor),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Stack(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      height: 120,
                                      width: 100,
                                      color: isDarkMode ? Colors.grey[900]! : Colors.white,
                                      child: isNetworkImage
                                          ? Image.network(
                                        effectiveImageUrl,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) => Image.asset(
                                          'assets/placeholder.png',
                                          fit: BoxFit.contain,
                                        ),
                                      )
                                          : Image.asset(
                                        effectiveImageUrl,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(wishlistItem.title,
                                              style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.bold,
                                                  color: textColor)),
                                          Text(wishlistItem.subtitle,
                                              style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: textColor)),
                                          Text('Unit Size: ${wishlistItem.selectedUnitSize}',
                                              style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: textColor)),
                                          Text(
                                            '₹ ${wishlistItem.pricePerUnit.toStringAsFixed(2)}/piece',
                                            style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: orangeColor),
                                          ),
                                          const SizedBox(height: 10),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed: () => _moveToCart(wishlistItem, context),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: orangeColor,
                                                padding: const EdgeInsets.symmetric(vertical: 10),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                elevation: 0,
                                              ),
                                              child: Text(
                                                'Move to cart',
                                                style: GoogleFonts.poppins(
                                                    fontSize: 14,
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: GestureDetector(
                                    onTap: () async {
                                      final product = Product(
                                        mainProductId: wishlistItem.pro_id.toString(),
                                        title: wishlistItem.title,
                                        subtitle: wishlistItem.subtitle,
                                        imageUrl: wishlistItem.imageUrl,
                                        category: wishlistItem.category,
                                        availableSizes: [
                                          ProductSize(
                                            proId: wishlistItem.pro_id,
                                            size: wishlistItem.selectedUnitSize,
                                            price: wishlistItem.pricePerUnit,
                                            sellingPrice: wishlistItem.pricePerUnit,
                                          )
                                        ],
                                        initialSelectedUnitProId: wishlistItem.pro_id,
                                      );
                                      await wishlist.toggleItem(product);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('${wishlistItem.title} removed from wishlist!'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    },
                                    child: Icon(
                                      Icons.close,
                                      size: 18,
                                      color: orangeColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}