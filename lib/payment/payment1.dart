import 'package:flutter/material.dart';
import 'package:kisangro/home/bottom.dart';
import 'package:kisangro/models/product_model.dart';
import 'package:kisangro/payment/payment2.dart';
import 'package:kisangro/payment/payment3.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:kisangro/models/cart_model.dart';
import 'package:kisangro/models/order_model.dart';
import 'package:kisangro/models/address_model.dart';
import 'package:kisangro/models/kyc_business_model.dart';
import '../common/common_app_bar.dart';
import '../home/cart.dart';
import '../home/myorder.dart';
import '../menu/wishlist.dart';
import '../home/noti.dart';
import '../home/theme_mode_provider.dart';

class delivery extends StatefulWidget {
  final Product? product; // Optional product for "Buy Now" flow

  const delivery({super.key, this.product});

  @override
  State<delivery> createState() => _deliveryState();
}

class _deliveryState extends State<delivery> {
  @override
  void initState() {
    super.initState();
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    );
  }

  Widget _buildAddressSection(
      BuildContext context,
      AddressModel addressModel,
      bool isDarkMode,
      Color textColor,
      Color orangeColor) {
    final Color containerColor = isDarkMode ? Colors.grey[700]! : Colors.grey[200]!;

    return Card(
      color: containerColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const delivery2(),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_outlined,
                color: orangeColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${addressModel.currentName} - ${addressModel.currentPincode}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      addressModel.currentAddress,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.arrow_forward_ios_outlined,
                color: textColor.withOpacity(0.7),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductTile(CartItem cartItem, bool isDarkMode, Color textColor) {
    final Color containerColor = isDarkMode ? Colors.grey[700]! : Colors.grey[200]!;
    final Color greyTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[700]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: FadeInImage.assetNetwork(
                placeholder: 'assets/images/placeholder.png', // Add a placeholder asset
                image: cartItem.imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                imageErrorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported,
                          color: Colors.grey[600],
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'No Image',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                },
                placeholderErrorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          color: Colors.grey[600],
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Product',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cartItem.title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Unit: ${cartItem.selectedUnitSize}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: greyTextColor,
                    ),
                  ),
                  Text(
                    'Quantity: ${cartItem.quantity}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: greyTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${(cartItem.pricePerUnit * cartItem.quantity).toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value,
      {bool isDiscount = false, bool isGrandTotal = false, required bool isDarkMode}) {
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color greyTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[700]!;
    final Color orangeColor = const Color(0xffEB7720); // Orange color, remains constant

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: isGrandTotal ? 16 : 14,
              fontWeight: isGrandTotal ? FontWeight.bold : FontWeight.normal,
              color: isGrandTotal ? textColor : greyTextColor, // Apply theme colors
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: isGrandTotal ? 18 : 14,
              fontWeight: isGrandTotal ? FontWeight.bold : FontWeight.normal,
              color: isDiscount
                  ? Colors.red
                  : (isGrandTotal ? orangeColor : textColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDottedLine(bool isDarkMode) {
    final Color dottedLineColor = isDarkMode ? Colors.grey[600]! : Colors.grey[400]!;
    return CustomPaint(
      painter: DottedLinePainter(color: dottedLineColor),
      child: const SizedBox(
        width: double.infinity,
        height: 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    final Color primaryColor = isDarkMode ? Colors.grey[850]! : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color orangeColor = const Color(0xffEB7720);
    final Color buttonColor = const Color(0xffEB7720);

    final cartModel = Provider.of<CartModel>(context);
    final addressModel = Provider.of<AddressModel>(context); // Listen to AddressModel

    // Determine the list of items to display and the subtotal
    List<CartItem> items;
    double subTotal = 0.0;
    if (widget.product != null) {
      // Single product 'Buy Now' flow
      final product = widget.product!;
      final cartItem = CartItem(
        cusId: 'buy-now-user', // A temporary placeholder for the customer ID
        proId: product.selectedUnit.proId, // CORRECTED: Use proId from the selected unit
        title: product.title,
        subtitle: product.subtitle,
        imageUrl: product.imageUrl,
        category: product.category,
        selectedUnitSize: product.selectedUnit.size,
        pricePerUnit: product.sellingPricePerSelectedUnit ?? 0.0,
        quantity: 1, // Assume quantity is 1 for 'Buy Now'
      );
      items = [cartItem];
      subTotal = cartItem.totalPrice;
    } else {
      // Cart flow
      items = cartModel.items;
      subTotal = cartModel.totalAmount;
    }

    const double shippingFee = 40.0;
    const double discount = 0.0;
    final double grandTotal = subTotal + shippingFee - discount;

    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: orangeColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Address Details',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Top section with total amount
          Container(
            width: double.infinity,
            color: const Color(0xFFF5E6D3), // Light beige color
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      // FIX: Replaced BorderDirectional with BorderSide

                      bottom: BorderSide(
                        color: Colors.black,
                        width: 1,
                        style: BorderStyle.solid,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount:',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        '₹ ${grandTotal.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        'Step 2/3',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: orangeColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: Container(
              color: const Color(0xFFF5E6D3),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Delivery Address Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Delivery Address',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: orangeColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Business',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Address Card - Updated to use AddressModel data
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: orangeColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  addressModel.currentName, // Use AddressModel data
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 40), // Matches location icon's left padding
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(addressModel.currentAddress),
                                const SizedBox(height: 8),
                                Text('Pin-code: ${addressModel.currentPincode}'),
                                const SizedBox(height: 12),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center, // Vertically center align
                                  children: [
                                    Container(
                                      width: 70, // Increased width for bigger GIF
                                      height: 40, // Increased height for bigger GIF
                                      alignment: Alignment.centerLeft, // Force left alignment
                                      child: Image.asset(
                                        'assets/delivery.gif',
                                        fit: BoxFit.contain, // Maintains aspect ratio without overflow
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible( // Ensures text wraps properly
                                      child: Text(
                                        'Deliverable by 20 Apr 2024',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.black87,
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

                    const SizedBox(height: 24),

                    // Change Address Button - Updated design
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const delivery2(),
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 16,
                          ),
                          label: Text(
                            'Change Address',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: orangeColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: const Color(0xFFF5E6D3),
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentPage(orderId: 'ORDER_${DateTime.now().millisecondsSinceEpoch}'),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            backgroundColor: buttonColor,
            minimumSize: const Size(double.infinity, 50),
          ),
          child: Text(
            'Proceed',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class DottedLinePainter extends CustomPainter {
  final Color color;
  DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double currentX = 0;

    while (currentX < size.width) {
      canvas.drawLine(
        Offset(currentX, 0),
        Offset(currentX + dashWidth, 0),
        paint,
      );
      currentX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}