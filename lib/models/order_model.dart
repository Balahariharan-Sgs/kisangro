import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:kisangro/models/product_model.dart';
import 'package:kisangro/models/database_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum OrderStatus {
  pending, // Payment initiated but not confirmed
  booked, // Payment successful, order confirmed
  dispatched, // Order shipped
  delivered, // Order delivered
  cancelled, // Order cancelled
  confirmed, // Order confirmed (similar to booked)
  failed, // Payment failed
}

class OrderedProduct {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String category;
  final String unit;
  final double price;
  final int quantity;
  final String orderId;

  OrderedProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.unit,
    required this.price,
    required this.quantity,
    required this.orderId,
  });

  factory OrderedProduct.fromProduct(
    Product product,
    int quantity,
    String orderId,
  ) {
    return OrderedProduct(
      id: product.mainProductId,
      title: product.title,
      description: product.subtitle,
      imageUrl: product.imageUrl,
      category: product.category,
      unit: product.selectedUnit.size,
      price:
          product.sellingPricePerSelectedUnit ??
          product.pricePerSelectedUnit ??
          0.0,
      quantity: quantity,
      orderId: orderId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'imageUrl': imageUrl,
    'category': category,
    'unit': unit,
    'price': price,
    'quantity': quantity,
    'orderId': orderId,
  };

  factory OrderedProduct.fromJson(Map<String, dynamic> json) => OrderedProduct(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    imageUrl: json['imageUrl'] as String,
    category: json['category'] as String,
    unit: json['unit'] as String,
    price: json['price'] as double,
    quantity: json['quantity'] as int,
    orderId: json['orderId'] as String,
  );
}

class Order {
  final String id;
  final List<OrderedProduct> products;
  final double totalAmount;
  final DateTime orderDate;
  OrderStatus status;
  DateTime? deliveredDate;
  final String paymentMethod;
  
  // Additional fields for cancelled orders
  String? cancellationReason;
  String? refundStatus;
  Map<String, dynamic>? bankData;

  Order({
    required this.id,
    required this.products,
    required this.totalAmount,
    required this.orderDate,
    this.deliveredDate,
    required this.status,
    required this.paymentMethod,
    this.cancellationReason,
    this.refundStatus,
    this.bankData,
    String? paymentId,
  });

  void updateStatus(OrderStatus newStatus) {
    if (status != newStatus) {
      status = newStatus;
      if (newStatus == OrderStatus.delivered) {
        deliveredDate = DateTime.now();
      }
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'products': products.map((product) => product.toJson()).toList(),
    'totalAmount': totalAmount,
    'orderDate': orderDate.toIso8601String(),
    'deliveredDate': deliveredDate?.toIso8601String(),
    'status': status.index,
    'paymentMethod': paymentMethod,
    'cancellationReason': cancellationReason,
    'refundStatus': refundStatus,
    'bankData': bankData,
  };

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json['id'] as String,
    products:
        (json['products'] as List)
            .map((productJson) => OrderedProduct.fromJson(productJson))
            .toList(),
    totalAmount: json['totalAmount'] as double,
    orderDate: DateTime.parse(json['orderDate'] as String),
    deliveredDate:
        json['deliveredDate'] != null
            ? DateTime.parse(json['deliveredDate'] as String)
            : null,
    status: OrderStatus.values[json['status'] as int],
    paymentMethod: json['paymentMethod'] as String,
    cancellationReason: json['cancellationReason'] as String?,
    refundStatus: json['refundStatus'] as String?,
    bankData: json['bankData'] as Map<String, dynamic>?,
  );
}

class OrderModel extends ChangeNotifier {
  final List<Order> _orders = [];
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  static const String _orderApiUrl = 'https://erpsmart.in/total/api/m_api/';
  static const String _cid = '85788578';

  List<Order> get orders => List.unmodifiable(_orders);

  OrderModel() {
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      // IMPORTANT: Always clear local database to ensure fresh API data
      // This ensures we NEVER show products from local storage
      await _dbHelper.clearOrders();
      
      // Clear in-memory orders
      _orders.clear();

      // Load ONLY from API - fetch all order types
      await _loadOrdersFromApi(type: '1031'); // For booked orders
      await _loadCancelledOrdersFromApi(); // For cancelled orders

      // DO NOT load from local DB - we only want API data
      // if (_orders.isEmpty) {
      //   _orders.clear();
      //   _orders.addAll(await _dbHelper.getOrders());
      // }

      // Sort orders by date (newest first)
      _sortOrdersByDate();

      notifyListeners();
      
      debugPrint('✅ Loaded ${_orders.length} orders from API only');
    } catch (e) {
      debugPrint('Error loading orders: $e');
      // Even on error, ensure we have empty list, not local data
      _orders.clear();
      notifyListeners();
    }
  }

  void _sortOrdersByDate() {
    _orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
  }

  // Method to force reload orders from API (call this when debugging)
  Future<void> forceReloadFromApi() async {
    debugPrint('=== FORCE RELOAD FROM API ===');

    // Clear everything
    _orders.clear();
    await _dbHelper.clearOrders();

    // Load fresh from API only
    await _loadOrdersFromApi(type: '1031');
    await _loadCancelledOrdersFromApi();

    debugPrint('Orders after force reload:');
    debugOrderCreationProcess();
    
    notifyListeners();
  }

  // Method to fetch cancelled orders using type 1017
  Future<void> _loadCancelledOrdersFromApi() async {
    try {
      debugPrint('=== LOADING CANCELLED ORDERS FROM API ===');
      final response = await _callOrderApi(type: '1017');

      debugPrint('Raw Cancelled Orders API Response: ${response.toString()}');

      if (response['error'] == false) {
        final dynamic ordersData = response['orders'];

        if (ordersData is List) {
          final apiOrders = List<Map<String, dynamic>>.from(ordersData);
          debugPrint('Found ${apiOrders.length} cancelled orders from API');

          for (int i = 0; i < apiOrders.length; i++) {
            final orderData = apiOrders[i];
            debugPrint('Processing cancelled order ${i + 1}/${apiOrders.length}: $orderData');

            try {
              final order = _parseCancelledOrderFromApi(orderData);
              if (order != null) {
                debugPrint('Successfully parsed cancelled order with ID: ${order.id} (from API)');
                
                // Check if order already exists, if so update it, otherwise add new
                final existingIndex = _orders.indexWhere((o) => o.id == order.id);
                if (existingIndex != -1) {
                  _orders[existingIndex] = order;
                  // Don't save to local DB - we only want API data
                  // await _dbHelper.updateOrderStatus(order.id, order.status);
                } else {
                  _orders.add(order);
                  // Don't save to local DB - we only want API data
                  // await _dbHelper.insertOrder(order);
                }
              } else {
                debugPrint('Failed to parse cancelled order data: $orderData');
              }
            } catch (e, stackTrace) {
              debugPrint('Exception parsing cancelled order: $e');
              debugPrint('Stack trace: $stackTrace');
            }
          }

          _sortOrdersByDate();
          debugPrint('Successfully loaded/updated cancelled orders from API');
          notifyListeners();
        } else {
          debugPrint('Cancelled orders response data is not a List: ${ordersData.runtimeType}');
        }
      } else {
        debugPrint('API returned error for cancelled orders: ${response['message'] ?? 'Unknown error'}');
      }
    } catch (e, stackTrace) {
      debugPrint('Exception in _loadCancelledOrdersFromApi: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  // Parse cancelled order from API response
  Order? _parseCancelledOrderFromApi(Map<String, dynamic> orderData) {
    try {
      debugPrint('--- Parsing Cancelled Order Data ---');
      debugPrint('Raw cancelled order data: $orderData');

      // Extract order_id from cancel_data
      final cancelData = orderData['cancel_data'] as Map<String, dynamic>?;
      if (cancelData == null) {
        debugPrint('No cancel_data found in cancelled order');
        return null;
      }

      final dynamic orderIdRaw = cancelData['order_id'];
      debugPrint('Raw cancelled order_id from API: $orderIdRaw');

      String? orderIdFromApi;
      if (orderIdRaw != null) {
        orderIdFromApi = orderIdRaw.toString();
        debugPrint('Using cancelled API order_id: "$orderIdFromApi"');
      }

      if (orderIdFromApi == null || orderIdFromApi.isEmpty || orderIdFromApi == 'null') {
        debugPrint('Invalid cancelled order_id, skipping this order');
        return null;
      }

      // Parse products
      final dynamic productsRaw = orderData['products'];
      debugPrint('Raw cancelled products data: $productsRaw');

      List<OrderedProduct> products = [];
      if (productsRaw is List) {
        for (var productData in productsRaw) {
          try {
            final orderedProduct = OrderedProduct(
              id: (productData['product_id'] ?? '').toString(),
              title: (productData['product_name'] ?? 'Unknown Product').toString(),
              description: (productData['product_name'] ?? '').toString(),
              imageUrl: '', // API doesn't provide image for cancelled orders
              category: '', // API doesn't provide category
              unit: '1', // Default unit size
              price: _parseDouble(productData['price']),
              quantity: _parseInt(productData['qty']),
              orderId: orderIdFromApi,
            );
            products.add(orderedProduct);
            debugPrint('Added cancelled product: ${orderedProduct.title}');
          } catch (e) {
            debugPrint('Error parsing cancelled product: $e');
          }
        }
      }

      debugPrint('Parsed ${products.length} products for cancelled order');

      // Parse order date (use current date as fallback since API doesn't provide date)
      DateTime orderDate = DateTime.now();

      // Calculate total amount
      double totalAmount = _parseDouble(orderData['total_price']);
      if (totalAmount == 0 && products.isNotEmpty) {
        totalAmount = products.fold(
          0.0,
          (sum, product) => sum + (product.price * product.quantity),
        );
      }
      debugPrint('Cancelled order total amount: $totalAmount');

      // Get cancellation details
      final cancellationReason = cancelData['cancellation_reason'] as String?;
      final refundStatus = cancelData['refund_status'] as String?;
      
      // Get bank data
      final bankData = orderData['bank_data'] as Map<String, dynamic>?;

      final order = Order(
        id: orderIdFromApi, // Using the API order_id directly
        products: products,
        totalAmount: totalAmount,
        orderDate: orderDate,
        status: OrderStatus.cancelled,
        paymentMethod: 'Online', // Default payment method
        cancellationReason: cancellationReason,
        refundStatus: refundStatus,
        bankData: bankData,
      );

      debugPrint('Successfully created cancelled order with ID: "${order.id}" (from API)');
      if (cancellationReason != null) {
        debugPrint('Cancellation reason: $cancellationReason');
      }
      if (refundStatus != null) {
        debugPrint('Refund status: $refundStatus');
      }

      return order;
    } catch (e, stackTrace) {
      debugPrint('Exception in _parseCancelledOrderFromApi: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  // Enhanced order loading with better error handling - Using type 1031 for booked orders
  Future<void> _loadOrdersFromApi({String type = '1031'}) async {
    try {
      debugPrint('=== LOADING ORDERS FROM API ===');
      // Using type 1031 for booked orders
      final response = await _callOrderApi(type: type);

      debugPrint('Raw API Response: ${response.toString()}');

      if (response['status'] == 'success') {
        final dynamic responseData = response['data'];

        if (responseData is List) {
          final apiOrders = List<Map<String, dynamic>>.from(responseData);
          debugPrint('Found ${apiOrders.length} orders from API');

          for (int i = 0; i < apiOrders.length; i++) {
            final orderData = apiOrders[i];
            debugPrint(
              'Processing order ${i + 1}/${apiOrders.length}: $orderData',
            );

            try {
              final order = _parseOrderFromApi(orderData);
              if (order != null) {
                debugPrint('Successfully parsed order with ID: ${order.id} (from API)');
                _orders.add(order);
                // Don't save to local DB - we only want API data
                // await _dbHelper.insertOrder(order);
              } else {
                debugPrint('Failed to parse order data: $orderData');
              }
            } catch (e, stackTrace) {
              debugPrint('Exception parsing order: $e');
              debugPrint('Stack trace: $stackTrace');
            }
          }

          _sortOrdersByDate();
          debugPrint(
            'Successfully loaded ${_orders.length} orders from API into memory',
          );

          // Debug print all loaded orders
          for (var order in _orders) {
            debugPrint(
              'Loaded Order - ID: ${order.id}, Status: ${order.status.name}',
            );
          }

          notifyListeners();
        } else {
          debugPrint(
            'API response data is not a List: ${responseData.runtimeType}',
          );
        }
      } else {
        debugPrint(
          'API returned error: ${response['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Exception in _loadOrdersFromApi: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  // Enhanced parsing with detailed logging - for booked orders
  Order? _parseOrderFromApi(Map<String, dynamic> orderData) {
    try {
      debugPrint('--- Parsing Order Data ---');
      debugPrint('Raw order data: $orderData');

      // Extract order_id from the new format
      final dynamic orderIdRaw = orderData['order_id'];
      debugPrint(
        'Raw order_id from API: $orderIdRaw (type: ${orderIdRaw.runtimeType})',
      );

      String? orderIdFromApi;
      if (orderIdRaw != null) {
        orderIdFromApi = orderIdRaw.toString();
        debugPrint('Using API order_id: "$orderIdFromApi"');
      }

      if (orderIdFromApi == null ||
          orderIdFromApi.isEmpty ||
          orderIdFromApi == 'null') {
        debugPrint('Invalid order_id, skipping this order');
        return null;
      }

      // Parse products from the new format
      final dynamic productsRaw = orderData['products'];
      debugPrint('Raw products data: $productsRaw (type: ${productsRaw.runtimeType})');

      List<OrderedProduct> products = [];
      if (productsRaw is List) {
        for (var productData in productsRaw) {
          try {
            final orderedProduct = OrderedProduct(
              id: (productData['pro_id'] ?? '').toString(),
              title: (productData['product_name'] ?? 'Unknown Product').toString(),
              description: (productData['product_name'] ?? '').toString(), // Using product_name as description
              imageUrl: (productData['product_image'] ?? '').toString(),
              category: '', // API doesn't provide category in this format
              unit: '1', // Default unit size
              price: _parseDouble(productData['price']),
              quantity: _parseInt(productData['qty']), // Note: using 'qty' not 'quantity'
              orderId: orderIdFromApi,
            );
            products.add(orderedProduct);
            debugPrint('Added product: ${orderedProduct.title}');
          } catch (e) {
            debugPrint('Error parsing product: $e');
          }
        }
      }

      debugPrint('Parsed ${products.length} products');

      // Parse order date from the new format
      DateTime orderDate = DateTime.now();
      final dateStr = orderData['order_date'];
      if (dateStr != null) {
        try {
          // Parse date in format "2026-02-23"
          final parts = dateStr.toString().split('-');
          if (parts.length == 3) {
            orderDate = DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            );
          }
          debugPrint('Parsed order date: $orderDate');
        } catch (e) {
          debugPrint('Error parsing date, using current date: $e');
        }
      }

      // Calculate total amount - either from API or from products
      double totalAmount = _parseDouble(orderData['total_price']);
      if (totalAmount == 0 && products.isNotEmpty) {
        totalAmount = products.fold(
          0.0,
          (sum, product) => sum + (product.price * product.quantity),
        );
      }
      debugPrint('Total amount: $totalAmount');

      // Parse status from the new format
      final status = _parseOrderStatus(orderData['order_status']?.toString());
      debugPrint('Parsed status: ${status.name}');

      final order = Order(
        id: orderIdFromApi, // Using the API order_id directly
        products: products,
        totalAmount: totalAmount,
        orderDate: orderDate,
        status: status,
        paymentMethod: 'Online', // Default payment method
      );

      debugPrint('Successfully created order with final ID: "${order.id}" (from API)');
      return order;
    } catch (e, stackTrace) {
      debugPrint('Exception in _parseOrderFromApi: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  // Helper methods for safe parsing
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        debugPrint('Error parsing double from string: $value');
        return 0.0;
      }
    }
    return 0.0;
  }

  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        try {
          return double.parse(value).round();
        } catch (e2) {
          debugPrint('Error parsing int from string: $value');
          return 0;
        }
      }
    }
    return 0;
  }

  OrderStatus _parseOrderStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'captured': // Added captured status
      case 'booked':
      case 'pending':
      case 'confirmed':
        return OrderStatus.booked;
      case 'dispatched':
        return OrderStatus.dispatched;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'failed':
        return OrderStatus.failed;
      default:
        debugPrint('Unknown order status: $status, defaulting to booked');
        return OrderStatus.booked;
    }
  }

  Future<bool> cancelOrderWithApi(String orderId) async {
    try {
      debugPrint('=== CANCEL ORDER WITH API ===');
      debugPrint('Order ID to cancel: $orderId');

      final response = await _callOrderApi(type: '1027', orderId: orderId);

      debugPrint('Cancel order API response: $response');
      return response['error'] == 'false';
    } catch (e) {
      debugPrint('Error cancelling order with API: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> _callOrderApi({
    required String type,
    String? orderId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cusId = prefs.getInt('cus_id')?.toString() ?? '';

    double? latitude = prefs.getDouble('latitude');
    double? longitude = prefs.getDouble('longitude');
    String? deviceId = prefs.getString('device_id');

    final body = {
      'cid': _cid,
      'type': type,
      'lt': latitude?.toString() ?? '',
      'ln': longitude?.toString() ?? '',
      'device_id': deviceId ?? '',
      'cus_id': cusId,
    };

    if (orderId != null) {
      body['order_id'] = orderId;
    }

    try {
      debugPrint('Making API call with body: $body');

      final response = await http
          .post(
            Uri.parse(_orderApiUrl),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: body,
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'error': true, 'message': 'API failed'};
    } catch (e) {
      debugPrint('API call error: $e');
      return {'error': true, 'message': e.toString()};
    }
  }

  void addOrder(Order order) {
    debugPrint('=== ADDING NEW ORDER ===');
    debugPrint('Order ID being added: ${order.id}');
    debugPrint('Order status: ${order.status}');

    // Check if this looks like a generated ID (should not happen now)
    if (order.id.startsWith('ORDER_')) {
      debugPrint('WARNING: Adding order with generated ID instead of API ID');
      debugPrint('This order might not be cancellable via API');
    }

    // Add new order at the beginning of the list (top position)
    _orders.insert(0, order);
    // Don't save to local DB - we only want API data
    // _dbHelper.insertOrder(order);
    notifyListeners();
  }

  // Enhanced status update with better logging
  void updateOrderStatus(String orderId, OrderStatus newStatus) {
    debugPrint('=== UPDATE ORDER STATUS ===');
    debugPrint('Target order ID: "$orderId"');
    debugPrint('New status: ${newStatus.name}');
    debugPrint('Current orders in memory:');

    for (int i = 0; i < _orders.length; i++) {
      final order = _orders[i];
      debugPrint(
        '  [$i] ID: "${order.id}" (${order.id.length} chars), Status: ${order.status.name}',
      );
      debugPrint('      ID Match: ${order.id == orderId}');
    }

    final orderIndex = _orders.indexWhere((order) => order.id == orderId);

    if (orderIndex != -1) {
      debugPrint('Found order at index $orderIndex, updating status');
      _orders[orderIndex].updateStatus(newStatus);
      // Don't update local DB - we only want API data
      // _dbHelper.updateOrderStatus(orderId, newStatus);
      notifyListeners();
      debugPrint('Order status updated successfully');
    } else {
      debugPrint('Order not found in local list');
      debugPrint('Available order IDs:');
      for (var order in _orders) {
        debugPrint('  - "${order.id}"');
      }
    }
  }

  void dispatchAllBookedOrders() {
    for (var order in _orders) {
      if (order.status == OrderStatus.booked) {
        order.updateStatus(OrderStatus.dispatched);
        // Don't update local DB - we only want API data
        // _dbHelper.updateOrderStatus(order.id, OrderStatus.dispatched);
      }
    }
    notifyListeners();
  }

  void deliverOrder(String orderId) {
    updateOrderStatus(orderId, OrderStatus.delivered);
  }

  void cancelOrder(String orderId) {
    updateOrderStatus(orderId, OrderStatus.cancelled);
  }

  void clearOrders() {
    _orders.clear();
    // Don't clear local DB - we're not using it
    // _dbHelper.clearOrders();
    notifyListeners();
  }

  List<Order> getOrdersByStatus(OrderStatus status) {
    final filteredOrders =
        _orders.where((order) => order.status == status).toList();
    // Return filtered orders sorted by date (newest first)
    filteredOrders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
    return filteredOrders;
  }

  Order? getOrderById(String orderId) {
    return _orders.firstWhereOrNull((order) => order.id == orderId);
  }

  // Helper method to get orders sorted by date (newest first)
  List<Order> getOrdersSortedByDate() {
    final sortedOrders = List<Order>.from(_orders);
    sortedOrders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
    return sortedOrders;
  }

  // Method to check if we have the right order ID format
  void validateOrderIds() {
    debugPrint('=== VALIDATE ORDER IDS ===');
    for (var order in _orders) {
      if (order.id.startsWith('ORDER_')) {
        debugPrint(
          'Found generated ID: ${order.id} - This may not work with API',
        );
      } else if (RegExp(r'^ORD-\d+-\d+-\d+$').hasMatch(order.id)) {
        debugPrint('Found API ID format: ${order.id} - Should work with API');
      } else {
        debugPrint('Unknown ID format: ${order.id}');
      }
    }
  }

  // Debug method
  void debugOrderCreationProcess() {
    debugPrint('=== DEBUG ORDER CREATION PROCESS ===');
    debugPrint('Current orders in memory: ${_orders.length} (from API only)');
    for (int i = 0; i < _orders.length; i++) {
      final order = _orders[i];
      debugPrint('[$i] Order ID: "${order.id}" (from API)');
      debugPrint('    Status: ${order.status.name}');
      debugPrint('    Products: ${order.products.length}');
      debugPrint('    Date: ${order.orderDate}');
      if (order.status == OrderStatus.cancelled) {
        debugPrint('    Cancellation Reason: ${order.cancellationReason ?? "N/A"}');
        debugPrint('    Refund Status: ${order.refundStatus ?? "N/A"}');
      }
    }
  }
}