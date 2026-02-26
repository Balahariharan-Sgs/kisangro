import 'package:flutter/material.dart';
import 'package:kisangro/common/common_app_bar.dart';
import 'package:kisangro/home/myorder.dart';
import 'package:kisangro/home/noti.dart';
import 'package:kisangro/menu/wishlist.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:kisangro/models/order_model.dart';
import 'package:kisangro/models/cart_model.dart';
import 'package:kisangro/home/cart.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../home/theme_mode_provider.dart';

// Transaction model class
class Transaction {
  final String orderId;
  final String paidUsing;
  final String paymentId;
  final List<TransactionProduct> products;
  final int totalQty;
  final double totalAmount;
  final DateTime transactionDate;

  Transaction({
    required this.orderId,
    required this.paidUsing,
    required this.paymentId,
    required this.products,
    required this.totalQty,
    required this.totalAmount,
    required this.transactionDate,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    // Parse products
    List<TransactionProduct> products = [];
    if (json['products'] != null && json['products'] is List) {
      products = (json['products'] as List)
          .map((p) => TransactionProduct.fromJson(p))
          .toList();
    }

    return Transaction(
      orderId: json['order_id']?.toString() ?? '0',
      paidUsing: json['paid_using']?.toString() ?? 'Unknown',
      paymentId: json['payment_id']?.toString() ?? '',
      products: products,
      totalQty: json['total_qty'] ?? 0,
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      transactionDate: DateTime.now(), // API doesn't provide date, use current
    );
  }
}

class TransactionProduct {
  final String productId;
  final String productName;
  final int qty;
  final double price;
  final double subtotal;
  final String? productImage;

  TransactionProduct({
    required this.productId,
    required this.productName,
    required this.qty,
    required this.price,
    required this.subtotal,
    this.productImage,
  });

  factory TransactionProduct.fromJson(Map<String, dynamic> json) {
    return TransactionProduct(
      productId: json['product_id']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? 'Unknown Product',
      qty: json['qty'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      productImage: json['product_image']?.toString(),
    );
  }
}

class TransactionProvider extends ChangeNotifier {
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchTransactions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final cusId = prefs.getInt('cus_id')?.toString() ?? '26'; // Default to 26

      double? latitude = prefs.getDouble('latitude');
      double? longitude = prefs.getDouble('longitude');
      String? deviceId = prefs.getString('device_id');

      debugPrint('📊 TransactionProvider: Fetching transactions for cus_id: $cusId');
      
      final response = await http.post(
        Uri.parse('https://erpsmart.in/total/api/m_api/'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'cid': '85788578',
          'type': '1029', // Using type 1029 for transactions
          'lt': latitude?.toString() ?? '145',
          'ln': longitude?.toString() ?? '145',
          'device_id': deviceId ?? '12345',
          'cus_id': cusId,
        },
      ).timeout(const Duration(seconds: 15));

      debugPrint('📊 Response status: ${response.statusCode}');
      debugPrint('📊 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        
        if (jsonResponse['error'] == false) {
          final data = jsonResponse['data'] as List? ?? [];
          _transactions = data.map((item) => Transaction.fromJson(item)).toList();
          debugPrint('📊 Loaded ${_transactions.length} transactions');
        } else {
          _error = jsonResponse['message'] ?? 'Failed to fetch transactions';
        }
      } else {
        _error = 'Server error: ${response.statusCode}';
      }
    } catch (e) {
      debugPrint('📊 Error fetching transactions: $e');
      _error = 'Network error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

class TransactionHistoryPage extends StatefulWidget {
  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int entries = 0; // 0 means no limit (show all)
  String history = 'All'; // Default to show all transactions
  List<bool> expanded = [];

  @override
  void initState() {
    super.initState();
    // Fetch transactions when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<TransactionProvider>(context, listen: false);
      provider.fetchTransactions();
    });
  }

  List<Transaction> _filterTransactions(List<Transaction> transactions, String history, int entries) {
    List<Transaction> filtered = List.from(transactions.reversed);

    // Apply time-based filter only if history is not 'All'
    if (history != 'All') {
      final now = DateTime.now();
      DateTime startDate;
      switch (history) {
        case '1 week':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case '1 month':
          startDate = now.subtract(const Duration(days: 30));
          break;
        case '3 months':
          startDate = now.subtract(const Duration(days: 90));
          break;
        default:
          startDate = now.subtract(const Duration(days: 365 * 100));
      }
      filtered = filtered
          .where((transaction) => transaction.transactionDate.isAfter(startDate))
          .toList();
    }

    // Apply entries limit only if entries is not 0
    if (entries > 0) {
      filtered = filtered.take(entries).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    // Define colors based on theme
    final Color gradientStartColor = isDarkMode ? Colors.black : const Color(0xffFFD9BD);
    final Color gradientEndColor = isDarkMode ? Colors.black : const Color(0xffFFFFFF);
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color dropdownBgColor = isDarkMode ? Colors.grey[800]! : Colors.white;
    final Color dropdownBorderColor = isDarkMode ? Colors.grey[600]! : Colors.orange.shade300;
    final Color dropdownIconColor = isDarkMode ? Colors.white70 : Colors.orange;
    final Color cardBgColor = isDarkMode ? Colors.grey[850]! : Colors.white;
    final Color cardBorderColor = isDarkMode ? Colors.grey[700]! : Colors.grey.shade200;
    final Color subtitleColor = isDarkMode ? Colors.white70 : const Color(0xffEB7720);
    final Color greyTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey.shade700;
    final Color orangeColor = const Color(0xffEB7720);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
      appBar: CustomAppBar(
        title: "Transactions",
        showBackButton: true,
        showMenuButton: false,
        isMyOrderActive: false,
        isWishlistActive: false,
        isNotiActive: false,
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            children: [
              Row(
                children: [
                  Text('Entries:',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: textColor)),
                  const SizedBox(width: 6),
                  Container(
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: dropdownBorderColor),
                      borderRadius: BorderRadius.circular(6),
                      color: dropdownBgColor,
                    ),
                    child: DropdownButton<int>(
                      value: entries == 0 ? null : entries,
                      underline: const SizedBox(),
                      hint: Text('All', style: GoogleFonts.poppins(color: textColor)),
                      icon: Icon(Icons.keyboard_arrow_down, color: dropdownIconColor),
                      items: [0, 10, 20, 50, 100]
                          .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e == 0 ? 'All' : '$e', 
                                  style: GoogleFonts.poppins(color: textColor))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => entries = val);
                        }
                      },
                      dropdownColor: dropdownBgColor,
                    ),
                  ),
                  const Spacer(),
                  Text('History:',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: textColor)),
                  const SizedBox(width: 6),
                  Container(
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: dropdownBorderColor),
                      borderRadius: BorderRadius.circular(6),
                      color: dropdownBgColor,
                    ),
                    child: DropdownButton<String>(
                      value: history,
                      underline: const SizedBox(),
                      icon: Icon(Icons.keyboard_arrow_down, color: dropdownIconColor),
                      items: ['All', '1 week', '1 month', '3 months']
                          .map((e) => DropdownMenuItem(
                              value: e, 
                              child: Text(e, style: GoogleFonts.poppins(color: textColor))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => history = val);
                        }
                      },
                      dropdownColor: dropdownBgColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Consumer<TransactionProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(orangeColor),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Loading transactions...',
                              style: GoogleFonts.poppins(color: textColor),
                            ),
                          ],
                        ),
                      );
                    }

                    if (provider.error != null) {
                      return Center(
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
                              'Error: ${provider.error}',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.red,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                provider.fetchTransactions();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: orangeColor,
                              ),
                              child: Text('Retry', 
                                  style: GoogleFonts.poppins(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                    }

                    final filteredTransactions = _filterTransactions(
                      provider.transactions, 
                      history, 
                      entries
                    );

                    if (filteredTransactions.isEmpty) {
                      return Center(
                        child: Text(
                          'No transactions found',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: greyTextColor,
                          ),
                        ),
                      );
                    }

                    // Initialize expanded list
                    if (expanded.length != filteredTransactions.length) {
                      expanded = List<bool>.filled(filteredTransactions.length, false);
                    }

                    return ListView.builder(
                      itemCount: filteredTransactions.length,
                      itemBuilder: (context, index) {
                        final transaction = filteredTransactions[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: _transactionCard(
                            avatarLetter: transaction.products.isNotEmpty
                                ? transaction.products[0].productName[0]
                                : 'T',
                            title: transaction.products.length == 1
                                ? 'To Kisangro Product'
                                : 'To Kisangro Products',
                            subtitle: transaction.products.length == 1
                                ? 'Order: ${transaction.products[0].productName}'
                                : 'Order: Multiple Items',
                            amount: '₹ ${transaction.totalAmount.toStringAsFixed(2)}',
                            paymentMethod: transaction.paidUsing,
                            dateTime: DateFormat('dd/MM/yyyy hh:mm a')
                                .format(transaction.transactionDate),
                            expanded: expanded[index],
                            onToggleExpanded: () {
                              setState(() {
                                expanded[index] = !expanded[index];
                              });
                            },
                            invoiceCallback: () {
                              // Invoice action
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Generating invoice...',
                                      style: GoogleFonts.poppins()),
                                ),
                              );
                            },
                            reorderCallback: () {
                              final cartModel =
                                  Provider.of<CartModel>(context, listen: false);
                              
                              // Convert transaction products to OrderedProduct
                              final orderedProducts = transaction.products.map((p) {
                                return OrderedProduct(
                                  id: p.productId,
                                  title: p.productName,
                                  description: p.productName,
                                  imageUrl: p.productImage ?? '',
                                  category: '',
                                  unit: '1',
                                  price: p.price,
                                  quantity: p.qty,
                                  orderId: transaction.orderId,
                                );
                              }).toList();
                              
                              cartModel.addProductsFromOrder(orderedProducts);
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Order added to cart for reordering!',
                                      style: GoogleFonts.poppins()),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const Cart()));
                            },
                            detailsWidget: transaction.products.length == 1
                                ? _productDetailsWidget(
                                    transaction.products[0], 
                                    transaction.orderId,
                                    isDarkMode)
                                : _multipleItemsDetailsWidget(
                                    transaction, 
                                    isDarkMode),
                            isDarkMode: isDarkMode,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _transactionCard({
    required String avatarLetter,
    required String title,
    required String subtitle,
    required String amount,
    required String paymentMethod,
    required String dateTime,
    required bool expanded,
    required VoidCallback onToggleExpanded,
    required VoidCallback invoiceCallback,
    required VoidCallback reorderCallback,
    Widget? detailsWidget,
    required bool isDarkMode,
  }) {
    String paymentImage;
    switch (paymentMethod) {
      case 'RAZORPAY':
        paymentImage = 'assets/razor_logo.png';
        break;
      case 'Google Pay':
        paymentImage = 'assets/gpay.png';
        break;
      case 'Phone Pe':
        paymentImage = 'assets/phonepay.png';
        break;
      case 'Paytm':
        paymentImage = 'assets/paytm.png';
        break;
      case 'Amazon Pay':
        paymentImage = 'assets/amzpay.png';
        break;
      case 'Apple Pay':
        paymentImage = 'assets/applepay.png';
        break;
      case 'Debit/Credit Card':
        paymentImage = 'assets/debit.png';
        break;
      case 'Net Banking':
        paymentImage = 'assets/netbanking.png';
        break;
      default:
        paymentImage = 'assets/gpay.png';
    }

    final Color cardBgColor = isDarkMode ? Colors.grey[850]! : Colors.white;
    final Color cardBorderColor = isDarkMode ? Colors.grey[700]! : Colors.grey.shade200;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color greyTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey.shade700;
    final Color orangeColor = const Color(0xffEB7720);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
                child: Text(
                  avatarLetter,
                  style: GoogleFonts.poppins(
                    color: orangeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600, fontSize: 16, color: textColor)),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                          color: orangeColor,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('Paid using: ',
                            style: GoogleFonts.poppins(
                                color: greyTextColor)),
                        if (paymentImage.isNotEmpty)
                          Image(image: AssetImage(paymentImage), width: 30, 
                              color: isDarkMode ? Colors.white70 : null),
                        const SizedBox(width: 4),
                        Text(paymentMethod,
                            style: GoogleFonts.poppins(
                                color: greyTextColor)),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                amount,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: orangeColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // ElevatedButton.icon(
              //   onPressed: invoiceCallback,
              //   icon: const Icon(Icons.download, size: 16, color: Colors.white),
              //   label: Text(
              //     'Invoice',
              //     style: GoogleFonts.poppins(color: Colors.white),
              //   ),
              //   style: ElevatedButton.styleFrom(
              //     shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(6)),
              //     backgroundColor: orangeColor,
              //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              //     elevation: 0,
              //   ),
              // ),
              const Spacer(),
              Text(
                dateTime,
                style: GoogleFonts.poppins(color: greyTextColor, fontSize: 12),
              ),
              const SizedBox(width: 8),
              if (detailsWidget != null)
                GestureDetector(
                  onTap: onToggleExpanded,
                  child: Text(
                    expanded ? 'Hide Details ▲' : 'Show Details ▼',
                    style: GoogleFonts.poppins(
                      color: orangeColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          if (expanded && detailsWidget != null) ...[
            const SizedBox(height: 12),
            detailsWidget,
          ],
        ],
      ),
    );
  }

  Widget _productDetailsWidget(TransactionProduct product, String orderId, bool isDarkMode) {
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color greyTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey.shade700;
    final Color imageBgColor = isDarkMode ? Colors.grey[900]! : Colors.grey.shade100;
    final Color orangeColor = const Color(0xffEB7720);

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDarkMode ? Colors.grey[700]! : Colors.white),
                color: imageBgColor,
              ),
              child: product.productImage != null && product.productImage!.startsWith('http')
                  ? Image.network(
                      product.productImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Image.asset('assets/placeholder.png', fit: BoxFit.cover))
                  : Image.asset('assets/placeholder.png', fit: BoxFit.cover,
                      color: isDarkMode ? Colors.white70 : null),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.productName,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 14, color: textColor)),
                  const SizedBox(height: 4),
                  Text(product.productName,
                      style: GoogleFonts.poppins(
                          color: greyTextColor, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('Unit Size: 1',
                      style: GoogleFonts.poppins(
                          color: greyTextColor, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('₹ ${product.price.toStringAsFixed(2)}/piece',
                      style: GoogleFonts.poppins(
                          color: orangeColor, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Ordered Units: ${product.qty}',
                      style: GoogleFonts.poppins(
                          color: greyTextColor, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('Order ID: $orderId',
                      style: GoogleFonts.poppins(
                          color: greyTextColor, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: () {
              final cartModel = Provider.of<CartModel>(context, listen: false);
              final orderedProducts = [
                OrderedProduct(
                  id: product.productId,
                  title: product.productName,
                  description: product.productName,
                  imageUrl: product.productImage ?? '',
                  category: '',
                  unit: '1',
                  price: product.price,
                  quantity: product.qty,
                  orderId: orderId,
                )
              ];
              cartModel.addProductsFromOrder(orderedProducts);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Product added to cart for reordering!',
                      style: GoogleFonts.poppins()),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => const Cart()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: orangeColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: Text(
              'Re-order',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _multipleItemsDetailsWidget(Transaction transaction, bool isDarkMode) {
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color greyTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey.shade700;
    final Color orangeColor = const Color(0xffEB7720);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${transaction.products.length} Items',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: textColor)),
        const SizedBox(height: 6),
        Text(transaction.products.map((p) => p.productName).join(', '),
            style: GoogleFonts.poppins(fontSize: 12, color: greyTextColor)),
        const SizedBox(height: 6),
        Text('Total Cost: ₹ ${transaction.totalAmount.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: orangeColor)),
        const SizedBox(height: 6),
        Text('Order ID: ${transaction.orderId}',
            style: GoogleFonts.poppins(fontSize: 12, color: greyTextColor)),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: () {
              final cartModel = Provider.of<CartModel>(context, listen: false);
              final orderedProducts = transaction.products.map((p) {
                return OrderedProduct(
                  id: p.productId,
                  title: p.productName,
                  description: p.productName,
                  imageUrl: p.productImage ?? '',
                  category: '',
                  unit: '1',
                  price: p.price,
                  quantity: p.qty,
                  orderId: transaction.orderId,
                );
              }).toList();
              
              cartModel.addProductsFromOrder(orderedProducts);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Order added to cart for reordering!',
                      style: GoogleFonts.poppins()),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => const Cart()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: orangeColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: Text(
              'Re-order',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}