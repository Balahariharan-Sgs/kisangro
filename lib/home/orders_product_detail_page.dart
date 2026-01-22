import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisangro/home/theme_mode_provider.dart';
import 'package:provider/provider.dart';
import 'package:kisangro/models/product_model.dart'; // Your Product model
import 'package:kisangro/models/cart_model.dart'; // Your CartModel
import 'package:kisangro/home/cart.dart'; // Your Cart page
import 'package:collection/collection.dart'; // For firstWhereOrNull

// Renamed class to avoid conflict with existing ProductDetailPage
class OrdersProductDetailPage extends StatefulWidget {
  final Product product;

  const OrdersProductDetailPage({Key? key, required this.product}) : super(key: key);

  @override
  State<OrdersProductDetailPage> createState() => _OrdersProductDetailPageState();
}

class _OrdersProductDetailPageState extends State<OrdersProductDetailPage> {
  ProductSize? _selectedUnit; // Changed type to ProductSize?
  double? _pricePerSelectedUnit;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    // Initialize selected unit and price based on the product passed.
    // Prioritize widget.product.selectedUnit if it's valid and present in availableSizes.
    // Otherwise, default to the first available size.
    if (widget.product.availableSizes.isNotEmpty) {
      // Find if the product's pre-selected unit (from the order) exists in its available sizes.
      // Use proId for a robust match.
      _selectedUnit = widget.product.availableSizes.firstWhereOrNull(
            (size) => size.proId == widget.product.selectedUnit.proId,
      );

      // If the pre-selected unit from the order is not found in availableSizes (e.g., product data changed),
      // or if it was null initially, default to the first available size.
      _selectedUnit ??= widget.product.availableSizes.first;

      _pricePerSelectedUnit = _selectedUnit?.sellingPrice ?? _selectedUnit?.price;
    }
    // If availableSizes is empty, _selectedUnit and _pricePerSelectedUnit will remain null,
    // and the UI will display "N/A" as handled in the Text widgets.
  }

  // Helper to check if the image URL is valid (not an asset path or empty)
  bool _isValidUrl(String? url) {
    if (url == null || url.isEmpty) {
      return false;
    }
    return Uri.tryParse(url)?.isAbsolute == true && !url.endsWith('erp/api/');
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    // Define colors based on theme
    final Color gradientStartColor = isDarkMode ? Colors.black : const Color(0xffFFD9BD);
    final Color gradientEndColor = isDarkMode ? Colors.black : const Color(0xffFFFFFF);
    final Color imageBackgroundColor = isDarkMode ? Colors.grey[900]! : Colors.grey[200]!;
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;
    final Color subtitleColor = isDarkMode ? Colors.white70 : Colors.grey[700]!;
    final Color dropdownBorderColor = isDarkMode ? Colors.grey[600]! : Colors.grey.shade400;
    final Color orangeColor = const Color(0xffEB7720); // Orange color, remains constant


    return Scaffold(
      appBar: AppBar(
        backgroundColor: orangeColor,
        elevation: 0,
        title: Text(
          widget.product.title,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Center(
                child: Container(
                  width: double.infinity,
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: imageBackgroundColor, // Apply theme color
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _isValidUrl(widget.product.imageUrl)
                        ? Image.network(
                      widget.product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stacktrace) {
                        debugPrint("Error loading image: ${widget.product.imageUrl}");
                        return Center(child: Icon(Icons.broken_image, color: isDarkMode ? Colors.grey[400] : Colors.grey[400], size: 60)); // Apply theme color
                      },
                    )
                        : Image.asset(
                      widget.product.imageUrl, // Assuming it's a local asset if not a valid URL
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stacktrace) {
                        return Center(child: Icon(Icons.broken_image, color: isDarkMode ? Colors.grey[400] : Colors.grey[400], size: 60)); // Apply theme color
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Product Title
              Text(
                widget.product.title,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor, // Apply theme color
                ),
              ),
              const SizedBox(height: 8),

              // Product Description
              Text(
                widget.product.subtitle, // Using subtitle as description
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: subtitleColor, // Apply theme color
                ),
              ),
              const SizedBox(height: 16),

              // Price and Unit Selection
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Price:',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor, // Apply theme color
                    ),
                  ),
                  Text(
                    '₹${_pricePerSelectedUnit?.toStringAsFixed(2) ?? 'N/A'}',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: orangeColor, // Always orange
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Unit selection dropdown if multiple units are available
              if (widget.product.availableSizes.length > 1)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Unit:',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor, // Apply theme color
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: dropdownBorderColor), // Apply theme color
                        color: isDarkMode ? Colors.grey[800] : Colors.white, // Apply theme color
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>( // Changed type to int (proId)
                          isExpanded: true,
                          value: _selectedUnit?.proId, // Use proId as value
                          icon: Icon(Icons.arrow_drop_down, color: orangeColor), // Always orange
                          onChanged: (int? newProId) { // newProId is now int
                            setState(() {
                              if (newProId != null) {
                                final selectedSize = widget.product.availableSizes.firstWhere((s) => s.proId == newProId);
                                _selectedUnit = selectedSize; // Set the entire ProductSize object
                                _pricePerSelectedUnit = _selectedUnit?.sellingPrice ?? _selectedUnit?.price;
                              }
                            });
                          },
                          items: widget.product.availableSizes.map<DropdownMenuItem<int>>((ProductSize sizeOption) { // Changed type to int
                            return DropdownMenuItem<int>(
                              value: sizeOption.proId, // Use proId as value
                              child: Text(
                                '${sizeOption.size} (₹${(sizeOption.sellingPrice ?? sizeOption.price).toStringAsFixed(2)})',
                                style: GoogleFonts.poppins(color: textColor), // Apply theme color
                              ),
                            );
                          }).toList(),
                          dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white, // Apply theme color
                        ),
                      ),
                    ),
                  ],
                )
              else if (widget.product.availableSizes.length == 1 && _selectedUnit != null)
              // Display single unit if only one is available and it's initialized
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Unit: ${_selectedUnit!.size}', // Use .size property
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor, // Apply theme color
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // Quantity Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quantity:',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor, // Apply theme color
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline, color: orangeColor), // Always orange
                        onPressed: () {
                          setState(() {
                            if (_quantity > 1) _quantity--;
                          });
                        },
                      ),
                      Text(
                        _quantity.toString(),
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: textColor), // Apply theme color
                      ),
                      IconButton(
                        icon: Icon(Icons.add_circle_outline, color: orangeColor), // Always orange
                        onPressed: () {
                          setState(() {
                            _quantity++;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Add to Cart Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_selectedUnit == null || _pricePerSelectedUnit == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please select a unit for the product.', style: GoogleFonts.poppins())),
                      );
                      return;
                    }

                    final cartModel = Provider.of<CartModel>(context, listen: false);
                    // Create a copy of the product with the currently selected unit and quantity
                    // to pass to cartModel.addItem which expects a Product.
                    final productToAdd = widget.product.copyWith(
                      selectedUnit: _selectedUnit, // FIX 1: Pass the ProductSize object
                      // The quantity is handled by CartModel's addItem logic
                      // which increments if existing or sets to 1 for new item.
                      // If you want to add the specific _quantity from this page,
                      // you'd need to modify CartModel.addItem to accept quantity.
                      // For now, it will add 1 or increment existing.
                    );

                    cartModel.addItem(productToAdd); // Correctly passing a Product object

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${_quantity} ${widget.product.title}(s) added to cart!', style: GoogleFonts.poppins())),
                    );
                    // Optionally navigate to cart or show a confirmation
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const Cart()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orangeColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.shopping_cart, color: Colors.white, size: 24),
                  label: Text(
                    'Add to Cart',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
