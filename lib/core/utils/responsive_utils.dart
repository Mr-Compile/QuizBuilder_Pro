import 'package:flutter/material.dart';

/// Centralized responsive design utilities for Quiz Builder Pro.
/// 
/// This class provides breakpoints, device type detection, and responsive
/// sizing helpers to create adaptive layouts for mobile phones and tablets.
class ResponsiveUtils {
  ResponsiveUtils._();

  // ==================== BREAKPOINTS ====================
  
  /// Width breakpoints for different device sizes
  static const double mobilePortraitMin = 320.0;
  static const double mobilePortraitMax = 412.0;
  static const double tabletPortraitMin = 600.0;
  static const double tabletPortraitMax = 834.0;
  static const double tabletLandscapeMin = 900.0;
  static const double desktopMin = 1024.0;

  /// Device type breakpoints
  static const double isMobileMax = 599.0;
  static const double isTabletMax = 1023.0;

  // ==================== DEVICE TYPE DETECTION ====================

  /// Check if the current device is a mobile phone (portrait)
  static bool isMobile(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width < isMobileMax;
  }

  /// Check if the current device is a tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= isMobileMax && width < isTabletMax;
  }

  /// Check if the current device is a desktop or large tablet
  static bool isDesktop(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= isTabletMax;
  }

  /// Check if the device is in portrait orientation
  static bool isPortrait(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.height > size.width;
  }

  /// Check if the device is in landscape orientation
  static bool isLandscape(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width > size.height;
  }

  /// Get the current device type as a string
  static String getDeviceType(BuildContext context) {
    if (isDesktop(context)) return 'desktop';
    if (isTablet(context)) return 'tablet';
    return 'mobile';
  }

  // ==================== RESPONSIVE SIZING ====================

  /// Get responsive value based on device type
  /// 
  /// Returns [mobile] value for mobile devices, [tablet] for tablets,
  /// and [desktop] for desktop/large tablets.
  static T getValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context) && desktop != null) return desktop;
    if (isTablet(context) && tablet != null) return tablet;
    return mobile;
  }

  /// Get responsive spacing based on device type
  static double getSpacing(BuildContext context) {
    return getValue(
      context,
      mobile: 16.0,
      tablet: 24.0,
      desktop: 32.0,
    );
  }

  /// Get responsive card padding based on device type
  static double getCardPadding(BuildContext context) {
    return getValue(
      context,
      mobile: 16.0,
      tablet: 24.0,
      desktop: 32.0,
    );
  }

  /// Get responsive border radius based on device type
  static double getBorderRadius(BuildContext context) {
    return getValue(
      context,
      mobile: 12.0,
      tablet: 16.0,
      desktop: 20.0,
    );
  }

  /// Get responsive icon size based on device type
  static double getIconSize(BuildContext context) {
    return getValue(
      context,
      mobile: 24.0,
      tablet: 32.0,
      desktop: 40.0,
    );
  }

  /// Get responsive font size multiplier
  static double getFontScale(BuildContext context) {
    return getValue(
      context,
      mobile: 1.0,
      tablet: 1.1,
      desktop: 1.2,
    );
  }

  // ==================== LAYOUT HELPERS ====================

  /// Get the number of columns for a grid based on screen width
  static int getGridColumns(BuildContext context, {int maxColumns = 4}) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < 360) return 1;
    if (width < 600) return 2;
    if (width < 900) return 3;
    return maxColumns;
  }

  /// Get the child aspect ratio for grid items based on screen width
  static double getGridChildAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < 360) return 2.5;
    if (width < 600) return 1.5;
    if (width < 900) return 1.3;
    return 1.2;
  }

  /// Get responsive max width for content containers
  static double getMaxContentWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (isMobile(context)) return width;
    if (isTablet(context)) return width * 0.9;
    return 1200.0; // Max width for desktop
  }

  /// Get responsive cross axis count for a GridView
  static int getCrossAxisCount(
    BuildContext context, {
    int mobile = 1,
    int tablet = 2,
    int desktop = 3,
  }) {
    return getValue(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  // ==================== WIDGET HELPERS ====================

  /// Build a responsive layout that adapts to screen size
  static Widget buildResponsiveLayout({
    required BuildContext context,
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    if (isDesktop(context) && desktop != null) return desktop;
    if (isTablet(context) && tablet != null) return tablet;
    return mobile;
  }

  /// Wrap content in a centered container with max width on larger screens
  static Widget buildMaxWidthContainer({
    required BuildContext context,
    required Widget child,
    double? maxWidth,
  }) {
    final effectiveMaxWidth = maxWidth ?? getMaxContentWidth(context);
    
    if (isMobile(context)) {
      return child;
    }
    
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
        child: child,
      ),
    );
  }

  /// Build a responsive grid that adapts column count to screen size
  static Widget buildResponsiveGrid({
    required BuildContext context,
    required List<Widget> children,
    int? mobileColumns,
    int? tabletColumns,
    int? desktopColumns,
    double? mainAxisSpacing,
    double? crossAxisSpacing,
    double? childAspectRatio,
    EdgeInsets? padding,
    bool shrinkWrap = true,
  }) {
    final crossAxisCount = getCrossAxisCount(
      context,
      mobile: mobileColumns ?? 1,
      tablet: tabletColumns ?? 2,
      desktop: desktopColumns ?? 3,
    );

    final effectiveMainAxisSpacing = mainAxisSpacing ?? getSpacing(context);
    final effectiveCrossAxisSpacing = crossAxisSpacing ?? getSpacing(context);
    final effectiveChildAspectRatio = childAspectRatio ?? getGridChildAspectRatio(context);

    return Padding(
      padding: padding ?? EdgeInsets.all(getSpacing(context)),
      child: GridView.count(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: effectiveMainAxisSpacing,
        crossAxisSpacing: effectiveCrossAxisSpacing,
        childAspectRatio: effectiveChildAspectRatio,
        shrinkWrap: shrinkWrap,
        physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
        children: children,
      ),
    );
  }
}

/// Extension method for easier access to responsive utilities
extension ResponsiveContext on BuildContext {
  /// Check if current device is mobile
  bool get isMobile => ResponsiveUtils.isMobile(this);
  
  /// Check if current device is tablet
  bool get isTablet => ResponsiveUtils.isTablet(this);
  
  /// Check if current device is desktop
  bool get isDesktop => ResponsiveUtils.isDesktop(this);
  
  /// Check if current orientation is portrait
  bool get isPortrait => ResponsiveUtils.isPortrait(this);
  
  /// Check if current orientation is landscape
  bool get isLandscape => ResponsiveUtils.isLandscape(this);
  
  /// Get current device type
  String get deviceType => ResponsiveUtils.getDeviceType(this);
  
  /// Get responsive spacing
  double get responsiveSpacing => ResponsiveUtils.getSpacing(this);
  
  /// Get responsive card padding
  double get responsiveCardPadding => ResponsiveUtils.getCardPadding(this);
  
  /// Get responsive border radius
  double get responsiveBorderRadius => ResponsiveUtils.getBorderRadius(this);
  
  /// Get responsive icon size
  double get responsiveIconSize => ResponsiveUtils.getIconSize(this);
  
  /// Get responsive font scale
  double get responsiveFontScale => ResponsiveUtils.getFontScale(this);
}
