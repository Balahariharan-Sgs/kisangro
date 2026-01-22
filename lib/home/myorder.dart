import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:kisangro/home/bottom.dart'; // Import Bot for navigation
import 'package:kisangro/home/product.dart'; // This is your existing ProductDetailPage
import 'package:kisangro/home/theme_mode_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:kisangro/home/cancel1.dart';
import 'package:kisangro/home/noti.dart';
import 'package:kisangro/home/cart.dart';
import 'package:kisangro/home/multi_product_order_detail_page.dart'; // Correct import path for MultiProductOrderDetailPage
import 'package:kisangro/login/login.dart';
import 'package:kisangro/menu/account.dart';
import 'package:kisangro/menu/ask.dart';
import 'package:kisangro/menu/logout.dart';
import 'package:kisangro/menu/setting.dart';
import 'package:kisangro/menu/transaction.dart';
import 'package:kisangro/menu/wishlist.dart';
import 'package:kisangro/models/order_model.dart';
import 'package:kisangro/models/cart_model.dart';
import 'package:kisangro/models/kyc_image_provider.dart';
import 'package:kisangro/models/product_model.dart'; // Ensure Product model is imported for conversion
import 'package:kisangro/services/product_service.dart'; // Import ProductService
import 'package:kisangro/home/trending_products_screen.dart'; // Import TrendingProductsScreen
import 'package:kisangro/models/wishlist_model.dart'; // Import WishlistModel for _buildProductTile
import '../common/common_app_bar.dart';
import 'dispatched_orders_screen.dart';
import 'custom_drawer.dart'; // Import the CustomDrawer
import 'package:collection/collection.dart'; // For firstWhereOrNull


class MyOrder extends StatefulWidget {
  const MyOrder({super.key});

  @override
  State<MyOrder> createState() => _MyOrderState();
}

class _MyOrderState extends State<MyOrder> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _rating = 4; // Changed from double to int
  final TextEditingController _reviewController = TextEditingController(); // Controller for review text field
  static const int maxChars = 100; // Max characters for review
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Product> similarProducts = []; // For "Browse Similar Products"
  List<Product> topSellingProducts = []; // For "Top Selling Products"

  // Helper method to determine if a URL is valid for network image or if it's a local asset
  String _getEffectiveImageUrl(String rawImageUrl) {
    if (rawImageUrl.isEmpty || rawImageUrl == 'https://sgserp.in/erp/api/' || (Uri.tryParse(rawImageUrl)?.isAbsolute != true && !rawImageUrl.startsWith('assets/'))) {
      return ProductService.getRandomValidImageUrl(); // Use a random valid API image or local placeholder
    }
    return rawImageUrl;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSimilarProducts();
      _loadTopSellingProducts();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reviewController.dispose(); // Re-added dispose
    super.dispose();
  }

  void _loadSimilarProducts() {
    final allProducts = ProductService.getAllProducts();
    if (allProducts.isNotEmpty) {
      allProducts.shuffle();
      setState(() {
        similarProducts = allProducts.take(6).toList(); // Take 6 random products
        debugPrint('MyOrder: Loaded ${similarProducts.length} similar products.');
      });
    } else {
      debugPrint('MyOrder: No products available from ProductService for similar items.');
      // Optionally, load dummy products if ProductService is completely empty
    }
  }

  void _loadTopSellingProducts() {
    final allProducts = ProductService.getAllProducts();
    if (allProducts.isNotEmpty) {
      // For "top selling", we can simply reverse or take a subset of the existing products
      // In a real app, this would come from a specific API endpoint for top-selling items
      setState(() {
        topSellingProducts = allProducts.reversed.take(6).toList(); // Example: last 6 products as "top selling"
        debugPrint('MyOrder: Loaded ${topSellingProducts.length} top selling products.');
      });
    } else {
      debugPrint('MyOrder: No products available from ProductService for top selling items.');
      // Optionally, load dummy products if ProductService is completely empty
    }
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
  void showComplaintDialog(BuildContext context) {
    final themeMode = Provider.of<ThemeModeProvider>(context, listen: false).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    final Color dialogBackgroundColor = isDarkMode ? Colors.grey[900]! : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;
    final Color hintColor = isDarkMode ? Colors.white70 : Colors.grey;
    final Color borderColor = isDarkMode ? Colors.grey[700]! : Colors.grey;
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
                          initialRating: _rating.toDouble(),
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
                          onRatingUpdate: (rating) {
                            setState(() {
                              _rating = rating.toInt(); // Update rating state
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _reviewController,
                      maxLength: maxChars,
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
                        '${_reviewController.text.length}/$maxChars', // Character counter
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

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    // Define colors based on theme
    final Color backgroundColor = isDarkMode ? Colors.black : const Color(0xFFFFF7F1);
    final Color gradientStartColor = isDarkMode ? Colors.black : const Color(0xffFFD9BD);
    final Color gradientEndColor = isDarkMode ? Colors.black : const Color(0xffFFFFFF);
    final Color tabBackgroundColor = const Color(0xffEB7720); // Tab bar background remains orange
    final Color tabLabelColor = Colors.white;
    final Color tabUnselectedLabelColor = Colors.white.withOpacity(0.7);
    final Color infoIconColor = isDarkMode ? Colors.grey[600]! : Colors.grey[400]!;
    final Color infoTextColor = isDarkMode ? Colors.grey[300]! : Colors.grey[600]!;
    final Color headerTextColor = isDarkMode ? Colors.white : Colors.black;
    final Color headerDividerColor = isDarkMode ? Colors.grey[700]! : Colors.black;
    final Color drawerContainerColor = isDarkMode ? Colors.grey[850]! : const Color(0xffffecdc); // Drawer menu item background

    return PopScope( // <--- Added PopScope here
      canPop: false, // Prevent default back behavior
      onPopInvoked: (didPop) {
        if (didPop) return; // If the pop was successful, do nothing.
        debugPrint('MyOrder: PopScope triggered. Navigating to Bot(initialIndex: 0).');
        // Navigate to the home screen (Bot with initialIndex: 0)
        // This will replace all routes until the Bot screen.
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Bot(initialIndex: 0)),
              (Route<dynamic> route) => false, // Remove all previous routes
        );
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: CustomDrawer( // Using CustomDrawer
          showComplaintDialog: showComplaintDialog, // Pass the method
          showLogoutDialog: _showLogoutDialog, // Pass the method
        ),
        appBar: CustomAppBar( // Use the CustomAppBar widget
          title: "My Orders",
          showBackButton: true, // Show back button as per original AppBar
          showMenuButton: false, // Do not show menu button
          scaffoldKey: _scaffoldKey, // Pass the scaffold key
          isMyOrderActive: true, // Highlight My Orders icon
          isWishlistActive: false,
          isNotiActive: false,
          isDetailPage: false, // This is not a detail page that pops back to another page within its own flow
          // showWhatsAppIcon is false by default in CustomAppBar, matching original
        ),
        body: Container(
          height: double.infinity,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [gradientStartColor, gradientEndColor], // Apply theme colors
            ),
          ),
          child: Consumer<OrderModel>(
            builder: (context, orderModel, child) {
              final bookedOrders = orderModel.orders
                  .where((order) => order.status == OrderStatus.booked || order.status == OrderStatus.pending || order.status == OrderStatus.confirmed)
                  .toList();
              final dispatchedOrders = orderModel.orders
                  .where((order) => order.status == OrderStatus.dispatched)
                  .toList();
              final deliveredOrders = orderModel.orders
                  .where((order) => order.status == OrderStatus.delivered)
                  .toList();
              final cancelledOrders = orderModel.orders
                  .where((order) => order.status == OrderStatus.cancelled)
                  .toList();

              return Column( // Wrap TabBar and TabBarView in a Column
                children: [
                  Material( // Wrap TabBar in Material to give it a background color
                    color: tabBackgroundColor, // Apply theme color
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: tabLabelColor, // Apply theme color
                      labelColor: tabLabelColor, // Apply theme color
                      unselectedLabelColor: tabUnselectedLabelColor, // Apply theme color
                      labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      unselectedLabelStyle: GoogleFonts.poppins(),
                      tabs: const [
                        Tab(text: 'Booked'),
                        Tab(text: 'Dispatched'),
                        Tab(text: 'Delivered'),
                        Tab(text: 'Cancelled'),
                      ],
                    ),
                  ),
                  Expanded( // TabBarView should take the remaining space
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOrderList(bookedOrders, orderModel, isDarkMode), // Pass isDarkMode
                        _buildOrderList(dispatchedOrders, orderModel, isDarkMode), // Pass isDarkMode
                        _buildOrderList(deliveredOrders, orderModel, isDarkMode), // Pass isDarkMode
                        _buildOrderList(cancelledOrders, orderModel, isDarkMode), // Pass isDarkMode
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOrderList(List<Order> orders, OrderModel orderModel, bool isDarkMode) {
    final Color infoIconColor = isDarkMode ? Colors.grey[600]! : Colors.grey[400]!;
    final Color infoTextColor = isDarkMode ? Colors.grey[300]! : Colors.grey[600]!;

    if (orders.isEmpty) {
      return Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 80,
                  color: infoIconColor, // Apply theme color
                ),
                const SizedBox(height: 20),
                Text(
                  'No orders in this category yet!',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: infoTextColor, // Apply theme color
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Once you place orders, they will appear here.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: infoTextColor, // Apply theme color

                  )
                  ,
                ),
              ])
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return OrderCard(order: order, orderModel: orderModel, isDarkMode: isDarkMode); // Pass isDarkMode
      },
    );
  }

  // Re-added _buildHeader
  Widget _buildHeader() {
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    final Color headerTextColor = isDarkMode ? Colors.white : Colors.black;
    final Color headerDividerColor = isDarkMode ? Colors.grey[700]! : Colors.black;
    final Color dottedBorderColor = isDarkMode ? Colors.red.shade300 : Colors.red;
    final Color buttonBackgroundColor = const Color(0xffEB7720); // Button remains orange
    final Color buttonTextColor = Colors.white70; // Button text remains white70

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              DottedBorder(
                borderType: BorderType.Circle,
                color: dottedBorderColor, // Apply theme color
                strokeWidth: 2,
                dashPattern: const [6, 3],
                child: Container(
                  padding: const EdgeInsets.all(6),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: Consumer<KycImageProvider>(
                      builder: (context, kycImageProvider, child) {
                        final Uint8List? kycImageBytes = kycImageProvider.kycImageBytes;
                        return kycImageBytes != null
                            ? Image.memory(
                          kycImageBytes,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        )
                            : Image.asset(
                          'assets/profile.png',
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          // Removed color property
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Text(
                "Hi Smart!\n9876543210",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: headerTextColor, // Apply theme color
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.only(left: 0),
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to MembershipDetailsScreen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonBackgroundColor, // Always orange
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Not A Member Yet",
                      style: GoogleFonts.poppins(
                        color: buttonTextColor, // Always white70
                        fontSize: 10,
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_outlined,
                      color: Colors.white70,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Divider(height: 30, thickness: 1, color: headerDividerColor), // Apply theme color
        ],
      ),
    );
  }

  // Re-added _buildMenuItem
  Widget _buildMenuItem(IconData icon, String label) {
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    final Color drawerContainerColor = isDarkMode ? Colors.grey[850]! : const Color(0xffffecdc);
    final Color iconColor = const Color(0xffEB7720); // Icon remains orange
    final Color textColor = isDarkMode ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        height: 40,
        decoration: BoxDecoration(color: drawerContainerColor), // Apply theme color
        child: ListTile(
          leading: Icon(icon, color: iconColor), // Always orange
          title: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: textColor, // Apply theme color
            ),
          ),
          onTap: () {
            Navigator.pop(context);

            switch (label) {
              case 'My Account':
                Navigator.push(context, MaterialPageRoute(builder: (context) => const MyAccountPage()));
                break;
              case 'Transaction History':
                Navigator.push(context, MaterialPageRoute(builder: (context) => TransactionHistoryPage()));
                break;
              case 'Ask Us!':
                Navigator.push(context, MaterialPageRoute(builder: (context) => AskUsPage()));
                break;
              case 'Rate Us':
                showComplaintDialog(context);
                break;
              case 'Settings':
                Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage()));
                break;
              case 'Logout':
                _showLogoutDialog(context);
                break;
              case 'About Us':
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('About Us page coming soon!')),
                );
                break;
              case 'Share Kisangro':
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share functionality coming soon!')),
                );
                break;
              case 'Wishlist':
                Navigator.push(context, MaterialPageRoute(builder: (context) => const WishlistPage()));
                break;
            }
          },
        ),
      ),
    );
  }

  // This _buildProductTile is specifically for similar and top-selling products in MyOrder screen
  Widget _buildProductTile(BuildContext context, Product product, bool isDarkMode) {
    final themeOrange = const Color(0xffEB7720);
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
            : [ProductSize(proId: 0, size: 'Unit', price: 0.0, sellingPrice: 0.0)]; // FIX 1: Add proId to fallback

        // Resolve the selected unit for the dropdown
        ProductSize currentSelectedUnit = effectiveAvailableSizes.firstWhere(
              (sizeOption) => sizeOption.proId == product.selectedUnit.proId,
          orElse: () => effectiveAvailableSizes.first,
        );

        final double? currentMrp = product.pricePerSelectedUnit;
        final double? currentSellingPrice = product.sellingPricePerSelectedUnit;

        return Container(
          width: 150, // Fixed width for horizontal list items
          decoration: BoxDecoration(
            color: cardBackgroundColor, // Apply theme color
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor), // Apply theme color
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 100,
                width: double.infinity,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
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
                      // Removed color property
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: textColor), // Apply theme color
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      product.subtitle,
                      style: GoogleFonts.poppins(fontSize: 12, color: textColor), // Apply theme color
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Text(
                          '₹ ${currentMrp?.toStringAsFixed(2) ?? 'N/A'}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
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
                              style: GoogleFonts.poppins(fontSize: 14, color: Colors.green, fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                    Text('Unit: ${currentSelectedUnit.size}', // FIX 2: Use .size property
                        style: GoogleFonts.poppins(fontSize: 10, color: themeOrange)),
                    const SizedBox(height: 8),
                    Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: themeOrange),
                        borderRadius: BorderRadius.circular(6),
                        color: isDarkMode ? Colors.grey[800] : Colors.white, // Apply theme color
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>( // FIX 2: Change type to int (proId)
                          value: currentSelectedUnit.proId, // FIX 2: Use proId as value
                          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xffEB7720), size: 20),
                          underline: const SizedBox(),
                          isExpanded: true,
                          style: GoogleFonts.poppins(fontSize: 12, color: textColor), // Apply theme color
                          items: effectiveAvailableSizes
                              .map(
                                (sizeOption) => DropdownMenuItem<int>( // FIX 2: Change type to int
                              value: sizeOption.proId, // FIX 2: Use proId as value
                              child: Text(sizeOption.size),
                            ),
                          )
                              .toList(),
                          onChanged: (int? newProId) { // FIX 3: newProId is now int
                            if (newProId != null) {
                              final selectedSize = effectiveAvailableSizes.firstWhere((s) => s.proId == newProId);
                              product.selectedUnit = selectedSize; // FIX 3: Set the entire ProductSize object
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Provider.of<CartModel>(context, listen: false).addItem(product.copyWith());
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${product.title} added to cart!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeOrange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: Text("Add", style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
                          ),
                        ),
                        Consumer<WishlistModel>(
                          builder: (context, wishlist, child) {
                            final isFavorite = wishlist.containsItem(product.selectedUnit.proId);
                            return IconButton(
                              onPressed: () async {
                                final result = await wishlist.toggleItem(product);
                                if (result != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        result
                                            ? '${product.title} added to wishlist!'
                                            : '${product.title} removed from wishlist!',
                                      ),
                                      backgroundColor: result ? Colors.blue : Colors.red,
                                    ),
                                  );
                                }
                              },
                              icon: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: themeOrange,  // Changed from orangeColor to themeOrange
                              ),
                            );
                          },
                        )
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
}

class OrderCard extends StatelessWidget {
  final Order order;
  final OrderModel orderModel;
  final bool isDarkMode; // New parameter

  const OrderCard({Key? key, required this.order, required this.orderModel, required this.isDarkMode}) : super(key: key);

  // Helper method to determine if a URL is valid for network image or if it's a local asset
  String _getEffectiveImageUrlForOrderCard(String rawImageUrl) {
    if (rawImageUrl.isEmpty ||
        rawImageUrl == 'https://sgserp.in/erp/api/' || // Specific API placeholder
        (Uri.tryParse(rawImageUrl)?.isAbsolute != true && !rawImageUrl.startsWith('assets/'))) {
      return ProductService.getRandomValidImageUrl(); // Use a random valid API image or local placeholder
    }
    return rawImageUrl;
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (order.status) {
      case OrderStatus.pending:
      case OrderStatus.booked:
      case OrderStatus.confirmed:
        statusColor = Colors.blue;
        break;
      case OrderStatus.dispatched:
        statusColor = Colors.orange;
        break;
      case OrderStatus.delivered:
        statusColor = Colors.green;
        break;
      case OrderStatus.cancelled:
        statusColor = Colors.red;
        break;
      default: // Added default case to ensure statusColor is always initialized
        statusColor = Colors.grey;
        break;
    }

    // Determine button visibility based on order status
    bool showCancelButton = (order.status == OrderStatus.booked || order.status == OrderStatus.pending || order.status == OrderStatus.confirmed);
    bool showModifyOrderButton = (order.status == OrderStatus.booked || order.status == OrderStatus.pending || order.status == OrderStatus.confirmed);
    bool showTrackOrderButton = (order.status == OrderStatus.dispatched); // Only for dispatched
    bool showRateProductButton = order.status == OrderStatus.delivered;
    bool showInvoiceButton = (order.status == OrderStatus.delivered); // Only for delivered orders
    bool showBrowseMoreButton = order.status == OrderStatus.delivered || order.status == OrderStatus.cancelled;

    // Define colors based on theme
    final Color cardBackgroundColor = isDarkMode ? Colors.grey[850]! : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color greyTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final Color dividerColor = isDarkMode ? Colors.grey[700]! : Colors.grey;
    final Color orangeColor = const Color(0xffEB7720); // Orange color, remains constant
    final Color imageBackgroundColor = isDarkMode ? Colors.grey[900]! : Colors.grey[200]!;


    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: cardBackgroundColor, // Apply theme color
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order ID: ${order.id}',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: textColor), // Apply theme color
                ),
                // Conditionally display the status box based on order status
                // This is a single widget (Container) so it can be directly in the Row's children list.
                if (!(order.status == OrderStatus.booked || order.status == OrderStatus.pending || order.status == OrderStatus.confirmed || order.status == OrderStatus.cancelled))
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      order.status.name.toUpperCase(),
                      style: GoogleFonts.poppins(color: statusColor, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Order Date: ${DateFormat('dd MMMyyyy, hh:mm a').format(order.orderDate)}',
              style: GoogleFonts.poppins(color: greyTextColor), // Apply theme color
            ),
            // This is a single widget (Padding) so it can be directly in the Column's children list.
            if (order.status == OrderStatus.delivered && order.deliveredDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Delivered On: ${DateFormat('dd MMMyyyy').format(order.deliveredDate!)}',
                  style: GoogleFonts.poppins(color: Colors.green, fontWeight: FontWeight.w500),
                ),
              ),
            Divider(height: 20, thickness: 1, color: dividerColor), // Apply theme color
            // The entire ListView.builder for products is now wrapped in a GestureDetector
            // to navigate to MultiProductOrderDetailPage for the whole order.
            // This is a single widget (GestureDetector) so it can be directly in the Column's children list.
            GestureDetector(
              onTap: () {
                // Navigate to MultiProductOrderDetailPage with the entire order object
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MultiProductOrderDetailPage(order: order),
                  ),
                );
              },
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: order.products.length,
                itemBuilder: (context, idx) {
                  final orderedProduct = order.products[idx];
                  // Determine the effective image URL using the helper
                  final String effectiveImageUrl = _getEffectiveImageUrlForOrderCard(orderedProduct.imageUrl);
                  final bool isNetworkImage = effectiveImageUrl.startsWith('http');

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: imageBackgroundColor, // Apply theme color
                          ),
                          child: isNetworkImage
                              ? Image.network(
                            effectiveImageUrl,
                            fit: BoxFit.contain, // Use contain for product images
                            errorBuilder: (context, error, stackTrace) => Image.asset(
                              'assets/placeholder.png', // Fallback to local placeholder if network image fails
                              fit: BoxFit.contain,
                            ),
                          )
                              : Image.asset(
                            effectiveImageUrl, // This will be 'assets/placeholder.png' if original was bad
                            fit: BoxFit.contain,
                            // Removed color property
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                orderedProduct.title,
                                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor), // Apply theme color
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                orderedProduct.description,
                                style: GoogleFonts.poppins(fontSize: 12, color: greyTextColor), // Apply theme color
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${orderedProduct.unit} x ${orderedProduct.quantity}',
                                style: GoogleFonts.poppins(fontSize: 12, color: textColor), // Apply theme color
                              ),
                              Text(
                                '₹${orderedProduct.price.toStringAsFixed(2)}',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold, color: orangeColor), // Always orange
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Divider(height: 20, thickness: 1, color: dividerColor), // Apply theme color
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount:',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor), // Apply theme color
                ),
                Text(
                  '₹${order.totalAmount.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.bold, color: orangeColor), // Always orange
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Row for Cancel and Modify (only for booked/pending/confirmed)
            // This entire block is conditionally rendered by the outer 'if'
            // The Column widget ensures that both the Row and the SizedBox are treated as a single child
            // within the parent Column's children list.
            if (showCancelButton || showModifyOrderButton)
              Column(
                children: [
                  Row(
                    children: [
                      // In myorder.dart, in the OrderCard widget, modify the cancel button part:
                      // In the OrderCard widget in myorder.dart, update the cancel button onPressed handler
                      if (showCancelButton)
                        if (showCancelButton)
                          Expanded(
                            child: SizedBox(
                              height: 40,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  // Navigate to CancellationStep1Page instead of direct cancellation
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CancellationStep1Page(
                                        orderId: order.id,
                                        onCancelConfirmed: () {
                                          // This callback will be executed when cancellation is confirmed
                                          // in CancellationStep2Page after bank details are submitted
                                          debugPrint('Order ${order.id} cancellation confirmed via callback');
                                        },
                                      ),
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.red),
                                ),
                                icon: Icon(Icons.cancel_outlined, color: Colors.red, size: 16),
                                label: Text(
                                  'Cancel',
                                  style: GoogleFonts.poppins(color: Colors.red),
                                ),
                              ),
                            ),
                          ),
                      // Conditional spacing between buttons
                      if (showCancelButton && showModifyOrderButton)
                        const SizedBox(width: 12),
                      if (showModifyOrderButton)
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            // MODIFIED: Changed to ElevatedButton for filled highlight
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // MODIFIED: Call the new method to ADD products to cart
                                Provider.of<CartModel>(context, listen: false).addProductsFromOrder(order.products);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const Cart()),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Order ${order.id} loaded to cart for modification!', style: GoogleFonts.poppins())),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                // MODIFIED: Darker orange color for fill
                                backgroundColor: const Color(0xFFE65100), // Always darker orange
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                              ),
                              icon: const Icon(Icons.edit, color: Colors.white, size: 16), // Icon color to white for better contrast
                              label: Text(
                                'Modify',
                                style: GoogleFonts.poppins(color: Colors.white), // Text color to white for better contrast
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  // Conditional spacing after this row of buttons, if other button rows follow
                  if (showTrackOrderButton || showRateProductButton || showBrowseMoreButton)
                    const SizedBox(height: 12),
                ],
              ),

            // Row for Track Order (only for dispatched)
            // This entire block is conditionally rendered by the outer 'if'
            // The Column widget ensures that both the Row and the SizedBox are treated as a single child
            // within the parent Column's children list.
            if (showTrackOrderButton)
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Tracking order ${order.id}!', style: GoogleFonts.poppins())),
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const DispatchedOrdersScreen()),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              // MODIFIED: Darker orange color for outline
                              side: const BorderSide(color: Color(0xFFE65100)), // Always darker orange
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                            ),
                            icon: const Icon(Icons.delivery_dining, color: Color(0xffEB7720), size: 16), // Always orange
                            label: Text(
                              'Track Order',
                              style: GoogleFonts.poppins(color: const Color(0xffEB7720)), // Always orange
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Conditional spacing after this row of buttons, if other button rows follow
                  if (showRateProductButton || showBrowseMoreButton)
                    const SizedBox(height: 12),
                ],
              ),


            // Row for Rate Product and Browse More / Invoice (for delivered and cancelled)
            // This entire block is conditionally rendered by the outer 'if'
            // The Column widget ensures that the Row is treated as a single child
            // within the parent Column's children list.
            if (showRateProductButton || showBrowseMoreButton)
              Column(
                children: [
                  Row(
                    children: [
                      if (showInvoiceButton) // Only show Invoice button for delivered orders
                        SizedBox(
                          height: 40,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Generating invoice for order ${order.id}!', style: GoogleFonts.poppins())),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              // MODIFIED: Darker orange color for outline
                              side: const BorderSide(color: Color(0xFFE65100)), // Always darker orange
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                            ),
                            icon: const Icon(Icons.file_download_sharp, color: Color(0xffEB7720), size: 16), // Always orange
                            label: Text(
                              'Invoice',
                              style: GoogleFonts.poppins(color: const Color(0xffEB7720)), // Always orange
                            ),
                          ),
                        ),
                      // Conditional spacing between buttons
                      if (showInvoiceButton && showBrowseMoreButton)
                        const SizedBox(width: 12),
                      if (showRateProductButton)
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // You would typically navigate to a rating screen or show a dialog here
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Rating product for order ${order.id}!', style: GoogleFonts.poppins())),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                // MODIFIED: Darker orange color for fill
                                backgroundColor: const Color(0xFFE65100), // Always darker orange
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                              ),
                              icon: const Icon(Icons.star, color: Colors.white, size: 16),
                              label: Text(
                                'Rate Product',
                                style: GoogleFonts.poppins(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      // Conditional spacing between buttons
                      if (showRateProductButton && showBrowseMoreButton && order.status != OrderStatus.cancelled)
                        const SizedBox(width: 12),
                      if (showBrowseMoreButton) // Only show "Browse More" if needed for delivered or cancelled
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: ElevatedButton(
                              onPressed: () {
                                // Navigate to TrendingProductsScreen on homepage.dart
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const TrendingProductsScreen()),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Browsing more products!', style: GoogleFonts.poppins())),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                // MODIFIED: Darker orange color for fill
                                backgroundColor: const Color(0xFFE65100), // Darker orange
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                padding: const EdgeInsets.symmetric(vertical: 5),
                              ),
                              child: Text('Browse More', style: GoogleFonts.poppins(color: Colors.white)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
