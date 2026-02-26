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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// API Suggestion Model
class ApiSuggestion {
  final String label;
  final int productId;
  final String name;

  ApiSuggestion({
    required this.label,
    required this.productId,
    required this.name,
  });

  factory ApiSuggestion.fromJson(Map<String, dynamic> json) {
    return ApiSuggestion(
      label: json['label']?.toString() ?? '',
      productId: json['product_id'] ?? 0,
      name: json['name']?.toString() ?? '',
    );
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final LayerLink _layerLink = LayerLink(); // Add LayerLink for overlay positioning

  List<Product> _recentSearches = [];
  List<Product> _trendingSearches = [];
  bool _isSearching = false;
  List<ApiSuggestion> _apiSuggestions = [];
  List<Map<String, dynamic>> _suggestionItems = [];
  OverlayEntry? _overlayEntry;
  bool _showSuggestions = false;
  static const String RECENT_SEARCHES_KEY = 'recent_searches';
  
  // API suggestion debounce timer
  Timer? _suggestionDebounce;

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
    _suggestionDebounce?.cancel();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (_searchFocusNode.hasFocus) {
      if (_searchController.text.isNotEmpty && _suggestionItems.isNotEmpty) {
        _showSuggestionsOverlay();
      }
    } else {
      _removeOverlay();
    }
  }

  void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      setState(() {
        _apiSuggestions = [];
        _suggestionItems = [];
      });
      _removeOverlay();
      return;
    }

    // Show loading state in overlay
    if (_searchFocusNode.hasFocus) {
      setState(() {
        _suggestionItems = [{'type': 'loading', 'text': 'Searching...'}];
      });
      _showSuggestionsOverlay();
    }

    // Debounce API calls to avoid too many requests
    if (_suggestionDebounce?.isActive ?? false) _suggestionDebounce!.cancel();
    _suggestionDebounce = Timer(const Duration(milliseconds: 300), () {
      _fetchApiSuggestions(_searchController.text);
    });
  }

  // Fetch suggestions from API using type 1039
  Future<void> _fetchApiSuggestions(String query) async {
    if (query.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get location and device data
      double? latitude = prefs.getDouble('latitude') ?? 123.0;
      double? longitude = prefs.getDouble('longitude') ?? 145.0;
      String? deviceId = prefs.getString('device_id') ?? '1';

      // Prepare API parameters
      final Map<String, String> params = {
        'cid': '85788578',
        'type': '1039',
        'lt': latitude.toString(),
        'ln': longitude.toString(),
        'device_id': deviceId,
        'search': query,
      };

      debugPrint('🔍 Fetching search suggestions: $query');

      final response = await http.post(
        Uri.parse('https://erpsmart.in/total/api/m_api/'),
        body: params,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        
        if (responseData is List) {
          final apiSuggestions = responseData
              .map((item) => ApiSuggestion.fromJson(item))
              .toList();
          
          debugPrint('🔍 Found ${apiSuggestions.length} suggestions');
          
          // Create suggestion items for display
          final suggestionItems = <Map<String, dynamic>>[];
          
          // Add search query as first suggestion
          suggestionItems.add({
            'type': 'search',
            'text': query,
            'product': null,
          });
          
          // Add API suggestions
          final allProducts = ProductService.getAllProducts();
          for (final apiSuggestion in apiSuggestions) {
            // Try to find matching product for image
            Product? matchedProduct;
            try {
              matchedProduct = allProducts.firstWhereOrNull(
                (p) => p.mainProductId == apiSuggestion.productId.toString() ||
                       p.title.toLowerCase().contains(apiSuggestion.name.toLowerCase())
              );
            } catch (e) {
              debugPrint('Error matching product: $e');
            }
            
            suggestionItems.add({
              'type': 'product',
              'text': apiSuggestion.name,
              'productId': apiSuggestion.productId,
              'product': matchedProduct,
            });
          }
          
          if (mounted) {
            setState(() {
              _apiSuggestions = apiSuggestions;
              _suggestionItems = suggestionItems;
            });

            // Update overlay
            if (_searchFocusNode.hasFocus) {
              _showSuggestionsOverlay();
            }
          }
        }
      } else {
        debugPrint('🔍 API error: ${response.statusCode}');
        _performLocalSearchSuggestions(query);
      }
    } catch (e) {
      debugPrint('🔍 Error fetching suggestions: $e');
      _performLocalSearchSuggestions(query);
    }
  }

  void _performLocalSearchSuggestions(String query) {
    try {
      List<Product> results = ProductService.searchProductsLocally(query);
      
      final suggestionItems = <Map<String, dynamic>>[];
      
      // Add search query as first suggestion
      suggestionItems.add({
        'type': 'search',
        'text': query,
        'product': null,
      });
      
      // Add product suggestions
      for (final product in results.take(10)) {
        suggestionItems.add({
          'type': 'product',
          'text': product.title,
          'product': product,
        });
      }
      
      if (mounted) {
        setState(() {
          _suggestionItems = suggestionItems;
        });

        if (_searchFocusNode.hasFocus) {
          _showSuggestionsOverlay();
        }
      }
    } catch (e) {
      debugPrint('Local search suggestions error: $e');
    }
  }

  void _showSuggestionsOverlay() {
    // Don't show overlay if no items or already showing
    if (_suggestionItems.isEmpty) return;
    
    // Remove existing overlay
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 32, // Match search bar width with padding
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 50), // Position below the search bar
          child: Material(
            elevation: 8.0,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildSuggestionsList(),
              ),
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

  Widget _buildSuggestionsList() {
    if (_suggestionItems.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text('No suggestions found'),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: _suggestionItems.length,
      separatorBuilder: (context, index) => const Divider(height: 1, thickness: 1),
      itemBuilder: (context, index) {
        final item = _suggestionItems[index];
        final type = item['type'];
        
        if (type == 'loading') {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xffEB7720)),
            ),
          );
        } else if (type == 'search') {
          return _buildSearchSuggestionTile(item['text']);
        } else {
          return _buildProductSuggestionTile(
            item['text'], 
            item['product'],
            item.containsKey('productId') ? item['productId'] : null,
          );
        }
      },
    );
  }

  Widget _buildSearchSuggestionTile(String query) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xffEB7720).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.search, color: Color(0xffEB7720), size: 20),
      ),
      title: Text(
        query,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        'Search for products',
        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
      ),
      onTap: () {
        _searchController.text = query;
        _saveRecentSearch(query);
        _navigateToSearchResults(query);
        _removeOverlay();
      },
    );
  }

  Widget _buildProductSuggestionTile(String text, Product? product, int? productId) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: product != null && product.imageUrl.isNotEmpty
            ? (_getEffectiveImageUrl(product.imageUrl).startsWith('http')
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
                  ))
            : Image.asset(
                'assets/placeholder.png',
                fit: BoxFit.contain,
              ),
      ),
      title: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        'Product',
        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: () {
        _searchController.text = text;
        _saveRecentSearch(text);
        _navigateToSearchResults(text);
        _removeOverlay();
      },
    );
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

  Future<void> _saveRecentSearch(String query) async {
    if (query.isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    List<String> searches = prefs.getStringList(RECENT_SEARCHES_KEY) ?? [];
    
    searches.remove(query);
    searches.insert(0, query);
    if (searches.length > 10) {
      searches = searches.sublist(0, 10);
    }
    
    await prefs.setStringList(RECENT_SEARCHES_KEY, searches);
    _loadRecentSearchProducts();
  }

  Future<void> _loadRecentSearchProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentQueries = prefs.getStringList(RECENT_SEARCHES_KEY) ?? [];
      
      if (recentQueries.isEmpty) {
        if (mounted) {
          setState(() {
            _recentSearches = [];
          });
        }
        return;
      }
      
      final allProducts = ProductService.getAllProducts();
      final recentProducts = <Product>[];
      final validQueries = <String>[];
      
      for (final query in recentQueries) {
        try {
          Product? matchedProduct;
          
          for (final product in allProducts) {
            if (product.title.toLowerCase() == query.toLowerCase()) {
              matchedProduct = product;
              break;
            }
          }
          
          if (matchedProduct == null) {
            for (final product in allProducts) {
              if (product.title.toLowerCase().contains(query.toLowerCase())) {
                matchedProduct = product;
                break;
              }
            }
          }
          
          if (matchedProduct != null) {
            if (!recentProducts.any((p) => p.title == matchedProduct!.title)) {
              recentProducts.add(matchedProduct!);
              validQueries.add(query);
            }
          }
        } catch (e) {
          debugPrint('Error processing query "$query": $e');
          continue;
        }
      }
      
      if (validQueries.length != recentQueries.length) {
        await prefs.setStringList(RECENT_SEARCHES_KEY, validQueries);
      }
      
      if (mounted) {
        setState(() {
          _recentSearches = recentProducts.take(5).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading recent search products: $e');
      if (mounted) {
        setState(() {
          _recentSearches = [];
        });
      }
    }
  }

  Future<void> _loadInitialData() async {
    await ProductService().initialize();
    if (mounted) {
      setState(() {
        final allProducts = ProductService.getAllProducts();
        if (allProducts.isNotEmpty) {
          _trendingSearches = allProducts.take(5).toList();
        }
      });
      _loadRecentSearchProducts();
    }
  }

  void _navigateToSearchResults(String query) {
    if (query.isEmpty) return;
    _saveRecentSearch(query);
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

  void _clearAllRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(RECENT_SEARCHES_KEY);
    setState(() {
      _recentSearches = [];
    });
  }

  void _removeRecentSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> searches = prefs.getStringList(RECENT_SEARCHES_KEY) ?? [];
    searches.remove(query);
    await prefs.setStringList(RECENT_SEARCHES_KEY, searches);
    _loadRecentSearchProducts();
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
              CompositedTransformTarget(
                link: _layerLink,
                child: Row(
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
                        if (_recentSearches.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Recent Searches",
                                  style: GoogleFonts.poppins(
                                      fontSize: isTablet ? 18 : 16,
                                      fontWeight: FontWeight.bold)),
                              TextButton(
                                onPressed: _clearAllRecentSearches,
                                child: Text(
                                  "Clear All",
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xffEB7720),
                                    fontSize: isTablet ? 14 : 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: verticalSpacing),
                          Wrap(
                            spacing: isTablet ? 15 : 10,
                            runSpacing: isTablet ? 15 : 10,
                            children: _recentSearches.map((product) =>
                                _buildRecentSearchTag(product, isTablet)).toList(),
                          ),
                        ],
                        if (_recentSearches.isEmpty)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: verticalSpacing * 2),
                            child: Center(
                              child: Text(
                                "No recent searches",
                                style: GoogleFonts.poppins(
                                  color: Colors.grey,
                                  fontSize: isTablet ? 16 : 14,
                                ),
                              ),
                            ),
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

  Widget _buildRecentSearchTag(Product product, bool isTablet) {
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
            IconButton(
              icon: Icon(Icons.close,
                  size: isTablet ? 18 : 14,
                  color: Colors.grey),
              onPressed: () {
                _removeRecentSearch(product.title);
              },
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
            ),
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

// Search Results Page (keep as is)
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

    try {
      List<Product> results = [];
      
      if (query.isNotEmpty) {
        results = ProductService.searchProductsLocally(query);
      }

      if (_selectedCategory != null && _selectedCategory != 'All' && _selectedCategory != 'All Categories') {
        results = results.where((product) => product.category == _selectedCategory).toList();
      }

      if (_selectedSortBy != null && results.isNotEmpty) {
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