import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisangro/services/product_service.dart';
import 'package:kisangro/models/product_model.dart';
import 'package:kisangro/home/product.dart';
import 'package:provider/provider.dart';
import 'package:kisangro/models/cart_model.dart';
import 'package:kisangro/models/wishlist_model.dart';
import 'dart:async';
import 'package:collection/collection.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<Product> _recentSearches = [];
  List<Product> _trendingSearches = [];
  bool _isSearching = false;
  List<Product> _searchSuggestions = [];
  OverlayEntry? _overlayEntry;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _searchFocusNode.addListener(_onFocusChange);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.removeListener(_onFocusChange);
    _searchFocusNode.dispose();
    _removeOverlay();
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
    if (_searchController.text.isEmpty) {
      _removeOverlay();
      return;
    }

    _performSearchSuggestions(_searchController.text);

    if (_searchFocusNode.hasFocus) {
      _showSuggestionsOverlay();
    }
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
              color: Colors.white,
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
                    _navigateToSearchResults(product.title);
                    _removeOverlay();
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

  Future<void> _loadInitialData() async {
    await ProductService().initialize();
    if (mounted) {
      setState(() {
        final allProducts = ProductService.getAllProducts();
        if (allProducts.isNotEmpty) {
          _recentSearches = allProducts.reversed.take(5).toList();
          _trendingSearches = allProducts.take(5).toList();
        }
      });
    }
  }

  void _performSearchSuggestions(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchSuggestions = [];
      });
      return;
    }

    try {
      List<Product> results = ProductService.searchProductsLocally(query);
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

  void _navigateToSearchResults(String query) {
    if (query.isEmpty) return;
    _removeOverlay();
    _searchFocusNode.unfocus();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsPage(
          searchQuery: query,
          recentSearches: _recentSearches,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.shortestSide >= 600;
    final double horizontalPadding = isTablet ? 24.0 : 12.0;
    final double verticalSpacing = isTablet ? 20.0 : 10.0;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back),
                  ),
                  SizedBox(width: isTablet ? 12 : 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 20 : 15,
                            vertical: isTablet ? 12 : 8),
                        hintText: 'Search by item/crop/chemical name',
                        hintStyle: GoogleFonts.poppins(
                            color: Colors.grey, fontSize: isTablet ? 16 : 14),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                          icon: Icon(Icons.clear,
                              color: Colors.grey,
                              size: isTablet ? 24 : 20),
                          onPressed: () {
                            _searchController.clear();
                            _removeOverlay();
                          },
                        )
                            : Icon(Icons.search,
                            color: Colors.orange,
                            size: isTablet ? 24 : 20),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color: Color(0xffEB7720), width: 2),
                        ),
                      ),
                      style: GoogleFonts.poppins(fontSize: isTablet ? 16 : 14),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (query) {
                        _navigateToSearchResults(query);
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: verticalSpacing),

              if (_isSearching)
                const Center(child: CircularProgressIndicator(color: Color(0xffEB7720)))
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Recent Searches",
                            style: GoogleFonts.poppins(
                                fontSize: isTablet ? 18 : 16,
                                fontWeight: FontWeight.bold)),
                        SizedBox(height: verticalSpacing),
                        Wrap(
                          spacing: isTablet ? 15 : 10,
                          runSpacing: isTablet ? 15 : 10,
                          children: _recentSearches.map((product) =>
                              _buildProductTag(product, isTablet)).toList(),
                        ),
                        SizedBox(height: verticalSpacing * 2),
                        const Divider(),
                        SizedBox(height: verticalSpacing),
                        Text("Trending Searches",
                            style: GoogleFonts.poppins(
                                fontSize: isTablet ? 18 : 16,
                                fontWeight: FontWeight.bold)),
                        SizedBox(height: verticalSpacing),
                        Wrap(
                          spacing: isTablet ? 15 : 10,
                          runSpacing: isTablet ? 15 : 10,
                          children: _trendingSearches.map((product) =>
                              _buildProductTag(product, isTablet)).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductTag(Product product, bool isTablet) {
    return GestureDetector(
      onTap: () {
        _navigateToSearchResults(product.title);
      },
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 18 : 12,
            vertical: isTablet ? 8 : 6),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xffEB7720)),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: isTablet ? 30 : 24,
              height: isTablet ? 30 : 24,
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
            SizedBox(width: isTablet ? 10 : 8),
            Text(product.title,
                style: GoogleFonts.poppins(fontSize: isTablet ? 16 : 14)),
            SizedBox(width: isTablet ? 8 : 5),
            Icon(Icons.trending_up,
                size: isTablet ? 18 : 14,
                color: Color(0xffEB7720)),
          ],
        ),
      ),
    );
  }

  String _getEffectiveImageUrl(String rawImageUrl) {
    if (rawImageUrl.isEmpty ||
        rawImageUrl == 'https://sgserp.in/erp/api/' ||
        (Uri.tryParse(rawImageUrl)?.isAbsolute != true &&
            !rawImageUrl.startsWith('assets/'))) {
      return ProductService.getRandomValidImageUrl();
    }
    return rawImageUrl;
  }
}

// New Search Results Page
class SearchResultsPage extends StatefulWidget {
  final String searchQuery;
  final List<Product> recentSearches;

  const SearchResultsPage({
    super.key,
    required this.searchQuery,
    required this.recentSearches,
  });

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _searchResults = [];
  bool _isSearching = false;
  String? _searchError;
  Timer? _debounce;

  // Filter and Sort States
  String? _selectedCategory;
  String? _selectedSortBy;
  List<Map<String, String>> _categories = [];

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchQuery;
    _loadCategories();
    _performSearch(widget.searchQuery);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(_searchController.text);
    });
  }

  Future<void> _loadCategories() async {
    await ProductService().initialize();
    if (mounted) {
      setState(() {
        _categories = ProductService.getAllCategories();
      });
    }
  }

  String _getEffectiveImageUrl(String rawImageUrl) {
    if (rawImageUrl.isEmpty ||
        rawImageUrl == 'https://sgserp.in/erp/api/' ||
        (Uri.tryParse(rawImageUrl)?.isAbsolute != true &&
            !rawImageUrl.startsWith('assets/'))) {
      return ProductService.getRandomValidImageUrl();
    }
    return rawImageUrl;
  }

  void _performSearch(String query) {
    if (!mounted) return;

    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    if (query.isEmpty && (_selectedCategory == null || _selectedCategory == 'All') && _selectedSortBy == null) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    try {
      List<Product> results = ProductService.searchProductsLocally(query);

      // Apply category filter
      if (_selectedCategory != null && _selectedCategory != 'All') {
        results = results.where((product) => product.category == _selectedCategory).toList();
      }

      // Apply sorting
      if (_selectedSortBy != null) {
        results.sort((a, b) {
          final double priceA = a.sellingPricePerSelectedUnit ?? a.pricePerSelectedUnit ?? 0.0;
          final double priceB = b.sellingPricePerSelectedUnit ?? b.pricePerSelectedUnit ?? 0.0;

          switch (_selectedSortBy) {
            case 'weight_asc':
              final double weightA = a.availableSizes.firstWhere(
                    (s) => s.size.toLowerCase().contains('kg') || s.size.toLowerCase().contains('grm'),
                orElse: () => ProductSize(proId: 0, size: 'kg', price: 0.0),
              ).price;
              final double weightB = b.availableSizes.firstWhere(
                    (s) => s.size.toLowerCase().contains('kg') || s.size.toLowerCase().contains('grm'),
                orElse: () => ProductSize(proId: 0, size: 'kg', price: 0.0),
              ).price;
              return weightA.compareTo(weightB);
            case 'weight_desc':
              final double weightA = a.availableSizes.firstWhere(
                    (s) => s.size.toLowerCase().contains('kg') || s.size.toLowerCase().contains('grm'),
                orElse: () => ProductSize(proId: 0, size: 'kg', price: 0.0),
              ).price;
              final double weightB = b.availableSizes.firstWhere(
                    (s) => s.size.toLowerCase().contains('kg') || s.size.toLowerCase().contains('grm'),
                orElse: () => ProductSize(proId: 0, size: 'kg', price: 0.0),
              ).price;
              return weightB.compareTo(weightA);
            case 'price_asc':
              return priceA.compareTo(priceB);
            case 'price_desc':
              return priceB.compareTo(priceA);
            default:
              return 0;
          }
        });
      }

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _searchError = 'Error searching products: ${e.toString()}';
        _searchResults = [];
        _isSearching = false;
      });
      debugPrint('Search error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.shortestSide >= 600;
    final double horizontalPadding = isTablet ? 24.0 : 12.0;
    final double verticalSpacing = isTablet ? 20.0 : 10.0;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search by item/crop/chemical name',
            hintStyle: GoogleFonts.poppins(color: Colors.grey, fontSize: isTablet ? 16 : 14),
            border: InputBorder.none,
          ),
          style: GoogleFonts.poppins(fontSize: isTablet ? 16 : 14),
          textInputAction: TextInputAction.search,
          onSubmitted: (query) {
            _performSearch(query);
          },
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear, color: Colors.grey, size: isTablet ? 24 : 20),
              onPressed: () {
                _searchController.clear();
                _performSearch('');
              },
            ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(horizontalPadding),
        child: Column(
          children: [
            // Category Filter and Sort By - Only show when there are search results
            if (_searchResults.isNotEmpty || _isSearching)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: isTablet ? 50 : 40,
                      padding: EdgeInsets.symmetric(horizontal: isTablet ? 12 : 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          hint: Text('Category',
                              style: GoogleFonts.poppins(
                                  color: Colors.grey,
                                  fontSize: isTablet ? 16 : 14)),
                          icon: Icon(Icons.arrow_drop_down,
                              color: Color(0xffEB7720),
                              size: isTablet ? 24 : 20),
                          isExpanded: true,
                          style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontSize: isTablet ? 16 : 14),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedCategory = newValue;
                              _performSearch(_searchController.text);
                            });
                          },
                          items: [
                            const DropdownMenuItem(value: 'All', child: Text('All Categories')),
                            ..._categories.map((category) {
                              return DropdownMenuItem<String>(
                                value: category['label'],
                                child: Text(category['label']!),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: isTablet ? 15 : 10),
                  Expanded(
                    child: Container(
                      height: isTablet ? 50 : 40,
                      padding: EdgeInsets.symmetric(horizontal: isTablet ? 12 : 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSortBy,
                          hint: Text('Sort By',
                              style: GoogleFonts.poppins(
                                  color: Colors.grey,
                                  fontSize: isTablet ? 16 : 14)),
                          icon: Icon(Icons.sort,
                              color: Color(0xffEB7720),
                              size: isTablet ? 24 : 20),
                          isExpanded: true,
                          style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontSize: isTablet ? 16 : 14),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedSortBy = newValue;
                              _performSearch(_searchController.text);
                            });
                          },
                          items: const [
                            DropdownMenuItem(value: 'price_asc', child: Text('Price: Low to High')),
                            DropdownMenuItem(value: 'price_desc', child: Text('Price: High to Low')),
                            DropdownMenuItem(value: 'weight_asc', child: Text('Weight: Low to High')),
                            DropdownMenuItem(value: 'weight_desc', child: Text('Weight: High to Low')),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            SizedBox(height: verticalSpacing),

            // Search Results Display
            if (_isSearching)
              const Expanded(
                  child: Center(child: CircularProgressIndicator(color: Color(0xffEB7720)))
              )
            else if (_searchError != null)
              Expanded(
                child: Center(
                  child: Text(
                    _searchError!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(color: Colors.red),
                  ),
                ),
              )
            else if (_searchController.text.isNotEmpty && _searchResults.isEmpty)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'No products found matching your criteria.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                            fontSize: isTablet ? 18 : 16,
                            color: Colors.grey),
                      ),
                    ),
                  ),
                )
              else if (_searchResults.isNotEmpty)
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isTablet ? 3 : 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.55,
                      ),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final product = _searchResults[index];
                        return ChangeNotifierProvider<Product>.value(
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
                            child: _buildProductTile(context, product, isTablet),
                          ),
                        );
                      },
                    ),
                  )
                else
                  Expanded(
                    child: Center(
                      child: Text(
                        'Enter a search term to find products',
                        style: GoogleFonts.poppins(
                            fontSize: isTablet ? 18 : 16,
                            color: Colors.grey),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductTile(BuildContext context, Product product, bool isTablet) {
    final Color themeOrange = const Color(0xffEB7720);

    return Consumer<Product>(
      builder: (context, product, child) {
        final List<ProductSize> effectiveAvailableSizes = product.availableSizes.isNotEmpty
            ? product.availableSizes
            : [ProductSize(proId: 0, size: 'Unit', price: 0.0, sellingPrice: 0.0)];

        ProductSize currentSelectedUnit = effectiveAvailableSizes.firstWhere(
              (sizeOption) => sizeOption.proId == product.selectedUnit.proId,
          orElse: () => effectiveAvailableSizes.first,
        );

        final double? currentMrp = currentSelectedUnit.price;
        final double? currentSellingPrice = currentSelectedUnit.sellingPrice;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: isTablet ? 120 : 100,
                width: double.infinity,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(isTablet ? 12 : 8),
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
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(isTablet ? 10 : 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.title,
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: isTablet ? 16 : 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            product.subtitle,
                            style: GoogleFonts.poppins(fontSize: isTablet ? 14 : 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              Text(
                                '₹ ${currentMrp?.toStringAsFixed(2) ?? 'N/A'}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  decoration: (currentSellingPrice != null && currentSellingPrice != currentMrp)
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
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
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                            ],
                          ),
                          Text('Unit: ${currentSelectedUnit.size}',
                              style: GoogleFonts.poppins(
                                  fontSize: isTablet ? 12 : 10,
                                  color: themeOrange)),
                          SizedBox(height: isTablet ? 10 : 8),
                          Container(
                            height: isTablet ? 45 : 36,
                            padding: EdgeInsets.symmetric(horizontal: isTablet ? 10 : 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: themeOrange),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: currentSelectedUnit.proId,
                                icon: Icon(Icons.keyboard_arrow_down,
                                    color: Color(0xffEB7720),
                                    size: isTablet ? 24 : 20),
                                underline: const SizedBox(),
                                isExpanded: true,
                                style: GoogleFonts.poppins(
                                    fontSize: isTablet ? 14 : 12,
                                    color: Colors.black),
                                items: effectiveAvailableSizes.map((sizeOption) => DropdownMenuItem<int>(
                                  value: sizeOption.proId,
                                  child: Text(sizeOption.size),
                                )).toList(),
                                onChanged: (int? newProId) {
                                  if (newProId != null) {
                                    final selectedSize = effectiveAvailableSizes.firstWhere((s) => s.proId == newProId);
                                    product.selectedUnit = selectedSize;
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isTablet ? 10 : 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Provider.of<CartModel>(context, listen: false).addItem(product.copyWith());
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${product.title} added to cart!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: themeOrange,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: isTablet ? 10 : 8)),
                              child: Text(
                                "Add",
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: isTablet ? 14 : 13),
                              ),
                            ),
                          ),
                          Consumer<WishlistModel>(
                            builder: (context, wishlist, child) {
                              final isFavorite = wishlist.containsItem(product.selectedUnit.proId);
                              return IconButton(
                                onPressed: () async {
                                  final result = await wishlist.toggleItem(product);
                                  if (result != null) {
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
                                icon: Icon(
                                  isFavorite ? Icons.favorite : Icons.favorite_border,
                                  color: themeOrange,
                                ),
                              );
                            },
                          )
                        ],
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
}
