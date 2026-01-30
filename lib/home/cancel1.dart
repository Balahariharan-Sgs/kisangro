import 'package:flutter/material.dart';
import 'package:kisangro/home/myorder.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:kisangro/models/order_model.dart';
import '../home/theme_mode_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CancellationStep1Page extends StatefulWidget {
  final String orderId;
  final VoidCallback? onCancelConfirmed;

  const CancellationStep1Page({
    super.key,
    required this.orderId,
    this.onCancelConfirmed,
  });

  @override
  State<CancellationStep1Page> createState() => _CancellationStep1PageState();
}

class _CancellationStep1PageState extends State<CancellationStep1Page> {
  String selectedReason = 'Wrong Product Ordered';
  final TextEditingController otherController = TextEditingController();
  bool _isLoading = false;

  List<String> reasons = [
    'Wrong Product Ordered',
    'Wrong Quantity Of Product Ordered',
    'Changed Delivery Address',
    'Price Too High',
    'Changed My Mind',
    'Prefer to Buy In-Store',
    'Other Reasons',
  ];

  @override
  void dispose() {
    otherController.dispose();
    super.dispose();
  }

  // API call to initiate cancellation (Step 1 API - type: 2021)
  Future<Map<String, dynamic>> _initiateCancellation(String orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      double? latitude = prefs.getDouble('latitude');
      double? longitude = prefs.getDouble('longitude');
      String? deviceId = prefs.getString('device_id');

      final cusId = prefs.getInt('cus_id')?.toString() ?? '';

      print('=== STEP 1: INITIATING CANCELLATION ===');
      print('Order ID: $orderId');
      print('Customer ID: $cusId');

      final requestBody = {
        'cid': '85788578',
        'type': '1027',
        'lt': latitude?.toString() ?? '',
        'ln': longitude?.toString() ?? '',
        'device_id': deviceId ?? '',
        'cus_id': cusId,
        'order_id': orderId,
      };

      print('Request Body: $requestBody');

      final response = await http
          .post(
            Uri.parse('https://sgserp.in/erp/api/m_api/'),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: requestBody,
          )
          .timeout(const Duration(seconds: 15));

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print('Parsed Response: $jsonResponse');
        return jsonResponse;
      }
      return {
        'error': 'true',
        'message': 'API failed with status ${response.statusCode}',
      };
    } catch (e) {
      print('ERROR in _initiateCancellation: $e');
      return {'error': 'true', 'message': e.toString()};
    }
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final bool isKeyboardVisible = keyboardHeight > 0;
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    // Define colors based on theme
    final Color gradientStartColor =
        isDarkMode ? Colors.black : const Color(0xffFFD9BD);
    final Color gradientEndColor =
        isDarkMode ? Colors.black : const Color(0xffFFFFFF);
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color subtitleColor = isDarkMode ? Colors.white70 : Colors.black87;
    final Color greyTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey;
    final Color inputFillColor = isDarkMode ? Colors.grey[800]! : Colors.white;
    final Color inputBorderColor =
        isDarkMode ? Colors.grey[600]! : Colors.black;
    final Color inputFocusedBorderColor =
        isDarkMode ? Colors.white : const Color(0xffEB7720);
    final Color radioActiveColor = const Color(0xffEB7720);
    final Color radioInactiveColor =
        isDarkMode ? Colors.grey[400]! : Colors.black;
    final Color orangeColor = const Color(0xffEB7720);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: orangeColor,
        elevation: 0,
        title: Text(
          "Order Cancellation",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
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
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 20,
                    bottom: isKeyboardVisible ? keyboardHeight + 10 : 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "step 1/2",
                          style: GoogleFonts.poppins(
                            color: greyTextColor,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Cancellation Reason',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: inputBorderColor),
                          borderRadius: BorderRadius.circular(8),
                          color: inputFillColor,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ...reasons.map((reason) {
                              return RadioListTile<String>(
                                title: Text(
                                  reason,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: textColor,
                                  ),
                                ),
                                value: reason,
                                groupValue: selectedReason,
                                onChanged: (value) {
                                  setState(() {
                                    selectedReason = value!;
                                  });
                                },
                                contentPadding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                                activeColor: radioActiveColor,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                tileColor: inputFillColor,
                              );
                            }).toList(),
                            if (selectedReason == "Other Reasons")
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 50,
                                  right: 30,
                                  bottom: 30,
                                ),
                                child: TextField(
                                  controller: otherController,
                                  style: GoogleFonts.poppins(color: textColor),
                                  decoration: InputDecoration(
                                    hintText: "Type Here...",
                                    hintStyle: GoogleFonts.poppins(
                                      color: greyTextColor,
                                    ),
                                    filled: true,
                                    fillColor: inputFillColor,
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: inputBorderColor,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: inputBorderColor,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: inputFocusedBorderColor,
                                      ),
                                    ),
                                  ),
                                  maxLines: 3,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      Center(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.7,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () async {
                              print(
                                '=== CANCELLATION STEP 1 BUTTON PRESSED ===',
                              );
                              print('Order ID: ${widget.orderId}');
                              print('Selected Reason: $selectedReason');

                              setState(() {
                                _isLoading = true;
                              });

                              // First initiate cancellation
                              print('About to call _initiateCancellation...');
                              final initiationResult =
                                  await _initiateCancellation(widget.orderId);
                              print(
                                '_initiateCancellation completed with result: $initiationResult',
                              );

                              setState(() {
                                _isLoading = false;
                              });

                              // Check if API returned success (error: "false" as string)
                              if (initiationResult['error'] == 'false' ||
                                  initiationResult['error'] == false) {
                                print(
                                  'Step 1 API successful, proceeding to Step 2...',
                                );
                                // Proceed to step 2
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => CancellationStep2Page(
                                          orderId: widget.orderId,
                                          cancellationReason:
                                              selectedReason == "Other Reasons"
                                                  ? otherController.text
                                                  : selectedReason,
                                          onCancelConfirmed:
                                              widget.onCancelConfirmed,
                                        ),
                                  ),
                                );
                              } else {
                                print(
                                  'Step 1 API failed: ${initiationResult['message'] ?? 'Unknown error'}',
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Failed to initiate cancellation: ${initiationResult['message'] ?? 'Unknown error'}',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              backgroundColor: orangeColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              'Proceed',
                              style: GoogleFonts.poppins(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}

class CancellationStep2Page extends StatefulWidget {
  final String orderId;
  final String cancellationReason;
  final VoidCallback? onCancelConfirmed;

  const CancellationStep2Page({
    super.key,
    required this.orderId,
    required this.cancellationReason,
    this.onCancelConfirmed,
  });

  @override
  State<CancellationStep2Page> createState() => _CancellationStep2PageState();
}

class _CancellationStep2PageState extends State<CancellationStep2Page> {
  final TextEditingController bankNameController = TextEditingController();
  final TextEditingController accountNumberController = TextEditingController();
  final TextEditingController ifscController = TextEditingController();
  final TextEditingController holderNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    bankNameController.dispose();
    accountNumberController.dispose();
    ifscController.dispose();
    holderNameController.dispose();
    super.dispose();
  }

  // API call to submit cancellation with bank details (Step 2 API - type: 1017)
  Future<Map<String, dynamic>> _submitCancellationWithBankDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      double? latitude = prefs.getDouble('latitude');
      double? longitude = prefs.getDouble('longitude');
      String? deviceId = prefs.getString('device_id');

      final cusId = prefs.getInt('cus_id')?.toString() ?? '';

      print('=== STEP 2: SUBMITTING BANK DETAILS ===');
      print('Order ID: ${widget.orderId}');
      print('Customer ID: $cusId');
      print('Cancellation Reason: ${widget.cancellationReason}');
      print('Bank Name: ${bankNameController.text}');
      print('Account Number: ${accountNumberController.text}');
      print('IFSC: ${ifscController.text}');
      print('Holder Name: ${holderNameController.text}');

      final requestBody = {
        'cid': '85788578',
        'cus_id': cusId,
        'lt': latitude?.toString() ?? '',
        'ln': longitude?.toString() ?? '',
        'device_id': deviceId ?? '',
        'type': '1028',
        'order_id': widget.orderId,
        'order_status': 'cancel',
        'cancellation_reason': widget.cancellationReason,
        'cancelled_by': holderNameController.text,
        'acc_num': accountNumberController.text,
        'bank_name': bankNameController.text,
        'holder_name': holderNameController.text,
        'acc_ifsc': ifscController.text,
        'refund_status': 'not yet',
      };

      print('Request Body: $requestBody');

      final response = await http
          .post(
            Uri.parse('https://erpsmart.in/total/api/m_api/'),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: requestBody,
          )
          .timeout(const Duration(seconds: 15));

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print('Parsed Response: $jsonResponse');
        return jsonResponse;
      }
      return {
        'error': true,
        'message': 'API failed with status ${response.statusCode}',
      };
    } catch (e) {
      print('ERROR in _submitCancellationWithBankDetails: $e');
      return {'error': true, 'message': e.toString()};
    }
  }

  // API call to fetch cancelled order details (type: 1016)
  Future<Map<String, dynamic>> _fetchCancelledOrderDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cusId = prefs.getInt('cus_id')?.toString() ?? '';

      print('=== STEP 3: FETCHING CANCELLED ORDER DETAILS ===');
      print('Order ID: ${widget.orderId}');
      print('Customer ID: $cusId');

      final requestBody = {
        'cid': '23262954',
        'cus_id': cusId,
        'device_id': '345343',
        'ln': '2324',
        'lt': '23',
        'type': '1016',
        'order_id': widget.orderId,
      };

      print('Request Body: $requestBody');

      final response = await http
          .post(
            Uri.parse('https://sgserp.in/erp/api/m_api/'),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: requestBody,
          )
          .timeout(const Duration(seconds: 15));

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print('Parsed Response: $jsonResponse');
        return jsonResponse;
      }
      return {
        'error': true,
        'message': 'API failed with status ${response.statusCode}',
      };
    } catch (e) {
      print('ERROR in _fetchCancelledOrderDetails: $e');
      return {'error': true, 'message': e.toString()};
    }
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final bool isKeyboardVisible = keyboardHeight > 0;
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    final Color gradientStartColor =
        isDarkMode ? Colors.black : const Color(0xffFFD9BD);
    final Color gradientEndColor =
        isDarkMode ? Colors.black : const Color(0xffFFFFFF);
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color subtitleColor = isDarkMode ? Colors.white70 : Colors.black87;
    final Color greyTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey;
    final Color inputFillColor = isDarkMode ? Colors.grey[800]! : Colors.white;
    final Color inputBorderColor =
        isDarkMode ? Colors.grey[600]! : Colors.grey.shade400;
    final Color inputFocusedBorderColor =
        isDarkMode ? Colors.white : const Color(0xffEB7720);
    final Color orangeColor = const Color(0xffEB7720);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: orangeColor,
        elevation: 0,
        title: Text(
          "Order Cancellation",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
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
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 20,
                    bottom: isKeyboardVisible ? keyboardHeight + 10 : 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "step 2/2",
                          style: GoogleFonts.poppins(
                            color: greyTextColor,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Enter Bank Details',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '(Note: The cancellation amount will be refunded to your bank account shortly. So enter bank details carefully)',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: subtitleColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        child: TextField(
                          controller: bankNameController,
                          style: GoogleFonts.poppins(color: textColor),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: inputFillColor,
                            hintText: 'Bank name',
                            hintStyle: GoogleFonts.poppins(
                              color: greyTextColor,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: inputBorderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: inputBorderColor),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: inputFocusedBorderColor,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        child: TextField(
                          controller: accountNumberController,
                          style: GoogleFonts.poppins(color: textColor),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: inputFillColor,
                            hintText: 'Bank Account number',
                            hintStyle: GoogleFonts.poppins(
                              color: greyTextColor,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: inputBorderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: inputBorderColor),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: inputFocusedBorderColor,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        child: TextField(
                          controller: ifscController,
                          style: GoogleFonts.poppins(color: textColor),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: inputFillColor,
                            hintText: 'IFSC code',
                            hintStyle: GoogleFonts.poppins(
                              color: greyTextColor,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: inputBorderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: inputBorderColor),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: inputFocusedBorderColor,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        child: TextField(
                          controller: holderNameController,
                          style: GoogleFonts.poppins(color: textColor),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: inputFillColor,
                            hintText: 'Account holder name',
                            hintStyle: GoogleFonts.poppins(
                              color: greyTextColor,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: inputBorderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: inputBorderColor),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: inputFocusedBorderColor,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Center(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.7,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (bankNameController.text.isEmpty ||
                                  accountNumberController.text.isEmpty ||
                                  ifscController.text.isEmpty ||
                                  holderNameController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Please fill all bank details.',
                                      style: GoogleFonts.poppins(),
                                    ),
                                  ),
                                );
                                return;
                              }

                              setState(() {
                                _isLoading = true;
                              });

                              // Submit cancellation with bank details
                              final result =
                                  await _submitCancellationWithBankDetails();

                              // If submission successful, fetch the cancelled order details
                              if (result['error'] == false ||
                                  result['error'] == 'false') {
                                // Fetch cancelled order details for confirmation
                                final fetchResult =
                                    await _fetchCancelledOrderDetails();

                                setState(() {
                                  _isLoading = false;
                                });

                                if (fetchResult['error'] == false ||
                                    fetchResult['error'] == 'false') {
                                  debugPrint(
                                    'Cancellation process completed successfully',
                                  );
                                  debugPrint(
                                    'Cancelled order details: ${fetchResult['data']}',
                                  );
                                }

                                // Success - update local state and navigate back
                                if (widget.onCancelConfirmed != null) {
                                  widget.onCancelConfirmed!();
                                }

                                final orderModel = Provider.of<OrderModel>(
                                  context,
                                  listen: false,
                                );
                                orderModel.updateOrderStatus(
                                  widget.orderId,
                                  OrderStatus.cancelled,
                                );

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Order ${widget.orderId} cancelled successfully!',
                                      style: GoogleFonts.poppins(),
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );

                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const MyOrder(),
                                  ),
                                  (Route<dynamic> route) => false,
                                );
                              } else {
                                setState(() {
                                  _isLoading = false;
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Failed to cancel order: ${result['message'] ?? 'Unknown error'}',
                                      style: GoogleFonts.poppins(),
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              backgroundColor: orangeColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              'Verify & Submit',
                              style: GoogleFonts.poppins(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
