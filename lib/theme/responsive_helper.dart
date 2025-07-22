import 'package:flutter/material.dart';

class ResponsiveHelper {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double smallMobileBreakpoint = 400;
  static const double smallHeightBreakpoint = 700;

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  static bool isSmallMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < smallMobileBreakpoint;
  }

  static bool isSmallHeight(BuildContext context) {
    return MediaQuery.of(context).size.height < smallHeightBreakpoint;
  }

  static bool isCompactDevice(BuildContext context) {
    return isSmallMobile(context) || isSmallHeight(context);
  }

  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= mobileBreakpoint &&
           MediaQuery.of(context).size.width < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  // Responsive padding
  static double responsivePadding(BuildContext context, {double mobile = 16, double tablet = 24, double desktop = 32}) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  // Responsive font size
  static double responsiveFontSize(BuildContext context, {double mobile = 12, double tablet = 16, double desktop = 18}) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  // Responsive spacing
  static double responsiveSpacing(BuildContext context, {double mobile = 8, double tablet = 12, double desktop = 16}) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  // Responsive width percentage
  static double responsiveWidth(BuildContext context, {double mobile = 0.9, double tablet = 0.8, double desktop = 0.7}) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  // Specific helpers for common use cases
  static double screenWidth(BuildContext context) => MediaQuery.of(context).size.width;
  static double screenHeight(BuildContext context) => MediaQuery.of(context).size.height;

  // Card width based on screen size
  static double cardWidth(BuildContext context) {
    final width = screenWidth(context);
    if (width < 400) return width * 0.9;  // Small phones
    if (width < 600) return width * 0.85; // Normal phones
    return width * 0.8; // Tablets and larger
  }

  // Header height based on screen size  
  static double headerHeight(BuildContext context) {
    final height = screenHeight(context);
    final width = screenWidth(context);
    if (height < 700 || width < 400) return 280.0; // Small screens like Galaxy S24 - très compact
    if (height < 800) return 320.0; // Normal screens - compact
    return 360.0; // Large screens - standard
  }

  // Logo size based on screen width
  static double logoSize(BuildContext context) {
    final width = screenWidth(context);
    if (width < 400) return width * 0.12;  // Very small screens
    if (width < 600) return width * 0.15;  // Small screens
    return width * 0.18; // Larger screens
  }

  // Button width for social auth buttons
  static double buttonWidth(BuildContext context) {
    final width = screenWidth(context);
    if (width < 400) return width * 0.35;  // Small screens
    return width * 0.4; // Normal and large screens
  }

  // Vehicle card dimensions
  static Size vehicleCardSize(BuildContext context) {
    final width = screenWidth(context);
    if (width < 400) return Size(width * 0.25, width * 0.15);  // Small screens
    return Size(width * 0.3, width * 0.2); 
  }  
  

  static Size infoCardSize(BuildContext context) {
    final width = screenWidth(context);
    final height = screenHeight(context);
    if (width < 400 || height < 700) return const Size(95.0, 90.0);   // Very small screens like Galaxy S24 - très compact
    if (width < 600) return const Size(110.0, 100.0);  // Small screens
    return const Size(118.0, 108.0); // Normal and large screens - taille originale
  }

  // Brand logo size in vehicle detail header
  static Size brandLogoSize(BuildContext context) {
    final width = screenWidth(context);
    if (width < 400) return const Size(70.0, 40.0);   // Small screens - un peu plus grand
    if (width < 600) return const Size(76.0, 42.0);   // Normal screens - légèrement augmenté
    return const Size(81.0, 27.0); // Large screens - taille originale
  }

  // Vehicle image size in vehicle detail header  
  static Size vehicleImageSize(BuildContext context) {
    final width = screenWidth(context);
    if (width < 400) return const Size(250.0, 150.0);  // Small screens - réduit de 304x194
    if (width < 600) return const Size(280.0, 170.0);  // Normal screens
    return const Size(304.0, 194.0); // Large screens - taille originale
  }
}

