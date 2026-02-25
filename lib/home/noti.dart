import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisangro/home/theme_mode_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

// Imports for mutual navigation
import 'package:kisangro/home/myorder.dart';
import 'package:kisangro/menu/wishlist.dart';
import 'package:kisangro/home/bottom.dart';

import '../common/common_app_bar.dart';

// NotificationProvider for global unread count
class NotificationProvider extends ChangeNotifier {
  bool _hasUnreadNotifications = false;

  bool get hasUnreadNotifications => _hasUnreadNotifications;

  void setUnreadNotifications(bool value) {
    if (_hasUnreadNotifications != value) {
      _hasUnreadNotifications = value;
      notifyListeners();
    }
  }

  void markAllAsRead() {
    _hasUnreadNotifications = false;
    notifyListeners();
  }

  // Load notification state from SharedPreferences
  Future<void> loadNotificationState() async {
    final prefs = await SharedPreferences.getInstance();
    _hasUnreadNotifications = prefs.getBool('hasUnreadNotifications') ?? false;
    notifyListeners();
  }
}

// Product model within notification
class NotificationProduct {
  final String productId;
  final String productName;
  final int qty;
  final double price;
  final double subtotal;

  NotificationProduct({
    required this.productId,
    required this.productName,
    required this.qty,
    required this.price,
    required this.subtotal,
  });

  factory NotificationProduct.fromJson(Map<String, dynamic> json) {
    return NotificationProduct(
      productId: json['product_id']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? 'Unknown Product',
      qty: json['qty'] ?? 0,
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0.0,
      subtotal: (json['subtotal'] is num) ? (json['subtotal'] as num).toDouble() : 0.0,
    );
  }
}

// Data model for a Notification Item
class AppNotification {
  final String id;
  final String title;
  final String message;
  final List<NotificationProduct> products;
  final int totalQty;
  final double totalAmount;
  final String date;
  final String datetime;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.products,
    required this.totalQty,
    required this.totalAmount,
    required this.date,
    required this.datetime,
    this.isRead = false,
  });

  // Convert AppNotification to JSON for SharedPreferences
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'products': products.map((p) => {
      'product_id': p.productId,
      'product_name': p.productName,
      'qty': p.qty,
      'price': p.price,
      'subtotal': p.subtotal,
    }).toList(),
    'total_qty': totalQty,
    'total_amount': totalAmount,
    'date': date,
    'datetime': datetime,
    'isRead': isRead,
  };

  // Create AppNotification from JSON
  factory AppNotification.fromJson(Map<String, dynamic> json) {
    List<NotificationProduct> products = [];
    if (json['products'] != null && json['products'] is List) {
      products = (json['products'] as List)
          .map((p) => NotificationProduct.fromJson(p as Map<String, dynamic>))
          .toList();
    }

    return AppNotification(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? '',
      products: products,
      totalQty: json['total_qty'] ?? 0,
      totalAmount: (json['total_amount'] is num) ? (json['total_amount'] as num).toDouble() : 0.0,
      date: json['date']?.toString() ?? '',
      datetime: json['datetime']?.toString() ?? DateTime.now().toString(),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  // Factory method to create from API response
  factory AppNotification.fromApi(Map<String, dynamic> json) {
    debugPrint('Parsing notification: $json');
    
    List<NotificationProduct> products = [];
    
    // Handle products array
    if (json.containsKey('products') && json['products'] != null) {
      try {
        if (json['products'] is List) {
          products = (json['products'] as List)
              .map((p) {
                if (p is Map<String, dynamic>) {
                  return NotificationProduct(
                    productId: p['product_id']?.toString() ?? '',
                    productName: p['product_name']?.toString() ?? 'Unknown Product',
                    qty: p['qty'] ?? 0,
                    price: (p['price'] is num) ? (p['price'] as num).toDouble() : 0.0,
                    subtotal: (p['subtotal'] is num) ? (p['subtotal'] as num).toDouble() : 0.0,
                  );
                } else {
                  debugPrint('Warning: Product is not a Map: $p');
                  return NotificationProduct(
                    productId: '',
                    productName: 'Unknown',
                    qty: 0,
                    price: 0.0,
                    subtotal: 0.0,
                  );
                }
              })
              .toList();
          debugPrint('Parsed ${products.length} products');
        } else {
          debugPrint('Products is not a List: ${json['products'].runtimeType}');
        }
      } catch (e, stackTrace) {
        debugPrint('Error parsing products: $e');
        debugPrint('Stack trace: $stackTrace');
      }
    } else {
      debugPrint('No products key in notification JSON');
    }

    // Parse total_qty - could be int or string
    int totalQty = 0;
    if (json.containsKey('total_qty')) {
      if (json['total_qty'] is int) {
        totalQty = json['total_qty'];
      } else if (json['total_qty'] is String) {
        totalQty = int.tryParse(json['total_qty']) ?? 0;
      }
    }

    // Parse total_amount - could be int or string
    double totalAmount = 0.0;
    if (json.containsKey('total_amount')) {
      if (json['total_amount'] is num) {
        totalAmount = (json['total_amount'] as num).toDouble();
      } else if (json['total_amount'] is String) {
        totalAmount = double.tryParse(json['total_amount']) ?? 0.0;
      }
    }

    // Parse date and datetime
    String date = json['date']?.toString() ?? '';
    String datetime = json['datetime']?.toString() ?? DateTime.now().toString();

    // Parse notification_id - could be int or string
    String id = '';
    if (json.containsKey('notification_id')) {
      if (json['notification_id'] is int) {
        id = json['notification_id'].toString();
      } else if (json['notification_id'] is String) {
        id = json['notification_id'];
      } else {
        id = DateTime.now().millisecondsSinceEpoch.toString();
      }
    } else {
      id = DateTime.now().millisecondsSinceEpoch.toString();
    }

    // Parse title and message
    String title = json['title']?.toString() ?? 'Notification';
    String message = json['message']?.toString() ?? '';

    return AppNotification(
      id: id,
      title: title,
      message: message,
      products: products,
      totalQty: totalQty,
      totalAmount: totalAmount,
      date: date,
      datetime: datetime,
      isRead: false,
    );
  }
}

// Order Arriving Details screen UI
class OrderArrivingDetailsPage extends StatelessWidget {
  final AppNotification notification;

  const OrderArrivingDetailsPage({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    final Color orangeColor = const Color(0xffEB7720);
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color subtitleColor = isDarkMode ? Colors.grey[400]! : Colors.grey[700]!;
    final Color gradientStartColor = isDarkMode ? Colors.black : const Color(0xffFFD9BD);
    final Color gradientEndColor = isDarkMode ? Colors.black : const Color(0xffFFFFFF);
    final Color cardBackgroundColor = isDarkMode ? Colors.grey[900]! : Colors.white;
    final Color dividerColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;

    return WillPopScope(
      onWillPop: () async {
        debugPrint('OrderArrivingDetailsPage: WillPopScope triggered. Popping to previous screen (noti.dart).');
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: "Order Details",
          showBackButton: true,
          showMenuButton: false,
          isMyOrderActive: false,
          isWishlistActive: false,
          isNotiActive: false,
          isDetailPage: true,
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
                Center(
                  child: Text(
                    notification.datetime,
                    style: GoogleFonts.poppins(
                      color: subtitleColor,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: isDarkMode ? Colors.transparent : Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: GoogleFonts.poppins(
                          color: orangeColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (notification.products.isNotEmpty) ...[
                        Text(
                          'Products:',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...notification.products.map((product) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  product.productName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: textColor,
                                  ),
                                ),
                              ),
                              Text(
                                'x${product.qty}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: subtitleColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '₹${product.subtotal.toStringAsFixed(2)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: orangeColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                        const SizedBox(height: 12),
                      ],

                      if (notification.message.isNotEmpty && notification.message != 'null') ...[
                        Text(
                          'Message:',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.message,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: subtitleColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Items:',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: textColor,
                            ),
                          ),
                          Text(
                            notification.totalQty.toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: orangeColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Amount:',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          Text(
                            '₹${notification.totalAmount.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: orangeColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Text(
                        'Date: ${notification.date}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: subtitleColor,
                        ),
                      ),
                      const SizedBox(height: 20),

                      Divider(color: dividerColor, thickness: 1),
                      const SizedBox(height: 16),

                      Text(
                        'Specification',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        notification.message.isNotEmpty && notification.message != 'null'
                            ? notification.message 
                            : 'No additional details available for this notification.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: subtitleColor,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // SizedBox(
                      //   width: double.infinity,
                      //   child: ElevatedButton(
                      //     onPressed: () {
                      //       ScaffoldMessenger.of(context).showSnackBar(
                      //         SnackBar(
                      //           content: Text('Tracking order status...', style: GoogleFonts.poppins()),
                      //           backgroundColor: orangeColor,
                      //         ),
                      //       );
                      //     },
                      //     style: ElevatedButton.styleFrom(
                      //       backgroundColor: orangeColor,
                      //       padding: const EdgeInsets.symmetric(vertical: 16),
                      //       shape: RoundedRectangleBorder(
                      //         borderRadius: BorderRadius.circular(8),
                      //       ),
                      //       elevation: 2,
                      //     ),
                      //     child: Row(
                      //       mainAxisAlignment: MainAxisAlignment.center,
                      //       children: [
                      //         Text(
                      //           'Track Status',
                      //           style: GoogleFonts.poppins(
                      //             color: Colors.white,
                      //             fontSize: 16,
                      //             fontWeight: FontWeight.w600,
                      //           ),
                      //         ),
                      //         const SizedBox(width: 8),
                      //         const Icon(
                      //           Icons.arrow_forward,
                      //           color: Colors.white,
                      //           size: 20,
                      //         ),
                      //       ],
                      //     ),
                      //   ),
                      // ),
                    
                    
                    
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class noti extends StatefulWidget {
  const noti({super.key});

  @override
  State<noti> createState() => _notiState();
}

class _notiState extends State<noti> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  List<AppNotification> _notifications = [];
  bool _hasUnreadNotifications = false;
  bool _isLoading = true;
  String? _errorMessage;
  String? _debugInfo;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _loadNotifications();
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _animationController.forward();
      }
    });
  }

  void _startAnimation() {
    if (_hasUnreadNotifications) {
      if (!_animationController.isAnimating) {
        _animationController.forward();
      }
    } else {
      _animationController.stop();
      _animationController.value = 1.0;
    }
  }

  // ================= FETCH NOTIFICATIONS FROM API =================
  Future<void> _fetchNotificationsFromApi() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get required data for API call
      int? customerId = prefs.getInt('cus_id');
      if (customerId == null) {
        String? cusIdString = prefs.getString('cus_id');
        if (cusIdString != null) {
          customerId = int.tryParse(cusIdString);
        }
      }

      if (customerId == null) {
        debugPrint('Customer ID not available - user might not be logged in');
        setState(() {
          _errorMessage = 'Please login to view notifications';
          _isLoading = false;
        });
        return;
      }

      // Get location and device data
      double? latitude = prefs.getDouble('latitude') ?? 123.0;
      double? longitude = prefs.getDouble('longitude') ?? 12.0;
      String? deviceId = prefs.getString('device_id') ?? '1';

      // Prepare API parameters
      final Map<String, String> params = {
        'cid': '85788578',
        'type': '1035', // Using type 1035 for notifications
        'cus_id': customerId.toString(),
        'lt': latitude.toString(),
        'ln': longitude.toString(),
        'device_id': deviceId,
      };

      debugPrint('Fetching notifications with params: $params');

      // Make API call
      final response = await http.post(
        Uri.parse('https://erpsmart.in/total/api/m_api/'),
        body: params,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('Notification fetch API timeout');
          return http.Response('Timeout', 408);
        },
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);
          debugPrint('Parsed response: $responseData');

          setState(() {
            _debugInfo = 'Response received';
          });

          // Check if response has error field
          if (responseData['error'] == false) {
            final data = responseData['data'] as List? ?? [];
            
            debugPrint('Data array length: ${data.length}');
            
            List<AppNotification> fetchedNotifications = [];
            
            for (var item in data) {
              try {
                if (item is Map<String, dynamic>) {
                  var notification = AppNotification.fromApi(item);
                  fetchedNotifications.add(notification);
                  debugPrint('Successfully parsed notification: ${notification.id} - ${notification.title}');
                } else {
                  debugPrint('Item is not a Map: ${item.runtimeType}');
                }
              } catch (e, stackTrace) {
                debugPrint('Error parsing individual notification: $e');
                debugPrint('Stack trace: $stackTrace');
                debugPrint('Problematic item: $item');
              }
            }

            // Save fetched notifications
            setState(() {
              _notifications = fetchedNotifications;
              _hasUnreadNotifications = _notifications.any((n) => !n.isRead);
              _isLoading = false;
              _errorMessage = null;
              _debugInfo = 'Loaded ${fetchedNotifications.length} notifications';
            });

            // Save to SharedPreferences
            await _saveNotificationsToPrefs(fetchedNotifications);

            // Update global notification state
            final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
            notificationProvider.setUnreadNotifications(_hasUnreadNotifications);

            _startAnimation();
            
            debugPrint('Loaded ${fetchedNotifications.length} notifications from API');
          } else {
            debugPrint('API returned error: ${responseData['message']}');
            setState(() {
              _errorMessage = responseData['message'] ?? 'Failed to load notifications';
              _debugInfo = 'API Error: ${responseData.toString()}';
              _isLoading = false;
            });
          }
        } catch (e, stackTrace) {
          debugPrint('Error parsing notifications: $e');
          debugPrint('Stack trace: $stackTrace');
          setState(() {
            _errorMessage = 'Error parsing notification data';
            // Fixed: Using substring with proper length check
            String truncatedBody = response.body.length > 200 
                ? response.body.substring(0, 200) + '...' 
                : response.body;
            _debugInfo = 'Parse error: $e\nResponse body: $truncatedBody';
            _isLoading = false;
          });
        }
      } else {
        debugPrint('Failed to fetch notifications. Status: ${response.statusCode}');
        setState(() {
          _errorMessage = 'Failed to load notifications (${response.statusCode})';
          _debugInfo = 'HTTP Error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error fetching notifications: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _errorMessage = 'Network error. Please try again.';
        _debugInfo = 'Network error: $e';
        _isLoading = false;
      });
    }
  }

  // Save notifications to SharedPreferences
  Future<void> _saveNotificationsToPrefs(List<AppNotification> notifications) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<Map<String, dynamic>> notificationsJson = 
          notifications.map((n) => n.toJson()).toList();
      String encodedData = json.encode(notificationsJson);
      await prefs.setString('cached_notifications', encodedData);
      
      // Also save the count of unread notifications
      int unreadCount = notifications.where((n) => !n.isRead).length;
      await prefs.setInt('unread_notification_count', unreadCount);
      await prefs.setBool('hasUnreadNotifications', unreadCount > 0);
      
      debugPrint('Saved ${notifications.length} notifications to cache');
    } catch (e) {
      debugPrint('Error saving notifications to cache: $e');
    }
  }

  // Load notifications from cache first, then fetch from API
  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _debugInfo = null;
    });

    final prefs = await SharedPreferences.getInstance();

    // Try to load from cache first
    String? cachedData = prefs.getString('cached_notifications');
    if (cachedData != null && cachedData.isNotEmpty) {
      try {
        List<dynamic> cachedList = json.decode(cachedData);
        List<AppNotification> cachedNotifications = 
            cachedList.map((item) => AppNotification.fromJson(item as Map<String, dynamic>)).toList();
        
        setState(() {
          _notifications = cachedNotifications;
          _hasUnreadNotifications = _notifications.any((n) => !n.isRead);
          _isLoading = false;
          _debugInfo = 'Loaded ${cachedNotifications.length} from cache';
        });

        // Update global notification state
        final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
        notificationProvider.setUnreadNotifications(_hasUnreadNotifications);

        _startAnimation();
        
        debugPrint('Loaded ${cachedNotifications.length} notifications from cache');
      } catch (e) {
        debugPrint('Error loading cached notifications: $e');
      }
    }

    // Always fetch fresh data from API
    await _fetchNotificationsFromApi();
  }

  Future<void> _markAsRead(String notificationId) async {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1 && !_notifications[index].isRead) {
        _notifications[index].isRead = true;
        _hasUnreadNotifications = _notifications.any((n) => !n.isRead);

        // Update global notification state
        final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
        notificationProvider.setUnreadNotifications(_hasUnreadNotifications);

        _startAnimation();

        // Save updated notifications to cache
        _saveNotificationsToPrefs(_notifications);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    final Color orangeColor = const Color(0xffEB7720);
    final Color gradientStartColor = isDarkMode ? Colors.black : const Color(0xffFFD9BD);
    final Color gradientEndColor = isDarkMode ? Colors.black : const Color(0xffFFFFFF);
    final Color itemUnreadColor = isDarkMode ? Colors.grey[800]! : const Color(0xffFFF0E6);
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color subtitleColor = isDarkMode ? Colors.grey[400]! : Colors.grey[700]!;
    final Color dividerColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;

    return WillPopScope(
      onWillPop: () async {
        debugPrint('noti.dart: WillPopScope triggered. Navigating to Bot(initialIndex: 0).');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Bot(initialIndex: 0)),
              (Route<dynamic> route) => false,
        );
        return false;
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: "Notification",
          showBackButton: true,
          showMenuButton: false,
          isMyOrderActive: false,
          isWishlistActive: false,
          isNotiActive: true,
          isDetailPage: false,
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [gradientStartColor, gradientEndColor],
            ),
          ),
          child: Column(
            children: [
              // Header section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Notifications',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    if (_hasUnreadNotifications)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: orangeColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_notifications.where((n) => !n.isRead).length} New',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    
                    // Refresh button
                    IconButton(
                      icon: Icon(Icons.refresh, color: orangeColor),
                      onPressed: () {
                        _loadNotifications();
                      },
                    ),
                  ],
                ),
              ),

              Expanded(
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: orangeColor,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Loading notifications...',
                              style: GoogleFonts.poppins(color: textColor),
                            ),
                          ],
                        ),
                      )
                    : _errorMessage != null
                        ? Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.notifications_off_outlined,
                                    size: 64,
                                    color: subtitleColor,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _errorMessage!,
                                    style: GoogleFonts.poppins(
                                      color: subtitleColor,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (_debugInfo != null) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isDarkMode ? Colors.grey[900]! : Colors.grey[200]!,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Debug: $_debugInfo',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: isDarkMode ? Colors.white70 : Colors.black54,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _loadNotifications,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: orangeColor,
                                    ),
                                    child: Text(
                                      'Retry',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _notifications.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.notifications_none,
                                      size: 80,
                                      color: subtitleColor,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No notifications yet',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'We\'ll notify you when something arrives',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: subtitleColor,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    if (_debugInfo != null) ...[
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isDarkMode ? Colors.grey[900]! : Colors.grey[200]!,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Debug: $_debugInfo',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: isDarkMode ? Colors.white70 : Colors.black54,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: _notifications.length + 1,
                                itemBuilder: (context, index) {
                                  if (index == _notifications.length) {
                                    return _buildBrowseMoreButton(isDarkMode);
                                  }

                                  final notification = _notifications[index];
                                  
                                  // Determine notification type based on title or content
                                  bool isOrderNotification = notification.title.toLowerCase().contains('payment') ||
                                                             notification.products.isNotEmpty;

                                  Widget notificationContentWidget;

                                  if (isOrderNotification) {
                                    notificationContentWidget = _buildNotificationItem(
                                      isNew: !notification.isRead,
                                      title: notification.title,
                                      timestamp: notification.datetime,
                                      product: notification.products.isNotEmpty 
                                          ? notification.products.map((p) => p.productName).join(', ')
                                          : '',
                                      description: notification.message ?? 'No description',
                                      isDarkMode: isDarkMode,
                                    );
                                  } else {
                                    notificationContentWidget = _buildMembershipItem(
                                      isNew: !notification.isRead,
                                      title: notification.title,
                                      timestamp: notification.datetime,
                                      description: notification.message ?? '',
                                      additionalText: 'Total: ₹${notification.totalAmount.toStringAsFixed(2)}',
                                      isDarkMode: isDarkMode,
                                    );
                                  }

                                  return Column(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          _markAsRead(notification.id);
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => OrderArrivingDetailsPage(
                                                notification: notification
                                              ),
                                            ),
                                          );
                                        },
                                        child: notificationContentWidget,
                                      ),
                                      Divider(height: 1, thickness: 1, color: dividerColor),
                                    ],
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

  Widget _buildNotificationItem({
    required bool isNew,
    required String title,
    required String timestamp,
    required String product,
    required String description,
    required bool isDarkMode,
  }) {
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color subtitleColor = isDarkMode ? Colors.grey[400]! : Colors.grey[700]!;
    final Color itemUnreadColor = isDarkMode ? Colors.grey[800]! : const Color(0xffFFF0E6);
    final Color orangeColor = const Color(0xffEB7720);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: isNew ? itemUnreadColor : Colors.transparent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isNew)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 8, right: 10),
              decoration: BoxDecoration(
                color: orangeColor,
                shape: BoxShape.circle,
              ),
            )
          else
            const SizedBox(width: 18),

          SizedBox(
            width: 40,
            height: 40,
            child: ClipOval(
              child: Image.asset(
                "assets/logo.png",
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.poppins(
                          color: orangeColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _formatTimestamp(timestamp),
                        style: GoogleFonts.poppins(
                          color: subtitleColor,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (product.isNotEmpty) ...[
                  Text(
                    product,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: textColor,
                    fontWeight: FontWeight.normal,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembershipItem({
    required bool isNew,
    required String title,
    required String timestamp,
    required String description,
    required String additionalText,
    required bool isDarkMode,
  }) {
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color subtitleColor = isDarkMode ? Colors.grey[400]! : Colors.grey[700]!;
    final Color itemUnreadColor = isDarkMode ? Colors.grey[800]! : const Color(0xffFFF0E6);
    final Color orangeColor = const Color(0xffEB7720);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      color: isNew ? itemUnreadColor : Colors.transparent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isNew)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 8, right: 10),
              decoration: BoxDecoration(
                color: orangeColor,
                shape: BoxShape.circle,
              ),
            )
          else
            const SizedBox(width: 18),

          SizedBox(
            width: 40,
            height: 40,
            child: ClipOval(
              child: Image.asset(
                "assets/logo.png",
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.poppins(
                          color: orangeColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _formatTimestamp(timestamp),
                        style: GoogleFonts.poppins(
                          color: subtitleColor,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: textColor,
                    fontWeight: FontWeight.normal,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (additionalText.isNotEmpty && additionalText != 'Total: ₹0.00') ...[
                  const SizedBox(height: 2),
                  Text(
                    additionalText,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: orangeColor,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    // Format timestamp to show relative time or formatted date
    try {
      if (timestamp.contains(' ')) {
        // Handle "2026-02-24 16:55:09" format
        final parts = timestamp.split(' ');
        if (parts.length > 1) {
          final dateParts = parts[0].split('-');
          if (dateParts.length == 3) {
            final timeParts = parts[1].split(':');
            if (timeParts.length >= 2) {
              return '${timeParts[0]}:${timeParts[1]} ${dateParts[2]}/${dateParts[1]}';
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error formatting timestamp: $e');
    }
    
    // Return truncated version if too long
    if (timestamp.length > 20) {
      return timestamp.substring(0, 17) + '...';
    }
    return timestamp;
  }

  Widget _buildBrowseMoreButton(bool isDarkMode) {
    final Color buttonBackgroundColor = const Color(0xffEB7720);
    final Color buttonTextColor = Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      alignment: Alignment.centerRight,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const Bot(initialIndex: 0)),
                (Route<dynamic> route) => false,
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          'Browse More',
          style: GoogleFonts.poppins(
            color: buttonTextColor,
          ),
        ),
      ),
    );
  }
}