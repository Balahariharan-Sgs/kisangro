import 'dart:async';
import 'dart:typed_data';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:kisangro/home/theme_mode_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:kisangro/home/membership.dart';
import 'package:kisangro/home/myorder.dart';
import 'package:kisangro/home/noti.dart';
import 'package:kisangro/menu/wishlist.dart';
import 'package:kisangro/services/product_service.dart';
import 'package:shimmer/shimmer.dart';

import '../categories/category_products_screen.dart';
import '../common/common_app_bar.dart';
import '../login/login.dart';
import '../menu/account.dart';
import '../menu/ask.dart';
import '../menu/logout.dart';
import '../menu/setting.dart';
import '../menu/transaction.dart';
import '../models/kyc_image_provider.dart';
import 'bottom.dart';
import 'custom_drawer.dart';

class ProductCategoriesScreen extends StatefulWidget {
  const ProductCategoriesScreen({super.key});

  @override
  State<ProductCategoriesScreen> createState() => _ProductCategoriesScreenState();
}

class _ProductCategoriesScreenState extends State<ProductCategoriesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map<String, String>> _categories = [];
  bool _isLoading = true;
  int? _pressedIndex; // Track which tile is being pressed

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Simulate network delay (remove this in production)
      await Future.delayed(const Duration(milliseconds: 500));

      final categories = await ProductService.getAllCategories();

      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoading = false;
        });
      }
      debugPrint('ProductCategoriesScreen: Loaded ${_categories.length} categories.');
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      debugPrint('Error loading categories: $e');
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

  /// Shows a confirmation dialog for logging out, clears navigation stack.
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap a button to dismiss
      builder: (context) => LogoutConfirmationDialog(
        onCancel: () => Navigator.of(context).pop(), // Close dialog on cancel
        onLogout: () {
          // Perform logout actions and navigate to LoginApp, clearing navigation stack
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginApp()),
                (Route<dynamic> route) => false, // Remove all routes below
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Logged out successfully!')),
          );
        },
      ),
    );
  }

  /// Shows a dialog for giving ratings and writing a review about the app.
  void _showComplaintDialog(BuildContext context) {
    final themeMode = Provider.of<ThemeModeProvider>(context, listen: false).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    final Color dialogBackgroundColor = isDarkMode ? Colors.grey[850]! : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;
    final Color hintColor = isDarkMode ? Colors.grey[400]! : Colors.grey;
    final Color borderColor = isDarkMode ? Colors.grey[600]! : Colors.grey;
    final Color orangeColor = const Color(0xffEB7720);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: dialogBackgroundColor, // Apply theme color
          content: StatefulBuilder(
            // Use StatefulBuilder to manage dialog's internal state for _rating and _reviewController
            builder: (context, setState) {
              return SizedBox(
                width: 328, // Fixed width for dialog content
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Make column content fit
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context), // Close dialog
                        child: const Icon(
                          Icons.close,
                          color: Color(0xffEB7720), // Orange close icon
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Give ratings and write a review about your experience using this app.",
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: textColor, // Apply theme color
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Text("Rate:", style: GoogleFonts.lato(fontSize: 16, color: textColor)), // Apply theme color
                        const SizedBox(width: 12),
                        RatingBar.builder(
                          // Star rating bar
                          initialRating: 4.0,
                          minRating: 1,
                          direction: Axis.horizontal,
                          allowHalfRating: false,
                          itemCount: 5,
                          itemSize: 32,
                          unratedColor: isDarkMode ? Colors.grey[700] : Colors.grey[300], // Apply theme color
                          itemBuilder: (context, _) => const Icon(
                            Icons.star,
                            color: Color(0xffEB7720),
                          ),
                          onRatingUpdate: (rating) {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: TextEditingController(),
                      maxLength: 100,
                      maxLines: 3,
                      style: GoogleFonts.lato(color: textColor), // Apply theme color
                      decoration: InputDecoration(
                        hintText: 'Write here',
                        hintStyle: GoogleFonts.lato(color: hintColor), // Apply theme color
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: borderColor), // Apply theme color
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: borderColor), // Apply theme color
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: const Color(0xffEB7720)), // Orange for focused
                        ),
                        counterText: '', // Hide default counter text
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 12,
                        ),
                      ),
                      onChanged: (_) => setState(
                              () {}), // Rebuild to update character count dynamically
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '0/100', // Character counter
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: hintColor, // Apply theme color
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xffEB7720),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context); // Close review dialog

                          // Show "Thank you" confirmation dialog
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: dialogBackgroundColor, // Apply theme color
                              contentPadding: const EdgeInsets.all(24),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Color(0xffEB7720),
                                    size: 48,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Thank you!',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: textColor, // Apply theme color
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Thanks for rating us.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: isDarkMode ? Colors.white70 : Colors.black54, // Apply theme color
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(context), // Close thank you dialog
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                        const Color(0xffEB7720),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        'OK',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Text(
                          'Submit',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white,
                          ),
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
    );
  }

  Widget _buildShimmerCategoryTile(bool isDarkMode) {
    final Color baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final Color highlightColor = isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;
    final Color cardColor = Colors.white; // Always white for shimmer

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.transparent : Colors.black12,
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 12,
              width: 60,
              color: Colors.white,
            ),
            const SizedBox(height: 4),
            Container(
              height: 10,
              width: 40,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.shortestSide >= 600;
    final orientation = MediaQuery.of(context).orientation;
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color iconColor = isDarkMode ? Colors.white70 : const Color(0xffEB7720);
    final Color borderColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;
    final Color backgroundColor = isDarkMode ? Colors.black : Colors.grey[100]!;
    final Color gradientStartColor = isDarkMode ? Colors.black : const Color(0xffFFD9BD);
    final Color gradientEndColor = isDarkMode ? Colors.black : const Color(0xffFFFFFF);

    int crossAxisCount;
    double childAspectRatio;

    final double screenWidth = screenSize.width;

    if (screenWidth > 900) {
      crossAxisCount = 5;
      childAspectRatio = 0.9;
    } else if (screenWidth > 700) {
      crossAxisCount = 4;
      childAspectRatio = 0.9;
    } else if (screenWidth > 450) {
      crossAxisCount = 3;
      childAspectRatio = 0.85;
    } else {
      crossAxisCount = 3;
      childAspectRatio = 0.85;
    }

    if (orientation == Orientation.landscape && screenWidth < 700) {
      crossAxisCount = 4;
      childAspectRatio = 0.9;
    }

    if (isTablet && orientation == Orientation.landscape) {
      crossAxisCount = 5;
      childAspectRatio = 0.9;
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        debugPrint('ProductCategoriesScreen: PopScope triggered. Navigating to Bot(initialIndex: 0).');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Bot(initialIndex: 0)),
              (Route<dynamic> route) => false,
        );
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: CustomDrawer(
          showComplaintDialog: _showComplaintDialog,
          showLogoutDialog: _showLogoutDialog,
        ),
        appBar: CustomAppBar(
          title: "Categories",
          showBackButton: true,
          showMenuButton: true,
          scaffoldKey: _scaffoldKey,
          isMyOrderActive: false,
          isWishlistActive: false,
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
          child: _isLoading
              ? GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 12.0,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: 8, // Show 8 shimmer placeholders
            itemBuilder: (context, index) {
              return _buildShimmerCategoryTile(isDarkMode);
            },
          )
              : _categories.isEmpty
              ? Center(
            child: Text(
              'No categories found',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: textColor,
              ),
            ),
          )
              : GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 12.0,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final String effectiveIconPath = _getEffectiveImageUrl(category['icon']!);
              final bool isNetworkImage = effectiveIconPath.startsWith('http');

              return GestureDetector(
                onTapDown: (_) {
                  setState(() {
                    _pressedIndex = index;
                  });
                },
                onTapUp: (_) {
                  setState(() {
                    _pressedIndex = null;
                  });
                },
                onTapCancel: () {
                  setState(() {
                    _pressedIndex = null;
                  });
                },
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategoryProductsScreen(
                        categoryTitle: category['label']!,
                        categoryId: category['cat_id']!,
                      ),
                    ),
                  );
                },
                child: Transform.scale(
                  scale: _pressedIndex == index ? 0.98 : 1.0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: Colors.white, // Pure white background
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: borderColor),
                      boxShadow: _pressedIndex == index
                          ? [
                        BoxShadow(
                          color: const Color(0xffEB7720).withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                          spreadRadius: 1,
                        ),
                      ]
                          : [
                        BoxShadow(
                          color: isDarkMode ? Colors.transparent : Colors.black12,
                          blurRadius: 4,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        isNetworkImage
                            ? Image.network(
                          effectiveIconPath,
                          height: 40,
                          width: 40,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.category, size: 40, color: iconColor);
                          },
                        )
                            : Image.asset(
                          effectiveIconPath,
                          height: 40,
                          width: 40,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.category, size: 40, color: iconColor);
                          },
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Text(
                            category['label']!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}