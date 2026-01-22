import 'package:flutter/foundation.dart';

class NotificationManager with ChangeNotifier {
  static final NotificationManager _instance = NotificationManager._internal();

  factory NotificationManager() {
    return _instance;
  }

  NotificationManager._internal();

  bool _hasUnreadNotifications = false;

  bool get hasUnreadNotifications => _hasUnreadNotifications;

  void setUnreadStatus(bool hasUnread) {
    if (_hasUnreadNotifications != hasUnread) {
      _hasUnreadNotifications = hasUnread;
      notifyListeners();
    }
  }

  void markAllAsRead() {
    if (_hasUnreadNotifications) {
      _hasUnreadNotifications = false;
      notifyListeners();
    }
  }
}