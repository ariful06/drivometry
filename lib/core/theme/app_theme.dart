// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const _primaryColor = Color(0xFF1E88E5);
  static const _secondaryColor = Color(0xFF26C6DA);
  static const _errorColor = Color(0xFFE53935);

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: _primaryColor,
          secondary: _secondaryColor,
          error: _errorColor,
          surface: Color(0xFFF5F7FA),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1A1A2E),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Color(0xFF1A1A2E),
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _primaryColor, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          labelStyle: const TextStyle(color: Color(0xFF757575)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: _primaryColor,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: CircleBorder(),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: _primaryColor,
          unselectedItemColor: Color(0xFF9E9E9E),
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFF5F7FA),
          selectedColor: _primaryColor.withOpacity(0.15),
          labelStyle: const TextStyle(fontSize: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        extensions: const [AppColors.light],
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: _primaryColor,
          secondary: _secondaryColor,
          error: _errorColor,
          surface: Color(0xFF1A1A2E),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F0F1A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A2E),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1A1A2E),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1A1A2E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2E2E4E)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2E2E4E)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _primaryColor, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          labelStyle: const TextStyle(color: Color(0xFF9E9E9E)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: _primaryColor,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: CircleBorder(),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1A1A2E),
          selectedItemColor: _primaryColor,
          unselectedItemColor: Color(0xFF616161),
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFF1A1A2E),
          selectedColor: _primaryColor.withOpacity(0.25),
          labelStyle: const TextStyle(fontSize: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        extensions: const [AppColors.dark],
      );
}

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.success,
    required this.warning,
    required this.cardBackground,
    required this.divider,
    required this.textSecondary,
    required this.fuelColor,
    required this.maintenanceColor,
    required this.partsColor,
  });

  final Color success;
  final Color warning;
  final Color cardBackground;
  final Color divider;
  final Color textSecondary;
  final Color fuelColor;
  final Color maintenanceColor;
  final Color partsColor;

  static const light = AppColors(
    success: Color(0xFF43A047),
    warning: Color(0xFFFB8C00),
    cardBackground: Colors.white,
    divider: Color(0xFFE0E0E0),
    textSecondary: Color(0xFF757575),
    fuelColor: Color(0xFF1E88E5),
    maintenanceColor: Color(0xFF43A047),
    partsColor: Color(0xFFFB8C00),
  );

  static const dark = AppColors(
    success: Color(0xFF66BB6A),
    warning: Color(0xFFFFB74D),
    cardBackground: Color(0xFF1A1A2E),
    divider: Color(0xFF2E2E4E),
    textSecondary: Color(0xFF9E9E9E),
    fuelColor: Color(0xFF42A5F5),
    maintenanceColor: Color(0xFF66BB6A),
    partsColor: Color(0xFFFFB74D),
  );

  @override
  AppColors copyWith({
    Color? success,
    Color? warning,
    Color? cardBackground,
    Color? divider,
    Color? textSecondary,
    Color? fuelColor,
    Color? maintenanceColor,
    Color? partsColor,
  }) {
    return AppColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      cardBackground: cardBackground ?? this.cardBackground,
      divider: divider ?? this.divider,
      textSecondary: textSecondary ?? this.textSecondary,
      fuelColor: fuelColor ?? this.fuelColor,
      maintenanceColor: maintenanceColor ?? this.maintenanceColor,
      partsColor: partsColor ?? this.partsColor,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      fuelColor: Color.lerp(fuelColor, other.fuelColor, t)!,
      maintenanceColor:
          Color.lerp(maintenanceColor, other.maintenanceColor, t)!,
      partsColor: Color.lerp(partsColor, other.partsColor, t)!,
    );
  }
}
