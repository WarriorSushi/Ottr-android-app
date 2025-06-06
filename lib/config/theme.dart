// Flutter imports
import 'package:flutter/material.dart';

// Color constants defined in Windsurf Rules
const primaryColor = Color(0xFF2196F3);
const primaryVariant = Color(0xFF1976D2);
const secondaryColor = Color(0xFF4CAF50);
const errorColor = Color(0xFFF44336);
const backgroundColor = Color(0xFFFFFFFF);
const surfaceColor = Color(0xFFF5F5F5);
const messageSentColor = Color(0xFFE3F2FD);
const messageReceivedColor = Color(0xFFF5F5F5);

// App theme using Material 3
final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: const ColorScheme(
    primary: primaryColor,
    onPrimary: Colors.white,
    secondary: secondaryColor,
    onSecondary: Colors.white,
    error: errorColor,
    onError: Colors.white,
    surface: backgroundColor, // Replacing background with surface
    onSurface: Colors.black87, // Replacing onBackground with onSurface
    surfaceTint: surfaceColor,
    brightness: Brightness.light,
  ),
  scaffoldBackgroundColor: backgroundColor,
  appBarTheme: const AppBarTheme(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    centerTitle: true,
    elevation: 0,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: primaryColor,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: surfaceColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: primaryColor),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: errorColor),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
);
