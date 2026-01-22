import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FungicideScreen3 extends StatefulWidget {
  const FungicideScreen3({super.key});

  @override
  State<FungicideScreen3> createState() => _FungicideScreenState();
}

class _FungicideScreenState extends State<FungicideScreen3> {
  String selectedCategory = 'Insecticides';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fungicide Products'),
        backgroundColor: const Color(0xffEB7720),
      ),
      body: Column(
        children: [
          buildSectionHeaderWithSort(),
          // Your product list or other UI here
        ],
      ),
    );
  }

  Widget buildSectionHeaderWithSort() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: Colors.grey[200],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Top Categories',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                isScrollControlled: true,
                backgroundColor: Colors.white,
                builder: (context) => CategorySelectorSheet(
                  selected: selectedCategory,
                  onSelected: (category) {
                    setState(() {
                      selectedCategory = category;
                    });
                    Navigator.pop(context);
                  },
                ),
              );
            },
            icon: const Icon(Icons.category, size: 18, color: Colors.white),
            label: Text(
              'Category',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffEB7720),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}

class CategorySelectorSheet extends StatefulWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const CategorySelectorSheet({
    Key? key,
    required this.selected,
    required this.onSelected,
  }) : super(key: key);

  @override
  _CategorySelectorSheetState createState() => _CategorySelectorSheetState();
}

class _CategorySelectorSheetState extends State<CategorySelectorSheet> {
  late String selectedCategory;

  final List<String> categories = [
    'Insecticides',
    'Fungicides',
    'Herbicides',
    'Plant Growth Promotor',
    'Micro Nutrients',
    'Bio Stimulants',
    'Water Soluble Fertilizers',
    'Liquid Fertilizers',
    'Organic Fertilizers',
    'Bio-Fertilizers And Biopesticides',
    'Specialty Product',
  ];

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Choose Category',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xffEB7720),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 100,
            height: 1.5,
            color: const Color(0xffEB7720),
          ),
          const SizedBox(height: 16),
          ...categories.map((category) {
            return RadioListTile<String>(
              title: Text(
                category,
                style: GoogleFonts.poppins(color: const Color(0xffEB7720)),
              ),
              value: category,
              groupValue: selectedCategory,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedCategory = value;
                  });
                  widget.onSelected(value);
                }
              },
              activeColor: const Color(0xffEB7720),
            );
          }).toList(),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(
                color: const Color(0xffEB7720),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
