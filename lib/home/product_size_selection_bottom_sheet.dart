import 'package:flutter/material.dart';
import 'package:kisangro/models/product_model.dart';
import 'package:kisangro/models/cart_model.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductSizeSelectionBottomSheet extends StatefulWidget {
  final Product product;
  final bool isDarkMode;

  const ProductSizeSelectionBottomSheet({
    Key? key,
    required this.product,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  _ProductSizeSelectionBottomSheetState createState() => _ProductSizeSelectionBottomSheetState();
}

class _ProductSizeSelectionBottomSheetState extends State<ProductSizeSelectionBottomSheet> {
  ProductSize? _selectedSize;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _selectedSize = widget.product.selectedUnit;
  }

  String _getEffectiveImageUrl(String rawImageUrl) {
    if (rawImageUrl.isEmpty ||
        rawImageUrl == 'https://sgserp.in/erp/api/' ||
        (Uri.tryParse(rawImageUrl)?.isAbsolute != true && !rawImageUrl.startsWith('assets/'))) {
      return 'assets/placeholder.png';
    }
    return rawImageUrl;
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = widget.isDarkMode ? Colors.white : Colors.black;
    final Color cardColor = widget.isDarkMode ? Colors.grey[900]! : Colors.white;
    final Color borderColor = widget.isDarkMode ? Colors.grey[700]! : Colors.grey.shade300;
    final Color orangeColor = const Color(0xffEB7720);
    final Color backgroundColor = widget.isDarkMode ? Colors.grey[800]! : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Header
          Text(
            'Select Size & Quantity',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),

          const SizedBox(height: 20),

          // Product image and details row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                  color: cardColor,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _getEffectiveImageUrl(widget.product.imageUrl),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      'assets/placeholder.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Product details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.product.subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: textColor.withOpacity(0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Size selection dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(8),
              color: cardColor,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ProductSize>(
                value: _selectedSize,
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down, color: orangeColor),
                style: GoogleFonts.poppins(color: textColor, fontSize: 14),
                items: widget.product.availableSizes.map((size) {
                  return DropdownMenuItem<ProductSize>(
                    value: size,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          size.size,
                          style: GoogleFonts.poppins(fontSize: 14, color: textColor),
                        ),
                        Text(
                          '₹ ${(size.sellingPrice ?? size.price).toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: orangeColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (ProductSize? newSize) {
                  if (newSize != null) {
                    setState(() {
                      _selectedSize = newSize;
                    });
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Price display
          if (_selectedSize != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Price:',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_selectedSize!.sellingPrice != null &&
                        _selectedSize!.sellingPrice != _selectedSize!.price)
                      Text(
                        '₹ ${_selectedSize!.price.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    Text(
                      '₹ ${(_selectedSize!.sellingPrice ?? _selectedSize!.price).toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: orangeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),

          const SizedBox(height: 20),

          // Quantity selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quantity:',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(8),
                  color: cardColor,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove, size: 20, color: orangeColor),
                      onPressed: () {
                        if (_quantity > 1) {
                          setState(() {
                            _quantity--;
                          });
                        }
                      },
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.symmetric(
                          vertical: BorderSide(color: borderColor),
                        ),
                      ),
                      child: Text(
                        _quantity.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add, size: 20, color: orangeColor),
                      onPressed: () {
                        setState(() {
                          _quantity++;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Add to cart button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: orangeColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                if (_selectedSize != null) {
                  // Update product with selected size
                  widget.product.selectedUnit = _selectedSize!;

                  // Add to cart with quantity
                  final cart = Provider.of<CartModel>(context, listen: false);
                  for (int i = 0; i < _quantity; i++) {
                    cart.addItem(widget.product.copyWith());
                  }

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${widget.product.title} added to cart!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: Text(
                'Add to Cart',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }
}