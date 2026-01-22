import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:kisangro/home/theme_mode_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart'; // NEW: Import image_picker

// Import your custom models and services needed by the drawer's logic
import 'package:kisangro/models/kyc_image_provider.dart'; // Your custom KYC image provider
import 'package:kisangro/models/kyc_business_model.dart'; // Import KycBusinessData and KycBusinessDataProvider

// Your existing page imports for drawer navigation targets
import 'package:kisangro/home/membership.dart';
import 'package:kisangro/home/myorder.dart';
import 'package:kisangro/home/noti.dart';
import 'package:kisangro/login/login.dart';
import 'package:kisangro/menu/account.dart';
import 'package:kisangro/menu/ask.dart';
import 'package:kisangro/menu/logout.dart';
import 'package:kisangro/menu/setting.dart';
import 'package:kisangro/menu/transaction.dart';
import 'package:kisangro/menu/wishlist.dart';
// Import the new ThemeModeProvider

class CustomDrawer extends StatefulWidget {
  // Define callbacks for dialogs
  final Function(BuildContext) showComplaintDialog;
  final Function(BuildContext) showLogoutDialog;

  const CustomDrawer({
    super.key,
    required this.showComplaintDialog,
    required this.showLogoutDialog,
  });

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  double _rating = 4.0;
  final TextEditingController _reviewController = TextEditingController();
  static const int maxChars = 100;
  bool _isMembershipActive = false;
  String? _hoveredItem; // Track which menu item is being hovered/pressed

  @override
  void initState() {
    super.initState();
    _checkMembershipStatus();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _checkMembershipStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isActive = prefs.getBool('isMembershipActive') ?? false;
    if (isActive != _isMembershipActive) {
      setState(() {
        _isMembershipActive = isActive;
      });
      debugPrint('Membership status updated in CustomDrawer: $_isMembershipActive');
    }
  }

  // This _showLogoutDialog now calls the callback passed from the parent
  void _showLogoutDialog(BuildContext context) {
    widget.showLogoutDialog(context);
  }

  // This showComplaintDialog now calls the callback passed from the parent
  void showComplaintDialog(BuildContext context) {
    widget.showComplaintDialog(context);
  }

  // NEW: Function to pick an image from camera or gallery (kept for reference, but not used in drawer profile pic)
  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      final bytes = await image.readAsBytes();
      // Update the KycBusinessDataProvider with the new image bytes
      Provider.of<KycBusinessDataProvider>(context, listen: false).setKycBusinessData(shopImageBytes: bytes);
      // Also update the KycImageProvider if it's used elsewhere for temporary display
      Provider.of<KycImageProvider>(context, listen: false).setKycImage(bytes);

      // You can add a success message if needed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated!')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image picking cancelled.')),
        );
      }
    }
  }

  // NEW: Function to show a modal bottom sheet for image source selection (kept for reference)
  void _showImageSourceSelection() {
    final themeMode = Provider.of<ThemeModeProvider>(context, listen: false).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;
    final Color iconColor = const Color(0xffEB7720);
    final Color backgroundColor = isDarkMode ? Colors.grey[900]! : Colors.white;

    showModalBottomSheet(
      context: context,
      backgroundColor: backgroundColor,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.camera_alt, color: iconColor),
                title: Text('Take Photo', style: GoogleFonts.poppins(color: textColor)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: iconColor),
                title: Text('Choose from Gallery', style: GoogleFonts.poppins(color: textColor)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color dottedBorderColor = isDarkMode ? Colors.red.shade300 : Colors.red;
    final Color buttonTextColor = Colors.white70;

    return Consumer<KycBusinessDataProvider>(
      // Use Consumer to rebuild when KYC data changes
      builder: (context, kycBusinessDataProvider, child) {
        final kycData = kycBusinessDataProvider.kycBusinessData;
        final Uint8List? shopImageBytes = kycData?.shopImageBytes;
        final String fullName = kycData?.fullName ?? "Smart"; // Fallback to "Smart"
        final String whatsAppNumber = kycData?.whatsAppNumber ?? "9876543210"; // Fallback number

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Column(
            children: [
              Row(
                children: [
                  // Profile Image (without the edit button/gesture detector)
                  DottedBorder(
                    borderType: BorderType.Circle,
                    color: dottedBorderColor, // Apply theme color
                    strokeWidth: 2,
                    dashPattern: const [6, 3],
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: shopImageBytes != null
                            ? Image.memory(
                          shopImageBytes,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        )
                            : Image.asset(
                          'assets/profile.png',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  // Removed Positioned(Edit Icon Button) from here
                  const SizedBox(width: 16),
                  Expanded( // <--- WRAPPED TEXT IN EXPANDED TO PREVENT OVERFLOW
                    child: Text(
                      "$fullName\n$whatsAppNumber", // Use actual name and number
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textColor, // Apply theme color
                      ),
                      overflow: TextOverflow.ellipsis, // Add ellipsis for long text
                      maxLines: 2, // Allow up to 2 lines
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MembershipDetailsScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffEB7720),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isMembershipActive ? "You Are A Member" : "Not A Member Yet",
                        style: GoogleFonts.poppins(
                          color: buttonTextColor,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward_ios_outlined,
                        color: buttonTextColor,
                        size: 12,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(IconData icon, String label) {
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    return AnimatedMenuItem(
      icon: icon,
      label: label,
      isDarkMode: isDarkMode,
      hoveredItem: _hoveredItem,
      setHoveredItem: (value) => setState(() => _hoveredItem = value),
      onTap: () {
        Navigator.pop(context);

        switch (label) {
          case 'My Account':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MyAccountPage()),
            );
            break;
          case 'My Orders':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MyOrder()),
            );
            break;
          case 'Wishlist':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const WishlistPage()),
            );
            break;
          case 'Transaction History':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TransactionHistoryPage(),
              ),
            );
            break;
          case 'Ask Us!':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AskUsPage()),
            );
            break;
          case 'Rate Us':
            widget.showComplaintDialog(context);
            break;
          case 'Settings':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingsPage()),
            );
            break;
          case 'Logout':
            widget.showLogoutDialog(context);
            break;
          case 'About Us':
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('About Us page coming soon!',
                    style: GoogleFonts.poppins(color: isDarkMode ? Colors.white : Colors.black)),
                backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
              ),
            );
            break;
          case 'Share Kisangro':
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Share functionality coming soon!',
                    style: GoogleFonts.poppins(color: isDarkMode ? Colors.white : Colors.black)),
                backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
              ),
            );
            break;
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    final Color drawerBackgroundColor = isDarkMode ? Colors.black : Colors.white;

    return Drawer(
      backgroundColor: drawerBackgroundColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
                children: [
                  _buildMenuItem(Icons.person_outline, "My Account"),
                  _buildMenuItem(Icons.receipt_long, "My Orders"),
                  _buildMenuItem(Icons.favorite_border, "Wishlist"),
                  _buildMenuItem(Icons.history, "Transaction History"),
                  _buildMenuItem(Icons.headset_mic, "Ask Us!"),
                  _buildMenuItem(Icons.info_outline, "About Us"),
                  _buildMenuItem(Icons.star_border, "Rate Us"),
                  _buildMenuItem(Icons.share_outlined, "Share Kisangro"),
                  _buildMenuItem(Icons.settings_outlined, "Settings"),
                  _buildMenuItem(Icons.logout, "Logout"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedMenuItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final Function() onTap;
  final bool isDarkMode;
  final String? hoveredItem;
  final Function(String?) setHoveredItem; // Changed to accept nullable String

  const AnimatedMenuItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDarkMode,
    required this.hoveredItem,
    required this.setHoveredItem,
  });

  @override
  State<AnimatedMenuItem> createState() => _AnimatedMenuItemState();
}

class _AnimatedMenuItemState extends State<AnimatedMenuItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color itemBackgroundColor = widget.isDarkMode ? Colors.grey[900]! : const Color(0xffffecdc);
    final Color hoverBackgroundColor = widget.isDarkMode ? Colors.grey[800]! : const Color(0xffffe0cc);
    final Color textColor = widget.isDarkMode ? Colors.white : Colors.black;
    final Color iconColor = const Color(0xffEB7720);

    return MouseRegion(
      onEnter: (_) => widget.setHoveredItem(widget.label),
      onExit: (_) => widget.setHoveredItem(null), // Now accepts null
      child: GestureDetector(
        onTapDown: (_) {
          widget.setHoveredItem(widget.label);
          _controller.forward();
        },
        onTapUp: (_) {
          widget.setHoveredItem(null); // Now accepts null
          _controller.reverse();
        },
        onTapCancel: () {
          widget.setHoveredItem(null); // Now accepts null
          _controller.reverse();
        },
        onTap: () {
          // Add a small delay to allow the animation to complete
          Future.delayed(const Duration(milliseconds: 100), widget.onTap);
        },
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.hoveredItem == widget.label ? hoverBackgroundColor : itemBackgroundColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  leading: Icon(widget.icon, color: iconColor, size: 20),
                  title: Text(
                    widget.label,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}