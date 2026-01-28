import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:kisangro/payment/payment3.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/address_model.dart';

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

  @override
  void initState() {
    super.initState();

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    // Print received data
    debugPrint("Order ID: ${widget.orderId}");
    debugPrint("Total Amount: ${widget.totalAmount}");
    debugPrint("Address Model: ${widget.addressModel}");
    debugPrint("Cart Items: ${widget.cartItems}");
    debugPrint("Payment Method: ${widget.paymentMethod}");

    // 👉 Call Razorpay after init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      openCheckout();
    });
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void openCheckout() {
    var options = {
      'key': 'rzp_live_63M3pTf6POwTPN',
      'amount': (widget.totalAmount * 100).toInt(), // ✅ Use actual amount
      'name': 'Order Payment',
      'description': 'Payment for order #${widget.orderId}',
      'prefill': {
        'contact': '9486121229',
        'email': 'test@example.com',
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint("Razorpay Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Razorpay initialization failed: $e")),
      );
      Navigator.pop(context);
    }
  }

  Future<Map<String, dynamic>> recordPaymentStatus({
    required String paymentId,
    required String orderId,
    required double amount,
    required String status,
  }) async {
    const String apiUrl = 'https://erpsmart.in/total/api/m_api/';

    // Prepare the request parameters
    

    try {
      final prefs = await SharedPreferences.getInstance();
      
      double? latitude = prefs.getDouble('latitude');
      double? longitude = prefs.getDouble('longitude');
      String? deviceId = prefs.getString('device_id');

      final Map<String, String> requestBody = {
      'cid': '85788578',
     'ln': longitude?.toString() ?? '',
        'lt': latitude?.toString() ?? '',
        'device_id': deviceId ?? '',
      'type': '1009',
      'cus_id': '287',
      'payment_id': paymentId,
      'order_id': orderId,
      'amount': amount.toString(),
      'status': status,
      'payment_method': widget.paymentMethod,
    };
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: requestBody,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to record payment status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('API call failed: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() {
      _isProcessing = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("✅ Payment Successful: ${response.paymentId}")),
    );

    try {
      // Make API call to record payment status
      final apiResponse = await recordPaymentStatus(
          paymentId: response.paymentId!,
          orderId: widget.orderId,
          amount: widget.totalAmount,
          status: 'success'
      );

      if (apiResponse['error'] == 'false') {
        debugPrint("✅ Payment status recorded successfully in API");
      } else {
        debugPrint("⚠️ API returned error: ${apiResponse['message']}");
        // You might want to show a warning message to the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Payment successful but status update failed: ${apiResponse['message']}")),
        );
      }
    } catch (e) {
      debugPrint("❌ Error recording payment status: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Payment successful but status update failed")),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }

    // Navigate to success screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentSuccessScreen(
          orderId: widget.orderId,
          isMembershipPayment: false,
        ),
      ),
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) async {
    setState(() {
      _isProcessing = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("❌ Payment Failed: ${response.code} - ${response.message}")),
    );

    try {
      // Record failed payment status in API
      final apiResponse = await recordPaymentStatus(
          paymentId: 'failed_${DateTime.now().millisecondsSinceEpoch}',
          orderId: widget.orderId,
          amount: widget.totalAmount,
          status: 'failed'
      );

      if (apiResponse['error'] == 'false') {
        debugPrint("✅ Failed payment status recorded in API");
      } else {
        debugPrint("⚠️ API returned error: ${apiResponse['message']}");
      }
    } catch (e) {
      debugPrint("❌ Error recording failed payment status: $e");
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }

    Navigator.pop(context);
  }

  void _handleExternalWallet(ExternalWalletResponse response) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("💳 External Wallet Selected: ${response.walletName}")),
    );

    // You might want to handle external wallet payments differently
    try {
      final apiResponse = await recordPaymentStatus(
          paymentId: 'external_wallet_${DateTime.now().millisecondsSinceEpoch}',
          orderId: widget.orderId,
          amount: widget.totalAmount,
          status: 'pending'
      );

      if (apiResponse['error'] == 'false') {
        debugPrint("✅ External wallet payment status recorded in API");
      }
    } catch (e) {
      debugPrint("❌ Error recording external wallet status: $e");
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isProcessing
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Processing payment...'),
          ],
        ),
      )
          : const SizedBox.shrink(),
    );
  }
}