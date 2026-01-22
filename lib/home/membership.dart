import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisangro/payment/payment3.dart'; // Import the PaymentPage from payment3.dart
import 'package:shared_preferences/shared_preferences.dart'; // For SharedPreferences
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:kisangro/home/bottom.dart'; // Import Bot for navigation
import 'package:kisangro/home/myorder.dart'; // Import MyOrder
import 'package:kisangro/menu/wishlist.dart'; // Import WishlistPage
import 'package:kisangro/home/noti.dart'; // Import noti

class MembershipDetailsScreen extends StatefulWidget {
  const MembershipDetailsScreen({super.key});

  @override
  State<MembershipDetailsScreen> createState() => _MembershipDetailsScreenState();
}

class _MembershipDetailsScreenState extends State<MembershipDetailsScreen> with WidgetsBindingObserver {
  bool _isMembershipActive = false; // Local state to control which UI to show

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Add observer for lifecycle events
    _checkMembershipStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Remove observer
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // This method is called when the app's lifecycle state changes
    if (state == AppLifecycleState.resumed) {
      // When the app resumes (e.g., coming back from another screen like payment)
      debugPrint('App resumed, re-checking membership status...');
      _checkMembershipStatus();
    }
  }

  // Method to check membership status from SharedPreferences
  Future<void> _checkMembershipStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isMembershipActive = prefs.getBool('isMembershipActive') ?? false;
    });
    debugPrint('Membership status loaded: $_isMembershipActive');
  }

  // Method to activate membership (called after successful payment) - now directly tied to SharedPreferences
  // This method is primarily for internal state updates if you were to call it without pop/push.
  // In the current flow, payment3.dart will set the flag, and didChangeAppLifecycleState will trigger refresh.
  Future<void> _activateMembership() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isMembershipActive', true);
    setState(() {
      _isMembershipActive = true;
    });
    debugPrint('Membership activated!');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Congratulations! Your membership is now active!', style: GoogleFonts.poppins())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine if it's a tablet based on shortestSide
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final double horizontalPadding = isTablet ? 40.0 : 16.0; // More padding for tablets
    final double verticalSpacing = isTablet ? 30.0 : 20.0; // More spacing for tablets

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Image
          Positioned.fill( // Use Positioned.fill to make it cover the entire stack
            child: Image.asset(
              'assets/mem.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // Custom AppBar content positioned within the Stack
          Positioned(
            top: MediaQuery.of(context).padding.top + (isTablet ? 10 : 0), // Adjust top padding for tablets
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding / 2), // Half padding for app bar
              child: Row(
                children: [
                  // Back Button (perfectly left-aligned)
                  IconButton(
                    padding: EdgeInsets.zero, // Remove default padding
                    constraints: const BoxConstraints(), // Remove default constraints
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 8), // Small space between arrow and text
                  // Membership Details Title (near the arrow button)
                  Text(
                    'Membership Details',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: isTablet ? 22 : 18),
                  ),
                  const Spacer(),
                  // REMOVED: Action Icons (box, heart, noti) are removed from here
                ],
              ),
            ),
          ),
          // Main content of the screen, adjusted to start below the custom app bar
          Positioned.fill(
            top: MediaQuery.of(context).padding.top + (isTablet ? 80 : 100), // Adjusted top padding
            child: SingleChildScrollView( // Added SingleChildScrollView back for potential overflow on very small tablets or landscape
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: _isMembershipActive
                  ? _buildMembershipActiveUI(context, isTablet, verticalSpacing)
                  : _buildMembershipOfferUI(context, isTablet, verticalSpacing),
            ),
          ),
        ],
      ),
    );
  }

  // UI for when membership is NOT active (your original UI)
  Widget _buildMembershipOfferUI(BuildContext context, bool isTablet, double verticalSpacing) {
    return Column(
      children: [
        Text(
          '“Be A Part Of Something Bigger”',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: isTablet ? 22 : 18, // Responsive font size
            color: Colors.white,
          ),
        ),
        SizedBox(height: verticalSpacing / 2), // Responsive spacing
        Column(
          children: [
            Text(
              'Join Our Membership',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: isTablet ? 24 : 20, // Responsive font size
                color: Colors.yellow,
              ),
            ),
            Text(
              'Today!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: isTablet ? 24 : 20, // Responsive font size
                color: Colors.yellow,
              ),
            ),
          ],
        ),
        SizedBox(height: verticalSpacing), // Responsive spacing
        SizedBox(
          width: double.infinity,
          height: isTablet ? 150 : 120, // Responsive height for the info card
          child: Container(
            padding: EdgeInsets.all(isTablet ? 14 : 12), // Slightly reduced padding for horizontal compactness
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(1),
            ),
            child: Row(
              children: [
                Image.asset('assets/logo.png', height: isTablet ? 120 : 90), // Responsive image size
                SizedBox(width: isTablet ? 18 : 8), // Slightly reduced spacing
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Agri-Products Delivered\nTo Your Door Step',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: isTablet ? 16 : 12),
                      ),
                      SizedBox(height: isTablet ? 13 : 8), // Slightly reduced spacing
                      Text(
                        'Effortless Bulk Ordering With\nExclusive Membership Discounts.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(fontSize: isTablet ? 16 : 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: verticalSpacing), // Responsive spacing
        Container( // Wrap ElevatedButton in Container for gradient
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF00C20A), // Primary gradient color #00C20A
                Color(0xFF006005), // Secondary gradient color #006005
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ElevatedButton.icon(
            onPressed: () async {
              // This button navigates to the PaymentPage for the payment process
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentPage(orderId: 'MEMBERSHIP_ORDER_ID_ABC', isMembershipPayment: true),
                ),
              );
            },
            icon: Icon(Icons.lock_open, color: Colors.white, size: isTablet ? 24 : 18),
            label: Text('Unlock', style: GoogleFonts.poppins(fontSize: isTablet ? 22 : 18, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent, // Make button background transparent
              shadowColor: Colors.transparent, // Remove shadow
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 60 : 40, vertical: isTablet ? 18 : 12),
            ),
          ),
        ),
        SizedBox(height: verticalSpacing), // Responsive spacing
        Text(
          'Your Membership @ ₹ 500',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: isTablet ? 22 : 18, // Responsive font size
            color: Colors.white,
          ),
        ),
        SizedBox(height: verticalSpacing / 2), // Responsive spacing
        Text(
          '2% Membership Discount For Every\nProduct You Purchase',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: isTablet ? 18 : 14, color: Colors.white), // Responsive font size
        ),
        SizedBox(height: verticalSpacing / 2), // Responsive spacing
        Text(
          'For',
          style: GoogleFonts.poppins(fontSize: isTablet ? 18 : 14, color: Colors.white), // Responsive font size
        ),
        SizedBox(height: verticalSpacing / 2), // Responsive spacing
        // MODIFIED: Only show the "1 YEAR PLAN" part
        Row(
          mainAxisAlignment: MainAxisAlignment.center, // Center the content
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Removed Expanded, now directly uses Row for the "1 YEAR PLAN" part
            Image.asset(
              'assets/one.gif',
              height: isTablet ? 70 : 50,
              width: isTablet ? 70 : 50,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Text(
                  '1',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: isTablet ? 30 : 24,
                    color: Colors.white,
                  ),
                );
              },
            ),
            SizedBox(width: isTablet ? 12 : 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'YEAR',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: isTablet ? 30 : 24,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'PLAN',
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 18 : 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
        // REMOVED: "You Are A Part Of Our Community Now!" from this section
        SizedBox(height: verticalSpacing * 1.5),
        Text(
          'Plan Expires On: 23rd Dec, 2025',
          style: GoogleFonts.poppins(
            fontSize: isTablet ? 18 : 16,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: verticalSpacing * 1.5),
        Container(
          width: double.infinity,
          margin: EdgeInsets.symmetric(horizontal: isTablet ? 40 : 20),
          child: ElevatedButton(
            onPressed: () {
              // This button is for the pre-payment state, it should lead to payment.
              // However, since the prompt implies this button is for *after* payment,
              // and the UI is _buildMembershipOfferUI, there might be a slight confusion.
              // Assuming this is the "Proceed to Payment" button, it already navigates to PaymentPage.
              // If this button is meant to be "Continue" AFTER payment, it should be in _buildMembershipActiveUI.
              // The current code correctly sends it to PaymentPage.
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => PaymentPage(orderId: 'MEMBERSHIP_ORDER_ID_ABC', isMembershipPayment: true)));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              padding: EdgeInsets.symmetric(vertical: isTablet ? 20 : 14),
            ),
            child: Text(
              'Proceed to Payment', // This text is correct for the pre-payment state
              style: GoogleFonts.poppins(
                color: Colors.indigo,
                fontSize: isTablet ? 20 : 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(height: verticalSpacing),
      ],
    );
  }

  // UI for when membership IS active (your new sample UI)
  Widget _buildMembershipActiveUI(BuildContext context, bool isTablet, double verticalSpacing) {
    return Column(
      children: [
        Text(
          '"Be A Part Of Something Bigger"',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: isTablet ? 22 : 18,
            color: Colors.white,
          ),
        ),
        SizedBox(height: verticalSpacing),

        Column(
          children: [
            Text(
              'You Are A Member Now!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: isTablet ? 28 : 24,
                color: Colors.yellow,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              height: 3,
              width: isTablet ? 150 : 100,
              color: Colors.yellow,
            ),
          ],
        ),
        SizedBox(height: verticalSpacing * 1.5),

        Container(
          width: double.infinity,
          // Adjusted padding to fix 1px overflow horizontally
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 15, vertical: isTablet ? 25 : 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(1),
          ),
          child: Row(
            children: [
              Image.asset('assets/logo.png', height: isTablet ? 120 : 90),
              SizedBox(width: isTablet ? 15 : 10), // Adjusted spacing
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Agri-Products ',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: isTablet ? 18 : 14,
                              color: Colors.black,
                            ),
                          ),
                          TextSpan(
                            text: 'Delivered\nTo Your ',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w400,
                              fontSize: isTablet ? 18 : 14,
                              color: Colors.black,
                            ),
                          ),
                          TextSpan(
                            text: 'Door Step',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: isTablet ? 18 : 14,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isTablet ? 13 : 8), // Adjusted spacing
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Effortless Bulk Ordering With\nExclusive ',
                            style: GoogleFonts.poppins(
                              fontSize: isTablet ? 16 : 12,
                              color: Colors.black54,
                            ),
                          ),
                          TextSpan(
                            text: 'Membership ',
                            style: GoogleFonts.poppins(
                              fontSize: isTablet ? 16 : 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          TextSpan(
                            text: 'Discounts.',
                            style: GoogleFonts.poppins(
                              fontSize: isTablet ? 16 : 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: verticalSpacing * 1.5),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Membership',
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 24 : 20,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 30 : 20, vertical: isTablet ? 12 : 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF00C20A),
                    Color(0xFF006005),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_open, color: Colors.white, size: isTablet ? 22 : 18),
                  SizedBox(width: isTablet ? 10 : 8),
                  Text(
                    'Unlocked',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: isTablet ? 20 : 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: verticalSpacing * 1.5),

        Text(
          '2% Membership Discount For Every\nProduct You Purchase',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: isTablet ? 20 : 16,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: verticalSpacing * 1.5),

        Row(
          mainAxisAlignment: MainAxisAlignment.center, // Center this row
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded( // Keep Expanded for the "1 YEAR PLAN" part to take space
              flex: 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/one.gif',
                    height: isTablet ? 70 : 50,
                    width: isTablet ? 70 : 50,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Text(
                        '1',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: isTablet ? 30 : 24,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                  SizedBox(width: isTablet ? 12 : 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'YEAR',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: isTablet ? 30 : 24,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'PLAN',
                        style: GoogleFonts.poppins(
                          fontSize: isTablet ? 18 : 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // ADDED: "You Are A Part Of Our Community Now!" text here for active UI
            Expanded(
              flex: 1,
              child: Text(
                'You Are A Part Of\nOur Community Now!',
                textAlign: TextAlign.right,
                style: GoogleFonts.poppins(
                  fontSize: isTablet ? 18 : 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: verticalSpacing * 1.5),

        Text(
          'Plan Expires On: 23rd Dec, 2025',
          style: GoogleFonts.poppins(
            fontSize: isTablet ? 18 : 16,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: verticalSpacing * 1.5),

        Container(
          width: double.infinity,
          margin: EdgeInsets.symmetric(horizontal: isTablet ? 40 : 20),
          child: ElevatedButton(
            onPressed: () {
              // This button is for the post-payment (active membership) state.
              // It directly navigates to the home screen (Bot with initialIndex 0)
              // and ensures no rewards popup is shown.
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const Bot(initialIndex: 0, showRewardsPopup: false),
                ),
                    (Route<dynamic> route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              padding: EdgeInsets.symmetric(vertical: isTablet ? 20 : 14),
            ),
            child: Text(
              'Continue', // This text is correct for the post-payment state
              style: GoogleFonts.poppins(
                color: Colors.indigo,
                fontSize: isTablet ? 20 : 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(height: verticalSpacing),
      ],
    );
  }
}
