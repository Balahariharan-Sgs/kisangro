import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const Drop());
}

class Drop extends StatelessWidget {
  const Drop({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Product Selector',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: const ProductPage(),
    );
  }
}

class ProductPage extends StatelessWidget {
  const ProductPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Product Page")),
      body: Center(
        child: GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (_) => const ProductSelectionSheet(),
            );
          },
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xffEB7720)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '500 ML',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.black),
                ),
                const Icon(Icons.keyboard_arrow_down, color: Color(0xffEB7720)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProductSelectionSheet extends StatelessWidget {
  const ProductSelectionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> items = [
      {
        'quantity': '500 ML',
        'unit': '12 Pieces',
        'stock': 'In Stock',
        'outOfStock': false
      },
      {
        'quantity': '1 L',
        'unit': '30 Pieces',
        'stock': 'In Stock',
        'outOfStock': false
      },
      {
        'quantity': '2 L',
        'unit': '15 Pieces',
        'stock': 'Out Of Stock',
        'outOfStock': true
      },
      {
        'quantity': '5 L',
        'unit': '6 Pieces',
        'stock': 'In Stock',
        'outOfStock': false
      },
      {
        'quantity': '10 L',
        'unit': '20 Pieces',
        'stock': 'In Stock',
        'outOfStock': false
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'OXFEN',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xffEB7720),
                    fontSize: 16,
                  ),
                ),
              ),
              Divider(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Oxyflourfen 23.5% EC',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ),
              Text(
                '(Fungicide)',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                // Header row
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _HeaderText('Quantity'),
                      _HeaderText('Unit Size'),
                      _HeaderText('Stock'),
                    ],
                  ),
                ),
                // Item rows
                ...items.map((item) {
                  final bool isOutOfStock = item['outOfStock'] as bool;
                  final String quantity = item['quantity'] as String;
                  final String unit = item['unit'] as String;
                  final String stock = item['stock'] as String;

                  return Container(
                    color: isOutOfStock ? const Color(0xFFFFEEEE) : null,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _CellText(quantity),
                        _CellText(unit),
                        Text(
                          stock,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: isOutOfStock ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _HeaderText(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
    );
  }

  Widget _CellText(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(fontSize: 12),
    );
  }
}
