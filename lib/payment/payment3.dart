import 'package:flutter/material.dart';
import 'package:kisangro/home/bottom.dart';
import 'package:kisangro/home/cart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisangro/payment/razorPay_init.dart';
import 'package:provider/provider.dart';
import 'package:kisangro/models/cart_model.dart';
import 'package:kisangro/models/order_model.dart';
import 'package:kisangro/models/address_model.dart';
import 'package:intl/intl.dart';
import 'package:kisangro/home/rewards_popup.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../home/theme_mode_provider.dart';

class PaymentPage extends StatefulWidget {
  final String orderId;
  final bool isMembershipPayment;

  const PaymentPage({
    super.key,
    required this.orderId,
    this.isMembershipPayment = false,
  });

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String selectedPaymentMode = '';
  Map<String, dynamic>? selectedUpiApp;
  bool _applyRewardPoints = true;
  final TextEditingController _upiController = TextEditingController();

  List<Map<String, dynamic>> upiApps = [
    {'name': 'Google Pay', 'image': 'assets/gpay.png', 'type': 'UPI'},
    {'name': 'Phone Pe', 'image': 'assets/phonepay.png', 'type': 'UPI'},
    {'name': 'Paytm', 'image': 'assets/paytm.png', 'type': 'UPI'},
    {'name': 'Amazon Pay', 'image': 'assets/amzpay.png', 'type': 'UPI'},
    {'name': 'Apple Pay', 'image': 'assets/applepay.png', 'type': 'UPI'},
    {'name': 'RazorPay', 'image': 'assets/razorpay.png', 'type': 'RAZORPAY'},
  ];

  @override
  void dispose() {
    _upiController.dispose();
    super.dispose();
  }

  void _handlePaymentSelection() {
    final cart = Provider.of<CartModel>(context, listen: false);
    final addressModel = Provider.of<AddressModel>(context, listen: false);
    final totalAmount = cart.totalAmount + 90.0;

    if (selectedPaymentMode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method')),
      );
      return;
    }

    if (selectedPaymentMode == 'RAZORPAY') {
      // Navigate to RazorPay screen - ORDER CREATION HAPPENS ONLY AFTER PAYMENT SUCCESS
      _navigateToRazorPay(cart, addressModel, totalAmount);
    } else {
      // Handle other payment methods - simulate immediate success for demo
      _handleNonRazorPayment();
    }
  }

  void _navigateToRazorPay(CartModel cart, AddressModel addressModel, double totalAmount) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RazorpayPage(
          orderId: widget.orderId,
          totalAmount: totalAmount,
          addressModel: addressModel,
          cartItems: cart.items,
          paymentMethod: selectedPaymentMode,
        ),
      ),
    ).then((result) async {
      if (result != null && result['success'] == true) {
        // Payment was successful through RazorPay
        // Order creation is handled within RazorpayPage after payment success

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment successful! Order #${result['orderId']} has been placed.'),
            backgroundColor: Colors.green,
          ),
        );

        // // Navigate to success screen
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => PaymentSuccessScreen(
        //       orderId: result['orderId'],
        //       isMembershipPayment: widget.isMembershipPayment,
        //     ),
        //   ),
        // );
      } else if (result != null && result['success'] == false) {
        // Payment failed through RazorPay
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment was cancelled or failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  // For non-Razorpay payments (simulate immediate success for demo)
  void _handleNonRazorPayment() async {
    final cart = Provider.of<CartModel>(context, listen: false);
    final orderModel = Provider.of<OrderModel>(context, listen: false);

    try {
      // First try to confirm with API to get the real order ID
      final apiSuccess = await cart.confirmOrderWithApi(widget.orderId);

      if (apiSuccess) {
        // If API success, refresh orders to get the actual API order ID
        await orderModel.forceReloadFromApi();

        // Find the order with our temporary ID and update it
        final orders = orderModel.orders;
        final ourOrder = orders.firstWhere(
              (order) => order.id == widget.orderId,
          orElse: () => Order(
            id: widget.orderId,
            products: [],
            totalAmount: 0,
            orderDate: DateTime.now(),
            status: OrderStatus.booked,
            paymentMethod: selectedPaymentMode,
          ),
        );

        // Navigate to success screen with the actual order ID
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentSuccessScreen(
              orderId: ourOrder.id,
              isMembershipPayment: widget.isMembershipPayment,
            ),
          ),
        );
      } else {
        // If API fails, create local order with our generated ID
        final orderedProducts = cart.items.map((item) => item.toOrderedProduct(
          orderId: widget.orderId,
        )).toList();

        final newOrder = Order(
          id: widget.orderId,
          products: orderedProducts,
          totalAmount: cart.totalAmount + 90.0,
          orderDate: DateTime.now(),
          status: OrderStatus.booked,
          paymentMethod: selectedPaymentMode,
        );

        orderModel.addOrder(newOrder);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentSuccessScreen(
              orderId: widget.orderId,
              isMembershipPayment: widget.isMembershipPayment,
            ),
          ),
        );
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartModel>(context);
    final addressModel = Provider.of<AddressModel>(context);
    final totalAmount = cart.totalAmount + 90.0;
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    // Define colors based on theme
    final Color gradientStartColor = isDarkMode ? Colors.black : const Color(0xffFFD9BD);
    final Color gradientEndColor = isDarkMode ? Colors.black : const Color(0xffFFFFFF);
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color subtitleColor = isDarkMode ? Colors.white70 : Colors.grey[600]!;
    final Color cardBackgroundColor = isDarkMode ? Colors.grey[850]! : Colors.white;
    final Color cardBorderColor = isDarkMode ? Colors.grey[700]! : Colors.grey.shade300;
    final Color orangeColor = const Color(0xffEB7720);
    final Color dottedLineColor = isDarkMode ? Colors.grey[600]! : Colors.grey;
    final Color checkboxActiveColor = orangeColor;
    final Color checkboxUnselectedColor = isDarkMode ? Colors.white70 : Colors.black54;
    final Color inputHintColor = isDarkMode ? Colors.grey[400]! : Colors.grey;
    final Color inputBorderColor = isDarkMode ? Colors.grey[600]! : orangeColor;
    final Color inputFillColor = isDarkMode ? Colors.grey[900]! : Colors.white;
    final Color radioActiveColor = orangeColor;
    final Color radioUnselectedColor = isDarkMode ? Colors.white70 : Colors.black54;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: orangeColor,
        centerTitle: false,
        title: Transform.translate(
          offset: const Offset(-20, 0),
          child: Text(
            "Payment Method",
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 18),
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                height: 1,
                child: CustomPaint(
                  painter: DottedLinePainter(color: dottedLineColor),
                ),
              ),
              const SizedBox(height: 16),
              // Delivery Address Section
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
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
                    '₹ ${totalAmount.toStringAsFixed(2)}',
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
                '${cart.totalItemCount} Items from your cart',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: subtitleColor,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 1,
                child: CustomPaint(
                  painter: DottedLinePainter(color: dottedLineColor),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    'Your Reward Points',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: orangeColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '500',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      color: orangeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Image.asset(
                    'assets/coin.gif',
                    width: 30,
                    height: 20,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 30,
                        height: 20,
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[700] : Colors.yellow,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _applyRewardPoints,
                    onChanged: (value) {
                      setState(() {
                        _applyRewardPoints = value ?? false;
                      });
                    },
                    activeColor: checkboxActiveColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    checkColor: isDarkMode ? Colors.black : Colors.white,
                  ),
                  Expanded(
                    child: Text(
                      'Add Reward Points To Your Purchase',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: orangeColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Text(
                'Choose Payment Mode',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Select Payment Method',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: upiApps.length,
                itemBuilder: (context, index) {
                  final app = upiApps[index];
                  final isSelected = selectedUpiApp == app;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedUpiApp = app;
                        selectedPaymentMode = app['type'];
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? orangeColor
                              : cardBorderColor,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode ? Colors.transparent : Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            app['image'],
                            height: 40,
                            width: 40,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 40,
                                width: 40,
                                decoration: BoxDecoration(
                                  color: isDarkMode ? Colors.grey[700] : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.payment, color: isDarkMode ? Colors.grey[400] : Colors.grey),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            app['name'],
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _upiController,
                style: GoogleFonts.poppins(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Type or paste UPI Id here',
                  hintStyle: GoogleFonts.poppins(color: inputHintColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: inputBorderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: orangeColor, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: inputBorderColor),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  fillColor: inputFillColor,
                  filled: true,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'Other Modes',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  setState(() {
                    selectedPaymentMode = 'CARD';
                    selectedUpiApp = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBackgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selectedPaymentMode == 'CARD'
                          ? orangeColor
                          : cardBorderColor,
                      width: selectedPaymentMode == 'CARD' ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Radio<String>(
                        value: 'CARD',
                        groupValue: selectedPaymentMode,
                        onChanged: (value) {
                          setState(() {
                            selectedPaymentMode = value!;
                            selectedUpiApp = null;
                          });
                        },
                        activeColor: radioActiveColor,
                        fillColor: MaterialStateProperty.resolveWith<Color>(
                              (Set<MaterialState> states) {
                            if (states.contains(MaterialState.selected)) {
                              return radioActiveColor;
                            }
                            return radioUnselectedColor;
                          },
                        ),
                      ),
                      Image.asset(
                        'assets/debit.png',
                        height: 30,
                        width: 40,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 30,
                            width: 40,
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.grey[700] : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(Icons.credit_card, color: isDarkMode ? Colors.grey[400] : Colors.grey),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Debit/Credit Card',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  setState(() {
                    selectedPaymentMode = 'NETBANKING';
                    selectedUpiApp = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBackgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selectedPaymentMode == 'NETBANKING'
                          ? orangeColor
                          : cardBorderColor,
                      width: selectedPaymentMode == 'NETBANKING' ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Radio<String>(
                        value: 'NETBANKING',
                        groupValue: selectedPaymentMode,
                        onChanged: (value) {
                          setState(() {
                            selectedPaymentMode = value!;
                            selectedUpiApp = null;
                          });
                        },
                        activeColor: radioActiveColor,
                        fillColor: MaterialStateProperty.resolveWith<Color>(
                              (Set<MaterialState> states) {
                            if (states.contains(MaterialState.selected)) {
                              return radioActiveColor;
                            }
                            return radioUnselectedColor;
                          },
                        ),
                      ),
                      Image.asset(
                        'assets/netbanking.png',
                        height: 30,
                        width: 40,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 30,
                            width: 40,
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.grey[700] : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(Icons.account_balance, color: isDarkMode ? Colors.grey[400] : Colors.grey),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Net Banking',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
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
            onPressed: _handlePaymentSelection,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Pay Now',
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.arrow_forward_ios_outlined,
                    color: Colors.white70),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PaymentSuccessScreen extends StatefulWidget {
  final String orderId;
  final bool isMembershipPayment;

  const PaymentSuccessScreen({
    super.key,
    required this.orderId,
    this.isMembershipPayment = false,
  });

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHomeWithDelay();
  }

  Future<void> _navigateToHomeWithDelay() async {
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Clear cart after successful payment
    final cart = Provider.of<CartModel>(context, listen: false);
    await cart.clearCart();

    if (widget.isMembershipPayment) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isMembershipActive', true);
      await prefs.setBool('showRewardsPopupOnNextHomeLoad', false);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('showRewardsPopupOnNextHomeLoad', true);
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const Bot(initialIndex: 0, showRewardsPopup: true),
      ),
          (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    final Color backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color greyTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey;
    final Color orangeColor = const Color(0xffEB7720);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                color: orangeColor, size: 60),
            const SizedBox(height: 20),
            Text("Payment Successful!",
                style: GoogleFonts.poppins(
                    fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 10),
            Text("Order ID: ${widget.orderId}",
                style: GoogleFonts.poppins(fontSize: 16, color: textColor)),
            const SizedBox(height: 20),
            CircularProgressIndicator(color: orangeColor),
            const SizedBox(height: 20),
            Text(
              "Redirecting to home... ",
              style: GoogleFonts.poppins(color: greyTextColor),
            ),
          ],
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
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}