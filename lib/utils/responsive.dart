import 'package:flutter/material.dart';

class Responsive {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 768;

  static bool isSmallMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 480;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 768 &&
      MediaQuery.of(context).size.width < 1200;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;

  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  // Get responsive padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isSmallMobile(context)) {
      return const EdgeInsets.all(12);
    } else if (isMobile(context)) {
      return const EdgeInsets.all(16);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(20);
    } else {
      return const EdgeInsets.all(24);
    }
  }

  // Get responsive spacing between elements
  static double getResponsiveSpacing(BuildContext context) {
    if (isSmallMobile(context)) {
      return 8.0;
    } else if (isMobile(context)) {
      return 12.0;
    } else if (isTablet(context)) {
      return 16.0;
    } else {
      return 20.0;
    }
  }

  // Get responsive font size multiplier
  static double getFontSizeMultiplier(BuildContext context) {
    if (isSmallMobile(context)) {
      return 0.85;
    } else if (isMobile(context)) {
      return 0.9;
    } else {
      return 1.0;
    }
  }

  // Get responsive card dimensions for admin pages
  static Map<String, double> getAdminCardDimensions(BuildContext context) {
    if (isSmallMobile(context)) {
      return {
        'width': 120.0,
        'height': 160.0,
        'padding': 8.0,
        'spacing': 8.0,
        'iconSize': 20.0,
        'fontSize': 10.0,
      };
    } else if (isMobile(context)) {
      return {
        'width': 140.0,
        'height': 180.0,
        'padding': 12.0,
        'spacing': 12.0,
        'iconSize': 24.0,
        'fontSize': 11.0,
      };
    } else if (isTablet(context)) {
      return {
        'width': 160.0,
        'height': 200.0,
        'padding': 16.0,
        'spacing': 16.0,
        'iconSize': 28.0,
        'fontSize': 12.0,
      };
    } else {
      return {
        'width': 180.0,
        'height': 220.0,
        'padding': 20.0,
        'spacing': 20.0,
        'iconSize': 32.0,
        'fontSize': 13.0,
      };
    }
  }

  // Get responsive grid configuration for admin pages
  static Map<String, dynamic> getAdminGridConfig(BuildContext context) {
    if (isSmallMobile(context)) {
      return {
        'crossAxisCount': 1,
        'childAspectRatio': 2.8,
        'spacing': 12.0,
        'padding': 12.0,
      };
    } else if (isMobile(context)) {
      return {
        'crossAxisCount': 1,
        'childAspectRatio': 2.4,
        'spacing': 16.0,
        'padding': 16.0,
      };
    } else if (isTablet(context)) {
      return {
        'crossAxisCount': 2,
        'childAspectRatio': 2.0,
        'spacing': 18.0,
        'padding': 20.0,
      };
    } else {
      return {
        'crossAxisCount': 3,
        'childAspectRatio': 1.8,
        'spacing': 20.0,
        'padding': 24.0,
      };
    }
  }

  // Get responsive metrics grid configuration
  static Map<String, dynamic> getMetricsGridConfig(BuildContext context) {
    if (isSmallMobile(context)) {
      return {
        'crossAxisCount': 1,
        'childAspectRatio': 2.2,
        'spacing': 8.0,
        'padding': 8.0,
      };
    } else if (isMobile(context)) {
      return {
        'crossAxisCount': 2,
        'childAspectRatio': 1.4,
        'spacing': 12.0,
        'padding': 12.0,
      };
    } else if (isTablet(context)) {
      return {
        'crossAxisCount': 2,
        'childAspectRatio': 1.2,
        'spacing': 16.0,
        'padding': 16.0,
      };
    } else {
      return {
        'crossAxisCount': 4,
        'childAspectRatio': 1.1,
        'spacing': 16.0,
        'padding': 20.0,
      };
    }
  }

  // Get responsive tab configuration
  static Map<String, dynamic> getTabConfig(BuildContext context) {
    if (isSmallMobile(context)) {
      return {
        'height': 44.0,
        'iconSize': 16.0,
        'fontSize': 9.0,
        'isScrollable': true,
      };
    } else if (isMobile(context)) {
      return {
        'height': 48.0,
        'iconSize': 18.0,
        'fontSize': 10.0,
        'isScrollable': true,
      };
    } else {
      return {
        'height': 56.0,
        'iconSize': 20.0,
        'fontSize': 12.0,
        'isScrollable': false,
      };
    }
  }

  // Get responsive home page service grid configuration
  static Map<String, dynamic> getHomeServiceGridConfig(BuildContext context) {
    if (isSmallMobile(context)) {
      return {
        'crossAxisCount': 2,
        'childAspectRatio': 1.8, // Shorter, wider cards for small mobile
        'crossAxisSpacing': 8.0,
        'mainAxisSpacing': 8.0,
        'padding': 12.0,
        'sectionPadding': 16.0,
      };
    } else if (isMobile(context)) {
      return {
        'crossAxisCount': 2,
        'childAspectRatio': 2.2, // Slightly taller cards for mobile
        'crossAxisSpacing': 12.0,
        'mainAxisSpacing': 12.0,
        'padding': 16.0,
        'sectionPadding': 20.0,
      };
    } else if (isTablet(context)) {
      return {
        'crossAxisCount': 3,
        'childAspectRatio': 2.5, // Medium height for tablets
        'crossAxisSpacing': 16.0,
        'mainAxisSpacing': 16.0,
        'padding': 20.0,
        'sectionPadding': 24.0,
      };
    } else {
      return {
        'crossAxisCount': 4,
        'childAspectRatio': 3.0, // Taller cards for desktop
        'crossAxisSpacing': 20.0,
        'mainAxisSpacing': 20.0,
        'padding': 24.0,
        'sectionPadding': 32.0,
      };
    }
  }

  // Get responsive transport service grid configuration
  static Map<String, dynamic> getTransportServiceGridConfig(
      BuildContext context) {
    if (isSmallMobile(context)) {
      return {
        'crossAxisCount': 2,
        'childAspectRatio': 1.8, // Increased from 2.5 to 1.8 for bigger cards
        'crossAxisSpacing': 12.0, // Increased from 8.0 to 12.0
        'mainAxisSpacing': 12.0, // Increased from 8.0 to 12.0
        'padding': 16.0, // Increased from 12.0 to 16.0
        'sectionPadding': 20.0, // Increased from 16.0 to 20.0
      };
    } else if (isMobile(context)) {
      return {
        'crossAxisCount': 2,
        'childAspectRatio': 2.2, // Increased from 3.0 to 2.2 for bigger cards
        'crossAxisSpacing': 16.0, // Increased from 12.0 to 16.0
        'mainAxisSpacing': 16.0, // Increased from 12.0 to 16.0
        'padding': 20.0, // Increased from 16.0 to 20.0
        'sectionPadding': 24.0, // Increased from 20.0 to 24.0
      };
    } else if (isTablet(context)) {
      return {
        'crossAxisCount': 2,
        'childAspectRatio': 2.0, // Increased from 2.8 to 2.0 for bigger cards
        'crossAxisSpacing': 20.0, // Increased from 16.0 to 20.0
        'mainAxisSpacing': 20.0, // Increased from 16.0 to 20.0
        'padding': 24.0, // Increased from 20.0 to 24.0
        'sectionPadding': 28.0, // Increased from 24.0 to 28.0
      };
    } else {
      return {
        'crossAxisCount': 2,
        'childAspectRatio': 1.8, // Increased from 2.5 to 1.8 for bigger cards
        'crossAxisSpacing': 24.0, // Increased from 20.0 to 24.0
        'mainAxisSpacing': 24.0, // Increased from 20.0 to 24.0
        'padding': 28.0, // Increased from 24.0 to 28.0
        'sectionPadding': 36.0, // Increased from 32.0 to 36.0
      };
    }
  }

  // Get responsive service card dimensions
  static Map<String, double> getServiceCardDimensions(BuildContext context) {
    if (isSmallMobile(context)) {
      return {
        'iconSize': 32.0,
        'iconContainerSize': 36.0,
        'titleFontSize': 12.0,
        'descriptionFontSize': 10.0,
        'priceFontSize': 11.0,
        'cardPadding': 10.0,
        'spacing': 8.0,
      };
    } else if (isMobile(context)) {
      return {
        'iconSize': 36.0,
        'iconContainerSize': 40.0,
        'titleFontSize': 13.0,
        'descriptionFontSize': 11.0,
        'priceFontSize': 12.0,
        'cardPadding': 12.0,
        'spacing': 10.0,
      };
    } else if (isTablet(context)) {
      return {
        'iconSize': 40.0,
        'iconContainerSize': 44.0,
        'titleFontSize': 14.0,
        'descriptionFontSize': 12.0,
        'priceFontSize': 13.0,
        'cardPadding': 14.0,
        'spacing': 12.0,
      };
    } else {
      return {
        'iconSize': 44.0,
        'iconContainerSize': 48.0,
        'titleFontSize': 15.0,
        'descriptionFontSize': 13.0,
        'priceFontSize': 14.0,
        'cardPadding': 16.0,
        'spacing': 14.0,
      };
    }
  }
}
