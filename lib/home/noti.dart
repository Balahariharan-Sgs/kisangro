import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisangro/home/theme_mode_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

// Imports for mutual navigation
import 'package:kisangro/home/myorder.dart';
import 'package:kisangro/menu/wishlist.dart';
import 'package:kisangro/home/bottom.dart';

import '../common/common_app_bar.dart';

// Data model for a Notification Item
class AppNotification {
  final String id;
  final String title;
  final String timestamp;
  final String product;
  final String description;
  final String? additionalText;
  final String type;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.timestamp,
    this.product = '',
    this.description = '',
    this.additionalText,
    required this.type,
    this.isRead = false,
  });

  // Convert AppNotification to JSON for SharedPreferences
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'timestamp': timestamp,
    'product': product,
    'description': description,
    'additionalText': additionalText,
    'type': type,
    'isRead': isRead,
  };

  // Create AppNotification from JSON
  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    id: json['id'] as String,
    title: json['title'] as String,
    timestamp: json['timestamp'] as String,
    product: json['product'] as String,
    description: json['description'] as String,
    additionalText: json['additionalText'] as String?,
    type: json['type'] as String,
    isRead: json['isRead'] as bool,
  );
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
                    notification.timestamp,
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

                      Text(
                        notification.product,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        notification.description,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: subtitleColor,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Text(
                        'Ordered on: ${notification.timestamp}',
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
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: subtitleColor,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Tracking order status...', style: GoogleFonts.poppins()),
                                backgroundColor: orangeColor,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: orangeColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Track Status',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
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

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();

    // Sample notifications
    final List<AppNotification> defaultNotifications = [
      AppNotification(
        id: 'order_1',
        title: 'Order Arriving Today',
        timestamp: 'Friday, 3 November 2024  2:40 pm',
        product: 'AURASTAR',
        description: 'Fungicide | Order Units: 02',
        type: 'order',
        isRead: false,
      ),
      AppNotification(
        id: 'order_2',
        title: 'Order Delivered',
        timestamp: '03/11/2024 2:40 pm',
        product: 'AURASTAR',
        description: 'Fungicide | Order Units: 02',
        type: 'order',
        isRead: true,
      ),
      AppNotification(
        id: 'membership_1',
        title: 'Membership: basic',
        timestamp: '03/11/2024 2:40 pm',
        description: 'Congratulations Smart!',
        additionalText: 'You\'ve become our member in our...',
        type: 'membership',
        isRead: true,
      ),
      AppNotification(
        id: 'new_arrival_1',
        title: 'New Arrival!',
        timestamp: '03/11/2024 2:40 pm',
        description: 'New Product launched on the "Abk',
        additionalText: 'Industries"-your recent search. Bro...',
        type: 'new_arrival',
        isRead: true,
      ),
      AppNotification(
        id: 'promo_1',
        title: 'Special Discount!',
        timestamp: '15/11/2024 10:00 am',
        description: 'Get 20% off on all pesticides this week!',
        type: 'promotion',
        isRead: false,
      ),
    ];

    setState(() {
      _notifications = defaultNotifications;
      _hasUnreadNotifications = _notifications.any((n) => !n.isRead);
    });

    // Update global notification state
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    notificationProvider.setUnreadNotifications(_hasUnreadNotifications);

    _startAnimation();
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
                  ],
                ),
              ),

              Expanded(
                child: ListView.builder(
                  itemCount: _notifications.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _notifications.length) {
                      return _buildBrowseMoreButton(isDarkMode);
                    }

                    final notification = _notifications[index];
                    Widget notificationContentWidget;

                    if (notification.type == 'order') {
                      notificationContentWidget = _buildNotificationItem(
                        isNew: !notification.isRead,
                        title: notification.title,
                        timestamp: notification.timestamp,
                        product: notification.product,
                        description: notification.description,
                        isDarkMode: isDarkMode,
                      );
                    } else if (notification.type == 'membership' || notification.type == 'new_arrival' || notification.type == 'promotion') {
                      notificationContentWidget = _buildMembershipItem(
                        isNew: !notification.isRead,
                        title: notification.title,
                        timestamp: notification.timestamp,
                        description: notification.description,
                        additionalText: notification.additionalText ?? '',
                        isDarkMode: isDarkMode,
                      );
                    } else {
                      notificationContentWidget = Container();
                    }

                    return Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            _markAsRead(notification.id);
                            if (notification.type == 'order') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => OrderArrivingDetailsPage(notification: notification)),
                              );
                            }
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
                        timestamp,
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
                  product,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
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
                        timestamp,
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
                const SizedBox(height: 2),
                Text(
                  additionalText,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
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