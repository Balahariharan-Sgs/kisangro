import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisangro/home/theme_mode_provider.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart'; // For firstWhereOrNull

import 'package:kisangro/models/product_model.dart';
import 'package:kisangro/home/product.dart'; // ProductDetailPage
import 'package:kisangro/models/cart_model.dart'; // CartModel
import 'package:kisangro/models/wishlist_model.dart'; // WishlistModel
import 'package:kisangro/services/product_service.dart'; // Import ProductService for image fallback
import 'package:kisangro/home/product_size_selection_bottom_sheet.dart'; // Add this import

class DealsOfTheDayScreen extends StatefulWidget {
  final List<Product> deals; // List of deal products to display

  const DealsOfTheDayScreen({super.key, required this.deals});

  @override
  State<DealsOfTheDayScreen> createState() => _DealsOfTheDayScreenState();
}

class _DealsOfTheDayScreenState extends State<DealsOfTheDayScreen> {
  late List<Product> _displayedDeals; // Products currently displayed (filtered/sorted)
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedSortBy; // 'price_asc', 'price_desc', 'alpha_asc', 'alpha_desc'

  @override
  void initState() {
    super.initState();
    _displayedDeals = List.from(widget.deals); // Initialize with all deals
    _searchController.addListener(_onSearchChanged);
    _filterAndSortProducts(); // Apply initial filter/sort if any
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterAndSortProducts();
    });
  }

  void _filterAndSortProducts() {
    List<Product> results = List.from(widget.deals); // Start with original deals

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
      _displayedDeals = results;
    });
  }

  // Helper function to determine the effective image URL
  String _getEffectiveImageUrl(String rawImageUrl) {
    if (rawImageUrl.isEmpty || rawImageUrl == 'https://sgserp.in/erp/api/' || (Uri.tryParse(rawImageUrl)?.isAbsolute != true && !rawImageUrl.startsWith('assets/'))) {
      return ProductService.getRandomValidImageUrl(); // Fallback to a random valid API image
    }
    return rawImageUrl;
  }

  // Add this method to show the size selection bottom sheet
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
              hintText: 'Search deals...',
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

  @override
  Widget build(BuildContext context) {
    final Color orange = const Color(0xffEB7720); // Your app's theme color
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    // Define colors based on theme
    final Color backgroundColor = isDarkMode ? Colors.black : const Color(0xFFFFF7F1);
    final Color gradientStartColor = isDarkMode ? Colors.black : const Color(0xffFFD9BD);
    final Color gradientEndColor = isDarkMode ? Colors.black : const Color(0xffFFFFFF);
    final Color infoTextColor = isDarkMode ? Colors.grey[300]! : Colors.grey[700]!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: orange,
        title: Text(
          'Deals of the Day',
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
            colors: [gradientStartColor, gradientEndColor], // Consistent theme gradient
          ),
        ),
        child: Column(
          children: [
            _buildSearchBarAndSort(isDarkMode), // Add search bar and sort dropdown, pass isDarkMode
            Expanded(
              child: _displayedDeals.isEmpty
                  ? Center(
                child: Text(
                  _searchQuery.isNotEmpty
                      ? 'No deals found matching "${_searchController.text}".'
                      : 'No deals available today.',
                  style: GoogleFonts.poppins(fontSize: 16, color: infoTextColor), // Apply theme color
                  textAlign: TextAlign.center,
                ),
              )
                  : GridView.builder(
                padding: const EdgeInsets.all(15.0),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200, // Max width for items
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  mainAxisExtent: 320, // Explicitly set height for each tile to avoid overflow
                ),
                itemCount: _displayedDeals.length,
                itemBuilder: (context, index) {
                  final product = _displayedDeals[index];
                  return ChangeNotifierProvider<Product>.value( // Wrap with Provider
                    value: product,
                    child: _buildProductTile(context, product, isDarkMode), // Pass isDarkMode
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Reusing the _buildProductTile logic from homepage.dart for consistency
  Widget _buildProductTile(BuildContext context, Product product, bool isDarkMode) {
    final Color themeOrange = const Color(0xffEB7720); // Your app's theme color
    final Color cardBackgroundColor = isDarkMode ? Colors.grey[900]! : Colors.white;
    final Color borderColor = isDarkMode ? Colors.grey[700]! : Colors.grey.shade300;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color greyTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey;
    final Color boxShadowColor = isDarkMode ? Colors.transparent : Colors.black12;
    final Color dividerColor = isDarkMode ? Colors.grey[700]! : Colors.grey;

    return Consumer<Product>( // Consume the product to react to its selectedUnit changes
      builder: (context, product, child) {
        // Ensure availableSizes is never empty to prevent errors.
        final List<ProductSize> effectiveAvailableSizes = product.availableSizes.isNotEmpty
            ? product.availableSizes
            : [ProductSize(proId: 0, size: 'Unit', price: product.pricePerSelectedUnit ?? 0.0, sellingPrice: product.sellingPricePerSelectedUnit)];

        // Resolve the selected unit for display
        ProductSize currentSelectedUnit = effectiveAvailableSizes.firstWhere(
              (sizeOption) => sizeOption.proId == product.selectedUnit.proId,
          orElse: () => effectiveAvailableSizes.first,
        );

        final double? currentMrp = product.pricePerSelectedUnit;
        final double? currentSellingPrice = product.sellingPricePerSelectedUnit;

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cardBackgroundColor, // Apply theme color
            border: Border.all(color: borderColor), // Apply theme color
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(color: boxShadowColor, blurRadius: 6), // Apply theme color
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                child: SizedBox(
                  width: double.infinity,
                  height: 100,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1.0,
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
                ),
              ),
              Divider(color: dividerColor), // Apply theme color
              const SizedBox(height: 3),
              Text(
                product.title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: textColor, // Apply theme color
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                product.subtitle,
                style: GoogleFonts.poppins(fontSize: 12, color: textColor), // Apply theme color
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // Display MRP and Selling Price for the tile
              Row(
                children: [
                  // Use Flexible to prevent overflow if prices are long
                  Flexible(
                    child: Text(
                      'M.R.P.: ₹ ${currentMrp?.toStringAsFixed(2) ?? 'N/A'}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: greyTextColor, // Apply theme color
                        decoration: (currentSellingPrice != null && currentSellingPrice != currentMrp)
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (currentSellingPrice != null && currentSellingPrice != currentMrp)
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: Text(
                          'Our Price: ₹ ${currentSellingPrice.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(fontSize: 14, color: Colors.green, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              // Replace the dropdown with a button that opens the bottom sheet
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: themeOrange),
                  borderRadius: BorderRadius.circular(6),
                  color: isDarkMode ? Colors.grey[800] : Colors.white, // Apply theme color
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
                        color: themeOrange,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  // Replace the Add button with one that opens the bottom sheet
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _showSizeSelectionBottomSheet(context, product, isDarkMode);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: themeOrange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8)),
                      child: Text(
                        "Add",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: Consumer<WishlistModel>(
                      builder: (context, wishlist, child) {
                        final bool isFavorite = wishlist.containsItem(product.selectedUnit.proId);
                        return IconButton(
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          onPressed: () async {
                            if (!mounted) return;
                            final success = await wishlist.toggleItem(product);
                            if (success != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? '${product.title} added to wishlist!'
                                        : '${product.title} removed from wishlist!',
                                  ),
                                  backgroundColor: success ? Colors.blue : Colors.red,
                                ),
                              );
                            }
                          },
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: themeOrange,
                            size: 24,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}