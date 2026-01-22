import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisangro/home/cart.dart';
import 'package:kisangro/home/categories.dart';
import 'package:kisangro/home/homepage.dart';
import 'package:kisangro/home/reward_screen.dart';
import 'package:kisangro/home/rewards_popup.dart';
import 'package:provider/provider.dart';
import 'package:kisangro/models/cart_model.dart';

class Bot extends StatefulWidget {
  final int initialIndex;
  final bool showRewardsPopup;

  const Bot({
    super.key,
    this.initialIndex = 0,
    this.showRewardsPopup = false,
  });

  @override
  State<Bot> createState() => _BotState();
}

class _BotState extends State<Bot> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;

    if (widget.showRewardsPopup && widget.initialIndex == 0) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) => const RewardsPopup(coinsEarned: 100),
          );
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant Bot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIndex != oldWidget.initialIndex) {
      setState(() {
        _selectedIndex = widget.initialIndex;
      });
    }
  }

  final List<Widget> _screens = [
    Builder(builder: (context) {
      return HomePage(
        onCategoryViewAll: () {
          final _BotState? botState = context.findAncestorStateOfType<_BotState>();
          botState?._onItemTapped(1);
        },
      );
    }),
    const ProductCategoriesScreen(),
    const RewardScreen(),
    const Cart(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
        }
      },
      child: Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            selectedItemColor: const Color(0xffEB7720),
            unselectedItemColor: const Color(0xff575757),
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w400,
              fontSize: 12,
            ),
            items: [
              BottomNavigationBarItem(
                icon: Image.asset(
                  'assets/home.png',
                  width: 24,
                  height: 24,
                  color: _selectedIndex == 0 ? const Color(0xffEB7720) : const Color(0xff575757),
                ),
                label: "Home",
              ),
              BottomNavigationBarItem(
                icon: Image.asset(
                  'assets/cat.png',
                  width: 24,
                  height: 24,
                  color: _selectedIndex == 1 ? const Color(0xffEB7720) : const Color(0xff575757),
                ),
                label: "Categories",
              ),
              BottomNavigationBarItem(
                icon: Image.asset(
                  'assets/reward.png',
                  width: 24,
                  height: 24,
                  color: _selectedIndex == 2 ? const Color(0xffEB7720) : const Color(0xff575757),
                ),
                label: "Rewards",
              ),
              // Cart item with badge
              BottomNavigationBarItem(
                icon: Consumer<CartModel>(
                  builder: (context, cart, child) {
                    return Stack(
                      clipBehavior: Clip.none, // Allow badge to overflow
                      children: [
                        Image.asset(
                          'assets/cart.png',
                          width: 24,
                          height: 24,
                          color: _selectedIndex == 3 ? const Color(0xffEB7720) : const Color(0xff575757),
                        ),
                        if (cart.totalItemCount > 0)
                          Positioned(
                            right: -4, // Adjust position to not cover the icon
                            top: -4,   // Adjust position to not cover the icon
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
                                cart.totalItemCount > 9 ? '9+' : cart.totalItemCount.toString(),
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                label: "Cart",
              ),
            ],
          ),
        ),
      ),
    );
  }
}