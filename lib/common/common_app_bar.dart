import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:kisangro/home/myorder.dart';
import 'package:kisangro/menu/wishlist.dart';
import 'package:kisangro/home/noti.dart';
import 'package:kisangro/home/bottom.dart';
import 'package:kisangro/home/theme_mode_provider.dart';
import 'package:kisangro/models/cart_model.dart';
import 'package:kisangro/models/wishlist_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Notification Provider to manage unread notifications state globally
class NotificationProvider with ChangeNotifier {
  bool _hasUnreadNotifications = false;

  bool get hasUnreadNotifications => _hasUnreadNotifications;

  void setUnreadNotifications(bool value) {
    _hasUnreadNotifications = value;
    notifyListeners();
    saveNotificationState();
  }

  // Load notification state from SharedPreferences
  Future<void> loadNotificationState() async {
    final prefs = await SharedPreferences.getInstance();
    _hasUnreadNotifications = prefs.getBool('hasUnreadNotifications') ?? false;
    notifyListeners();
  }

  // Save notification state to SharedPreferences
  Future<void> saveNotificationState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasUnreadNotifications', _hasUnreadNotifications);
  }
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final bool showMenuButton;
  final bool showWhatsAppIcon;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final bool isMyOrderActive;
  final bool isWishlistActive;
  final bool isNotiActive;
  final bool isDetailPage;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.showBackButton = true,
    this.showMenuButton = false,
    this.showWhatsAppIcon = false,
    this.scaffoldKey,
    this.isMyOrderActive = false,
    this.isWishlistActive = false,
    this.isNotiActive = false,
    this.isDetailPage = false,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  // Helper function to build a highlighted icon with badge
  Widget _buildActionIconWithBadge({
    required String assetPath,
    required double height,
    required double width,
    required bool isActive,
    required VoidCallback onPressed,
    IconData? fontAwesomeIcon,
    int? badgeCount,
    bool showDot = false,
  }) {
    final double effectiveHeight = isActive ? height * 1.2 : height;
    final double effectiveWidth = isActive ? width * 1.2 : width;

    return Stack(
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Padding(
            padding: EdgeInsets.all(isActive ? 0 : 2),
            child: fontAwesomeIcon != null
                ? Icon(fontAwesomeIcon, color: Colors.white, size: effectiveWidth)
                : Image.asset(
              assetPath,
              height: effectiveHeight,
              width: effectiveWidth,
              color: Colors.white,
            ),
          ),
        ),
        if (badgeCount != null && badgeCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(6),
              ),
              constraints: const BoxConstraints(
                minWidth: 14,
                minHeight: 14,
              ),
              child: Text(
                badgeCount > 9 ? '9+' : badgeCount.toString(),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        if (showDot && (badgeCount == null || badgeCount == 0))
          Positioned(
            right: 10,
            top: 10,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final orange = const Color(0xFFEB7720);

    Widget? leadingWidget;
    if (showMenuButton) {
      leadingWidget = IconButton(
        onPressed: () {
          scaffoldKey?.currentState?.openDrawer();
        },
        icon: const Icon(Icons.menu, color: Colors.white),
      );
    } else if (showBackButton) {
      leadingWidget = IconButton(
        onPressed: () {
          if (isDetailPage) {
            debugPrint('CustomAppBar: Back button (isDetailPage: true) triggered. Popping.');
            Navigator.pop(context);
          } else {
            debugPrint('CustomAppBar: Back button (isDetailPage: false) triggered. Navigating to Bot(initialIndex: 0).');
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const Bot(initialIndex: 0)),
                  (Route<dynamic> route) => false,
            );
          }
        },
        icon: const Icon(Icons.arrow_back, color: Colors.white),
      );
    }

    return AppBar(
      backgroundColor: orange,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 0.0,
      automaticallyImplyLeading: false,
      leading: leadingWidget,
      title: Text(
        title,
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 18),
      ),
      actions: [
        // Wishlist icon with badge
        Consumer<WishlistModel>(
          builder: (context, wishlist, child) {
            return _buildActionIconWithBadge(
              assetPath: 'assets/heart.png',
              height: 26,
              width: 26,
              isActive: isWishlistActive,
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => const WishlistPage(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 300),
                  ),
                );
              },
              badgeCount: wishlist.items.length,
            );
          },
        ),

        // Notification icon with dot indicator - using Consumer to listen for changes
        Consumer<NotificationProvider>(
          builder: (context, notificationProvider, child) {
            return _buildActionIconWithBadge(
              assetPath: 'assets/noti.png',
              height: 28,
              width: 28,
              isActive: isNotiActive,
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => const noti(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 300),
                  ),
                );
              },
              showDot: notificationProvider.hasUnreadNotifications,
            );
          },
        ),

        const SizedBox(width: 10),
      ],
    );
  }
}