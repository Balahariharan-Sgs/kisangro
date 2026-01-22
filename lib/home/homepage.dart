import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:kisangro/home/categories.dart';
import 'package:kisangro/home/product.dart';
import 'package:kisangro/home/theme_mode_provider.dart';
import 'package:kisangro/models/kyc_business_model.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kisangro/models/product_model.dart';
import 'package:kisangro/models/cart_model.dart';
import 'package:kisangro/models/wishlist_model.dart';
import 'package:kisangro/models/kyc_image_provider.dart';
import 'package:kisangro/services/product_service.dart';
import 'package:kisangro/home/myorder.dart';
import 'package:kisangro/home/noti.dart';
import 'package:kisangro/home/search_bar.dart';
import 'package:kisangro/home/bottom.dart';
import 'package:kisangro/home/cart.dart';
import 'package:kisangro/home/trending_products_screen.dart';
import 'package:kisangro/home/new_on_kisangro_products_screen.dart';
import 'package:kisangro/home/deals_of_the_day_screen.dart';
import 'package:kisangro/models/ad_model.dart';
import 'package:kisangro/models/deal_model.dart';
import 'package:kisangro/login/login.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:collection/collection.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:kisangro/home/product_size_selection_bottom_sheet.dart';

import '../categories/category_products_screen.dart';
import '../common/common_app_bar.dart';
import '../menu/logout.dart';
import 'custom_drawer.dart';

class HomePage extends StatefulWidget {
  final VoidCallback? onCategoryViewAll;

  const HomePage({super.key, this.onCategoryViewAll});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;
  Timer? _carouselTimer;
  Timer? _refreshTimer;
  List<Product> _trendingItems = [];
  List<Product> _newOnKisangroItems = [];
  List<Map<String, String>> _categories = [];
  bool _isLoadingCategories = true;
  List<Deal> _dealsOfTheDay = [];
  bool _isLoadingDeals = true;
  List<Ad> _ads = [];
  bool _isLoadingAds = true;
  final List<String> _carouselImages = [
    'assets/veg.png',
    'assets/product.png',
    'assets/bulk.png',
    'assets/nature.png',
  ];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  double _rating = 4.0;
  final TextEditingController _reviewController = TextEditingController();
  static const int maxChars = 100;

  String _getEffectiveImageUrl(String rawImageUrl) {
    if (rawImageUrl.isEmpty ||
        rawImageUrl == 'https://sgserp.in/erp/api/' ||
        (Uri.tryParse(rawImageUrl)?.isAbsolute != true && !rawImageUrl.startsWith('assets/'))) {
      return 'assets/placeholder.png';
    }
    return rawImageUrl;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadInitialData();
    _startCarousel();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _carouselTimer?.cancel();
    _pageController.dispose();
    _refreshTimer?.cancel();
    _reviewController.dispose();
    super.dispose();
  }

  @override
  void _showSizeSelectionBottomSheet(BuildContext context, Product product, bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ProductSizeSelectionBottomSheet(
          product: product,
          isDarkMode: isDarkMode,
        );
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('App resumed to homepage, re-checking membership status...');
    }
  }

  Future<void> _loadInitialData() async {
    await ProductService().initialize();

    if (mounted) {
      setState(() {
        _trendingItems = ProductService.getAllProducts().take(10).toList();
        _newOnKisangroItems = ProductService.getAllProducts().skip(0).take(10).toList();

        if (_newOnKisangroItems.isEmpty) {
          _newOnKisangroItems = List.generate(
            10,
                (index) => Product(
              mainProductId: 'new_dummy_main_$index',
              title: 'New Item $index',
              subtitle: 'Fresh Arrival',
              imageUrl: ProductService.getRandomValidImageUrl(),
              category: 'New',
              availableSizes: [ProductSize(proId: 10000 + index, size: 'kg', price: 100.0 + index * 5, sellingPrice: 90.0 + index * 5)],
              initialSelectedUnitProId: 10000 + index,
            ),
          );
        }
      });

      await _loadCategories();
      await _fetchAds();
      await _fetchDealsOfTheDay();
    }
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });
    try {
      await ProductService.loadCategoriesFromApi();
      if (mounted) {
        setState(() {
          _categories = ProductService.getAllCategories();
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading categories in HomeScreen: $e');
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
      }
    }
  }

  Future<void> _fetchAds() async {
    setState(() {
      _isLoadingAds = true;
    });
    try {
      final fetchedAds = await ProductService.fetchAds();
      if (mounted) {
        setState(() {
          _ads = fetchedAds;
          _isLoadingAds = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching ads in HomeScreen: $e');
      if (mounted) {
        setState(() {
          _isLoadingAds = false;
        });
      }
    }
  }

  Future<void> _fetchDealsOfTheDay() async {
    setState(() {
      _isLoadingDeals = true;
    });
    try {
      final fetchedDeals = await ProductService.fetchDealsOfTheDay();
      if (mounted) {
        setState(() {
          _dealsOfTheDay = fetchedDeals;
          _isLoadingDeals = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching deals of the day in HomeScreen: $e');
      if (mounted) {
        setState(() {
          _isLoadingDeals = false;
        });
      }
    }
  }

  void _startCarousel() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients && mounted) {
        int nextPageIndex = _currentPage + 1;
        final int itemCount = _ads.isNotEmpty ? _ads.length : _carouselImages.length;

        if (itemCount == 0) return;

        if (nextPageIndex >= itemCount) {
          _pageController.jumpToPage(0);
          nextPageIndex = 0;
        } else {
          _pageController.animateToPage(
            nextPageIndex,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
        setState(() {
          _currentPage = nextPageIndex;
        });
      }
    });
  }

void _showLogoutDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => LogoutConfirmationDialog(
      onCancel: () => Navigator.of(context).pop(),
      onLogout: () async {
        // ADD KYC DATA CLEARING HERE
        try {
          // Clear KYC data providers
          final kycBusinessDataProvider = Provider.of<KycBusinessDataProvider>(context, listen: false);
          final kycImageProvider = Provider.of<KycImageProvider>(context, listen: false);
          
          await kycBusinessDataProvider.clearKycData(); // This is the actual method name
          kycImageProvider.clearKycImage();
          
          debugPrint('Cleared KYC data on logout');
        } catch (e) {
          debugPrint('Error clearing KYC data on logout: $e');
        }
        
        // Clear SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginApp()),
              (Route<dynamic> route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged out successfully!')),
        );
      },
    ),
  );
}

  void _showComplaintDialog(BuildContext context) {
    final themeMode = Provider.of<ThemeModeProvider>(context, listen: false).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    final Color dialogBackgroundColor = isDarkMode ? Colors.grey[850]! : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;
    final Color hintColor = isDarkMode ? Colors.grey[400]! : Colors.grey;
    final Color borderColor = isDarkMode ? Colors.grey[600]! : Colors.grey;
    final Color orangeColor = const Color(0xffEB7720);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: dialogBackgroundColor,
          content: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: 328,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.close,
                          color: Color(0xffEB7720),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Give ratings and write a review about your experience using this app.",
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Text("Rate:", style: GoogleFonts.lato(fontSize: 16, color: textColor)),
                        const SizedBox(width: 12),
                        RatingBar.builder(
                          initialRating: _rating,
                          minRating: 1,
                          direction: Axis.horizontal,
                          allowHalfRating: false,
                          itemCount: 5,
                          itemSize: 32,
                          unratedColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                          itemBuilder: (context, _) => const Icon(
                            Icons.star,
                            color: Color(0xffEB7720),
                          ),
                          onRatingUpdate: (rating) {
                            setState(() {
                              _rating = rating;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _reviewController,
                      maxLength: maxChars,
                      maxLines: 3,
                      style: GoogleFonts.lato(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Write here',
                        hintStyle: GoogleFonts.lato(color: hintColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: const Color(0xffEB7720)),
                        ),
                        counterText: '',
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 12,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${_reviewController.text.length}/$maxChars',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: hintColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xffEB7720),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: dialogBackgroundColor,
                              contentPadding: const EdgeInsets.all(24),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Color(0xffEB7720),
                                    size: 48,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Thank you!',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Thanks for rating us.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: isDarkMode ? Colors.white70 : Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xffEB7720),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        'OK',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Text(
                          'Submit',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildShimmerProductTile({double? width, required bool isDarkMode}) {
    final Color baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final Color highlightColor = isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;

    return Container(
      width: width,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900]! : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey.shade300,
        ),
      ),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: width != null ? width * 0.66 : 100,
              color: Colors.white,
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: double.infinity, height: 14, color: Colors.white),
                  const SizedBox(height: 6),
                  Container(width: 100, height: 12, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(width: 80, height: 12, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(width: 60, height: 10, color: Colors.white),
                  const SizedBox(height: 12),
                  Container(height: 36, color: Colors.white),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: Container(height: 36, color: Colors.white)),
                      const SizedBox(width: 8),
                      Container(width: 40, height: 36, color: Colors.white),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerDealTile(bool isDarkMode) {
    final Color baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final Color highlightColor = isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: isDarkMode ? Colors.grey[700]! : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
        color: isDarkMode ? Colors.grey[900]! : Colors.white,
      ),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: double.infinity, height: 80, color: Colors.white),
            const SizedBox(height: 8),
            Container(width: double.infinity, height: 14, color: Colors.white),
            const SizedBox(height: 8),
            Container(width: 80, height: 12, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCategoryTile(bool isDarkMode) {
    final Color baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final Color highlightColor = isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900]! : Colors.white,
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.transparent : Colors.black12,
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 12,
              width: 60,
              color: Colors.white,
            ),
            const SizedBox(height: 4),
            Container(
              height: 10,
              width: 40,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerAdTile(bool isDarkMode) {
    final Color baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final Color highlightColor = isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            color: Colors.white,
            width: double.infinity,
            height: 180,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.shortestSide >= 600;
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    final Color backgroundColor = isDarkMode ? Colors.black : const Color(0xFFFFF7F1);
    final Color gradientStartColor = isDarkMode ? Colors.black : const Color(0xffFFD9BD);
    final Color gradientEndColor = isDarkMode ? Colors.black : const Color(0xffFFFFFF);
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color subtitleColor = isDarkMode ? Colors.white70 : Colors.black;
    final Color cardBackgroundColor = isDarkMode ? Colors.grey[900]! : Colors.white;
    final Color dividerColor = isDarkMode ? Colors.grey[700]! : Colors.white;
    final Color iconColor = const Color(0xffEB7720);

    String? dealsBannerUrl;
    if (_dealsOfTheDay.isNotEmpty && _dealsOfTheDay.first.banner.isNotEmpty) {
      dealsBannerUrl = _dealsOfTheDay.first.banner;
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: CustomDrawer(
          showComplaintDialog: _showComplaintDialog,
          showLogoutDialog: _showLogoutDialog,
        ),
        appBar: CustomAppBar(
          title: "Hello!",
          showBackButton: false,
          showMenuButton: true,
          scaffoldKey: _scaffoldKey,
          isMyOrderActive: false,
          isWishlistActive: false,
          isNotiActive: false,
          showWhatsAppIcon: true,
        ),
        backgroundColor: backgroundColor,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      height: 290,
                      width: double.infinity,
                      color: isDarkMode ? Colors.grey[800] : Colors.grey.shade200,
                      child: Image.asset(
                        'assets/bghome.jpg',
                        height: 290,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Text(
                              'Error loading image: assets/bghome.jpg',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(color: Colors.red),
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      top: 10,
                      left: 12,
                      right: 12,
                      child: _buildSearchBar(isDarkMode),
                    ),
                    Positioned(
                      top: 80,
                      left: 0,
                      right: 0,
                      child: SizedBox(
                        height: 180,
                        child: _isLoadingAds
                            ? PageView.builder(
                          controller: _pageController,
                          itemCount: 3,
                          onPageChanged: (index) {
                            setState(() => _currentPage = index);
                          },
                          itemBuilder: (context, index) {
                            return _buildShimmerAdTile(isDarkMode);
                          },
                        )
                            : _ads.isEmpty
                            ? PageView.builder(
                          controller: _pageController,
                          itemCount: _carouselImages.length,
                          onPageChanged: (index) {
                            setState(() => _currentPage = index);
                          },
                          itemBuilder: (context, index) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                image: DecorationImage(
                                  image: AssetImage(_carouselImages[index]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        )
                            : PageView.builder(
                          controller: _pageController,
                          itemCount: _ads.length,
                          onPageChanged: (index) {
                            setState(() => _currentPage = index);
                          },
                          itemBuilder: (context, index) {
                            final ad = _ads[index];
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  ad.banner,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'assets/placeholder.png',
                                      fit: BoxFit.cover,
                                    );
                                  },
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return _buildShimmerAdTile(isDarkMode);
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      top: 270,
                      left: 0,
                      right: 0,
                      child: _buildDotIndicators(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Trending Items",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const TrendingProductsScreen()));
                        },
                        child: Text(
                          "View All",
                          style: GoogleFonts.poppins(color: iconColor),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 305,
                  child: _trendingItems.isEmpty
                      ? ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: 12, right: 12),
                    itemCount: 6,
                    itemBuilder: (context, index) {
                      return _buildShimmerProductTile(
                        width: 150,
                        isDarkMode: isDarkMode,
                      );
                    },
                  )
                      : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _trendingItems.length,
                    padding: const EdgeInsets.only(left: 12, right: 12),
                    itemBuilder: (context, index) {
                      final product = _trendingItems[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailPage(product: product),
                              ),
                            );
                          },
                          child: ChangeNotifierProvider<Product>.value(
                            value: product,
                            child: _buildProductTile(
                              context,
                              product,
                              tileWidth: 150,
                              isDarkMode: isDarkMode,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 30),
                _isLoadingDeals
                    ? SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: 12, right: 12),
                    itemCount: 6,
                    itemBuilder: (context, index) {
                      return _buildShimmerDealTile(isDarkMode);
                    },
                  ),
                )
                    : _dealsOfTheDay.isNotEmpty
                    ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Deals of the Day",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => DealsOfTheDayScreen(
                                          deals: _dealsOfTheDay.map((deal) {
                                            return Product(
                                              mainProductId: deal.proId.toString(),
                                              title: deal.productName,
                                              subtitle: deal.dealName,
                                              imageUrl: deal.productImg.isNotEmpty
                                                  ? deal.productImg
                                                  : ProductService.getRandomValidImageUrl(),
                                              category: 'Deals',
                                              availableSizes: [
                                                ProductSize(
                                                    proId: deal.proId,
                                                    size: deal.size.isNotEmpty ? deal.size : 'Unit',
                                                    price: deal.mrp ?? 0.0,
                                                    sellingPrice: deal.sellingPrice)
                                              ],
                                              initialSelectedUnitProId: deal.proId,
                                            );
                                          }).toList())));
                            },
                            child: Text(
                              "View All",
                              style: GoogleFonts.poppins(color: iconColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width,
                      height: 400,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        image: dealsBannerUrl != null && dealsBannerUrl.isNotEmpty && _getEffectiveImageUrl(dealsBannerUrl).startsWith('http')
                            ? DecorationImage(
                          image: NetworkImage(_getEffectiveImageUrl(dealsBannerUrl)),
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                        )
                            : const DecorationImage(
                          image: AssetImage("assets/diwali.png"),
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 160),
                          SizedBox(
                            height: 180,
                            child: _dealsOfTheDay.isEmpty
                                ? ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: 6,
                              itemBuilder: (context, index) {
                                return _buildShimmerDealTile(isDarkMode);
                              },
                            )
                                : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _dealsOfTheDay.length,
                              itemBuilder: (context, index) {
                                final deal = _dealsOfTheDay[index];
                                final tempProduct = Product(
                                  mainProductId: deal.proId.toString(),
                                  title: deal.productName,
                                  subtitle: deal.dealName,
                                  imageUrl: deal.productImg.isNotEmpty
                                      ? deal.productImg
                                      : ProductService.getRandomValidImageUrl(),
                                  category: 'Deals',
                                  availableSizes: [
                                    ProductSize(
                                        proId: deal.proId,
                                        size: deal.size.isNotEmpty ? deal.size : 'Unit',
                                        price: deal.mrp ?? 0.0,
                                        sellingPrice: deal.sellingPrice)
                                  ],
                                  initialSelectedUnitProId: deal.proId,
                                );

                                return Container(
                                  width: 140,
                                  margin: const EdgeInsets.only(right: 12),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: isDarkMode ? Colors.grey[700]! : Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(4),
                                    color: cardBackgroundColor,
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ProductDetailPage(product: tempProduct),
                                        ),
                                      );
                                    },
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: double.infinity,
                                          height: 80,
                                          child: Center(
                                            child: AspectRatio(
                                              aspectRatio: 1.0,
                                              child: deal.productImg.isNotEmpty &&
                                                  _getEffectiveImageUrl(deal.productImg).startsWith('http')
                                                  ? Image.network(
                                                _getEffectiveImageUrl(deal.productImg),
                                                fit: BoxFit.contain,
                                                errorBuilder: (context, error, stackTrace) => Image.asset(
                                                  'assets/placeholder.png',
                                                  fit: BoxFit.contain,
                                                ),
                                              )
                                                  : Image.asset(
                                                'assets/placeholder.png',
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          deal.productName,
                                          style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.bold, color: textColor),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                '₹ ${deal.mrp?.toStringAsFixed(2) ?? 'N/A'}',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: isDarkMode ? Colors.grey[400] : Colors.grey,
                                                  decoration: (deal.sellingPrice != null && deal.sellingPrice != deal.mrp)
                                                      ? TextDecoration.lineThrough
                                                      : TextDecoration.none,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (deal.sellingPrice != null && deal.sellingPrice != deal.mrp)
                                              Padding(
                                                padding: const EdgeInsets.only(left: 4.0),
                                                child: Flexible(
                                                  child: Text(
                                                    '₹ ${deal.sellingPrice!.toStringAsFixed(2)}',
                                                    style: GoogleFonts.poppins(
                                                        color: Colors.green,
                                                        fontSize: 12.5,
                                                        fontWeight: FontWeight.w600),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
                    : const SizedBox.shrink(),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Top Categories",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          widget.onCategoryViewAll?.call();
                        },
                        child: Text(
                          "View All",
                          style: GoogleFonts.poppins(color: iconColor),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: _isLoadingCategories
                      ? GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 6,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemBuilder: (context, index) {
                      return _buildShimmerCategoryTile(isDarkMode);
                    },
                  )
                      : _categories.isEmpty
                      ? Center(
                    child: Text(
                      'No categories found.',
                      style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
                    ),
                  )
                      : LayoutBuilder(
                    builder: (context, constraints) {
                      final double screenWidth = constraints.maxWidth;
                      final orientation = MediaQuery.of(context).orientation;
                      int crossAxisCount;
                      double childAspectRatio;

                      if (screenWidth > 900) {
                        crossAxisCount = 5;
                        childAspectRatio = 0.9;
                      } else if (screenWidth > 700) {
                        crossAxisCount = 4;
                        childAspectRatio = 0.9;
                      } else if (screenWidth > 450) {
                        crossAxisCount = 3;
                        childAspectRatio = 0.85;
                      } else {
                        crossAxisCount = 3;
                        childAspectRatio = 0.85;
                      }

                      if (orientation == Orientation.landscape && screenWidth < 700) {
                        crossAxisCount = 4;
                        childAspectRatio = 0.9;
                      }

                      if (isTablet && orientation == Orientation.landscape) {
                        crossAxisCount = 5;
                        childAspectRatio = 0.9;
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _categories.take(6).length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: childAspectRatio,
                        ),
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CategoryProductsScreen(
                                    categoryTitle: category['label']!,
                                    categoryId: category['cat_id']!,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: cardBackgroundColor,
                                borderRadius: BorderRadius.circular(5),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDarkMode ? Colors.transparent : Colors.black12,
                                    blurRadius: 4,
                                    offset: const Offset(2, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (category['icon'] != null && category['icon']!.isNotEmpty && _getEffectiveImageUrl(category['icon']!).startsWith('assets/'))
                                    Image.asset(
                                      _getEffectiveImageUrl(category['icon']!),
                                      height: 40,
                                      width: 40,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(Icons.category, size: 40, color: iconColor);
                                      },
                                    )
                                  else
                                    Icon(Icons.category, size: 40, color: iconColor),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                    child: Text(
                                      category['label']!,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: textColor,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 30),
                Divider(
                  color: dividerColor,
                  thickness: 8.0,
                  height: 0,
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "New On Kisangro",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const NewOnKisangroProductsScreen()));
                        },
                        child: Text(
                          "View All",
                          style: GoogleFonts.poppins(color: iconColor),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double screenWidth = constraints.maxWidth;
                      final orientation = MediaQuery.of(context).orientation;
                      int crossAxisCount;
                      double childAspectRatio;

                      if (screenWidth > 900) {
                        crossAxisCount = 5;
                        childAspectRatio = 0.35;
                      } else if (screenWidth > 700) {
                        crossAxisCount = 4;
                        childAspectRatio = 0.40;
                      } else {
                        crossAxisCount = 2;
                        childAspectRatio = 0.55;
                      }

                      if (orientation == Orientation.landscape && screenWidth < 700) {
                        crossAxisCount = 3;
                        childAspectRatio = 0.65;
                      }

                      if (isTablet && orientation == Orientation.landscape) {
                        crossAxisCount = 5;
                        childAspectRatio = 0.60;
                      }

                      return _newOnKisangroItems.isEmpty
                          ? GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: childAspectRatio,
                        ),
                        itemCount: 6,
                        itemBuilder: (context, index) {
                          return _buildShimmerProductTile(isDarkMode: isDarkMode);
                        },
                      )
                          : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: childAspectRatio,
                        ),
                        itemCount: _newOnKisangroItems.length,
                        itemBuilder: (context, index) {
                          final product = _newOnKisangroItems[index];
                          return ChangeNotifierProvider<Product>.value(
                            value: product,
                            child: _buildProductTile(context, product, isDarkMode: isDarkMode),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDarkMode) {
    final Color searchBarColor = isDarkMode ? Colors.grey[800]! : Colors.white;
    final Color hintTextColor = isDarkMode ? Colors.white70 : const Color(0xffEB7720);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: searchBarColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.transparent : Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchScreen()));
              },
              child: Row(
                children: [
                  Icon(Icons.search, color: hintTextColor),
                  const SizedBox(width: 10),
                  Text(
                    'Search here...',
                    style: GoogleFonts.poppins(color: hintTextColor),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDotIndicators() {
    final int count = _ads.isNotEmpty ? _ads.length : _carouselImages.length;
    if (count == 0) {
      return const SizedBox.shrink();
    }
    return Center(
      child: AnimatedSmoothIndicator(
        activeIndex: _currentPage,
        count: count,
        effect: const ExpandingDotsEffect(
          activeDotColor: Color(0xffEB7720),
          dotHeight: 5,
          dotWidth: 8,
        ),
      ),
    );
  }

  Widget _buildProductTile(BuildContext context, Product product, {double? tileWidth, required bool isDarkMode}) {
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color cardBackgroundColor = isDarkMode ? Colors.grey[900]! : Colors.white;
    final Color borderColor = isDarkMode ? Colors.grey[700]! : Colors.grey.shade300;
    final Color orangeColor = const Color(0xffEB7720);

    return Container(
      width: tileWidth,
      margin: const EdgeInsets.only(bottom: 4.5),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider<Product>.value(
                    value: product,
                    child: ProductDetailPage(product: product),
                  ),
                ),
              );
            },
            child: Container(
              height: tileWidth != null ? tileWidth * 0.66 : 100,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              ),
              child: Center(
                child: _getEffectiveImageUrl(product.imageUrl).startsWith('http')
                    ? Image.network(
                  _getEffectiveImageUrl(product.imageUrl),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    'assets/placeholder.png',
                    fit: BoxFit.contain,
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                            : null,
                        color: const Color(0xffEB7720),
                      ),
                    );
                  },
                )
                    : Image.asset(
                  _getEffectiveImageUrl(product.imageUrl),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 2, 8, 2),
            child: Consumer<Product>(
              builder: (context, product, child) {
                final currentSelectedUnit = product.selectedUnit;
                final currentMrp = product.pricePerSelectedUnit;
                final currentSellingPrice = product.sellingPricePerSelectedUnit;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: textColor
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.subtitle,
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: textColor
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '₹ ${currentMrp?.toStringAsFixed(2) ?? 'N/A'}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: isDarkMode ? Colors.grey[400] : Colors.grey,
                              decoration: (currentSellingPrice != null &&
                                  currentSellingPrice != currentMrp)
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                        ),
                        if (currentSellingPrice != null && currentSellingPrice != currentMrp)
                          Padding(
                            padding: const EdgeInsets.only(left: 4.0),
                            child: Text(
                              '₹ ${currentSellingPrice.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Unit: ${currentSelectedUnit.size}',
                      style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: orangeColor
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Replace the dropdown container with this:
                    Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: orangeColor),
                        borderRadius: BorderRadius.circular(6),
                        color: isDarkMode ? Colors.grey[800] : Colors.white,
                      ),
                      child: InkWell(
                        onTap: () {
                          _showSizeSelectionBottomSheet(context, product, isDarkMode);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              product.selectedUnit.size,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: textColor,
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color: orangeColor,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Replace the Add button with this:
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _showSizeSelectionBottomSheet(context, product, isDarkMode);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: orangeColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: Text(
                              "Add",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 40,
                          child: Consumer<WishlistModel>(
                            builder: (context, wishlist, child) {
                              final isFavorite = wishlist.containsItem(
                                  product.selectedUnit.proId);
                              return IconButton(
                                onPressed: () async {
                                  final success = await wishlist.toggleItem(product);
                                  if (success != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          success
                                              ? 'Added to wishlist!'
                                              : 'Removed from wishlist!',
                                        ),
                                        backgroundColor:
                                        success ? Colors.blue : Colors.red,
                                      ),
                                    );
                                  }
                                },
                                icon: Icon(
                                  isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: orangeColor,
                                  size: 20,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}