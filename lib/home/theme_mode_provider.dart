import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A [ChangeNotifier] that manages the application's theme mode (light or dark).
/// It persists the selected theme mode using [SharedPreferences].
class ThemeModeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light; // Default theme mode

  ThemeMode get themeMode => _themeMode;

  ThemeModeProvider() {
    _loadThemeMode(); // Load theme mode when the provider is initialized
  }

  /// Loads the saved theme mode from SharedPreferences.
  /// Defaults to [ThemeMode.light] if no preference is found.
  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final String? themeString = prefs.getString('themeMode');
    if (themeString == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }
    notifyListeners(); // Notify listeners after theme mode is loaded
  }

  /// Sets the new theme mode and saves it to SharedPreferences.
  ///
  /// [newThemeMode]: The [ThemeMode] to set (light or dark).
  Future<void> setThemeMode(ThemeMode newThemeMode) async {
    if (_themeMode == newThemeMode) return; // No change, do nothing

    _themeMode = newThemeMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', newThemeMode == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners(); // Notify listeners that the theme mode has changed
  }

  /// Toggles the current theme mode between light and dark.
  Future<void> toggleThemeMode() async {
    final newThemeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(newThemeMode);
  }
}
