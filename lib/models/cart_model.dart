import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:kisangro/models/product_model.dart';
import 'package:kisangro/models/order_model.dart';
import 'package:kisangro/models/database_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kisangro/services/product_service.dart';

class CartItem extends ChangeNotifier {
  final String cusId;
  final int proId;
  String title;
  String subtitle;
  String imageUrl;
  String category;
  String _selectedUnitSize;
  double _pricePerUnit;
  int _quantity;

  CartItem({
    required this.cusId,
    required this.proId,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.category,
    required String selectedUnitSize,
    required double pricePerUnit,
    int quantity = 1,
  })  : _selectedUnitSize = selectedUnitSize,
        _pricePerUnit = pricePerUnit,
        _quantity = quantity;

  String get selectedUnitSize => _selectedUnitSize;
  double get pricePerUnit => _pricePerUnit;
  int get quantity => _quantity;

  double get totalPrice => _pricePerUnit * _quantity;

  set selectedUnitSize(String newUnitSize) {
    if (_selectedUnitSize != newUnitSize) {
      _selectedUnitSize = newUnitSize;
      notifyListeners();
    }
  }

  set pricePerUnit(double newPrice) {
    if (_pricePerUnit != newPrice) {
      _pricePerUnit = newPrice;
      notifyListeners();
    }
  }

  set quantity(int newQuantity) {
    if (_quantity != newQuantity && newQuantity >= 0) {
      _quantity = newQuantity;
      notifyListeners();
    }
  }

  void incrementQuantity() => quantity++;
  void decrementQuantity() {
    if (quantity > 1) quantity--;
  }

  Map<String, dynamic> toJson() => {
    'cus_id': cusId,
    'pro_id': proId,
    'title': title,
    'subtitle': subtitle,
    'imageUrl': imageUrl,
    'category': category,
    'selectedUnitSize': _selectedUnitSize,
    'pricePerUnit': _pricePerUnit,
    'quantity': _quantity,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    cusId: json['cus_id'] as String,
    proId: json['pro_id'] as int,
    title: json['title'] as String,
    subtitle: json['subtitle'] as String,
    imageUrl: json['imageUrl'] as String,
    category: json['category'] as String,
    selectedUnitSize: json['selectedUnitSize'] as String,
    pricePerUnit: json['pricePerUnit'] as double,
    quantity: json['quantity'] as int,
  );

  OrderedProduct toOrderedProduct({required String orderId}) => OrderedProduct(
    id: proId.toString(),
    title: title,
    description: subtitle,
    imageUrl: imageUrl,
    category: category,
    unit: selectedUnitSize,
    price: pricePerUnit,
    quantity: quantity,
    orderId: orderId,
  );
}

class CartModel extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final List<CartItem> _items = [];
  Future<void>? _loadFuture;
  int? _cusId;

  static const String _cartApiUrl = 'https://erpsmart.in/total/api/m_api/';
  static const String _cid = '85788578';
  static const String _ln = '322334';
  static const String _lt = '233432';
  static const String _deviceId = '122334';

  List<CartItem> get items => List.unmodifiable(_items);
  double get totalAmount => _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  int get totalItemCount => _items.length;

  CartModel() {
    debugPrint('=== CART MODEL INITIALIZED ===');
    _loadFuture = _initializeCart();
  }

  Future<void> _initializeCart() async {
    debugPrint('=== _initializeCart() STARTED ===');
    await _loadCusId();

    if (_cusId != null) {
      debugPrint('Customer ID found: $_cusId - Loading cart from API...');
      await _loadCartFromApi();
      if (_items.isEmpty) {
        debugPrint('API cart is empty, loading from local database...');
        await _loadCartItemsFromDb();
      } else {
        debugPrint('API cart loaded with ${_items.length} items');
      }
    } else {
      debugPrint('No Customer ID found, loading from local database...');
      await _loadCartItemsFromDb();
    }
    
    debugPrint('=== Cart initialization complete. Total items: ${_items.length} ===');
    notifyListeners();
  }

  Future<void> _loadCartFromApi() async {
    if (_cusId == null) {
      debugPrint('❌ _loadCartFromApi: _cusId is null, skipping API call');
      return;
    }

    debugPrint('🔄 _loadCartFromApi: Attempting to load cart for cus_id: $_cusId');

    try {
      debugPrint('📡 Making API call with type: 1023 (Get cart details)');
      final response1023 = await _callCartApi(
        type: '1023',
        productId: '0',
        productName: '',
      );

      debugPrint('📥 Response for type 1023:');
      debugPrint('  - Success: ${response1023['error'] == false}');
      debugPrint('  - Error flag: ${response1023['error']}');
      debugPrint('  - Has data: ${response1023['data'] is List}');
      
      if (response1023['error'] == false && response1023['data'] is List) {
        debugPrint('✅ Type 1023 API call successful, processing response...');
        await _processApiResponse(response1023['data']);
        return;
      } else {
        debugPrint('⚠️ Type 1023 API failed or returned error, trying type 1026...');
      }

      debugPrint('📡 Making API call with type: 1026 (Alternative cart API)');
      final response1026 = await _callCartApi(
        type: '1026',
        productId: '0',
        productName: 'dummy',
        quantity: 0,
      );

      debugPrint('📥 Response for type 1026:');
      debugPrint('  - Error flag: ${response1026['error']}');
      debugPrint('  - Has cart: ${response1026['cart'] is List}');
      
      if (response1026['error'] == 'false' && response1026  ['cart'] is List) {
        debugPrint('✅ Type 1026 API call successful, processing response...');
        await _processApiResponse(response1026['cart']);
      } else {
        debugPrint('❌ Both API types failed to load cart data');
      }
    } catch (e) {
      debugPrint('❌ Error loading cart from API: $e');
      debugPrint('🔄 Falling back to local database...');
    }
  }

  Future<void> _processApiResponse(List<dynamic> apiItems) async {
    debugPrint('🔄 _processApiResponse: Processing ${apiItems.length} API items');
    _items.clear();
    
    if (_cusId == null) {
      debugPrint('❌ _cusId is null, cannot process API response');
      return;
    }

    debugPrint('🗑️ Clearing local cart database for cus_id: $_cusId');
    await _dbHelper.clearCart(_cusId.toString());

    final validItems = apiItems.where((item) =>
    item['pro_id'] != null && item['pro_name'] != null).toList();
    
    debugPrint('📋 Found ${validItems.length} valid items out of ${apiItems.length} total');

    for (var i = 0; i < validItems.length; i++) {
      final itemData = validItems[i];
      debugPrint('  📦 Processing item ${i + 1}/${validItems.length}:');
      debugPrint('    - pro_id: ${itemData['pro_id']}');
      debugPrint('    - pro_name: ${itemData['pro_name']}');
      debugPrint('    - sizes: ${itemData['sizes']}');
      debugPrint('    - technical_name: ${itemData['technical_name']}');
      debugPrint('    - cat_id: ${itemData['cat_id']}');
      
      final productId = (itemData['pro_id'] as num).toInt();
      final product = ProductService.getProductById(productId.toString());

      double price = 0.0;
      if (product != null) {
        price = product.sellingPricePerSelectedUnit ?? 0.0;
        debugPrint('    - Product found in ProductService, price: $price');
      } else {
        debugPrint('    - Product NOT found in ProductService');
      }

      final cartItem = CartItem(
        cusId: _cusId.toString(),
        proId: productId,
        title: itemData['pro_name'] ?? 'Unknown',
        subtitle: itemData['technical_name'] ?? '',
        imageUrl: itemData['image'] ?? '',
        category: itemData['cat_id']?.toString() ?? '',
        selectedUnitSize: itemData['sizes'] ?? 'Unit',
        pricePerUnit: price,
        quantity: 1,
      );

      _items.add(cartItem);
      cartItem.addListener(() => _updateItemInDb(cartItem));
      await _dbHelper.insertCartItem(cartItem);
      debugPrint('    ✅ Item added to cart and database');
    }
    
    debugPrint('✅ _processApiResponse completed. Total items in cart: ${_items.length}');
  }

  Future<bool> confirmOrderWithApi(String orderId) async {
    debugPrint('=== confirmOrderWithApi() STARTED ===');
    debugPrint('📡 Confirming order with ID: $orderId');
    
    try {
      final response = await _callOrderApi(
        type: '1025',
        orderId: orderId,
      );

      debugPrint('📥 Order confirmation API response:');
      debugPrint('  - Full response: $response');
      debugPrint('  - Error flag: ${response['error']}');
      debugPrint('  - Error type: ${response['error'].runtimeType}');
      debugPrint('  - Message: ${response['message']}');

      // Handle both string 'false' and boolean false
      final isSuccess = response['error'] == 'false' || response['error'] == false;
      debugPrint('  - Success: $isSuccess');
      
      return isSuccess;
    } catch (e) {
      debugPrint('❌ Error confirming order with API: $e');
      return false;
    }
  }
  
  Future<bool> cancelOrderWithApi(String orderId) async {
    debugPrint('=== cancelOrderWithApi() STARTED ===');
    debugPrint('📡 Cancelling order with ID: $orderId');
    
    try {
      final response = await _callOrderApi(
        type: '1027',
        orderId: orderId,
      );

      debugPrint('📥 Order cancellation API response:');
      debugPrint('  - Error flag: ${response['error']}');
      debugPrint('  - Message: ${response['message']}');

      final isSuccess = response['error'] == 'false';
      debugPrint('  - Success: $isSuccess');
      
      return isSuccess;
    } catch (e) {
      debugPrint('❌ Error cancelling order with API: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> _callOrderApi({
    required String type,
    String? orderId,
  }) async {
    debugPrint('📞 _callOrderApi called:');
    debugPrint('  - Type: $type');
    debugPrint('  - Order ID: $orderId');
    
    final prefs = await SharedPreferences.getInstance();
    final cusId = prefs.getInt('cus_id')?.toString() ?? '';
    final latitude = prefs.getDouble('latitude');
    final longitude = prefs.getDouble('longitude');
    final deviceId = prefs.getString('device_id');

    debugPrint('  - Retrieved cus_id from SharedPreferences: $cusId');

    if (cusId.isEmpty) {
      debugPrint('❌ No cus_id available in SharedPreferences');
      return {'error': true, 'message': 'No cus_id available'};
    }

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

    debugPrint('  - Request body: $body');
    debugPrint('  - API URL: $_cartApiUrl');

    try {
      debugPrint('  - Sending POST request...');
      final response = await http.post(
        Uri.parse(_cartApiUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      ).timeout(const Duration(seconds: 15));

      debugPrint('  - Response status code: ${response.statusCode}');
      debugPrint('  - Response body: ${response.body}');

      if (response.statusCode == 200) {
        final parsedResponse = json.decode(response.body);
        debugPrint('  - Response parsed successfully');
        return parsedResponse;
      }
      
      debugPrint('❌ API failed with status code: ${response.statusCode}');
      return {'error': true, 'message': 'API failed with status ${response.statusCode}'};
    } catch (e) {
      debugPrint('❌ Exception in _callOrderApi: $e');
      return {'error': true, 'message': e.toString()};
    }
  }

  Future<void> _loadCartItemsFromDb() async {
    debugPrint('🔄 _loadCartItemsFromDb: Loading cart from local database');
    
    try {
      _items.clear();
      final cusIdStr = _cusId?.toString() ?? 'guest';
      debugPrint('  - Looking for items with cus_id: $cusIdStr');
      
      final dbItems = await _dbHelper.getCartItems(cusIdStr);
      debugPrint('  - Found ${dbItems.length} items in database');

      for (var i = 0; i < dbItems.length; i++) {
        final item = dbItems[i];
        debugPrint('    📦 Processing DB item ${i + 1}:');
        debugPrint('      - pro_id: ${item.proId}');
        debugPrint('      - title: ${item.title}');
        debugPrint('      - quantity: ${item.quantity}');
        
        final product = ProductService.getProductById(item.proId.toString());
        if (product != null) {
          debugPrint('      - Product found in ProductService');
          item.title = product.title;
          item.subtitle = product.subtitle;
          item.imageUrl = product.imageUrl;
          item.category = product.category;
          item.selectedUnitSize = product.selectedUnit.size;
          item.pricePerUnit = product.sellingPricePerSelectedUnit ?? 0.0;
          debugPrint('      - Updated price: ${item.pricePerUnit}');
        } else {
          debugPrint('      - Product NOT found in ProductService');
        }

        _items.add(item);
        item.addListener(() => _updateItemInDb(item));
        debugPrint('      ✅ Item added to cart');
      }
      
      debugPrint('✅ _loadCartItemsFromDb completed. Total items: ${_items.length}');
    } catch (e) {
      debugPrint('❌ Error loading from DB: $e');
    }
  }

  Future<void> _loadCusId() async {
    debugPrint('🔄 _loadCusId: Loading customer ID from SharedPreferences');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _cusId = prefs.getInt('cus_id');
      
      if (_cusId != null) {
        debugPrint('✅ Customer ID loaded: $_cusId');
      } else {
        debugPrint('⚠️ No customer ID found in SharedPreferences');
      }
    } catch (e) {
      debugPrint('❌ Error loading cus_id: $e');
    }
  }

  Future<void> _ensureLoaded() async {
    debugPrint('🔄 _ensureLoaded: Checking if cart is loaded');
    
    if (_loadFuture != null) {
      debugPrint('  - Cart not loaded yet, waiting for initialization...');
      await _loadFuture;
      _loadFuture = null;
      debugPrint('  - Cart initialization complete');
    } else {
      debugPrint('  - Cart already loaded');
    }
  }

  Future<void> _updateItemInDb(CartItem item) async {
    debugPrint('🔄 _updateItemInDb: Updating item in database');
    debugPrint('  - pro_id: ${item.proId}');
    debugPrint('  - cus_id: ${item.cusId}');
    debugPrint('  - quantity: ${item.quantity}');
    debugPrint('  - price: ${item.pricePerUnit}');
    
    try {
      await _dbHelper.insertCartItem(item);
      debugPrint('  ✅ Item updated in database');
    } catch (e) {
      debugPrint('❌ Error updating item in DB: $e');
    }
  }

  Future<Map<String, dynamic>> _callCartApi({
    required String type,
    required String productId,
    required String productName,
    int? quantity,
    String? action,
  }) async {
    debugPrint('📞 _callCartApi called:');
    debugPrint('  - Type: $type');
    debugPrint('  - Product ID: $productId');
    debugPrint('  - Product Name: $productName');
    debugPrint('  - Quantity: $quantity');
    debugPrint('  - Action: $action');
    
    final prefs = await SharedPreferences.getInstance();
    final cusId = prefs.getInt('cus_id')?.toString() ?? '';

    debugPrint('  - Retrieved cus_id from SharedPreferences: $cusId');

    if (cusId.isEmpty) {
      debugPrint('❌ No cus_id available in SharedPreferences');
      return {'error': true, 'message': 'No cus_id'};
    }

    final body = {
      'cid': _cid,
      'type': type,
      'cus_id': cusId,
    };

    if (type == '1022' || type == '1026') {
      body.addAll({
        'ln': _ln,
        'lt': _lt,
        'device_id': _deviceId,
        'pro_id': productId,
        'pro_name': productName,
      });
      if (quantity != null) {
        body['qty'] = quantity.toString();
        debugPrint('  - Adding quantity to request: $quantity');
      }
      if (action != null) {
        body['action'] = action;
        debugPrint('  - Adding action to request: $action');
      }
    } else if (type == '2023') {
      body.addAll({
        'ln': '2324',
        'lt': '23',
        'device_id': '122',
      });
      debugPrint('  - Using alternative ln/lt/device_id for type 2023');
    }

    debugPrint('  - Full request body: $body');
    debugPrint('  - API URL: $_cartApiUrl');

    try {
      debugPrint('  - Sending POST request...');
      final response = await http.post(
        Uri.parse(_cartApiUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      ).timeout(const Duration(seconds: 15));

      debugPrint('  - Response status code: ${response.statusCode}');
      debugPrint('  - Response body: ${response.body}');

      if (response.statusCode == 200) {
        final parsedResponse = json.decode(response.body);
        debugPrint('  - Response parsed successfully');
        return parsedResponse;
      }
      
      debugPrint('❌ API failed with status code: ${response.statusCode}');
      return {'error': true, 'message': 'API failed with status ${response.statusCode}'};
    } catch (e) {
      debugPrint('❌ Exception in _callCartApi: $e');
      return {'error': true, 'message': e.toString()};
    }
  }

  // Add this method to check if an item exists in the cart
  bool containsItem(int proId) {
    debugPrint('🔄 containsItem (sync) called for pro_id: $proId');
    // Note: This sync method has limitations as it uses async SharedPreferences
    final prefs = SharedPreferences.getInstance().then((prefs) {
      final cusId = prefs.getInt('cus_id')?.toString() ?? '';
      final exists = _items.any((item) => item.proId == proId && item.cusId == cusId);
      debugPrint('  - Item exists (async check): $exists');
      return exists;
    });
    return false; // Temporary return, will be handled asynchronously
  }

  // Better async version of containsItem
  Future<bool> containsItemAsync(int proId) async {
    debugPrint('🔄 containsItemAsync called for pro_id: $proId');
    await _ensureLoaded();
    
    final prefs = await SharedPreferences.getInstance();
    final cusId = prefs.getInt('cus_id')?.toString() ?? '';
    
    debugPrint('  - cus_id: $cusId');
    debugPrint('  - Total items in cart: ${_items.length}');
    
    final exists = _items.any((item) => item.proId == proId && item.cusId == cusId);
    debugPrint('  - Item exists: $exists');
    
    return exists;
  }

  Future<void> addItem(Product product, {int quantity = 1}) async {
    debugPrint('=== addItem() STARTED ===');
    debugPrint('  - Product: ${product.title}');
    debugPrint('  - Product ID: ${product.selectedUnit.proId}');
    debugPrint('  - Quantity: $quantity');
    debugPrint('  - Selected Unit: ${product.selectedUnit.size}');
    debugPrint('  - Price: ${product.sellingPricePerSelectedUnit}');
    
    await _ensureLoaded();

    final prefs = await SharedPreferences.getInstance();
    final cusId = prefs.getInt('cus_id')?.toString() ?? '';

    debugPrint('  - cus_id: $cusId');

    if (cusId.isEmpty) {
      debugPrint('❌ No cus_id available, cannot add item');
      return;
    }

    final existingItem = _items.firstWhereOrNull(
          (item) => item.proId == product.selectedUnit.proId && item.cusId == cusId,
    );

    if (existingItem != null) {
      debugPrint('  - Item already exists in cart, updating quantity...');
      debugPrint('  - Old quantity: ${existingItem.quantity}');
      debugPrint('  - New quantity: ${existingItem.quantity + quantity}');
      
      await updateItemQuantity(existingItem.proId, existingItem.quantity + quantity);
    } else {
      debugPrint('  - Item not in cart, adding new item...');
      
      final cartItem = CartItem( 
        cusId: cusId,
        proId: product.selectedUnit.proId,
        title: product.title,
        subtitle: product.subtitle,
        imageUrl: product.imageUrl,
        category: product.category,
        selectedUnitSize: product.selectedUnit.size,
        pricePerUnit: product.sellingPricePerSelectedUnit ?? 0.0,
        quantity: quantity,
      );

      _items.add(cartItem);
      debugPrint('  - Item added to local cart');
      
      cartItem.addListener(() => _updateItemInDb(cartItem));
      await _dbHelper.insertCartItem(cartItem);
      debugPrint('  - Item saved to database');

      debugPrint('  - Making API call to add item to server cart...');
      final apiResponse = await _callCartApi(
        type: '1022',
        productId: cartItem.proId.toString(),
        productName: cartItem.title,
        quantity: cartItem.quantity,
      );
      
      debugPrint('  - API Response:');
      debugPrint('    - Error: ${apiResponse['error']}');
      debugPrint('    - Message: ${apiResponse['message']}');
    }
    
    debugPrint('✅ addItem completed. Total items in cart: ${_items.length}');
    notifyListeners();
  }

  Future<void> updateItemQuantity(int proId, int newQuantity) async {
    debugPrint('=== updateItemQuantity() STARTED ===');
    debugPrint('  - pro_id: $proId');
    debugPrint('  - newQuantity: $newQuantity');
    
    await _ensureLoaded();

    final prefs = await SharedPreferences.getInstance();
    final cusId = prefs.getInt('cus_id')?.toString() ?? '';

    debugPrint('  - cus_id: $cusId');

    if (cusId.isEmpty || newQuantity < 1) {
      debugPrint('❌ Invalid parameters: cus_id empty or quantity < 1');
      return;
    }

    final item = _items.firstWhereOrNull(
          (i) => i.proId == proId && i.cusId == cusId,
    );

    if (item != null) {
      debugPrint('  - Item found in cart:');
      debugPrint('    - Title: ${item.title}');
      debugPrint('    - Old quantity: ${item.quantity}');
      
      final oldQuantity = item.quantity;
      item.quantity = newQuantity;
      await _updateItemInDb(item);

      debugPrint('  - Making API call to update quantity on server...');
      final response = await _callCartApi(
        type: '1022',
        productId: proId.toString(),
        productName: item.title,
        quantity: newQuantity,
        action: newQuantity < oldQuantity ? 'minus' : null,
      );
      
      debugPrint('  - API Response:');
      debugPrint('    - Error: ${response['error']}');
      debugPrint('    - Message: ${response['message']}');

      if (response['error'] != 'false') {
        debugPrint('⚠️ API update failed, reverting local quantity...');
        item.quantity = oldQuantity;
        await _dbHelper.insertCartItem(item);
        debugPrint('  - Quantity reverted to: $oldQuantity');
      } else {
        debugPrint('✅ API update successful');
      }
      
      notifyListeners();
    } else {
      debugPrint('❌ Item not found in cart');
    }
  }

  Future<void> removeItem(int proId) async {
    debugPrint('=== removeItem() STARTED ===');
    debugPrint('  - pro_id: $proId');
    
    await _ensureLoaded();

    final prefs = await SharedPreferences.getInstance();
    final cusId = prefs.getInt('cus_id')?.toString() ?? '';

    debugPrint('  - cus_id: $cusId');

    if (cusId.isEmpty) {
      debugPrint('❌ No cus_id available, cannot remove item');
      return;
    }

    final index = _items.indexWhere(
          (item) => item.proId == proId && item.cusId == cusId,
    );

    debugPrint('  - Item index found: $index');

    if (index != -1) {
      final item = _items[index];
      debugPrint('  - Item to remove:');
      debugPrint('    - Title: ${item.title}');
      debugPrint('    - Quantity: ${item.quantity}');
      
      item.removeListener(() => _updateItemInDb(item));
      _items.removeAt(index);
      debugPrint('  - Item removed from local cart');
      
      await _dbHelper.removeCartItem(item.cusId, item.proId);
      debugPrint('  - Item removed from database');

      debugPrint('  - Making API call to remove item from server cart...');
      final apiResponse = await _callCartApi(
        type: '1026',
        productId: proId.toString(),
        productName: item.title,
      );
      
      debugPrint('  - API Response:');
      debugPrint('    - Error: ${apiResponse['error']}');
      debugPrint('    - Message: ${apiResponse['message']}');
      
      debugPrint('✅ Item removed. Remaining items: ${_items.length}');
      notifyListeners();
    } else {
      debugPrint('❌ Item not found in cart');
    }
  }

  Future<void> clearCart() async {
    debugPrint('=== clearCart() STARTED ===');
    
    await _ensureLoaded();

    final prefs = await SharedPreferences.getInstance();
    final cusId = prefs.getInt('cus_id')?.toString() ?? '';

    debugPrint('  - cus_id: $cusId');
    debugPrint('  - Items to clear: ${_items.length}');

    if (cusId.isEmpty) {
      debugPrint('❌ No cus_id available, cannot clear cart');
      return;
    }

    for (var item in _items) {
      item.removeListener(() => _updateItemInDb(item));
    }
    _items.clear();
    debugPrint('  - Local cart cleared');
    
    await _dbHelper.clearCart(cusId);
    debugPrint('  - Database cart cleared');

    // Clear cart from API
    debugPrint('  - Making API call to clear cart from server...');
    final apiResponse = await _callCartApi(
      type: '1026',
      productId: '0',
      productName: 'clear_all',
    );
    
    debugPrint('  - API Response:');
    debugPrint('    - Error: ${apiResponse['error']}');
    debugPrint('    - Message: ${apiResponse['message']}');

    debugPrint('✅ Cart cleared successfully');
    notifyListeners();
  }

  Future<void> addProductsFromOrder(List<OrderedProduct> products) async {
    debugPrint('=== addProductsFromOrder() STARTED ===');
    debugPrint('  - Number of products to add: ${products.length}');
    
    await _ensureLoaded();

    final prefs = await SharedPreferences.getInstance();
    final cusId = prefs.getInt('cus_id')?.toString() ?? '';

    debugPrint('  - cus_id: $cusId');

    if (cusId.isEmpty) {
      debugPrint('❌ No cus_id available, cannot add products');
      return;
    }

    for (var i = 0; i < products.length; i++) {
      final product = products[i];
      debugPrint('  📦 Processing product ${i + 1}/${products.length}:');
      debugPrint('    - ID: ${product.id}');
      debugPrint('    - Title: ${product.title}');
      debugPrint('    - Quantity: ${product.quantity}');
      
      final proId = int.tryParse(product.id) ?? 0;
      final existingItem = _items.firstWhereOrNull(
            (item) => item.proId == proId && item.cusId == cusId,
      );

      if (existingItem != null) {
        debugPrint('    - Item exists, updating quantity...');
        debugPrint('    - Old quantity: ${existingItem.quantity}');
        debugPrint('    - Adding quantity: ${product.quantity}');
        debugPrint('    - New quantity: ${existingItem.quantity + product.quantity}');
        
        existingItem.quantity += product.quantity;
        await _updateItemInDb(existingItem);
      } else {
        debugPrint('    - Item not in cart, adding new item...');
        
        final cartItem = CartItem(
          cusId: cusId,
          proId: proId,
          title: product.title,
          subtitle: product.description,
          imageUrl: product.imageUrl,
          category: product.category,
          selectedUnitSize: product.unit,
          pricePerUnit: product.price,
          quantity: product.quantity,
        );
        _items.add(cartItem);
        cartItem.addListener(() => _updateItemInDb(cartItem));
        await _dbHelper.insertCartItem(cartItem);
        debugPrint('    ✅ Item added to cart and database');
      }
    }
    
    debugPrint('✅ addProductsFromOrder completed. Total items in cart: ${_items.length}');
    notifyListeners();
  }

  Future<void> refreshCartFromAPI() async {
    debugPrint('=== refreshCartFromAPI() STARTED ===');
    debugPrint('🔄 Refreshing cart from API...');
    
    await _loadCartFromApi();
    
    debugPrint('✅ Cart refreshed from API. Total items: ${_items.length}');
    notifyListeners();
  }
}