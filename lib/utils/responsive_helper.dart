import 'package:flutter/material.dart';

class ResponsiveHelper {
  // Breakpoint definitions
  static const double mobileBreakpoint = 700;
  static const double tabletBreakpoint = 1200;
  
  // Get device type based on screen width
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return DeviceType.mobile;
    } else if (width < tabletBreakpoint) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }
  
  // Check if device is mobile
  static bool isMobile(BuildContext context) {
    return getDeviceType(context) == DeviceType.mobile;
  }
  
  // Check if device is tablet
  static bool isTablet(BuildContext context) {
    return getDeviceType(context) == DeviceType.tablet;
  }
  
  // Check if device is desktop
  static bool isDesktop(BuildContext context) {
    return getDeviceType(context) == DeviceType.desktop;
  }
  
  // Get responsive value based on device type
  static T getResponsiveValue<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }
  
  // Get responsive font size
  static double getResponsiveFontSize(BuildContext context, double mobileSize, {
    double? tabletSize,
    double? desktopSize,
  }) {
    return getResponsiveValue<double>(
      context: context,
      mobile: mobileSize,
      tablet: tabletSize,
      desktop: desktopSize,
    );
  }
  
  // Get responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context, {
    double mobile = 16.0,
    double tablet = 24.0,
    double desktop = 32.0,
  }) {
    return EdgeInsets.all(
      getResponsiveValue<double>(
        context: context,
        mobile: mobile,
        tablet: tablet,
        desktop: desktop,
      ),
    );
  }
  
  // Get responsive margin
  static EdgeInsets getResponsiveMargin(BuildContext context, {
    double mobile = 16.0,
    double tablet = 24.0,
    double desktop = 32.0,
  }) {
    return EdgeInsets.all(
      getResponsiveValue<double>(
        context: context,
        mobile: mobile,
        tablet: tablet,
        desktop: desktop,
      ),
    );
  }
  
  // Get responsive spacing
  static double getResponsiveSpacing(BuildContext context, double mobileSpacing, {
    double? tabletSpacing,
    double? desktopSpacing,
  }) {
    return getResponsiveValue<double>(
      context: context,
      mobile: mobileSpacing,
      tablet: tabletSpacing,
      desktop: desktopSpacing,
    );
  }
  
  // Get responsive icon size
  static double getResponsiveIconSize(BuildContext context, double mobileSize, {
    double? tabletSize,
    double? desktopSize,
  }) {
    return getResponsiveValue<double>(
      context: context,
      mobile: mobileSize,
      tablet: tabletSize,
      desktop: desktopSize,
    );
  }
  
  // Get responsive button height
  static double getResponsiveButtonHeight(BuildContext context) {
    return getResponsiveValue<double>(
      context: context,
      mobile: 48.0,
      tablet: 52.0,
      desktop: 56.0,
    );
  }
  
  // Get responsive card padding
  static EdgeInsets getResponsiveCardPadding(BuildContext context) {
    return EdgeInsets.all(
      getResponsiveValue<double>(
        context: context,
        mobile: 16.0,
        tablet: 20.0,
        desktop: 24.0,
      ),
    );
  }
  
  // Get responsive container max width
  static double getResponsiveMaxWidth(BuildContext context) {
    return getResponsiveValue<double>(
      context: context,
      mobile: double.infinity,
      tablet: 800.0,
      desktop: 1200.0,
    );
  }

  // Get responsive text constraints
  static BoxConstraints getTextConstraints(BuildContext context, {
    double? maxWidth,
    double? maxHeight,
  }) {
    final responsiveMaxWidth = maxWidth ?? ResponsiveHelper.getResponsiveMaxWidth(context);
    
    return BoxConstraints(
      maxWidth: responsiveMaxWidth,
      maxHeight: maxHeight ?? double.infinity,
    );
  }

  // Get safe max width for text in cards
  static double getSafeTextMaxWidth(BuildContext context) {
    if (ResponsiveHelper.isMobile(context)) {
      return 200.0; // Mobile cards
    } else if (ResponsiveHelper.isTablet(context)) {
      return 250.0; // Tablet cards
    } else {
      return 300.0; // Desktop cards
    }
  }
  
  // Get responsive columns count for grid
  static int getResponsiveColumns(BuildContext context, int mobileColumns, {
    int? tabletColumns,
    int? desktopColumns,
  }) {
    return getResponsiveValue<int>(
      context: context,
      mobile: mobileColumns,
      tablet: tabletColumns,
      desktop: desktopColumns,
    );
  }
  
  // Get responsive aspect ratio
  static double getResponsiveAspectRatio(BuildContext context, double mobileRatio, {
    double? tabletRatio,
    double? desktopRatio,
  }) {
    return getResponsiveValue<double>(
      context: context,
      mobile: mobileRatio,
      tablet: tabletRatio,
      desktop: desktopRatio,
    );
  }
}

enum DeviceType {
  mobile,
  tablet,
  desktop,
}
