import 'package:flutter/material.dart';
import 'package:kisangro/login/splashscreen.dart';
import 'package:kisangro/models/address_model.dart';
import 'package:provider/provider.dart';
import 'package:kisangro/home/bottom.dart';
import 'package:kisangro/models/cart_model.dart';
import 'package:kisangro/models/wishlist_model.dart';
import 'package:kisangro/models/order_model.dart';
import 'package:kisangro/models/kyc_image_provider.dart';
import 'package:kisangro/services/product_service.dart';
import 'package:kisangro/models/kyc_business_model.dart';
import 'package:kisangro/models/license_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisangro/home/notification_manager.dart';
import 'package:kisangro/home/noti.dart';
import 'package:firebase_core/firebase_core.dart';
import 'common/common_app_bar.dart';
import 'home/theme_mode_provider.dart';

void main() async {                            // ✅ make async
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ProductService()),
        ChangeNotifierProvider(create: (context) => CartModel()),
        ChangeNotifierProvider(create: (context) => WishlistModel()),
        ChangeNotifierProvider(create: (context) => OrderModel()),
        ChangeNotifierProvider(create: (context) => KycImageProvider()),
        ChangeNotifierProvider(create: (context) => AddressModel()),
        ChangeNotifierProvider(create: (context) => LicenseProvider()),
        ChangeNotifierProvider(create: (context) => KycBusinessDataProvider()),
        ChangeNotifierProvider(create: (context) => ThemeModeProvider()),
        ChangeNotifierProvider(create: (context) => NotificationManager()),
        ChangeNotifierProvider(
          create: (context) =>
              NotificationProvider()..loadNotificationState(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode =
        Provider.of<ThemeModeProvider>(context).themeMode;

    return MaterialApp(
      title: 'Kisangro App',
      debugShowCheckedModeBanner: false,

      // ✅ LIGHT THEME (SAFE)
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: const Color(0xFFFFF7F1),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xffEB7720),
          foregroundColor: Colors.white,
        ),
        cardColor: Colors.white,
        dividerColor: Colors.grey,
      ),

      // ✅ DARK THEME (SAFE)
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: Colors.black,
        canvasColor: Colors.black,
        cardColor: Colors.grey,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xffEB7720),
          foregroundColor: Colors.white,
        ),
        dividerColor: Colors.grey,
      ),

      themeMode: themeMode,
      home: const splashscreen(),
    );
  }
}
