import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:kisangro/models/order_model.dart';
import 'package:kisangro/models/cart_model.dart';
import 'package:kisangro/models/wishlist_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('kisangro_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onOpen: (db) async {
        // Verify all tables exist
        await _verifyTables(db);
      },
    );
  }

  Future<void> _verifyTables(Database db) async {
    try {
      await db.rawQuery('SELECT 1 FROM orders LIMIT 1');
      await db.rawQuery('SELECT 1 FROM ordered_products LIMIT 1');
      await db.rawQuery('SELECT 1 FROM cart_items LIMIT 1');
      await db.rawQuery('SELECT 1 FROM wishlist_items LIMIT 1');
    } on DatabaseException catch (e) {
      if (e.isNoSuchTableError()) {
        debugPrint('Missing tables detected, recreating database...');
        await db.close();
        await deleteDatabase(join(await getDatabasesPath(), 'kisangro_app.db'));
        _database = await _initDB('kisangro_app.db');
      } else {
        rethrow;
      }
    }
  }

  Future _createDB(Database db, int version) async {
    // Create orders table
    await db.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        orderDate INTEGER NOT NULL,
        deliveredDate INTEGER,
        status TEXT NOT NULL,
        totalAmount REAL NOT NULL,
        paymentMethod TEXT NOT NULL
      )
    ''');

    // Create ordered_products table
    await db.execute('''
      CREATE TABLE ordered_products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        orderId TEXT NOT NULL,
        productId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        imageUrl TEXT NOT NULL,
        category TEXT NOT NULL,
        unit TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        FOREIGN KEY (orderId) REFERENCES orders(id) ON DELETE CASCADE
      )
    ''');

    // Create cart_items table
    await db.execute('''
      CREATE TABLE cart_items (
        cus_id TEXT NOT NULL,
        pro_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        subtitle TEXT NOT NULL,
        imageUrl TEXT NOT NULL,
        category TEXT NOT NULL,
        selectedUnitSize TEXT NOT NULL,
        pricePerUnit REAL NOT NULL,
        quantity INTEGER NOT NULL,
        PRIMARY KEY (cus_id, pro_id)
      )
    ''');

    // Create wishlist_items table
    await db.execute('''
      CREATE TABLE wishlist_items (
        cus_id TEXT NOT NULL,
        pro_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        subtitle TEXT NOT NULL,
        imageUrl TEXT NOT NULL,
        category TEXT NOT NULL,
        selectedUnitSize TEXT NOT NULL,
        pricePerUnit REAL NOT NULL,
        PRIMARY KEY (cus_id, pro_id)
      )
    ''');
  }

  // Order operations
  Future<void> insertOrder(Order order) async {
    final db = await database;
    await db.insert(
      'orders',
      {
        'id': order.id,
        'orderDate': order.orderDate.millisecondsSinceEpoch,
        'deliveredDate': order.deliveredDate?.millisecondsSinceEpoch,
        'status': order.status.name,
        'totalAmount': order.totalAmount,
        'paymentMethod': order.paymentMethod,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    for (var product in order.products) {
      await db.insert(
        'ordered_products',
        {
          'orderId': order.id,
          'productId': product.id,
          'title': product.title,
          'description': product.description,
          'imageUrl': product.imageUrl,
          'category': product.category,
          'unit': product.unit,
          'price': product.price,
          'quantity': product.quantity,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<List<Order>> getOrders() async {
    final db = await database;
    final orderMaps = await db.query('orders');
    List<Order> orders = [];

    for (var orderMap in orderMaps) {
      final productMaps = await db.query(
        'ordered_products',
        where: 'orderId = ?',
        whereArgs: [orderMap['id']],
      );
      List<OrderedProduct> products = productMaps.map((p) => OrderedProduct(
        id: p['productId'] as String,
        title: p['title'] as String,
        description: p['description'] as String,
        imageUrl: p['imageUrl'] as String,
        category: p['category'] as String,
        unit: p['unit'] as String,
        price: p['price'] as double,
        quantity: p['quantity'] as int,
        orderId: p['orderId'] as String,
      )).toList();

      orders.add(Order(
        id: orderMap['id'] as String,
        products: products,
        orderDate: DateTime.fromMillisecondsSinceEpoch(orderMap['orderDate'] as int),
        deliveredDate: orderMap['deliveredDate'] != null
            ? DateTime.fromMillisecondsSinceEpoch(orderMap['deliveredDate'] as int)
            : null,
        status: OrderStatus.values.firstWhere((e) => e.name == orderMap['status']),
        totalAmount: orderMap['totalAmount'] as double,
        paymentMethod: orderMap['paymentMethod'] as String,
      ));
    }
    return orders;
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    final db = await database;
    await db.update(
      'orders',
      {
        'status': status.name,
        'deliveredDate': status == OrderStatus.delivered ? DateTime.now().millisecondsSinceEpoch : null,
      },
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  Future<void> clearOrders() async {
    final db = await database;
    await db.delete('orders');
    await db.delete('ordered_products');
  }

  // Cart operations
  Future<void> insertCartItem(CartItem item) async {
    final db = await database;
    await db.insert(
      'cart_items',
      {
        'cus_id': item.cusId,
        'pro_id': item.proId,
        'title': item.title,
        'subtitle': item.subtitle,
        'imageUrl': item.imageUrl,
        'category': item.category,
        'selectedUnitSize': item.selectedUnitSize,
        'pricePerUnit': item.pricePerUnit,
        'quantity': item.quantity,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateCartItemQuantity(String cusId, int proId, int newQuantity) async {
    final db = await database;
    await db.update(
      'cart_items',
      {'quantity': newQuantity},
      where: 'cus_id = ? AND pro_id = ?',
      whereArgs: [cusId, proId],
    );
  }

  Future<void> removeCartItem(String cusId, int proId) async {
    final db = await database;
    await db.delete(
      'cart_items',
      where: 'cus_id = ? AND pro_id = ?',
      whereArgs: [cusId, proId],
    );
  }

  Future<List<CartItem>> getCartItems(String cusId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cart_items',
      where: 'cus_id = ?',
      whereArgs: [cusId],
    );

    return List.generate(maps.length, (i) {
      return CartItem(
        cusId: maps[i]['cus_id'] as String,
        proId: maps[i]['pro_id'] as int,
        title: maps[i]['title'] as String,
        subtitle: maps[i]['subtitle'] as String,
        imageUrl: maps[i]['imageUrl'] as String,
        category: maps[i]['category'] as String,
        selectedUnitSize: maps[i]['selectedUnitSize'] as String,
        pricePerUnit: maps[i]['pricePerUnit'] as double,
        quantity: maps[i]['quantity'] as int,
      );
    });
  }

  Future<void> clearCart(String cusId) async {
    final db = await database;
    await db.delete(
      'cart_items',
      where: 'cus_id = ?',
      whereArgs: [cusId],
    );
  }

  // Wishlist operations with enhanced error handling
  Future<void> insertWishlistItem(WishlistItem item) async {
    final db = await database;
    try {
      await db.insert(
        'wishlist_items',
        {
          'cus_id': item.cus_id,
          'pro_id': item.pro_id,
          'title': item.title,
          'subtitle': item.subtitle,
          'imageUrl': item.imageUrl,
          'category': item.category,
          'selectedUnitSize': item.selectedUnitSize,
          'pricePerUnit': item.pricePerUnit,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } on DatabaseException catch (e) {
      if (e.isNoSuchTableError()) {
        await _verifyTables(db);
        await insertWishlistItem(item); // Retry after verifying tables
      } else {
        rethrow;
      }
    }
  }

  Future<void> deleteWishlistItem(String cusId, int proId) async {
    final db = await database;
    try {
      await db.delete(
        'wishlist_items',
        where: 'cus_id = ? AND pro_id = ?',
        whereArgs: [cusId, proId],
      );
    } on DatabaseException catch (e) {
      if (e.isNoSuchTableError()) {
        await _verifyTables(db);
      } else {
        rethrow;
      }
    }
  }

  Future<List<WishlistItem>> getWishlistItems(String cusId) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'wishlist_items',
        where: 'cus_id = ?',
        whereArgs: [cusId],
      );

      return List.generate(maps.length, (i) {
        return WishlistItem(
          cus_id: maps[i]['cus_id'] as String,
          pro_id: maps[i]['pro_id'] as int,
          title: maps[i]['title'] as String,
          subtitle: maps[i]['subtitle'] as String,
          imageUrl: maps[i]['imageUrl'] as String,
          category: maps[i]['category'] as String,
          selectedUnitSize: maps[i]['selectedUnitSize'] as String,
          pricePerUnit: maps[i]['pricePerUnit'] as double,
        );
      });
    } on DatabaseException catch (e) {
      if (e.isNoSuchTableError()) {
        await _verifyTables(db);
        return []; // Return empty list after recreating tables
      }
      rethrow;
    }
  }

  Future<bool> isInWishlist(String cusId, int proId) async {
    final db = await database;
    try {
      final count = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM wishlist_items WHERE cus_id = ? AND pro_id = ?',
          [cusId, proId],
        ),
      );
      return count != null && count > 0;
    } on DatabaseException catch (e) {
      if (e.isNoSuchTableError()) {
        await _verifyTables(db);
        return false;
      }
      rethrow;
    }
  }

  Future<void> clearWishlist(String cusId) async {
    final db = await database;
    try {
      await db.delete(
        'wishlist_items',
        where: 'cus_id = ?',
        whereArgs: [cusId],
      );
    } on DatabaseException catch (e) {
      if (e.isNoSuchTableError()) {
        await _verifyTables(db);
      } else {
        rethrow;
      }
    }
  }

  Future<int> getWishlistItemCount(String cusId) async {
    final db = await database;
    try {
      final count = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM wishlist_items WHERE cus_id = ?',
          [cusId],
        ),
      );
      return count ?? 0;
    } on DatabaseException catch (e) {
      if (e.isNoSuchTableError()) {
        await _verifyTables(db);
        return 0;
      }
      rethrow;
    }
  }

  Future<void> printWishlistContents(String cusId) async {
    final db = await database;
    try {
      final items = await db.query(
        'wishlist_items',
        where: 'cus_id = ?',
        whereArgs: [cusId],
      );
      debugPrint('Wishlist contents for $cusId:');
      for (var item in items) {
        debugPrint(' - ${item['title']} (ID: ${item['pro_id']})');
      }
    } on DatabaseException catch (e) {
      if (e.isNoSuchTableError()) {
        await _verifyTables(db);
        debugPrint('Wishlist is empty (table was recreated)');
      } else {
        rethrow;
      }
    }
  }

  Future<void> close() async {
    final db = await database;
    _database = null;
    await db.close();
  }
}

extension DatabaseExceptionExtensions on DatabaseException {
  bool isNoSuchTableError() {
    return toString().contains('no such table');
  }
}