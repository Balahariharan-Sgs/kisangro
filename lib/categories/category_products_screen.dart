import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:kisangro/models/product_model.dart';
import 'package:kisangro/services/product_service.dart';
import 'package:kisangro/models/cart_model.dart';
import 'package:kisangro/menu/wishlist.dart';
import 'package:kisangro/models/wishlist_model.dart';
import 'package:kisangro/home/product.dart';
import '../home/theme_mode_provider.dart';
import '../common/common_app_bar.dart';
import 'package:collection/collection.dart';
import 'package:shimmer/shimmer.dart';
import 'package:kisangro/home/product_size_selection_bottom_sheet.dart';
import 'dart:async';
import 'package:kisangro/home/search_bar.dart'; // Import the search functionality

class CategoryProductsScreen extends StatefulWidget {
  final String categoryTitle;
  final String categoryId;

  const CategoryProductsScreen({
    Key? key,
    required this.categoryTitle,
    required this.categoryId,
  }) : super(key: key);

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  List<Product> _allProducts = [];
  List<Product> _displayedProducts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _offset = 0;
  final int _loadAllLimit = 999999999;
  bool _hasMore = false;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Search overlay functionality
  final FocusNode _searchFocusNode = FocusNode();
  List<Product> _searchSuggestions = [];
  OverlayEntry? _overlayEntry;
  bool _showSuggestions = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchCategoryProducts(initialLoad: true);
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);

    // Initialize search overlay listeners
    _searchFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.removeListener(_onFocusChange);
    _searchFocusNode.dispose();
    _removeOverlay();
    _debounce?.cancel();
    super.dispose();
  }

  void _onFocusChange() {
    if (_searchFocusNode.hasFocus && _searchController.text.isNotEmpty) {
      _showSuggestionsOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });

    // Handle search suggestions
    if (_searchController.text.isEmpty) {
      _removeOverlay();
      _filterAndDisplayProducts();
      return;
    }

    _performSearchSuggestions(_searchController.text);

    if (_searchFocusNode.hasFocus) {
      _showSuggestionsOverlay();
    }

    // Debounce the actual search filtering
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _filterAndDisplayProducts();
    });
  }

  void _showSuggestionsOverlay() {
    _removeOverlay();

    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 5,
        width: size.width,
        child: Material(
          elevation: 4.0,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4.0,
                ),
              ],
            ),
            child: _searchSuggestions.isEmpty
                ? Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No suggestions found',
                style: GoogleFonts.poppins(),
              ),
            )
                : ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: _searchSuggestions.length,
              itemBuilder: (context, index) {
                final product = _searchSuggestions[index];
                return ListTile(
                  leading: SizedBox(
                    width: 40,
                    height: 40,
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: _getEffectiveImageUrl(product.imageUrl).startsWith('http')
                          ? Image.network(
                        _getEffectiveImageUrl(product.imageUrl),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Image.asset(
                          'assets/placeholder.png',
                          fit: BoxFit.contain,
                        ),
                      )
                          : Image.asset(
                        _getEffectiveImageUrl(product.imageUrl),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  title: Text(
                    product.title,
                    style: GoogleFonts.poppins(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    product.subtitle,
                    style: GoogleFonts.poppins(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    _searchController.text = product.title;
                    _removeOverlay();
                    _searchFocusNode.unfocus();
                    _filterAndDisplayProducts();
                  },
                );
              },
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _showSuggestions = true;
    });
  }

  void _removeOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
    setState(() {
      _showSuggestions = false;
    });
  }

  void _performSearchSuggestions(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchSuggestions = [];
      });
      return;
    }

    try {
      // Filter from the current category products instead of all products
      List<Product> results = _allProducts.where((product) =>
      product.title.toLowerCase().contains(query.toLowerCase()) ||
          product.subtitle.toLowerCase().contains(query.toLowerCase()) ||
          product.category.toLowerCase().contains(query.toLowerCase())
      ).toList();

      setState(() {
        _searchSuggestions = results.take(5).toList();
      });

      // Update overlay if it's visible
      if (_showSuggestions && _overlayEntry != null) {
        _overlayEntry!.markNeedsBuild();
      }
    } catch (e) {
      setState(() {
        _searchSuggestions = [];
      });
      debugPrint('Search suggestions error: $e');
    }
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

  String _getEffectiveImageUrl(String rawImageUrl) {
    if (rawImageUrl.isEmpty ||
        rawImageUrl == 'https://sgserp.in/erp/api/' ||
        (Uri.tryParse(rawImageUrl)?.isAbsolute != true && !rawImageUrl.startsWith('assets/'))) {
      return ProductService.getRandomValidImageUrl();
    }
    return rawImageUrl;
  }

  void _onScroll() {
    if (!_hasMore || _isLoadingMore || _isLoading || _searchQuery.isNotEmpty) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      _loadMoreProducts();
    }
  }

  void _filterAndDisplayProducts() {
    if (_searchQuery.isEmpty) {
      _displayedProducts = List.from(_allProducts);
    } else {
      _displayedProducts = _allProducts
          .where((product) =>
      product.title.toLowerCase().contains(_searchQuery) ||
          product.subtitle.toLowerCase().contains(_searchQuery) ||
          product.category.toLowerCase().contains(_searchQuery))
          .toList();
    }
    _isLoadingMore = false;
  }

  Future<void> _fetchCategoryProducts({bool initialLoad = false}) async {
    if (initialLoad) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _offset = 0;
        _allProducts.clear();
        _displayedProducts.clear();
        _hasMore = true;
      });
    }

    try {
      final Map<String, dynamic> result = await ProductService.fetchProductsByCategory(
        widget.categoryId,
        offset: initialLoad ? 0 : _offset,
        limit: _loadAllLimit,
      );

      final List<Product> fetchedProducts = result['products'];
      final bool fetchedHasMore = result['hasMore'];

      if (mounted) {
        setState(() {
          _allProducts.addAll(fetchedProducts);
          _offset += fetchedProducts.length;
          _hasMore = fetchedHasMore;
          _isLoading = false;
          _isLoadingMore = false;
          _filterAndDisplayProducts();
        });
      }
    } catch (e) {
      debugPrint('Error fetching products for category ${widget.categoryTitle} (ID: ${widget.categoryId}): $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load products. Please try again later. ($e)';
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _loadMoreProducts() async {
    if (!_hasMore || _isLoadingMore || _searchQuery.isNotEmpty) return;

    setState(() {
      _isLoadingMore = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final Map<String, dynamic> result = await ProductService.fetchProductsByCategory(
        widget.categoryId,
        offset: _offset,
        limit: 10,
      );

      final List<Product> fetchedProducts = result['products'];
      final bool fetchedHasMore = result['hasMore'];

      if (mounted) {
        setState(() {
          _allProducts.addAll(fetchedProducts);
          _offset += fetchedProducts.length;
          _hasMore = fetchedHasMore;
          _isLoadingMore = false;
          _filterAndDisplayProducts();
        });
      }
    } catch (e) {
      debugPrint('Error loading more products for category ${widget.categoryTitle} (ID: ${widget.categoryId}): $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load more products. Please try again later. ($e)';
          _isLoadingMore = false;
        });
      }
    }
  }

  Widget _buildSearchBar(bool isDarkMode) {
    final Color searchBarFillColor = isDarkMode ? Colors.grey[800]! : Colors.white;
    final Color hintTextColor = isDarkMode ? Colors.white70 : Colors.grey[600]!;
    final Color prefixIconColor = isDarkMode ? Colors.white70 : const Color(0xffEB7720);
    final Color suffixIconColor = isDarkMode ? Colors.white70 : Colors.grey;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: 'Search products in ${widget.categoryTitle}...',
          hintStyle: GoogleFonts.poppins(color: hintTextColor),
          prefixIcon: Icon(Icons.search, color: prefixIconColor),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear, color: suffixIconColor),
            onPressed: () {
              _searchController.clear();
              _removeOverlay();
              _filterAndDisplayProducts();
            },
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: searchBarFillColor,
          contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        ),
        style: GoogleFonts.poppins(fontSize: 14, color: textColor),
        onSubmitted: (value) {
          _removeOverlay();
          _searchFocusNode.unfocus();
          _filterAndDisplayProducts();
        },
      ),
    );
  }

  // Updated shimmer effect to match wishlist.dart style
  Widget _buildShimmerGrid(bool isDarkMode) {
    final Color baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final Color highlightColor = isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;
    final Color cardColor = isDarkMode ? Colors.grey[850]! : Colors.white;
    final Color borderColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            return Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cardColor,
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Shimmer.fromColors(
                baseColor: baseColor,
                highlightColor: highlightColor,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image placeholder
                    Container(
                      width: double.infinity,
                      height: 100,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 10),
                    // Title placeholder
                    Container(
                      width: double.infinity,
                      height: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 5),
                    // Subtitle placeholder
                    Container(
                      width: 100,
                      height: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 10),
                    // Price placeholder
                    Container(
                      width: 80,
                      height: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 10),
                    // Dropdown placeholder
                    Container(
                      width: double.infinity,
                      height: 36,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 10),
                    // Button row placeholder
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 36,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 44,
                          height: 44,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
          childCount: 6, // Number of shimmer placeholders
        ),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          mainAxisExtent: 320,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    final Color backgroundColor = isDarkMode ? Colors.black : const Color(0xFFFFF7F1);
    final Color gradientStartColor = isDarkMode ? Colors.black : const Color(0xffFFD9BD);
    final Color gradientEndColor = isDarkMode ? Colors.black : const Color(0xffFFFFFF);
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color errorTextColor = isDarkMode ? Colors.red.shade300 : Colors.red;
    final Color infoTextColor = isDarkMode ? Colors.grey[300]! : Colors.black54;
    final Color orangeColor = const Color(0xffEB7720);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: orangeColor,
        elevation: 0,
        title: Text(
          widget.categoryTitle,
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
            colors: [gradientStartColor, gradientEndColor],
          ),
        ),
        child: _errorMessage != null
            ? Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: errorTextColor, fontSize: 16),
            ),
          ),
        )
            : CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: _buildSearchBar(isDarkMode),
            ),
            if (_isLoading)
              _buildShimmerGrid(isDarkMode)
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final product = _displayedProducts[index];
                      return ChangeNotifierProvider<Product>.value(
                        value: product,
                        child: _buildProductTile(context, product, isDarkMode),
                      );
                    },
                    childCount: _displayedProducts.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    mainAxisExtent: 320,
                  ),
                ),
              ),
            if (_isLoadingMore && _searchQuery.isEmpty && _hasMore)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: CircularProgressIndicator(color: orangeColor),
                  ),
                ),
              ),
            if (_displayedProducts.isEmpty && _searchQuery.isEmpty && !_isLoading && _errorMessage == null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    'No products found for this category.',
                    style: GoogleFonts.poppins(fontSize: 16, color: infoTextColor),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductTile(BuildContext context, Product product, bool isDarkMode) {
    final Color themeOrange = const Color(0xffEB7720);
    final Color cardBackgroundColor = isDarkMode ? Colors.grey[900]! : Colors.white;
    final Color borderColor = isDarkMode ? Colors.grey[700]! : Colors.grey.shade300;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color greyTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey;
    final Color boxShadowColor = isDarkMode ? Colors.transparent : Colors.black12;
    final Color dividerColor = isDarkMode ? Colors.grey[700]! : Colors.grey;

    return Consumer<Product>(
      builder: (context, product, child) {
        final List<ProductSize> effectiveAvailableSizes = product.availableSizes.isNotEmpty
            ? product.availableSizes
            : [ProductSize(proId: 0, size: 'Unit', price: 0.0, sellingPrice: 0.0)];

        ProductSize currentSelectedUnit = effectiveAvailableSizes.firstWhere(
              (sizeOption) => sizeOption.proId == product.selectedUnit.proId,
          orElse: () => effectiveAvailableSizes.first,
        );
        String resolvedSelectedUnitSize = currentSelectedUnit.size;

        final double? currentMrp = product.pricePerSelectedUnit;
        final double? currentSellingPrice = product.sellingPricePerSelectedUnit;

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cardBackgroundColor,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(color: boxShadowColor, blurRadius: 6),
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
                          'assets/placeholder.png',
                          fit: BoxFit.contain,
                        ),
                      )
                          : Image.asset(
                        _getEffectiveImageUrl(product.imageUrl),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              Divider(color: dividerColor),
              const SizedBox(height: 3),
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
                style: GoogleFonts.poppins(fontSize: 12, color: textColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'M.R.P.: ₹ ${currentMrp?.toStringAsFixed(2) ?? 'N/A'}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: greyTextColor,
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
              // Replace the dropdown with this:
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: themeOrange),
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
                  // Replace the Add button with this:
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
                                    isFavorite
                                        ? '${product.title} removed from wishlist!'
                                        : '${product.title} added to wishlist!',
                                  ),
                                  backgroundColor: isFavorite ? Colors.red : Colors.blue,
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