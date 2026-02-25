import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisangro/home/theme_mode_provider.dart';
import 'package:provider/provider.dart';
import 'package:kisangro/models/order_model.dart';
import "cancel1.dart";
import 'package:shared_preferences/shared_preferences.dart';

class BookedOrdersScreen extends StatelessWidget {
  final String? orderId;

  const BookedOrdersScreen({super.key, this.orderId});

  // Method to force reload orders from API
  Future<void> _reloadOrders(OrderModel orderModel) async {
    debugPrint('🔄 Forcing reload of orders from API');
    await orderModel.forceReloadFromApi();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    debugPrint('🎨 Building BookedOrdersScreen, isDarkMode: $isDarkMode');

    // Define colors based on theme
    final Color backgroundColor = isDarkMode ? Colors.black : const Color(0xFFFDF1E6);
    final Color appBarColor = const Color(0xFFF37021);
    final Color containerColor = isDarkMode ? Colors.grey[900]! : const Color(0xFFFCD8BD);
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color boldTextColor = isDarkMode ? Colors.white : Colors.black;
    final Color noteTextColor = isDarkMode ? Colors.white70 : Colors.black;
    final Color dividerColor = isDarkMode ? Colors.grey[700]! : Colors.grey;
    final Color cardBackgroundColor = isDarkMode ? Colors.grey[850]! : Colors.white;
    final Color cardShadowColor = isDarkMode ? Colors.transparent : Colors.grey.withOpacity(0.2);
    final Color itemBorderColor = isDarkMode ? Colors.grey[600]! : Colors.black;
    final Color orangeColor = const Color(0xffEB7720);
    final Color redButtonBorderColor = isDarkMode ? Colors.red.shade300 : Colors.red;
    final Color orangeButtonBorderColor = isDarkMode ? orangeColor : const Color(0xFFFF8C2F);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            debugPrint('⬅️ Back button pressed');
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Booked Orders',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        actions: [
          // Add reload button for debugging
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              final orderModel = Provider.of<OrderModel>(context, listen: false);
              _reloadOrders(orderModel);
            },
          ),
        ],
      ),
      body: Consumer<OrderModel>(
        builder: (context, orderModel, child) {
          // Get booked orders from OrderModel
          final bookedOrders = orderModel.getOrdersByStatus(OrderStatus.booked);
          
          debugPrint('📊 Found ${bookedOrders.length} booked orders from OrderModel');

          if (orderModel.orders.isEmpty) {
            // Show loading or empty state while orders are being fetched
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(appBarColor),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Loading orders...',
                    style: GoogleFonts.poppins(color: textColor),
                  ),
                ],
              ),
            );
          }

          if (bookedOrders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 80,
                    color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No booked orders found!',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Pull down to refresh',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey[500] : Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          // Find the specific order by ID if provided, otherwise use the first booked order
          Order order;
          if (orderId != null) {
            try {
              order = bookedOrders.firstWhere(
                (o) => o.id == orderId,
              );
              debugPrint('✅ Found specific order with ID: $orderId');
            } catch (e) {
              debugPrint('⚠️ Order ID not found, using first order');
              order = bookedOrders.first;
            }
          } else {
            order = bookedOrders.first;
            debugPrint('📦 Using first order: ${order.id}');
          }

          return RefreshIndicator(
            onRefresh: () => _reloadOrders(orderModel),
            color: appBarColor,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    color: containerColor,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                  text: 'Note: You can cancel or modify your order within ',
                                  style: GoogleFonts.poppins(color: noteTextColor)),
                              TextSpan(
                                  text: '2 hour ',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: boldTextColor)),
                              TextSpan(
                                  text: 'from the time you booked.',
                                  style: GoogleFonts.poppins(color: noteTextColor)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text('Delivery Address:', style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: textColor)),
                        const SizedBox(height: 4),
                        Text('Smart (name)', style: GoogleFonts.poppins(color: textColor)),
                        Text('D/no: 123, abc street, rrr nagar, near ppp, Coimbatore.', style: GoogleFonts.poppins(color: textColor)),
                        Text('Pin-code: 641612', style: GoogleFonts.poppins(color: textColor)),
                        const SizedBox(height: 10),
                        Text('Expected Delivery: 20 Apr 2024', style: GoogleFonts.poppins(color: textColor)),
                      ],
                    ),
                  ),
                  Divider(color: dividerColor),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: itemBorderColor),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('${order.products.length} Items', style: GoogleFonts.poppins(color: textColor)),
                        ),
                        const Spacer(),
                        Text('Ordered On: ${order.orderDate.day.toString().padLeft(2, '0')}/${order.orderDate.month.toString().padLeft(2, '0')}/${order.orderDate.year}',
                            style: GoogleFonts.poppins(fontSize: 13, color: textColor)),
                      ],
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: order.products.length,
                    itemBuilder: (context, index) {
                      final product = order.products[index];
                      debugPrint('🖼️ Product $index: ${product.title}');
                      
                      return Column(
                        children: [
                          Stack(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 100,
                                    height: 120,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: cardBackgroundColor,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: cardShadowColor,
                                          blurRadius: 4,
                                          offset: const Offset(2, 2),
                                        ),
                                      ],
                                    ),
                                    child: product.imageUrl.isNotEmpty && product.imageUrl.startsWith('http')
                                        ? Image.network(
                                      product.imageUrl,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        debugPrint('❌ Image error for ${product.title}: $error');
                                        return Image.asset(
                                          'assets/oxyfen.png',
                                          fit: BoxFit.contain,
                                          color: isDarkMode ? Colors.white70 : null,
                                        );
                                      },
                                    )
                                        : Image.asset(
                                      'assets/oxyfen.png',
                                      fit: BoxFit.contain,
                                      color: isDarkMode ? Colors.white70 : null,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(product.title, 
                                             style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                                        Text(product.description, 
                                             style: GoogleFonts.poppins(color: textColor)),
                                        const SizedBox(height: 4),
                                        Text('Unit Size: ${product.unit}', 
                                             style: GoogleFonts.poppins(fontSize: 13, color: textColor)),
                                        const SizedBox(height: 4),
                                        Text('₹ ${product.price.toStringAsFixed(2)}/piece', 
                                             style: GoogleFonts.poppins(color: orangeColor, fontSize: 14)),
                                        const SizedBox(height: 4),
                                        Text('Ordered Units: ${product.quantity.toString().padLeft(2, '0')}', 
                                             style: GoogleFonts.poppins(fontSize: 13, color: textColor)),
                                        Text('Total Cost: ₹ ${(product.price * product.quantity).toStringAsFixed(2)}', 
                                             style: GoogleFonts.poppins(fontSize: 13, color: orangeColor)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Column(
                                  children: [
                                    Icon(Icons.arrow_forward_ios, size: 16, color: textColor),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: appBarColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(product.unit, 
                                           style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Order ID: ${order.id}', 
                                       style: GoogleFonts.poppins(fontSize: 12, color: textColor)),
                          ),
                          Divider(thickness: 1, color: dividerColor),
                        ],
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              debugPrint('❌ Cancel button pressed for order: ${order.id}');
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => CancellationStep1Page(orderId: order.id)),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: redButtonBorderColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text('Cancel Order', 
                                       style: GoogleFonts.poppins(color: redButtonBorderColor)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              debugPrint('✏️ Modify button pressed');
                              // Add modify functionality here
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
                              side: BorderSide(color: orangeButtonBorderColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text('Modify Order', 
                                       style: GoogleFonts.poppins(color: orangeButtonBorderColor)),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}