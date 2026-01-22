import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisangro/home/myorder.dart';
import 'package:kisangro/home/noti.dart';
import 'package:kisangro/menu/wishlist.dart';

class FungicideScreen2 extends StatefulWidget {
  const FungicideScreen2({super.key});

  @override
  State<FungicideScreen2> createState() => _FungicideScreenState();
}

class _FungicideScreenState extends State<FungicideScreen2> {
  String selectedSort = 'Price: Low to High';
  int currentPage = 1;
  final int totalPages = 23;
  final TextEditingController _controller = TextEditingController();

  final List<String> sortOptions = [
    'Price: Low to High',
    'Price: High to Low',
    'Name: A-Z',
    'Name: Z-A',
  ];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedIndex = 1;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      // Navigator.push(... to Home);
    } else if (index == 2) {
      // Navigator.push(... to Profile);
    }
  }

  @override
  void initState() {
    super.initState();
    _controller.text = currentPage.toString();
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= totalPages) {
      setState(() {
        currentPage = page;
        _controller.text = page.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF3D5C2),
      appBar: AppBar(
        backgroundColor: const Color(0xffEB7720),
        elevation: 0,
        title: Transform.translate(offset: Offset(-25, 0),
          child: Text("Fungicide",style: GoogleFonts.poppins(color: Colors.white,fontSize: 18),),),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => MyOrder()));
            },
            icon: Image.asset('assets/box.png', height: 24, width: 24, color: Colors.white),
          ),
          const SizedBox(width: 5),
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => WishlistPage()));
            },
            icon: Image.asset('assets/heart.png', height: 24, width: 24, color: Colors.white),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => noti()));
            },
            icon: Image.asset('assets/noti.png', height: 24, width: 24, color: Colors.white),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF3D5C2), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildSearchBar(),
              const SizedBox(height: 18),
              buildSectionHeaderWithSort(),
              const SizedBox(height: 12),
              buildDealGrid(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: currentPage > 1 ? () => _goToPage(currentPage - 1) : null,
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xff909090),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child:  Text('Previous', style: GoogleFonts.poppins(color: Colors.white)),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.purple, width: 1.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: TextField(
                      controller: _controller,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style:  GoogleFonts.poppins(fontSize: 16),
                      onSubmitted: (value) {
                        final page = int.tryParse(value);
                        if (page != null) {
                          _goToPage(page);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '/ $totalPages',
                    style:  GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: currentPage < totalPages ? () => _goToPage(currentPage + 1) : null,
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xffEB7720),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: const Text('Next'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search by item/crop/chemical name',
          hintStyle: GoogleFonts.poppins(fontSize: 14),
          suffix: const Icon(Icons.search, size: 22, color: Color(0xffEB7720)),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget buildSectionHeaderWithSort() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton.icon(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) {
                return Dialog(
                  backgroundColor: Colors.transparent,
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Image.asset(
                          'assets/category_popup.png', // 🔄 Replace with your image
                          fit: BoxFit.contain,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.black),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          icon: const Icon(Icons.filter_list, color: Colors.white),
          label:  Text(
            'Category',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
          ),
          style: TextButton.styleFrom(
            backgroundColor: const Color(0xffEB7720),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedSort,
              icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xffEB7720)),
              style: GoogleFonts.poppins(fontSize: 13, color: Color(0xffEB7720)),
              items: sortOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: GoogleFonts.poppins(fontSize: 13)),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  selectedSort = newValue!;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget buildDealGrid() {
    List<Map<String, String>> deals = [
      {'name': 'AURASTAR', 'image': 'assets/hyfen.png', 'old': '2000', 'new': '1550'},
      {'name': 'AZEEM', 'image': 'assets/Valaxa.png', 'old': '2000', 'new': '1000'},
      {'name': 'VALAX', 'image': 'assets/Valaxa.png', 'old': '2000', 'new': '1550'},
      {'name': 'OXYFEN', 'image': 'assets/Oxyfen.png', 'old': '2000', 'new': '1000'},
      {'name': 'OXYFEN', 'image': 'assets/Oxyfen.png', 'old': '2000', 'new': '1000'},
      {'name': 'OXYFEN', 'image': 'assets/Oxyfen.png', 'old': '2000', 'new': '1000'},
      {'name': 'OXYFEN', 'image': 'assets/Oxyfen.png', 'old': '2000', 'new': '1000'},
      {'name': 'OXYFEN', 'image': 'assets/Oxyfen.png', 'old': '2000', 'new': '1000'},
      {'name': 'OXYFEN', 'image': 'assets/Oxyfen.png', 'old': '2000', 'new': '1000'},
      {'name': 'OXYFEN', 'image': 'assets/Oxyfen.png', 'old': '2000', 'new': '1000'},
      {'name': 'OXYFEN', 'image': 'assets/Oxyfen.png', 'old': '2000', 'new': '1000'},
      {'name': 'OXYFEN', 'image': 'assets/Oxyfen.png', 'old': '2000', 'new': '1000'},
    ];

    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 140 / 150,
      children: deals.map((item) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Image.asset(item['image']!, height: 90),
              const SizedBox(height: 6),
              const Divider(),
              Text(item['name']!, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '₹${item['old']} ',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                      ),
                    ),
                    TextSpan(
                      text: '₹${item['new']}/piece',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
