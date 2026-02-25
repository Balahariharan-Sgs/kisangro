import 'package:flutter/material.dart';
import 'package:kisangro/login/splashscreen.dart';
import 'package:kisangro/menu/transaction.dart';
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
import 'package:kisangro/home/noti.dart'; // Import noti.dart directly (no prefix needed)
import 'package:firebase_core/firebase_core.dart';
import 'common/common_app_bar.dart'; // Import common_app_bar.dart directly (no prefix needed)
import 'home/theme_mode_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("📱 Background message received: ${message.notification?.title}");
}

// ADD THIS - Initialize local notifications
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // ADD THIS - Setup local notifications for foreground
  await setupForegroundNotifications();

  FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler);

  // ADD THIS - Listen to foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("📱 Foreground message received: ${message.notification?.title}");
    showForegroundNotification(message);
  });

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
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        // Use the provider directly (no prefix needed)
        ChangeNotifierProvider(
          create: (context) =>
              NotificationProvider()..loadNotificationState(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

// ADD THIS FUNCTION - Setup notification channel
Future<void> setupForegroundNotifications() async {
  // Android settings
  const AndroidInitializationSettings androidSettings = 
      AndroidInitializationSettings('@mipmap/ic_launcher');
  
  const DarwinInitializationSettings iosSettings = 
      DarwinInitializationSettings();
  
  // ✅ CORRECT - Using named parameters
  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  // ✅ CORRECT - initialize uses named parameter 'settings'
  await flutterLocalNotificationsPlugin.initialize(
    settings: initSettings,
  );

  // Create notification channel for Android
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'foreground_channel', // id
    'Foreground Notifications', // name
    description: 'Shows notifications when app is open',
    importance: Importance.high,
    playSound: true,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

// FIX THIS FUNCTION - Show notification when app is in foreground
Future<void> showForegroundNotification(RemoteMessage message) async {
  // Get notification details
  String title = message.notification?.title ?? 'New Notification';
  String body = message.notification?.body ?? '';
  
  // If no notification object, try to get from data payload
  if (title == 'New Notification' && message.data.containsKey('title')) {
    title = message.data['title'] ?? 'New Notification';
    body = message.data['body'] ?? '';
  }

  // Create a unique ID
  int id = DateTime.now().millisecond;

  // ✅ CORRECT SYNTAX - Using named parameters
  await flutterLocalNotificationsPlugin.show(
    id: id,  // Named parameter
    title: title,
    body: body,
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        'foreground_channel',
        'Foreground Notifications',
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'ticker',
        playSound: true,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
    payload: message.data.toString(),
  );
  
  print("✅ Foreground notification shown: $title");
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