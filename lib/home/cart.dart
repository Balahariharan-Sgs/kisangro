import 'package:flutter/material.dart';
import 'package:kisangro/home/bottom.dart';
import 'package:kisangro/home/myorder.dart';
import 'package:kisangro/home/noti.dart';
import 'package:kisangro/home/theme_mode_provider.dart';
import 'package:kisangro/menu/wishlist.dart';
import 'package:kisangro/models/wishlist_model.dart';
import 'package:kisangro/payment/payment1.dart';
import 'package:kisangro/payment/payment3.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:kisangro/models/cart_model.dart';
import 'package:kisangro/models/product_model.dart';
import 'package:kisangro/services/product_service.dart';
import 'package:kisangro/home/product.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collection/collection.dart';
import 'package:shimmer/shimmer.dart';

import '../common/common_app_bar.dart';
import '../home/product_size_selection_bottom_sheet.dart';

class Cart extends StatefulWidget {
  const Cart({super.key});

  @override
  State<Cart> createState() => _cartState();
}

class _cartState extends State<Cart> {
  List<Product> _similarProducts = [];
  int? _cusId;
  bool _isLoading = true;
  bool _cartLoaded = false;

  String _getEffectiveImageUrl(String rawImageUrl) {
    if (rawImageUrl.isEmpty ||
        rawImageUrl == 'https://sgserp.in/erp/api/' ||
        (Uri.tryParse(rawImageUrl)?.isAbsolute != true && !rawImageUrl.startsWith('assets/'))) {
      return 'assets/placeholder.png';
    }
    return rawImageUrl;
  }

  @override
  void initState() {
    super.initState();
    _initializeCartScreen();
  }

  Future<void> _initializeCartScreen() async {
    setState(() {
      _isLoading = true;
      _cartLoaded = false;
    });
    await _loadCusId();
    _loadSimilarProducts();

    // Add a small delay to show the loading animation
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      setState(() {
        _isLoading = false;
        _cartLoaded = true;
      });
    }
  }

  Future<void> _loadCusId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _cusId = prefs.getInt('cus_id');
      debugPrint('Cart Screen: Loaded cus_id: $_cusId');
    });
  }

  void _loadSimilarProducts() {
    final allAvailableProducts = ProductService.getAllProducts();

    if (allAvailableProducts.isNotEmpty) {
      allAvailableProducts.shuffle();
      setState(() {
        _similarProducts = allAvailableProducts.take(10).toList();
        debugPrint('Cart: Loaded ${_similarProducts.length} similar products from ProductService.');
      });
    } else {
      debugPrint('Cart: ProductService returned no products for similar items. Using dummy fallback.');
      setState(() {
        _similarProducts = List.generate(
          5,
              (index) => Product(
            mainProductId: 'similar_dummy_main_$index',
            title: 'Dummy Similar $index',
            subtitle: 'Placeholder Item',
            imageUrl: ProductService.getRandomValidImageUrl(),
            category: 'Dummy',
            availableSizes: [ProductSize(proId: 9000 + index, size: 'kg', price: 75.0 + index * 5)],
            initialSelectedUnitProId: 9000 + index,
          ),
        );
      });
    }
  }

  Widget _buildShimmerItem(bool isDarkMode) {
    final Color baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final Color highlightColor = isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;
    final Color cardColor = isDarkMode ? Colors.grey[900]! : Colors.white;

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
              height: 128,
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
                    width: 120,
                    height: 30,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerSimilarProduct(bool isDarkMode) {
    final Color baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final Color highlightColor = isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;
    final Color cardColor = isDarkMode ? Colors.grey[900]! : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 100,
              width: double.infinity,
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            Container(
              width: 100,
              height: 16,
              color: Colors.white,
            ),
            const SizedBox(height: 4),
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
            const SizedBox(height: 8),
            Container(
              width: 80,
              height: 30,
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            Container(
              width: 100,
              height: 30,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  void _showSizeSelectionBottomSheet(BuildContext context, Product product, bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ProductSizeSelectionBottomSheet(
          product: product,
          isDarkMode: isDarkMode,
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, CartItem cartItem, VoidCallback onRemove, bool isDarkMode) {
    final Color orangeColor = const Color(0xffEB7720);
    final Color backgroundColor = isDarkMode ? Colors.grey[900]! : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: orangeColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Are you sure?',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'You are going to delete "${cartItem.title}" from your cart.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: textColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: orangeColor),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              child: Text(
                                'No',
                                style: GoogleFonts.poppins(
                                  color: orangeColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                onRemove();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: orangeColor,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              child: Text(
                                'Yes',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
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
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.shortestSide >= 600;

    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    final Color backgroundColor = isDarkMode ? Colors.black : const Color(0xFFFFF7F1);
    final Color gradientStartColor = isDarkMode ? Colors.black : const Color(0xffFFD9BD);
    final Color gradientEndColor = isDarkMode ? Colors.black : const Color(0xffFFFFFF);
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color cardBackgroundColor = isDarkMode ? Colors.grey[900]! : Colors.white;
    final Color borderColor = isDarkMode ? Colors.grey[700]! : Colors.grey.shade300;
    final Color orangeColor = const Color(0xffEB7720);
    final Color dividerColor = isDarkMode ? Colors.grey[700]! : Colors.grey;

    return Scaffold(
      appBar: CustomAppBar(
        title: "Cart",
        showBackButton: true,
        showMenuButton: false,
        isMyOrderActive: false,
        isWishlistActive: false,
        isNotiActive: false,
        isDetailPage: false,
      ),
      body: _isLoading
          ? Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [gradientStartColor, gradientEndColor],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(orangeColor),
                strokeWidth: 4,
              ),
              const SizedBox(height: 20),
              Text(
                'Loading your cart...',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      )
          : Consumer<CartModel>(
        builder: (context, cart, child) {
          if (!_cartLoaded) {
            return Container(
              height: double.infinity,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [gradientStartColor, gradientEndColor],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(orangeColor),
                      strokeWidth: 4,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Loading your cart...',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // FIX: Use cart.totalAmount directly without adding extra fees
          // The cart.totalAmount should already include all applicable charges
          final double grandTotal = cart.totalAmount;

          debugPrint('Cart: Total Amount=₹$grandTotal');

          if (cart.items.isEmpty) {
            return Container(
              height: double.infinity,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [gradientStartColor, gradientEndColor],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 80,
                      color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Your cart is empty!',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Start adding some products from the home screen.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 20),

                  ],
                ),
              ),
            );
          }

          return Container(
            height: double.infinity,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [gradientStartColor, gradientEndColor],
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Amount:',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor)),
                      Text('₹ ${grandTotal.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                    ],
                  ),
                  Divider(thickness: 1, color: dividerColor),
                  Text(
                    'Step 1/3',
                    style: GoogleFonts.poppins(color: orangeColor, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Item Summary (${cart.totalItemCount} items in your cart)',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final cartItem = cart.items[index];
                      return ChangeNotifierProvider<CartItem>.value(
                        value: cartItem,
                        builder: (context, child) {
                          final item = Provider.of<CartItem>(context);
                          return _itemCard(
                            cartItem: item,
                            onRemove: () async {
                              await cart.removeItem(item.proId);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${item.title} removed from cart!'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              debugPrint('Cart: Removed item ${item.proId}, Unit: ${item.selectedUnitSize}, New Total: ₹${cart.totalAmount}');
                            },
                            onIncrement: () async {
                              await cart.updateItemQuantity(item.proId, item.quantity + 1);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Quantity of ${item.title} incremented to ${item.quantity}!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              debugPrint('Cart: Incremented ${item.proId}, Quantity: ${item.quantity}, New Total: ₹${cart.totalAmount}');
                            },
                            onDecrement: () async {
                              if (item.quantity > 1) {
                                await cart.updateItemQuantity(item.proId, item.quantity - 1);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Quantity of ${item.title} decremented to ${item.quantity}!'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                debugPrint('Cart: Decremented ${item.proId}, Quantity: ${item.quantity}, New Total: ₹${cart.totalAmount}');
                              } else {
                                await cart.removeItem(item.proId);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${item.title} removed from cart!'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                debugPrint('Cart: Removed item ${item.proId}, Unit: ${item.selectedUnitSize}, New Total: ₹${cart.totalAmount}');
                              }
                            },
                            isDarkMode: isDarkMode,
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Text("Browse Similar Products",
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                  ),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final double screenWidth = constraints.maxWidth;
                      int crossAxisCount;
                      double childAspectRatio;

                      if (screenWidth > 900) {
                        crossAxisCount = 5;
                        childAspectRatio = 0.6;
                      } else if (screenWidth > 600) {
                        crossAxisCount = 3;
                        childAspectRatio = 0.65;
                      } else {
                        crossAxisCount = 2;
                        childAspectRatio = 0.52;
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: childAspectRatio,
                          mainAxisExtent: 305,
                        ),
                        itemCount: _similarProducts.length,
                        itemBuilder: (context, index) {
                          final product = _similarProducts[index];
                          return ChangeNotifierProvider<Product>.value(
                            value: product,
                            child: _buildSimilarProductCard(context, product, isDarkMode: isDarkMode),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Consumer<CartModel>(
        builder: (context, cart, child) {
          if (cart.items.isEmpty || !_cartLoaded) {
            return const SizedBox.shrink();
          }
          return Container(
            height: 70,
            decoration: BoxDecoration(
              color: cardBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: isDarkMode ? Colors.transparent : Colors.black.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 6,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: orangeColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  if (cart.items.isNotEmpty) {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const delivery()));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Your cart is empty! Add items to proceed.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Proceed To Payment',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.arrow_forward_ios_outlined, color: Colors.white70),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _itemCard({
    required CartItem cartItem,
    required VoidCallback onRemove,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
    required bool isDarkMode,
  }) {
    final String effectiveImageUrl = _getEffectiveImageUrl(cartItem.imageUrl);
    final bool isNetworkImage = effectiveImageUrl.startsWith('http');

    final Color cardBackgroundColor = isDarkMode ? Colors.grey[900]! : Colors.orange.shade50.withOpacity(0.3);
    final Color borderColor = isDarkMode ? Colors.grey[700]! : Colors.grey.shade300;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color orangeColor = const Color(0xffEB7720);
    final Color imageContainerColor = isDarkMode ? Colors.grey[800]! : Colors.white;
    final Color quantityBorderColor = isDarkMode ? Colors.grey[600]! : Colors.grey.shade400;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 128,
                width: 100,
                color: imageContainerColor,
                child: isNetworkImage
                    ? Image.network(
                  effectiveImageUrl,
                  width: 100,
                  height: 128,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    'assets/placeholder.png',
                    width: 100,
                    height: 128,
                    fit: BoxFit.contain,
                  ),
                )
                    : Image.asset(
                  effectiveImageUrl,
                  width: 100,
                  height: 128,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cartItem.title,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor)),
                    Text(cartItem.subtitle,
                        style: GoogleFonts.poppins(fontSize: 12, color: textColor)),
                    Text('Unit Size: ${cartItem.selectedUnitSize}',
                        style: GoogleFonts.poppins(fontSize: 12, color: textColor)),
                    Text('₹ ${cartItem.pricePerUnit.toStringAsFixed(2)}/piece',
                        style: GoogleFonts.poppins(fontSize: 12, color: orangeColor)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text("Units: ", style: GoogleFonts.poppins(fontSize: 13, color: textColor)),
                            InkWell(
                              onTap: onDecrement,
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
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: quantityBorderColor),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('${cartItem.quantity}',
                                    style: GoogleFonts.poppins(fontSize: 14, color: textColor)),
                              ),
                            ),
                            InkWell(
                              onTap: onIncrement,
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
                        // Delete button in the same line with quantity controls
                        InkWell(
                          onTap: () {
                            _showDeleteConfirmationDialog(context, cartItem, onRemove, isDarkMode);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: const EdgeInsets.all(6),
                            child: const Icon(Icons.delete_outline, size: 18, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, bool isDarkMode) {
    final Color textColor = isDarkMode ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(color: textColor)),
          Text(value, style: GoogleFonts.poppins(color: textColor)),
        ],
      ),
    );
  }

  Widget _buildSimilarProductCard(BuildContext context, Product product, {required bool isDarkMode}) {
    final Color cardBackgroundColor = isDarkMode ? Colors.grey[900]! : Colors.white;
    final Color borderColor = isDarkMode ? Colors.grey[700]! : Colors.grey.shade300;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color orangeColor = const Color(0xffEB7720);
    final Color dividerColor = isDarkMode ? Colors.grey[700]! : Colors.grey;

    return Consumer<Product>(
      builder: (context, product, child) {
        final List<ProductSize> effectiveAvailableSizes = product.availableSizes.isNotEmpty
            ? product.availableSizes
            : [ProductSize(proId: 0, size: 'Unit', price: 0.0, sellingPrice: 0.0)];

        ProductSize currentSelectedUnit = effectiveAvailableSizes.firstWhere(
              (sizeOption) => sizeOption.proId == product.selectedUnit.proId,
          orElse: () => effectiveAvailableSizes.first,
        );
        String resolvedSelectedUnitSize = currentSelectedUnit.size;

        final String effectiveImageUrl = _getEffectiveImageUrl(product.imageUrl);
        final bool isNetworkImage = effectiveImageUrl.startsWith('http');

        return Container(
          decoration: BoxDecoration(
            color: cardBackgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
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
                child: SizedBox(
                  height: 100,
                  width: double.infinity,
                  child: Center(
                    child: isNetworkImage
                        ? Image.network(
                      effectiveImageUrl,
                      height: 100,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        'assets/placeholder.png',
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                    )
                        : Image.asset(
                      effectiveImageUrl,
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Divider(color: dividerColor),
              const SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  product.title,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: textColor),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(product.subtitle,
                    style: GoogleFonts.poppins(fontSize: 12, color: textColor),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              Text('₹ ${product.sellingPricePerSelectedUnit?.toStringAsFixed(2) ?? product.pricePerSelectedUnit?.toStringAsFixed(2) ?? 'N/A'}',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.green)),
              const SizedBox(height: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Unit Size: ${resolvedSelectedUnitSize}",
                            style: GoogleFonts.poppins(fontSize: 12, color: orangeColor)),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: orangeColor),
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
                                product.selectedUnit.size,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: textColor,
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                color: orangeColor,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                _showSizeSelectionBottomSheet(context, product, isDarkMode);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: orangeColor,
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              child: Text("Add",
                                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
                            ),
                          ),
                          Consumer<WishlistModel>(
                            builder: (context, wishlist, child) {
                              final bool isFavorite = wishlist.containsItem(product.selectedUnit.proId);
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
                                        ),
                                        backgroundColor: isFavorite ? Colors.red : Colors.blue,
                                      ),
                                    );
                                  }
                                },
                                icon: Icon(
                                  isFavorite ? Icons.favorite : Icons.favorite_border,
                                  color: orangeColor,
                                  size: 20,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              );
                            },
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}