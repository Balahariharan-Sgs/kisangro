import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ForegroundNotificationHandler {
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  // Initialize only for foreground notifications
  static Future<void> init() async {
    // Setup Android notification channel
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings = 
        DarwinInitializationSettings();
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,  // Fixed: named parameter
    );

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'foreground_channel', // id
      'Foreground Notifications', // name
      description: 'Shows notifications when app is open',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Listen to foreground messages
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
  }

  // Show notification when app is in foreground
  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    // Get notification details from the message
    String title = message.notification?.title ?? 'Notification';
    String body = message.notification?.body ?? 'You have a new notification';
    
    // Create unique ID
    int id = DateTime.now().millisecond;
    
    // FIX: Use named parameters for show()
    await _localNotifications.show(
      id: id,  // Required named parameter
      title: title,
      body: body,
      payload: message.data.toString(),
      notificationDetails: const NotificationDetails(  // Changed to named parameter
        android: AndroidNotificationDetails(
          'foreground_channel',
          'Foreground Notifications',
          importance: Importance.high,
          priority: Priority.high,
          ticker: 'ticker',
        ),
      ),
    );
    
    print('✅ Foreground notification shown: $title');
  }
}