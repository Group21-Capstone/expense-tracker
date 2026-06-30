import 'package:flutter/material.dart';
import 'package:exp/core/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _prefsKey = 'isDarkMode';

  bool _isDarkMode;

  ThemeProvider({required bool initialIsDarkMode})
      : _isDarkMode = initialIsDarkMode;

  /// Reads the stored preference once at startup, before runApp(), so the
  /// first frame already uses the user's chosen theme (no flash).
  static Future<bool> loadInitialMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) ?? true;
  }

  bool get isDarkMode => _isDarkMode;
  ThemeData get theme => _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, _isDarkMode);
  }
}
