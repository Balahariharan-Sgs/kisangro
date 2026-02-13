import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/address_model.dart';
import '../models/cart_model.dart';
import '../models/order_model.dart';
import '../home/bottom.dart';
import '../home/theme_mode_provider.dart';

// Function to get cus_id from shared preferences (reuse from payment2.dart)
Future<String> getCusId() async {
  final prefs = await SharedPreferences.getInstance();
  final dynamic cusIdValue = prefs.get('cus_id');
  if (cusIdValue is int) {
    return cusIdValue.toString();
  } else if (cusIdValue is String) {
    return cusIdValue;
  }
  return '100'; // Default fallback
}

// Function to get mobile number from shared preferences
Future<String> getMobileNumber() async {
  final prefs = await SharedPreferences.getInstance();
  final String? mobile = prefs.getString('mobile_number');
  return mobile ?? '9486121229'; // Fallback only if not found
}

class RazorpayPage extends StatefulWidget {
  final String orderId;
  final double totalAmount;
  final AddressModel addressModel;
  final List cartItems;
  final String paymentMethod;

  const RazorpayPage({
    super.key,
    required this.orderId,
    required this.totalAmount,
    required this.addressModel,
    required this.cartItems,
    required this.paymentMethod,
  });

  @override
  State<RazorpayPage> createState() => _RazorpayPageState();
}

class _RazorpayPageState extends State<RazorpayPage> {
  late Razorpay _razorpay;
  bool _isProcessing = false;
  bool _paymentFailed = false;
  bool _isCreatingOrder = false;
  int _transactionCounter = 0;
  bool _isPaymentSuccessHandled = false;
  static final Set<String> _processedPaymentIds = {};
  
  // Real-time data
  String _cusId = '';
  String _mobileNumber = '';

  @override
  void initState() {
    super.initState();

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    // Load real-time user data before opening checkout
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    _cusId = await getCusId();
    _mobileNumber = await getMobileNumber();
    
    debugPrint('Loaded real-time user data - CusId: $_cusId, Mobile: $_mobileNumber');
    
    // Open Razorpay checkout after loading user data
    if (mounted) {
      _openRazorpayCheckout();
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  // Generate a unique transaction ID
  String _generateTransactionId() {
    _transactionCounter++;
    return 'KSG${_transactionCounter.toString().padLeft(3, '0')}${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}';
  }

  // Razorpay checkout opening with real-time user data
  void _openRazorpayCheckout() {
    setState(() {
      _isProcessing = true;
      _paymentFailed = false;
    });

    // Convert amount to paise (Razorpay expects amount in smallest currency unit)
    final amountInPaise = (widget.totalAmount * 100).toInt();
    final transactionId = _generateTransactionId();

    // USING YUVATHI'S WORKING RAZORPAY KEY (will replace with KisanGro key later)
    final options = {
      'key': 'rzp_live_RGF7AegArSFPTw', // Yuvathi's working key
      'amount': amountInPaise.toString(),
      "payment_capture": 1,
      'name': 'KisanGro',
      'description': 'Payment for order #${widget.orderId}',
      'prefill': {
        'contact': _mobileNumber, // REAL-TIME mobile number from SharedPreferences
        'name': widget.addressModel.currentName.isNotEmpty 
            ? widget.addressModel.currentName 
            : 'Customer',
        'email': '${_cusId}@kisangro.com', // Using cus_id for unique email
      },
      'notes': {
        'domain': 'https://erpsmart.in/total/api/m_api/',
        'order_id': widget.orderId,
        'customer_id': _cusId, // REAL-TIME customer ID
        'address': widget.addressModel.currentAddress,
        'mobile': _mobileNumber, // Store mobile in notes as well
      },
      'theme': {'color': '#EB7720'}, // KisanGro orange color
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _paymentFailed = true;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening payment gateway: $e'),
          backgroundColor: Colors.red,
        ),
      );
      
      // Navigate back after error
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    }
  }

  // Notify payment status to backend with real-time cus_id
  Future<void> _notifyPaymentStatus({
    required String paymentId,
    required String status,
    required String amount,
    required String orderId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      double? latitude = prefs.getDouble('latitude');
      double? longitude = prefs.getDouble('longitude');
      String? deviceId = prefs.getString('device_id');
      
      // Use the real-time cus_id from state
      String cusId = _cusId.isEmpty ? await getCusId() : _cusId;

      debugPrint('Notifying payment status: $status for $paymentId with cus_id: $cusId');
      
      final response = await http.post(
        Uri.parse('https://erpsmart.in/total/api/m_api/'),
        body: {
          'cid': '85788578',
          'type': '1009', // Payment status update type
          'lt': latitude?.toString() ?? '1',
          'ln': longitude?.toString() ?? '1',
          'device_id': deviceId ?? '1',
          'cus_id': cusId, // REAL-TIME customer ID
          'payment_id': paymentId,
          'order_id': orderId,
          'status': status,
          'amount': amount,
          'payment_method': 'RAZORPAY',
        },
      );

      if (response.statusCode == 200) {
        String responseBody = response.body;
        int startIndex = responseBody.indexOf('{');
        if (startIndex != -1) {
          responseBody = responseBody.substring(startIndex);
          final data = json.decode(responseBody);
          debugPrint('Payment Status Notification Response: $data');
        }
      }
    } catch (e) {
      debugPrint('Error notifying payment status: $e');
    }
  }

  // Auto cancel order on payment failure with real-time cus_id
  Future<void> _autoCancelOrder() async {
     try {
      final prefs = await SharedPreferences.getInstance();
      double? latitude = prefs.getDouble('latitude');
      double? longitude = prefs.getDouble('longitude');
      String? deviceId = prefs.getString('device_id');
      
      String cusId = _cusId.isEmpty ? await getCusId() : _cusId;

      debugPrint('Auto cancelling order: ${widget.orderId} for customer: $cusId');
      
      final response = await http.post(
        Uri.parse('https://erpsmart.in/total/api/m_api/'),
        body: {
          'cid': '85788578',
          'type': '1010', // Cancel order type - adjust based on your API
             'lt': latitude?.toString() ?? '1',
          'ln': longitude?.toString() ?? '1',
          'device_id': deviceId ?? '1',
          'cus_id': cusId, // REAL-TIME customer ID
          'order_id': widget.orderId,
        },
      );
      debugPrint('Auto Cancel Response: ${response.body}');
    } catch (e) {
      debugPrint('Error auto cancelling order: $e');
    }
  }

  // Show order processing dialog
  void _showOrderProcessingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Change text every few seconds to make it feel "active"
            Future.delayed(const Duration(seconds: 3), () {
              if (context.mounted) {
                setDialogState(() {});
              }
            });

            String getProgressMessage() {
              final sec = DateTime.now().second % 12;
              if (sec < 3) return 'Verifying payment status...';
              if (sec < 6) return 'Generating order details...';
              if (sec < 9) return 'Securing your order...';
              return 'Finalizing your purchase...';
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.0),
              ),
              content: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xffEB7720).withOpacity(0.2),
                            ),
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xffEB7720),
                            ),
                            strokeWidth: 4,
                          ),
                        ),
                        const Icon(
                          Icons.shopping_bag_outlined,
                          color: Color(0xffEB7720),
                          size: 30,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Processing Your Order!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black.withOpacity(0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: Text(
                        getProgressMessage(),
                        key: ValueKey(getProgressMessage()),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xffEB7720).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Please do not close or refresh',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xffEB7720),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_isPaymentSuccessHandled) {
      debugPrint('⚠️ Duplicate payment success event ignored');
      return;
    }

    if (response.paymentId != null &&
        _processedPaymentIds.contains(response.paymentId)) {
      debugPrint('⚠️ Duplicate payment success event ignored (Global ID check): ${response.paymentId}');
      return;
    }

    _isPaymentSuccessHandled = true;
    if (response.paymentId != null) {
      _processedPaymentIds.add(response.paymentId!);
    }

    // Notify backend about success with real-time cus_id
    await _notifyPaymentStatus(
      paymentId: response.paymentId ?? '',
      status: 'success',
      amount: widget.totalAmount.toString(),
      orderId: widget.orderId,
    );

    setState(() {
      _isProcessing = false;
      _paymentFailed = false;
      _isCreatingOrder = true;
    });

    try {
      // Show processing dialog
      _showOrderProcessingDialog();

      // Create order in OrderModel
      final orderModel = Provider.of<OrderModel>(context, listen: false);
      final cartModel = Provider.of<CartModel>(context, listen: false);
      
      // Convert cart items to ordered products
      final orderedProducts = widget.cartItems.map((item) {
        if (item is CartItem) {
          return item.toOrderedProduct(orderId: widget.orderId);
        }
        return null;
      }).whereType<OrderedProduct>().toList();
      
      // Create new order
      final newOrder = Order(
        id: widget.orderId,
        products: orderedProducts,
        totalAmount: widget.totalAmount,
        orderDate: DateTime.now(),
        status: OrderStatus.booked,
        paymentMethod: 'RAZORPAY',
        paymentId: response.paymentId,
      );
      
      orderModel.addOrder(newOrder);
      
      // Clear cart
      await cartModel.clearCart();
      
      // Close the processing dialog
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Set flag for rewards popup
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('showRewardsPopupOnNextHomeLoad', true);

      // Navigate to success screen with real-time data
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentSuccessScreen(
              orderId: widget.orderId,
              transactionId: response.paymentId!,
              amount: widget.totalAmount,
              paymentMethod: 'Razorpay',
              customerName: widget.addressModel.currentName,
              customerId: _cusId, // Pass real-time customer ID
              mobileNumber: _mobileNumber, // Pass real-time mobile number
              isMembershipPayment: false,
            ),
          ),
        );
      }

    } catch (e) {
      // Close the processing dialog if still open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      debugPrint('Error processing successful payment: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment successful but order creation failed: $e'),
            backgroundColor: Colors.orange,
          ),
        );
        
        // Still navigate to success with minimal info
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentSuccessScreen(
              orderId: widget.orderId,
              transactionId: response.paymentId ?? 'N/A',
              amount: widget.totalAmount,
              paymentMethod: 'Razorpay',
              customerName: widget.addressModel.currentName,
              customerId: _cusId,
              mobileNumber: _mobileNumber,
              isMembershipPayment: false,
            ),
          ),
        );
      }
    } finally {
      setState(() {
        _isCreatingOrder = false;
      });
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) async {
    _isPaymentSuccessHandled = false;

    // Check for valid order ID
    if (widget.orderId.isEmpty) {
      debugPrint('❌ Cannot process payment error: Invalid Order ID');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Invalid Order ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Notify backend about failure with real-time cus_id
    await _notifyPaymentStatus(
      paymentId: 'failed_${DateTime.now().millisecondsSinceEpoch}',
      status: 'failed',
      amount: widget.totalAmount.toString(),
      orderId: widget.orderId,
    );

    // Auto-cancel the order on payment failure
    await _autoCancelOrder();

    if (mounted) {
      setState(() {
        _isProcessing = false;
        _paymentFailed = true;
        _isCreatingOrder = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Payment Failed: ${response.message ?? 'Transaction failed'}'),
          backgroundColor: Colors.red,
        ),
      );

      // Navigate back after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) async {
    // Notify backend with real-time cus_id
    await _notifyPaymentStatus(
      paymentId: 'external_wallet_${DateTime.now().millisecondsSinceEpoch}',
      status: 'pending',
      amount: widget.totalAmount.toString(),
      orderId: widget.orderId,
    );

    setState(() {
      _isProcessing = false;
      _paymentFailed = false;
      _isCreatingOrder = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('💳 External wallet selected: ${response.walletName}'),
        backgroundColor: Colors.blue,
      ),
    );

    // Navigate back
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;
    final Color backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isProcessing || _isCreatingOrder
          ? Container(
              color: backgroundColor.withOpacity(0.7),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xffEB7720),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isCreatingOrder 
                            ? 'Creating your order...' 
                            : 'Processing payment...',
                        style: GoogleFonts.poppins(
                          color: textColor,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

// Enhanced PaymentSuccessScreen with real-time customer data
class PaymentSuccessScreen extends StatefulWidget {
  final String orderId;
  final String transactionId;
  final double amount;
  final String paymentMethod;
  final String customerName;
  final String customerId;
  final String mobileNumber;
  final bool isMembershipPayment;
  final String? shipRocketOrderId;
  final String? kitId;

  const PaymentSuccessScreen({
    super.key,
    required this.orderId,
    required this.transactionId,
    required this.amount,
    required this.paymentMethod,
    required this.customerName,
    required this.customerId,
    required this.mobileNumber,
    this.isMembershipPayment = false,
    this.shipRocketOrderId,
    this.kitId,
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

    final prefs = await SharedPreferences.getInstance();
    
    if (widget.isMembershipPayment) {
      await prefs.setBool('isMembershipActive', true);
      await prefs.setBool('showRewardsPopupOnNextHomeLoad', false);
    } else {
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

  String _formatOrderId(String orderId) {
    if (orderId.length > 8) {
      return '...${orderId.substring(orderId.length - 8)}';
    }
    return orderId;
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success Animation
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: orangeColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: orangeColor,
                  size: 60,
                ),
              ),
              const SizedBox(height: 24),
              
              // Success Text
              Text(
                "Payment Successful!",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Thank you for your purchase, ${widget.customerName.split(' ').first}!",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: greyTextColor,
                ),
              ),
              const SizedBox(height: 32),
              
              // Order Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[850] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Details',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('Order ID', _formatOrderId(widget.orderId), textColor, greyTextColor),
                    _buildDetailRow('Transaction ID', _formatOrderId(widget.transactionId), textColor, greyTextColor),
                    _buildDetailRow('Amount Paid', '₹${widget.amount.toStringAsFixed(2)}', textColor, greyTextColor, valueColor: orangeColor),
                    _buildDetailRow('Payment Method', widget.paymentMethod, textColor, greyTextColor),
                    _buildDetailRow('Customer ID', widget.customerId, textColor, greyTextColor),
                    _buildDetailRow('Mobile', widget.mobileNumber, textColor, greyTextColor),
                    if (widget.shipRocketOrderId != null && widget.shipRocketOrderId!.isNotEmpty)
                      _buildDetailRow('Tracking ID', _formatOrderId(widget.shipRocketOrderId!), textColor, greyTextColor),
                    _buildDetailRow('Date', _formatDate(DateTime.now()), textColor, greyTextColor),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Loading Indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(0xffEB7720),
                ),
              ),
              const SizedBox(height: 20),
              
              // Redirecting Text
              Text(
                "Redirecting to home...",
                style: GoogleFonts.poppins(
                  color: greyTextColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color textColor, Color greyTextColor, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: greyTextColor,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? textColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}