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

  static const String _cartApiUrl = 'https://sgserp.in/erp/api/m_api/';
  static const String _cid = '23262954';
  static const String _ln = '322334';
  static const String _lt = '233432';
  static const String _deviceId = '122334';

  List<CartItem> get items => List.unmodifiable(_items);
  double get totalAmount => _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  int get totalItemCount => _items.length;

  CartModel() {
    _loadFuture = _initializeCart();
  }

  Future<void> _initializeCart() async {
    await _loadCusId();

    if (_cusId != null) {
      await _loadCartFromApi();
      if (_items.isEmpty) {
        await _loadCartItemsFromDb();
      }
    } else {
      await _loadCartItemsFromDb();
    }
    notifyListeners();
  }

  Future<void> _loadCartFromApi() async {
    if (_cusId == null) return;

    try {
      final response2023 = await _callCartApi(
        type: '2023',
        productId: '0',
        productName: '',
      );

      if (response2023['error'] == false && response2023['data'] is List) {
        await _processApiResponse(response2023['data']);
        return;
      }

      final response2011 = await _callCartApi(
        type: '2011',
        productId: '0',
        productName: 'dummy',
        quantity: 0,
      );

      if (response2011['error'] == 'false' && response2011['cart'] is List) {
        await _processApiResponse(response2011['cart']);
      }
    } catch (e) {
      debugPrint('Error loading cart from API: $e');
    }
  }

  Future<void> _processApiResponse(List<dynamic> apiItems) async {
    _items.clear();
    if (_cusId == null) return;

    await _dbHelper.clearCart(_cusId.toString());

    final validItems = apiItems.where((item) =>
    item['pro_id'] != null && item['pro_name'] != null).toList();

    for (var itemData in validItems) {
      final productId = (itemData['pro_id'] as num).toInt();
      final product = ProductService.getProductById(productId.toString());

      double price = 0.0;
      if (product != null) {
        price = product.sellingPricePerSelectedUnit ?? 0.0;
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
    }
  }

  Future<bool> confirmOrderWithApi(String orderId) async {
    try {
      final response = await _callOrderApi(
        type: '2020',
        orderId: orderId,
      );

      debugPrint('Order confirmation API response: $response');

      // Handle both string 'false' and boolean false
      return response['error'] == 'false' || response['error'] == false;
    } catch (e) {
      debugPrint('Error confirming order with API: $e');
      return false;
    }
  }
  Future<bool> cancelOrderWithApi(String orderId) async {
    try {
      final response = await _callOrderApi(
        type: '2021',
        orderId: orderId,
      );

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

    if (cusId.isEmpty) {
      return {'error': true, 'message': 'No cus_id available'};
    }

    final body = {
      'cid': _cid,
      'type': type,
      'ln': '2324',
      'lt': '23',
      'device_id': '1223',
      'cus_id': cusId,
    };

    if (orderId != null) {
      body['order_id'] = orderId;
    }

    try {
      final response = await http.post(
        Uri.parse(_cartApiUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'error': true, 'message': 'API failed'};
    } catch (e) {
      return {'error': true, 'message': e.toString()};
    }
  }

  Future<void> _loadCartItemsFromDb() async {
    try {
      _items.clear();
      final dbItems = await _dbHelper.getCartItems(_cusId?.toString() ?? 'guest');

      for (var item in dbItems) {
        final product = ProductService.getProductById(item.proId.toString());
        if (product != null) {
          item.title = product.title;
          item.subtitle = product.subtitle;
          item.imageUrl = product.imageUrl;
          item.category = product.category;
          item.selectedUnitSize = product.selectedUnit.size;
          item.pricePerUnit = product.sellingPricePerSelectedUnit ?? 0.0;
        }

        _items.add(item);
        item.addListener(() => _updateItemInDb(item));
      }
    } catch (e) {
      debugPrint('Error loading from DB: $e');
    }
  }

  Future<void> _loadCusId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cusId = prefs.getInt('cus_id');
    } catch (e) {
      debugPrint('Error loading cus_id: $e');
    }
  }

  Future<void> _ensureLoaded() async {
    if (_loadFuture != null) {
      await _loadFuture;
      _loadFuture = null;
    }
  }

  Future<void> _updateItemInDb(CartItem item) async {
    try {
      await _dbHelper.insertCartItem(item);
    } catch (e) {
      debugPrint('Error updating item in DB: $e');
    }
  }

  Future<Map<String, dynamic>> _callCartApi({
    required String type,
    required String productId,
    required String productName,
    int? quantity,
    String? action,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cusId = prefs.getInt('cus_id')?.toString() ?? '';

    if (cusId.isEmpty) {
      return {'error': true, 'message': 'No cus_id'};
    }

    final body = {
      'cid': _cid,
      'type': type,
      'cus_id': cusId,
    };

    if (type == '2011' || type == '2012') {
      body.addAll({
        'ln': _ln,
        'lt': _lt,
        'device_id': _deviceId,
        'pro_id': productId,
        'pro_name': productName,
      });
      if (quantity != null) body['qty'] = quantity.toString();
      if (action != null) body['action'] = action;
    } else if (type == '2023') {
      body.addAll({
        'ln': '2324',
        'lt': '23',
        'device_id': '122',
      });
    }

    try {
      final response = await http.post(
        Uri.parse(_cartApiUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'error': true, 'message': 'API failed'};
    } catch (e) {
      return {'error': true, 'message': e.toString()};
    }
  }

  // Add this method to check if an item exists in the cart
  bool containsItem(int proId) {
    final prefs = SharedPreferences.getInstance().then((prefs) {
      final cusId = prefs.getInt('cus_id')?.toString() ?? '';
      return _items.any((item) => item.proId == proId && item.cusId == cusId);
    });
    return false; // Temporary return, will be handled asynchronously
  }

  // Better async version of containsItem
  Future<bool> containsItemAsync(int proId) async {
    await _ensureLoaded();
    final prefs = await SharedPreferences.getInstance();
    final cusId = prefs.getInt('cus_id')?.toString() ?? '';
    return _items.any((item) => item.proId == proId && item.cusId == cusId);
  }

  Future<void> addItem(Product product, {int quantity = 1}) async {
    await _ensureLoaded();

    final prefs = await SharedPreferences.getInstance();
    final cusId = prefs.getInt('cus_id')?.toString() ?? '';

    if (cusId.isEmpty) return;

    final existingItem = _items.firstWhereOrNull(
          (item) => item.proId == product.selectedUnit.proId && item.cusId == cusId,
    );

    if (existingItem != null) {
      await updateItemQuantity(existingItem.proId, existingItem.quantity + quantity);
    } else {
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
      cartItem.addListener(() => _updateItemInDb(cartItem));
      await _dbHelper.insertCartItem(cartItem);

      await _callCartApi(
        type: '2011',
        productId: cartItem.proId.toString(),
        productName: cartItem.title,
        quantity: cartItem.quantity,
      );
    }
    notifyListeners();
  }

  Future<void> updateItemQuantity(int proId, int newQuantity) async {
    await _ensureLoaded();

    final prefs = await SharedPreferences.getInstance();
    final cusId = prefs.getInt('cus_id')?.toString() ?? '';

    if (cusId.isEmpty || newQuantity < 1) return;

    final item = _items.firstWhereOrNull(
          (i) => i.proId == proId && i.cusId == cusId,
    );

    if (item != null) {
      final oldQuantity = item.quantity;
      item.quantity = newQuantity;
      await _updateItemInDb(item);

      final response = await _callCartApi(
        type: '2011',
        productId: proId.toString(),
        productName: item.title,
        quantity: newQuantity,
        action: newQuantity < oldQuantity ? 'minus' : null,
      );

      if (response['error'] != 'false') {
        item.quantity = oldQuantity;
        await _dbHelper.insertCartItem(item);
      }
      notifyListeners();
    }
  }

  Future<void> removeItem(int proId) async {
    await _ensureLoaded();

    final prefs = await SharedPreferences.getInstance();
    final cusId = prefs.getInt('cus_id')?.toString() ?? '';

    if (cusId.isEmpty) return;

    final index = _items.indexWhere(
          (item) => item.proId == proId && item.cusId == cusId,
    );

    if (index != -1) {
      final item = _items[index];
      item.removeListener(() => _updateItemInDb(item));
      _items.removeAt(index);
      await _dbHelper.removeCartItem(item.cusId, item.proId);

      await _callCartApi(
        type: '2012',
        productId: proId.toString(),
        productName: item.title,
      );
      notifyListeners();
    }
  }

  Future<void> clearCart() async {
    await _ensureLoaded();

    final prefs = await SharedPreferences.getInstance();
    final cusId = prefs.getInt('cus_id')?.toString() ?? '';

    if (cusId.isEmpty) return;

    for (var item in _items) {
      item.removeListener(() => _updateItemInDb(item));
    }
    _items.clear();
    await _dbHelper.clearCart(cusId);

    // Clear cart from API
    await _callCartApi(
      type: '2012',
      productId: '0',
      productName: 'clear_all',
    );

    notifyListeners();
  }

  Future<void> addProductsFromOrder(List<OrderedProduct> products) async {
    await _ensureLoaded();

    final prefs = await SharedPreferences.getInstance();
    final cusId = prefs.getInt('cus_id')?.toString() ?? '';

    if (cusId.isEmpty) return;

    for (var product in products) {
      final proId = int.tryParse(product.id) ?? 0;
      final existingItem = _items.firstWhereOrNull(
            (item) => item.proId == proId && item.cusId == cusId,
      );

      if (existingItem != null) {
        existingItem.quantity += product.quantity;
        await _updateItemInDb(existingItem);
      } else {
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
      }
    }
    notifyListeners();
  }

  Future<void> refreshCartFromAPI() async {
    await _loadCartFromApi();
    notifyListeners();
  }
}