import 'package:flutter/foundation.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  String _currentTheme = 'default';
  String _currentRole = 'child'; // Default role for theming

  bool get isDarkMode => _isDarkMode;
  String get currentTheme => _currentTheme;
  String get currentRole => _currentRole;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setTheme(String theme) {
    _currentTheme = theme;
    notifyListeners();
  }
  
  void setRole(String role) {
    _currentRole = role;
    notifyListeners();
  }
  
  // Get role-based color scheme
  ShadColorScheme getRoleColorScheme(bool isDark) {
    // For the French version, we'll implement a different theme approach
    // Different color schemes based on user role
    if (_currentTheme != 'default') {
      // If a specific theme is selected, use it regardless of role
      switch (_currentTheme) {
        case 'blue':
          return isDark ? const ShadBlueColorScheme.dark() : const ShadBlueColorScheme.light();
        case 'green':
          return isDark ? const ShadGreenColorScheme.dark() : const ShadGreenColorScheme.light();
        case 'orange':
          return isDark ? const ShadOrangeColorScheme.dark() : const ShadOrangeColorScheme.light();
        case 'red':
          return isDark ? const ShadRedColorScheme.dark() : const ShadRedColorScheme.light();
        case 'violet':
          return isDark ? const ShadVioletColorScheme.dark() : const ShadVioletColorScheme.light();
        case 'zinc':
          return isDark ? const ShadZincColorScheme.dark() : const ShadZincColorScheme.light();
        default:
          return isDark ? const ShadSlateColorScheme.dark() : const ShadSlateColorScheme.light();
      }
    } else {
      // Default role-based theming for the French version
      switch (_currentRole) {
        case 'child':
          // Softer, friendlier colors for children
          return isDark 
              ? const ShadGreenColorScheme.dark() 
              : const ShadGreenColorScheme.light();
        case 'parent':
          // More professional, calm colors for parents
          return isDark 
              ? const ShadBlueColorScheme.dark() 
              : const ShadBlueColorScheme.light();
        case 'psychologist':
          // Soothing, professional colors for psychologists
          return isDark 
              ? const ShadVioletColorScheme.dark() 
              : const ShadVioletColorScheme.light();
        default:
          // Default theme
          return isDark ? const ShadSlateColorScheme.dark() : const ShadSlateColorScheme.light();
      }
    }
  }
}