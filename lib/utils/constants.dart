import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryColor = Color(0xFF333333);  // Dark gray
  static const Color secondaryColor = Color(0xFFEEEEEE);  // Light gray
  static const Color accentColor = Color(0xFF008080);  // Teal
  static const Color errorColor = Color(0xFFD32F2F);  // Red for errors
}

class SensorConstants {
  // Distance thresholds (in cm)
  static const double dangerDistance = 10.0;
  static const double warningDistance = 20.0;
  static const double safeDistance = 50.0;
  
  // Temperature thresholds (in °C)
  static const double freezingTemp = 0.0;
  static const double coldTemp = 20.0;
  static const double normalTemp = 30.0;
  static const double hotTemp = 40.0;
  
  // Humidity thresholds (in %)
  static const double lowHumidity = 30.0;
  static const double normalHumidity = 60.0;
  static const double highHumidity = 80.0;
  
  // Sensor update intervals
  static const Duration sensorUpdateInterval = Duration(seconds: 1);
  static const Duration maxSensorAge = Duration(seconds: 5);
}

class AppTheme {
  static ThemeData getTheme() {
    return ThemeData(
      primaryColor: AppColors.primaryColor,
      scaffoldBackgroundColor: AppColors.secondaryColor,
      colorScheme: const ColorScheme.light( // Add const
        primary: AppColors.primaryColor,
        secondary: AppColors.accentColor,
        error: AppColors.errorColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.secondaryColor,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.accentColor,
        thumbColor: AppColors.accentColor,
        inactiveTrackColor: AppColors.primaryColor.withAlpha((0.3 * 255).round()), // Replace withOpacity
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentColor,
          foregroundColor: AppColors.secondaryColor,
        ),
      ),
    );
  }
}
