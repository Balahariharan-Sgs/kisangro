import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisangro/menu/chat.dart';
import 'package:kisangro/home/cart.dart';
import 'package:kisangro/menu/wishlist.dart';
import 'package:kisangro/home/noti.dart';
import 'package:provider/provider.dart';
import '../home/theme_mode_provider.dart';
import '../common/common_app_bar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AskUsPage extends StatefulWidget {
  @override
  _AskUsPageState createState() => _AskUsPageState();
}

class _AskUsPageState extends State<AskUsPage> {
  final List<bool> _commonExpanded = [false, false, false, false, false];
  final List<bool> _buyersExpanded = [false, false, false, false, false];

  // API data variables
  Map<String, dynamic>? _apiData;
  bool _isLoading = true;
  String? _errorMessage;
  String _contactPhone = "9092899444";
  String _contactSupport = "24/7 Assistance available";

  // Sample answer as fallback
  final String sampleAnswer =
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut";

  @override
  void initState() {
    super.initState();
    _fetchFAQData();
  }

  Future<void> _fetchFAQData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('https://erpsmart.in/total/api/m_api/'),
        body: {
          'cid': '85788578',
          'type': '1037',
          'ln': '145',
          'lt': '123',
          'device_id': '1',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print('FAQ Response: $jsonResponse');

        if (jsonResponse['error'] == false && jsonResponse['data'] != null) {
          setState(() {
            _apiData = jsonResponse['data'];

            // Update contact details
            if (_apiData!['contact_details'] != null) {
              _contactPhone =
                  _apiData!['contact_details']['phone']?.toString() ??
                  '9092899444';
              _contactSupport =
                  _apiData!['contact_details']['support']?.toString() ??
                  '24/7 Assistance available';
            }

            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage =
                jsonResponse['message'] ?? 'Failed to load FAQ data';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Server error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching FAQ data: $e');
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  // Helper method to get common queries
  List<Map<String, String>> get _commonQueries {
    if (_apiData != null && _apiData!['common_queries'] != null) {
      return List<Map<String, String>>.from(
        (_apiData!['common_queries'] as List).map(
          (item) => {
            'question': item['question']?.toString() ?? '',
            'answer': item['answer']?.toString() ?? sampleAnswer,
          },
        ),
      );
    }
    // Fallback data
    return [
      {
        'question': 'How can I sell my products on KisanAgro?',
        'answer':
            'Register as a seller, add your product details, and submit for approval before listing.',
      },
      {
        'question': 'Which payment methods are available?',
        'answer':
            'You can pay using UPI, debit/credit cards, net banking, or cash on delivery (if available).',
      },
      {
        'question': 'How can I check product quality and details?',
        'answer':
            'Open the product page to view specifications, usage instructions, and reviews.',
      },
      {
        'question': 'Can I order products in bulk?',
        'answer':
            'Yes, bulk orders are supported. Contact the seller or support for special pricing.',
      },
      {
        'question': 'How can I contact customer support?',
        'answer':
            'Use the Ask Us section in the app or call the support number provided.',
      },
    ];
  }

  // Helper method to get buyer queries
  List<Map<String, String>> get _buyerQueries {
    if (_apiData != null && _apiData!['buyer_queries'] != null) {
      return List<Map<String, String>>.from(
        (_apiData!['buyer_queries'] as List).map(
          (item) => {
            'question': item['question']?.toString() ?? '',
            'answer': item['answer']?.toString() ?? sampleAnswer,
          },
        ),
      );
    }
    // Fallback data
    return [
      {
        'question': 'How do I buy products on KisanAgro?',
        'answer':
            'Browse products, add items to your cart, and complete checkout to place your order.',
      },
      {
        'question': 'How do I track my order?',
        'answer':
            'Go to My Orders and select the order to view its current status.',
      },
      {
        'question': 'How long does delivery take?',
        'answer':
            'Delivery usually takes 2–7 business days depending on your location.',
      },
      {
        'question': 'Can I cancel my order?',
        'answer':
            'Yes, you can cancel the order before it is dispatched from the My Orders section.',
      },
      {
        'question': 'What should I do if I receive damaged or wrong products?',
        'answer':
            'Contact support immediately and share photos for quick replacement or resolution.',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    // Define colors based on theme
    final Color gradientStartColor =
        isDarkMode ? Colors.black : const Color(0xffFFD9BD);
    final Color gradientEndColor =
        isDarkMode ? Colors.black : const Color(0xffFFFFFF);
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;
    final Color titleColor = isDarkMode ? Colors.white : Colors.black;
    final Color dividerColor = isDarkMode ? Colors.grey[700]! : Colors.grey;

    return Scaffold(
      appBar: CustomAppBar(
        title: "Ask Us!",
        showBackButton: true,
        showMenuButton: false,
        isMyOrderActive: false,
        isWishlistActive: false,
        isNotiActive: false,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [gradientStartColor, gradientEndColor],
          ),
        ),
        child: Stack(
          children: [
            _isLoading
                ? Center(
                  child: CircularProgressIndicator(
                    color: const Color(0xffEB7720),
                  ),
                )
                : _errorMessage != null
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 60),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load FAQs',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: textColor.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _fetchFAQData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xffEB7720),
                        ),
                        child: Text(
                          'Retry',
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                )
                : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row with image and text
                      Padding(
                        padding: const EdgeInsets.only(left: 50),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/ask1.png',
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 20),
                                child: RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.lato(
                                      fontSize: 17,
                                      color: textColor,
                                      height: 1.3,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: '‘Stuck?\nLet Us Untangle It\n',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                        ),
                                      ),
                                      TextSpan(
                                        text: "For You!’",
                                        style: GoogleFonts.lato(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                          color: titleColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Contact box with dynamic phone and support
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 267,
                          height: 64,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: const LinearGradient(
                              colors: [Color(0xffEB7720), Color(0xffF59A4A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xffEB7720,
                                ).withOpacity(0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.phone,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),

                                const SizedBox(width: 12),

                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Contact us',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    Text(
                                      _contactPhone,
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ],
                                ),

                                const Spacer(),

                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Divider(color: dividerColor),

                      _buildSectionTitle('Common Queries', textColor),
                      const SizedBox(height: 12),
                      ...List.generate(_commonQueries.length, (index) {
                        final query = _commonQueries[index];
                        return _buildCustomExpansionTile(
                          title: '${index + 1}. ${query['question']}',
                          isExpanded:
                              index < _commonExpanded.length
                                  ? _commonExpanded[index]
                                  : false,
                          onExpansionChanged: (expanded) {
                            setState(() {
                              if (index < _commonExpanded.length) {
                                _commonExpanded[index] = expanded;
                              }
                            });
                          },
                          answer: query['answer'] ?? sampleAnswer,
                          isDarkMode: isDarkMode,
                        );
                      }),
                      const SizedBox(height: 32),

                      _buildSectionTitle('Buyers Queries', textColor),
                      const SizedBox(height: 12),
                      ...List.generate(_buyerQueries.length, (index) {
                        final query = _buyerQueries[index];
                        return _buildCustomExpansionTile(
                          title: '${index + 1}. ${query['question']}',
                          isExpanded:
                              index < _buyersExpanded.length
                                  ? _buyersExpanded[index]
                                  : false,
                          onExpansionChanged: (expanded) {
                            setState(() {
                              if (index < _buyersExpanded.length) {
                                _buyersExpanded[index] = expanded;
                              }
                            });
                          },
                          answer: query['answer'] ?? sampleAnswer,
                          isDarkMode: isDarkMode,
                        );
                      }),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Column(
      children: [
        Center(
          child: Text(
            title,
            style: GoogleFonts.lato(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Container(
            width: 60,
            height: 2,
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomExpansionTile({
    required String title,
    required bool isExpanded,
    required ValueChanged<bool> onExpansionChanged,
    required String answer,
    required bool isDarkMode,
  }) {
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;
    final Color expansionTileBgColor =
        isDarkMode ? Colors.grey[850]! : Colors.white;
    final Color expansionTileShadowColor =
        isDarkMode ? Colors.transparent : Colors.black.withOpacity(0.03);
    final Color expansionTileIconColor =
        isDarkMode ? Colors.white70 : Colors.black54;
    final Color dividerColor =
        isDarkMode ? Colors.grey[700]! : Colors.grey.shade400;

    if (!isExpanded) {
      return ListTile(
        title: Text(
          title,
          style: GoogleFonts.lato(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        trailing: Icon(
          Icons.keyboard_arrow_down,
          color: expansionTileIconColor,
        ),
        onTap: () => onExpansionChanged(true),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        dense: true,
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: expansionTileBgColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: expansionTileShadowColor,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              title,
              style: GoogleFonts.lato(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
            trailing: Icon(
              Icons.keyboard_arrow_up,
              color: expansionTileIconColor,
            ),
            onTap: () => onExpansionChanged(false),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 0,
            ),
            dense: true,
          ),
          Divider(
            color: dividerColor,
            thickness: 1,
            height: 1,
            indent: 16,
            endIndent: 16,
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              answer,
              style: GoogleFonts.lato(fontSize: 12, color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}
