import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisangro/home/theme_mode_provider.dart';
import 'package:provider/provider.dart'; // Import Provider
// Import the new ThemeModeProvider

// This main function is typically in main.dart, but kept here for self-containment if this is a standalone example.
// If this is part of a larger app, ensure MyApp in main.dart provides ThemeModeProvider.
void main() => runApp(MyOrdersApp());

class MyOrdersApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyOrdersPage(),
      debugShowCheckedModeBanner: false,
      // Theme is handled in main.dart's MaterialApp.
      // If this were a standalone app, you'd add theme and darkTheme here.
    );
  }
}

class MyOrdersPage extends StatelessWidget {
  final Color orange = const Color(0xFFFF7E1B); // Original orange color

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    final Color lightOrangeBackground = isDarkMode ? Colors.black : const Color(0xFFFFF4EC);
    final Color tabBarLabelColor = isDarkMode ? Colors.white : orange;
    final Color tabBarUnselectedLabelColor = isDarkMode ? Colors.white70 : Colors.black;
    final Color appBarIconColor = Colors.white; // Icons in app bar are always white

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: lightOrangeBackground, // Apply theme color
        appBar: AppBar(
          backgroundColor: orange, // AppBar remains orange
          leading: const Icon(Icons.arrow_back, color: Colors.white),
          title: Text("My Orders", style: GoogleFonts.poppins(color: appBarIconColor)),
          actions: [
            const Icon(Icons.local_shipping, color: Colors.white),
            Stack(
              children: [
                const Icon(Icons.favorite_border, color: Colors.white),
                Positioned(
                  right: 0,
                  child: CircleAvatar(
                    radius: 7,
                    backgroundColor: Colors.red,
                    child: Text("2", style: GoogleFonts.poppins(fontSize: 10, color: Colors.white)),
                  ),
                )
              ],
            ),
            const Icon(Icons.notifications_none, color: Colors.white),
            const SizedBox(width: 10),
          ],
          bottom: TabBar(
            labelColor: tabBarLabelColor, // Apply theme color
            unselectedLabelColor: tabBarUnselectedLabelColor, // Apply theme color
            indicatorColor: orange, // Indicator remains orange
            tabs: const [
              Tab(text: "Booked"),
              Tab(text: "Dispatched"),
              Tab(text: "Delivered"),
              Tab(text: "Canceled"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Center(child: Text("Booked", style: GoogleFonts.poppins(color: isDarkMode ? Colors.white : Colors.black))), // Apply theme color
            DispatchedTab(isDarkMode: isDarkMode), // Pass isDarkMode
            Center(child: Text("Delivered", style: GoogleFonts.poppins(color: isDarkMode ? Colors.white : Colors.black))), // Apply theme color
            Center(child: Text("Canceled", style: GoogleFonts.poppins(color: isDarkMode ? Colors.white : Colors.black))), // Apply theme color
          ],
        ),
      ),
    );
  }
}

class DispatchedTab extends StatelessWidget {
  final bool isDarkMode; // New parameter

  const DispatchedTab({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        OrderCard(
          imagePath: 'assets/Valaxa 1.png',
          productName: "AURASTAR",
          description: "Azoxistrobin 23 % EC",
          quantity: "02",
          cost: "₹ 37,200",
          unit: "1 L",
          orderId: "1234567",
          orderedOn: "03/11/2024  2:40 pm",
          isDarkMode: isDarkMode, // Pass isDarkMode
        ),
        const SizedBox(height: 12),
        SmallOrderCard(isDarkMode: isDarkMode), // Pass isDarkMode
        const SizedBox(height: 12),
        SmallOrderCard(isDarkMode: isDarkMode), // Pass isDarkMode
      ],
    );
  }
}

class OrderCard extends StatelessWidget {
  final String imagePath, productName, description, quantity, cost, unit, orderId, orderedOn;
  final bool isDarkMode; // New parameter

  OrderCard({
    super.key,
    required this.imagePath,
    required this.productName,
    required this.description,
    required this.quantity,
    required this.cost,
    required this.unit,
    required this.orderId,
    required this.orderedOn,
    required this.isDarkMode, // Initialize new parameter
  });

  @override
  Widget build(BuildContext context) {
    final Color cardBackgroundColor = isDarkMode ? Colors.grey[850]! : Colors.blue.shade50;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color greyTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final Color orangeColor = const Color(0xFFFF7E1B); // Original orange color

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: cardBackgroundColor, // Apply theme color
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(imagePath), // Removed color property
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(productName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)), // Apply theme color
                    Text(description, style: GoogleFonts.poppins(fontSize: 14, color: greyTextColor)), // Apply theme color
                    const SizedBox(height: 4),
                    Text("Ordered Units: $quantity", style: GoogleFonts.poppins(color: textColor)), // Apply theme color
                    Text("Total Cost: $cost", style: GoogleFonts.poppins(color: orangeColor)), // Remains orange
                    const SizedBox(height: 4),
                    Text("Order ID: $orderId", style: GoogleFonts.poppins(color: textColor)), // Apply theme color
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: orangeColor, // Remains orange
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Text(unit, style: GoogleFonts.poppins(color: Colors.white)),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white, // Apply theme color
                            foregroundColor: orangeColor, // Remains orange
                            side: BorderSide(color: orangeColor), // Remains orange
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text("Track Status", style: GoogleFonts.poppins(color: orangeColor)), // Remains orange
                        )
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          Text("Ordered On: $orderedOn", style: GoogleFonts.poppins(color: textColor)), // Apply theme color
        ],
      ),
    );
  }
}

class SmallOrderCard extends StatelessWidget {
  final bool isDarkMode; // New parameter

  const SmallOrderCard({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color orangeColor = const Color(0xFFFF7E1B); // Original orange color
    final Color borderColor = isDarkMode ? Colors.grey[700]! : Colors.black; // Adjust border color

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 30,
                width: 65,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor), // Apply theme color
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text("2 Items", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)), // Apply theme color
              ),
              const Spacer(),
              Text("Ordered On: 03/11/2024  2:40 pm", style: GoogleFonts.poppins(color: textColor)), // Apply theme color
              Icon(Icons.arrow_forward, size: 18, color: textColor), // Apply theme color
            ],
          ),
          const SizedBox(height: 8),
          Text("AURASTAR, VALAX", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)), // Apply theme color
          const SizedBox(height: 4),
          Text("Total Cost: ₹ 37,200", style: GoogleFonts.poppins(color: orangeColor)), // Remains orange
          Row(
            children: [
              Text("Order ID: 1234567", style: GoogleFonts.poppins(color: textColor)), // Apply theme color
              const SizedBox(width: 60),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white, // Apply theme color
                  foregroundColor: orangeColor, // Remains orange
                  side: BorderSide(color: orangeColor), // Remains orange
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                ),
                child: Text("Track Status", style: GoogleFonts.poppins(color: orangeColor)), // Remains orange
              )
            ],
          ),
        ],
      ),
    );
  }
}
