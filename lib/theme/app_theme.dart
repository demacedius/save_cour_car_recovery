import 'package:flutter/material.dart';
import '../theme/figma_color.dart';
import '../theme/figma_text_style.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: FigmaColors.neutral00,
      primaryColor: FigmaColors.primaryMain,
      fontFamily: 'Poppins',
      textTheme: TextTheme(
        headlineLarge: FigmaTextStyles().headingLBold,
        headlineMedium: FigmaTextStyles().headingMBold,
        headlineSmall: FigmaTextStyles().headingSBold,
        bodyLarge: FigmaTextStyles().textLBold,
        bodyMedium: FigmaTextStyles().textMRegular,
        bodySmall: FigmaTextStyles().captionSMedium,
        labelLarge: FigmaTextStyles().textMBold,
      ),
      colorScheme: ColorScheme.fromSwatch().copyWith(
        primary: FigmaColors.primaryMain,
        secondary: FigmaColors.secondaryYellowMain,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: FigmaColors.primaryMain,
          foregroundColor: FigmaColors.neutral00,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          textStyle: FigmaTextStyles().textLBold,
        ),
      ),
    );
  }
}