import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisangro/home/theme_mode_provider.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

// Model class for Dispatched Order
class DispatchedOrder {
  final String id;
  final String orderId;
  final String customerId;
  final String totalQty;
  final String totalAmount;
  final String status;
  final String statusText;
  final String productName;
  final String productId;
  final String productImage;
  final String dispatchDate;
  final String dtime;

  DispatchedOrder({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.totalQty,
    required this.totalAmount,
    required this.status,
    required this.statusText,
    required this.productName,
    required this.productId,
    required this.productImage,
    required this.dispatchDate,
    required this.dtime,
  });

  factory DispatchedOrder.fromJson(Map<String, dynamic> json) {
    return DispatchedOrder(
      id: json['id']?.toString() ?? '',
      orderId: json['order_id']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      totalQty: json['total_qty']?.toString() ?? '0',
      totalAmount: json['total_amount']?.toString() ?? '0',
      status: json['status']?.toString() ?? '',
      statusText: json['status_text']?.toString() ?? 'Dispatch',
      productName: json['product_name']?.toString() ?? 'Product',
      productId: json['product_id']?.toString() ?? '',
      productImage: json['product_image']?.toString() ?? '',
      dispatchDate: json['dispatch_date']?.toString() ?? '',
      dtime: json['dtime']?.toString() ?? '',
    );
  }
}

// Provider for Dispatched Orders
class DispatchedOrderProvider extends ChangeNotifier {
  List<DispatchedOrder> _dispatchedOrders = [];
  bool _isLoading = false;
  String? _error;

  List<DispatchedOrder> get dispatchedOrders => _dispatchedOrders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchDispatchedOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get customer ID
      String? customerId = prefs.getInt('cus_id')?.toString() ?? 
                          prefs.getString('cus_id') ?? 
                          '26'; // Default fallback

      // Get location and device data
      double? latitude = prefs.getDouble('latitude') ?? 123.0;
      double? longitude = prefs.getDouble('longitude') ?? 145.0;
      String? deviceId = prefs.getString('device_id') ?? '1';

      // Prepare API parameters
      final Map<String, String> params = {
        'cid': '85788578',
        'type': '1036', // Using type 1036 for dispatched orders
        'cus_id': customerId,
        'lt': latitude.toString(),
        'ln': longitude.toString(),
        'device_id': deviceId,
      };

      debugPrint('📦 Fetching dispatched orders with params: $params');

      // Make API call
      final response = await http.post(
        Uri.parse('https://erpsmart.in/total/api/m_api/'),
        body: params,
      ).timeout(const Duration(seconds: 15));

      debugPrint('📦 Response status: ${response.statusCode}');
      debugPrint('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['error'] == false) {
          final data = responseData['data'] as List? ?? [];
          
          _dispatchedOrders = data.map((item) => 
            DispatchedOrder.fromJson(item)
          ).toList();
          
          debugPrint('📦 Loaded ${_dispatchedOrders.length} dispatched orders');
        } else {
          _error = responseData['message'] ?? 'Failed to load dispatched orders';
        }
      } else {
        _error = 'Server error: ${response.statusCode}';
      }
    } catch (e) {
      debugPrint('📦 Error fetching dispatched orders: $e');
      _error = 'Network error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

class DispatchedOrdersScreen extends StatelessWidget {
  const DispatchedOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    // Define colors based on theme
    final Color gradientStartColor = isDarkMode ? Colors.black : const Color(0xffFFD9BD);
    final Color gradientEndColor = isDarkMode ? Colors.black : const Color(0xffFFFFFF);
    final Color iconColor = const Color(0xffEB7720);
    final Color titleColor = isDarkMode ? Colors.white : Colors.black87;
    final Color subtitleColor = isDarkMode ? Colors.grey[400]! : Colors.grey[700]!;
    final Color buttonBackgroundColor = const Color(0xffEB7720);
    final Color buttonTextColor = Colors.white;
    final Color cardBackgroundColor = isDarkMode ? Colors.grey[850]! : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color greyTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final Color borderColor = isDarkMode ? Colors.grey[700]! : Colors.grey.shade300;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xffEB7720),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Dispatched Orders",
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 18),
        ),
        centerTitle: false,
        titleSpacing: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              Provider.of<DispatchedOrderProvider>(context, listen: false)
                  .fetchDispatchedOrders();
            },
          ),
        ],
      ),
      body: ChangeNotifierProvider(
        create: (_) => DispatchedOrderProvider()..fetchDispatchedOrders(),
        child: Consumer<DispatchedOrderProvider>(
          builder: (context, provider, child) {
            return Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [gradientStartColor, gradientEndColor],
                ),
              ),
              child: provider.isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Loading dispatched orders...",
                            style: GoogleFonts.poppins(color: textColor),
                          ),
                        ],
                      ),
                    )
                  : provider.error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 80,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                provider.error!,
                                style: GoogleFonts.poppins(
                                  color: subtitleColor,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () {
                                  provider.fetchDispatchedOrders();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: buttonBackgroundColor,
                                ),
                                child: Text(
                                  "Retry",
                                  style: GoogleFonts.poppins(color: buttonTextColor),
                                ),
                              ),
                            ],
                          ),
                        )
                      : provider.dispatchedOrders.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.local_shipping,
                                    size: 80,
                                    color: iconColor,
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    "No dispatched orders found!",
                                    style: GoogleFonts.poppins(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: titleColor,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    "When your orders are dispatched, they will appear here.",
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: subtitleColor,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: provider.dispatchedOrders.length,
                              itemBuilder: (context, index) {
                                final order = provider.dispatchedOrders[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildOrderCard(context, order, isDarkMode),
                                );
                              },
                            ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, DispatchedOrder order, bool isDarkMode) {
    final Color cardBackgroundColor = isDarkMode ? Colors.grey[850]! : Colors.blue.shade50;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color greyTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final Color orangeColor = const Color(0xffEB7720);
    final Color borderColor = isDarkMode ? Colors.grey[700]! : Colors.grey.shade300;

    // Format date
    String formattedDate = '';
    try {
      if (order.dtime.isNotEmpty) {
        final dateTime = DateTime.parse(order.dtime.replaceAll(' ', 'T'));
        formattedDate = DateFormat('dd/MM/yyyy hh:mm a').format(dateTime);
      }
    } catch (e) {
      formattedDate = order.dtime;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 0.5),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[900]! : Colors.grey[200]!,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: order.productImage.isNotEmpty
                      ? Image.network(
                          order.productImage,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/placeholder.png',
                              fit: BoxFit.contain,
                            );
                          },
                        )
                      : Image.asset(
                          'assets/placeholder.png',
                          fit: BoxFit.contain,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.productName,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Order ID: ${order.orderId}",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: greyTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Quantity: ${order.totalQty}",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Total: ₹${double.parse(order.totalAmount).toStringAsFixed(2)}",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: orangeColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: orangeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: orangeColor),
                  ),
                  child: Text(
                    order.statusText,
                    style: GoogleFonts.poppins(
                      color: orangeColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                if (formattedDate.isNotEmpty)
                  Text(
                    formattedDate,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: greyTextColor,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to tracking details or show tracking info
                  _showTrackingDialog(context, order, isDarkMode);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: orangeColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "Track Order",
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTrackingDialog(BuildContext context, DispatchedOrder order, bool isDarkMode) {
    final Color dialogBackgroundColor = isDarkMode ? Colors.grey[900]! : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color orangeColor = const Color(0xffEB7720);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: dialogBackgroundColor,
        title: Text(
          "Track Order",
          style: GoogleFonts.poppins(color: orangeColor, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Order ID: ${order.orderId}",
              style: GoogleFonts.poppins(color: textColor),
            ),
            const SizedBox(height: 8),
            Text(
              "Product: ${order.productName}",
              style: GoogleFonts.poppins(color: textColor),
            ),
            const SizedBox(height: 8),
            Text(
              "Status: ${order.statusText}",
              style: GoogleFonts.poppins(color: orangeColor, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              "Dispatched on: ${order.dtime}",
              style: GoogleFonts.poppins(color: textColor),
            ),
            const SizedBox(height: 16),
            const LinearProgressIndicator(
              value: 0.6,
              backgroundColor: Colors.grey,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xffEB7720)),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Order Placed", style: GoogleFonts.poppins(fontSize: 10, color: textColor)),
                Text("Dispatched", style: GoogleFonts.poppins(fontSize: 10, color: orangeColor, fontWeight: FontWeight.bold)),
                Text("Out for Delivery", style: GoogleFonts.poppins(fontSize: 10, color: textColor)),
                Text("Delivered", style: GoogleFonts.poppins(fontSize: 10, color: textColor)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Close",
              style: GoogleFonts.poppins(color: orangeColor),
            ),
          ),
        ],
      ),
    );
  }
}