import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kisangro/home/theme_mode_provider.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'package:kisangro/home/product.dart';

import 'package:kisangro/models/order_model.dart';
import 'package:kisangro/models/product_model.dart'; // Ensure Product model is imported
import 'package:kisangro/services/product_service.dart'; // Import ProductService for image fallback

import 'orders_product_detail_page.dart'; // Import the new OrdersProductDetailPage

class MultiProductOrderDetailPage extends StatelessWidget {
  final Order order;

  const MultiProductOrderDetailPage({Key? key, required this.order}) : super(key: key);

  // Helper to check if the image URL is valid (not an asset path or empty)
  bool _isValidUrl(String? url) {
    if (url == null || url.isEmpty) {
      return false;
    }
    return Uri.tryParse(url)?.isAbsolute == true && !url.endsWith('erp/api/');
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy h:mm a');
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    // Define colors based on theme
    final Color gradientStartColor = isDarkMode ? Colors.black : const Color(0xffFFD9BD);
    final Color gradientEndColor = isDarkMode ? Colors.black : const Color(0xffFFFFFF);
    final Color cardBackgroundColor = isDarkMode ? Colors.grey[850]! : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;
    final Color subtitleColor = isDarkMode ? Colors.white70 : Colors.grey[600]!;
    final Color orangeColor = const Color(0xffEB7720); // Orange color, remains constant
    final Color dividerColor = isDarkMode ? Colors.grey[700]! : Colors.grey;
    final Color imageBackgroundColor = isDarkMode ? Colors.grey[900]! : Colors.grey[200]!;


    return Scaffold(
      appBar: AppBar(
        backgroundColor: orangeColor,
        elevation: 0,
        title: Text(
          "Order Details (ID: ${order.id})",
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
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
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.only(bottom: 16.0),
              color: cardBackgroundColor, // Apply theme color
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order Summary', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: orangeColor)), // Always orange
                    Divider(color: dividerColor), // Apply theme color
                    _buildDetailRow('Order ID:', order.id, isDarkMode), // Pass isDarkMode
                    //_buildDetailRow('Order Date:', dateFormat.format(order.orderDate), isDarkMode), // Pass isDarkMode
                    _buildDetailRow('Total Amount:', '₹${order.totalAmount.toStringAsFixed(2)}', isDarkMode), // Pass isDarkMode
                    _buildDetailRow('Status:', order.status.name.toUpperCase(), isDarkMode), // Pass isDarkMode
                    // if (order.deliveredDate != null)
                    //   _buildDetailRow('Delivered On:', dateFormat.format(order.deliveredDate!), isDarkMode), // Pass isDarkMode
                  ],
                ),
              ),
            ),
            Text('Products in this Order', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)), // Apply theme color
            const SizedBox(height: 10),
            ...order.products.map((orderedProduct) {
              // FIX 1: Parse proId from orderedProduct.id
              final int proId = int.tryParse(orderedProduct.id) ?? 0;

              // Convert OrderedProduct to Product for OrdersProductDetailPage
              final productForDetailPage = Product(
                mainProductId: orderedProduct.id, // Use orderedProduct.id as mainProductId
                title: orderedProduct.title,
                subtitle: orderedProduct.description,
                imageUrl: orderedProduct.imageUrl,
                category: orderedProduct.category,
                // For availableSizes, create a list with just the ordered unit/price
                availableSizes: [
                  ProductSize(
                    proId: proId, // FIX 1: Pass proId to ProductSize
                    size: orderedProduct.unit,
                    price: orderedProduct.price,
                  ),
                ],
                initialSelectedUnitProId: proId, // Set initialSelectedUnitProId
              );

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailPage(product: productForDetailPage),
                    ),
                  );
                },
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  color: cardBackgroundColor, // Apply theme color
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: imageBackgroundColor, // Apply theme color
                            ),
                            child: _isValidUrl(orderedProduct.imageUrl)
                                ? Image.network(
                              orderedProduct.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stacktrace) {
                                debugPrint("Error loading image: ${orderedProduct.imageUrl}");
                                return Center(child: Icon(Icons.broken_image, color: isDarkMode ? Colors.grey[400] : Colors.grey[400])); // Apply theme color
                              },
                            )
                                : Image.asset(
                              ProductService.getRandomValidImageUrl(), // Fallback to a random valid API image
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stacktrace) {
                                return Center(child: Icon(Icons.broken_image, color: isDarkMode ? Colors.grey[400] : Colors.grey[400])); // Apply theme color
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                orderedProduct.title,
                                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: textColor), // Apply theme color
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                orderedProduct.description,
                                style: GoogleFonts.poppins(fontSize: 14, color: subtitleColor), // Apply theme color
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Unit: ${orderedProduct.unit}',
                                style: GoogleFonts.poppins(fontSize: 13, color: textColor), // Apply theme color
                              ),
                              Text(
                                'Price: ₹${orderedProduct.price.toStringAsFixed(2)}',
                                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: orangeColor), // Always orange
                              ),
                              Text(
                                'Quantity: ${orderedProduct.quantity}',
                                style: GoogleFonts.poppins(fontSize: 13, color: textColor), // Apply theme color
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDarkMode) {
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color labelColor = isDarkMode ? Colors.white70 : Colors.black87; // Slightly lighter for label

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 15, color: labelColor), // Apply theme color
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(fontSize: 15, color: textColor), // Apply theme color
            ),
          ),
        ],
      ),
    );
  }
}
