import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kisangro/home/bottom.dart';
import 'package:kisangro/models/product_model.dart';
import 'package:kisangro/payment/payment2.dart';
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
import 'razorPay_init.dart'; // Add this import

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
                placeholder: 'assets/images/placeholder.png',
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
    final Color orangeColor = const Color(0xffEB7720);

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
              color: isGrandTotal ? textColor : greyTextColor,
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
    final Color subtitleColor = isDarkMode ? Colors.white70 : Colors.grey[600]!;
    final Color orangeColor = const Color(0xffEB7720);
    final Color buttonColor = const Color(0xffEB7720);
    final Color cardBackgroundColor = isDarkMode ? Colors.grey[850]! : Colors.white;
    final Color cardBorderColor = isDarkMode ? Colors.grey[700]! : Colors.grey.shade300;
    final Color dottedLineColor = isDarkMode ? Colors.grey[600]! : Colors.grey;

    final cartModel = Provider.of<CartModel>(context);
    final addressModel = Provider.of<AddressModel>(context);

    // Determine the list of items to display and the subtotal
    List<CartItem> items;
    double subTotal = 0.0;
    if (widget.product != null) {
      final product = widget.product!;
      final cartItem = CartItem(
        cusId: 'buy-now-user',
        proId: product.selectedUnit.proId,
        title: product.title,
        subtitle: product.subtitle,
        imageUrl: product.imageUrl,
        category: product.category,
        selectedUnitSize: product.selectedUnit.size,
        pricePerUnit: product.sellingPricePerSelectedUnit ?? 0.0,
        quantity: 1,
      );
      items = [cartItem];
      subTotal = cartItem.totalPrice;
    } else {
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
            color: const Color(0xFFF5E6D3),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
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
                    // Delivery Address Section - Enhanced with payment3 styling
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardBackgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: cardBorderColor),
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode ? Colors.transparent : Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delivery Address',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: orangeColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            addressModel.currentName.isNotEmpty && addressModel.currentName != "Smart (name)"
                                ? addressModel.currentName
                                : 'No Name Provided',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            addressModel.currentAddress.isNotEmpty
                                ? addressModel.currentAddress
                                : 'No address provided',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: subtitleColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pincode: ${addressModel.currentPincode}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: subtitleColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 70,
                                height: 40,
                                alignment: Alignment.centerLeft,
                                child: Image.asset(
                                  'assets/delivery.gif',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Deliverable by ${DateFormat('dd MMM yyyy').format(DateTime.now().add(const Duration(days: 3)))}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: subtitleColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Change Address Button
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

                    const SizedBox(height: 24),
                    
                    // Dotted Line Separator - From payment3
                    SizedBox(
                      width: double.infinity,
                      height: 1,
                      child: CustomPaint(
                        painter: DottedLinePainter(color: dottedLineColor),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Order Summary Section - From payment3
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount:',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        Text(
                          '₹ ${grandTotal.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${items.length} Item${items.length > 1 ? 's' : ''} from your cart',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: subtitleColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Price Breakdown
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardBackgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: cardBorderColor),
                      ),
                      child: Column(
                        children: [
                          _buildPriceRow('Subtotal', '₹ ${subTotal.toStringAsFixed(2)}', isDarkMode: isDarkMode),
                          const SizedBox(height: 8),
                          _buildPriceRow('Shipping Fee', '₹ $shippingFee', isDarkMode: isDarkMode),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 1,
                            child: CustomPaint(
                              painter: DottedLinePainter(color: dottedLineColor),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildPriceRow(
                            'Grand Total', 
                            '₹ ${grandTotal.toStringAsFixed(2)}', 
                            isGrandTotal: true, 
                            isDarkMode: isDarkMode
                          ),
                        ],
                      ),
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
            // Get the necessary models
            final cartModel = Provider.of<CartModel>(context, listen: false);
            final addressModel = Provider.of<AddressModel>(context, listen: false);
            
            // Determine items and total amount
            List<CartItem> items;
            double totalAmount = 0.0;
            
            if (widget.product != null) {
              final product = widget.product!;
              final cartItem = CartItem(
                cusId: 'buy-now-user',
                proId: product.selectedUnit.proId,
                title: product.title,
                subtitle: product.subtitle,
                imageUrl: product.imageUrl,
                category: product.category,
                selectedUnitSize: product.selectedUnit.size,
                pricePerUnit: product.sellingPricePerSelectedUnit ?? 0.0,
                quantity: 1,
              );
              items = [cartItem];
              totalAmount = cartItem.totalPrice;
            } else {
              items = cartModel.items;
              totalAmount = cartModel.totalAmount;
            }
            
            // Add shipping fee
            const double shippingFee = 40.0;
            final double grandTotal = totalAmount + shippingFee;
            
            // Navigate directly to RazorpayPage
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RazorpayPage(
                  orderId: 'ORDER_${DateTime.now().millisecondsSinceEpoch}',
                  totalAmount: grandTotal,
                  addressModel: addressModel,
                  cartItems: items,
                  paymentMethod: 'RAZORPAY',
                ),
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
            'Proceed to Payment',
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

// DottedLinePainter class - Moved from payment3.dart
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

