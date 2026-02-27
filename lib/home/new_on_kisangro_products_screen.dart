import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisangro/home/theme_mode_provider.dart';
import 'package:provider/provider.dart';
import 'package:kisangro/models/product_model.dart';
import 'package:kisangro/services/product_service.dart';
import 'package:kisangro/home/product.dart'; // Your existing ProductDetailPage
import 'package:kisangro/models/cart_model.dart';
import 'package:kisangro/models/wishlist_model.dart';
import 'package:collection/collection.dart'; // For firstWhereOrNull
import 'package:shimmer/shimmer.dart'; // Add this import for shimmer effect
import 'package:kisangro/home/product_size_selection_bottom_sheet.dart'; // Add this import

class NewOnKisangroProductsScreen extends StatefulWidget {
  const NewOnKisangroProductsScreen({super.key});

  @override
  State<NewOnKisangroProductsScreen> createState() => _NewOnKisangroProductsScreenState();
}

class _NewOnKisangroProductsScreenState extends State<NewOnKisangroProductsScreen> {
  List<Product> _allNewOnKisangroItems = []; // Store all new products initially
  List<Product> _displayedNewOnKisangroItems = []; // Products currently displayed (filtered/sorted)
  bool _isLoading = true; // Add loading state
  String _errorMessage = ''; // Add error message state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedSortBy; // 'price_asc', 'price_desc', 'alpha_asc', 'alpha_desc'

  @override
  void initState() {
    super.initState();
    _loadNewOnKisangroProducts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // Add this method for showing size selection bottom sheet
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

  Future<void> _loadNewOnKisangroProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      _allNewOnKisangroItems = ProductService.getAllProducts(); // Load all products
      _filterAndSortProducts(); // Apply initial filter/sort
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading new products: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load new products. Please try again later.';
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterAndSortProducts();
    });
  }

  void _filterAndSortProducts() {
    List<Product> results = List.from(_allNewOnKisangroItems); // Start with all new items

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      results = results.where((product) {
        return product.title.toLowerCase().contains(_searchQuery) ||
            product.subtitle.toLowerCase().contains(_searchQuery) ||
            product.category.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    // Apply sorting
    if (_selectedSortBy != null) {
      results.sort((a, b) {
        // Use sellingPricePerSelectedUnit for sorting if available, otherwise fallback to pricePerSelectedUnit (MRP)
        final double priceA = a.sellingPricePerSelectedUnit ?? a.pricePerSelectedUnit ?? 0.0;
        final double priceB = b.sellingPricePerSelectedUnit ?? b.pricePerSelectedUnit ?? 0.0;

        switch (_selectedSortBy) {
          case 'price_high_to_low':
            return priceB.compareTo(priceA);
          case 'price_low_to_high':
            return priceA.compareTo(priceB);
          case 'alpha_asc':
            return a.title.toLowerCase().compareTo(b.title.toLowerCase());
          case 'alpha_desc':
            return b.title.toLowerCase().compareTo(a.title.toLowerCase());
          default:
            return 0; // No sorting
        }
      });
    }

    setState(() {
      _displayedNewOnKisangroItems = results;
    });
  }

  // Helper function to determine the effective image URL
  String _getEffectiveImageUrl(String rawImageUrl) {
    if (rawImageUrl.isEmpty || rawImageUrl == 'https://sgserp.in/erp/api/' || (Uri.tryParse(rawImageUrl)?.isAbsolute != true && !rawImageUrl.startsWith('assets/'))) {
      return ProductService.getRandomValidImageUrl(); // Fallback to a random valid API image
    }
    return rawImageUrl;
  }

  Widget _buildSearchBarAndSort(bool isDarkMode) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    // Define colors based on theme
    final Color searchBarFillColor = isDarkMode ? Colors.grey[800]! : Colors.white;
    final Color hintTextColor = isDarkMode ? Colors.white70 : Colors.grey[600]!;
    final Color prefixIconColor = isDarkMode ? Colors.white70 : const Color(0xffEB7720);
    final Color suffixIconColor = isDarkMode ? Colors.white70 : Colors.grey;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color dropdownFillColor = isDarkMode ? Colors.grey[800]! : Colors.white;
    final Color dropdownBorderColor = isDarkMode ? Colors.grey[700]! : Colors.transparent; // Transparent for no border in light mode

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search new products...',
              hintStyle: GoogleFonts.poppins(color: hintTextColor), // Apply theme color
              prefixIcon: Icon(Icons.search, color: prefixIconColor, size: isTablet ? 28 : 24), // Apply theme color
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: Icon(Icons.clear, color: suffixIconColor, size: isTablet ? 28 : 24), // Apply theme color
                onPressed: () {
                  _searchController.clear();
                  _filterAndSortProducts();
                },
              )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: searchBarFillColor, // Apply theme color
              contentPadding: EdgeInsets.symmetric(vertical: isTablet ? 20.0 : 12.0, horizontal: 16.0),
            ),
            style: GoogleFonts.poppins(fontSize: isTablet ? 18 : 14, color: textColor), // Apply theme color
          ),
          const SizedBox(height: 10),
          // Sort By Dropdown (Smaller and to the right)
          Align(
            alignment: Alignment.centerRight, // Align to the right
            child: SizedBox(
              width: isTablet ? 200 : 160, // Smaller width for dropdown
              child: DropdownButtonFormField<String>(
                value: _selectedSortBy,
                hint: Text('Sort By', style: GoogleFonts.poppins(fontSize: isTablet ? 14 : 12, color: hintTextColor)), // Apply theme color
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: dropdownBorderColor), // Apply theme color
                  ),
                  filled: true,
                  fillColor: dropdownFillColor, // Apply theme color
                  contentPadding: EdgeInsets.symmetric(vertical: isTablet ? 12.0 : 8.0, horizontal: 12.0), // Smaller padding
                ),
                items: [
                  DropdownMenuItem(value: null, child: Text('Relevance', style: GoogleFonts.poppins(color: textColor))), // Apply theme color
                  DropdownMenuItem(value: 'price_high_to_low', child: Text('Price: High to Low', style: GoogleFonts.poppins(color: textColor))), // Apply theme color
                  DropdownMenuItem(value: 'price_low_to_high', child: Text('Price: Low to High', style: GoogleFonts.poppins(color: textColor))), // Apply theme color
                  DropdownMenuItem(value: 'alpha_asc', child: Text('Name: A to Z', style: GoogleFonts.poppins(color: textColor))), // Apply theme color
                  DropdownMenuItem(value: 'alpha_desc', child: Text('Name: Z to A', style: GoogleFonts.poppins(color: textColor))), // Apply theme color
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedSortBy = value;
                    _filterAndSortProducts(); // Re-run filter/sort with new option
                  });
                },
                style: GoogleFonts.poppins(fontSize: isTablet ? 14 : 12, color: textColor), // Apply theme color
                iconSize: isTablet ? 24 : 20, // Smaller icon size
                dropdownColor: dropdownFillColor, // Set dropdown menu background color
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Add shimmer effect widget
  Widget _buildShimmerGrid(bool isDarkMode) {
    final orientation = MediaQuery.of(context).orientation;
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    // Determine crossAxisCount and childAspectRatio based on orientation and device type
    int crossAxisCount;
    double childAspectRatio;

    if (isTablet) {
      if (orientation == Orientation.portrait) {
        crossAxisCount = 3;
        childAspectRatio = 0.90;
      } else { // Orientation.landscape
        crossAxisCount = 5;
        childAspectRatio = 1.0;
      }
    } else { // Mobile phones
      crossAxisCount = 2;
      childAspectRatio = 1.20;
    }

    final Color baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final Color highlightColor = isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;

    return GridView.builder(
      padding: const EdgeInsets.all(12.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: 6, // Number of shimmer placeholders
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[900]! : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDarkMode ? Colors.grey[700]! : Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 100,
                  width: double.infinity,
                  color: Colors.white,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            height: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 100,
                            height: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 80,
                            height: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    // Determine crossAxisCount and childAspectRatio based on orientation and device type
    int crossAxisCount;
    double childAspectRatio;

    if (isTablet) {
      if (orientation == Orientation.portrait) {
        crossAxisCount = 3;
        childAspectRatio = 0.80;
      } else {
        // Orientation.landscape
        crossAxisCount = 5;
        childAspectRatio = 1.0;
      }
    } else {
      // Mobile phones
      crossAxisCount = 2;
      childAspectRatio = 1.00;
    }

    // Define colors based on theme
    final Color backgroundColor = isDarkMode ? Colors.black : const Color(0xFFFFF7F1);
    final Color gradientStartColor = isDarkMode ? Colors.black : const Color(0xffFFD9BD);
    final Color gradientEndColor = isDarkMode ? Colors.black : const Color(0xffFFFFFF);
    final Color infoTextColor = isDarkMode ? Colors.grey[300]! : Colors.grey[600]!;
    final Color orangeColor = const Color(0xffEB7720); // Orange color, remains constant
    final Color errorTextColor = isDarkMode ? Colors.red[300]! : Colors.red;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: orangeColor,
        elevation: 0,
        title: Text(
          "New On Kisangro", // Correct title for this screen
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [gradientStartColor, gradientEndColor], // Apply theme colors
          ),
        ),
        child: Column(
          children: [
            _buildSearchBarAndSort(isDarkMode), // Add search bar and sort dropdown, pass isDarkMode
            Expanded(
              child: _isLoading
                  ? _buildShimmerGrid(isDarkMode) // Show shimmer effect while loading
                  : _errorMessage.isNotEmpty
                  ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(color: errorTextColor, fontSize: 16),
                  ),
                ),
              )
                  : _displayedNewOnKisangroItems.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 80,
                      color: isDarkMode ? Colors.grey[600] : Colors.grey[400], // Apply theme color
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'No new products found matching "${_searchController.text}"!'
                          : 'No new products available right now!',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: infoTextColor, // Apply theme color
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
                  : Padding(
                padding: const EdgeInsets.all(12.0),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemCount: _displayedNewOnKisangroItems.length,
                  itemBuilder: (context, index) {
                    final product = _displayedNewOnKisangroItems[index];
                    return ChangeNotifierProvider<Product>.value( // Wrap with Provider
                      value: product,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailPage(product: product),
                            ),
                          );
                        },
                        child: _buildProductTile(context, product, isDarkMode), // Pass isDarkMode
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductTile(BuildContext context, Product product, bool isDarkMode) {
    final Color themeOrange = const Color(0xffEB7720); // Your app's theme color
    final Color cardBackgroundColor = isDarkMode ? Colors.grey[900]! : Colors.white;
    final Color borderColor = isDarkMode ? Colors.grey[700]! : Colors.grey.shade300;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color greyTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey;

    return Consumer<Product>( // Consume the product to react to its selectedUnit changes
      builder: (context, product, child) {
        // Ensure availableSizes is never empty to prevent errors in DropdownButton.
        final List<ProductSize> effectiveAvailableSizes = product.availableSizes.isNotEmpty
            ? product.availableSizes
            : [ProductSize(proId: 0, size: 'Unit', price: 0.0, sellingPrice: 0.0)]; // FIX 1: Add proId to fallback

        // Resolve the selected unit for the dropdown.
        // Find if product.selectedUnit exists in effectiveAvailableSizes.
        ProductSize currentSelectedUnit = effectiveAvailableSizes.firstWhere(
              (sizeOption) => sizeOption.proId == product.selectedUnit.proId, // Compare by proId
          orElse: () => effectiveAvailableSizes.first, // Fallback to first if not found
        );

        final double? currentMrp = product.pricePerSelectedUnit;
        final double? currentSellingPrice = product.sellingPricePerSelectedUnit;

        return Container(
          decoration: BoxDecoration(
            color: cardBackgroundColor, // Apply theme color
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor), // Apply theme color
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// IMAGE
              Container(
                height: 100,
                width: double.infinity,
                child: Stack(
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _getEffectiveImageUrl(product.imageUrl).startsWith('http')
                            ? Image.network(
                                _getEffectiveImageUrl(product.imageUrl),
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => Image.asset(
                                  'assets/placeholder.png', // Fallback to local placeholder if network image fails
                                  fit: BoxFit.contain,
                                ),
                              )
                            : Image.asset(
                                _getEffectiveImageUrl(product.imageUrl), // This will now use the dynamic fallback if rawImageUrl is empty
                                fit: BoxFit.contain,
                              ),
                      ),
                    ),

                    /// Wishlist icon (top right)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Consumer<WishlistModel>(
                        builder: (context, wishlist, child) {
                          final isFavorite = wishlist.containsItem(
                            product.selectedUnit.proId,
                          );

                          return GestureDetector(
                            onTap: () async {
                              final result = await wishlist.toggleItem(product);
                              if (result != null && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      result
                                          ? '${product.title} added to wishlist!'
                                          : '${product.title} removed from wishlist!',
                                    ),
                                    backgroundColor: result ? Colors.blue : Colors.red,
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: const Color(0xffEB7720),
                                size: 20,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              /// DETAILS
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 2, 6, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),

                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '₹ ${currentMrp?.toStringAsFixed(2) ?? 'N/A'}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: greyTextColor,
                              decoration: (currentSellingPrice != null && currentSellingPrice != currentMrp)
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
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}