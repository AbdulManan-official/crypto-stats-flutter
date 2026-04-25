import 'package:flutter/material.dart';

class Responsive {
  Responsive._();

  // Breakpoints
  static const double _mobileBreakpoint = 600;
  static const double _tabletBreakpoint = 1024;

  // Device type checks
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < _mobileBreakpoint;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= _mobileBreakpoint &&
          MediaQuery.sizeOf(context).width < _tabletBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= _tabletBreakpoint;

  // Screen dimensions
  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;
  static double height(BuildContext context) => MediaQuery.sizeOf(context).height;

  // Percentage-based sizing
  static double wp(BuildContext context, double percent) =>
      MediaQuery.sizeOf(context).width * percent / 100;

  static double hp(BuildContext context, double percent) =>
      MediaQuery.sizeOf(context).height * percent / 100;

  // Adaptive value — returns value based on screen type
  static T adaptive<T>(
      BuildContext context, {
        required T mobile,
        T? tablet,
        T? desktop,
      }) {
    if (isDesktop(context)) return desktop ?? tablet ?? mobile;
    if (isTablet(context)) return tablet ?? mobile;
    return mobile;
  }

  // Adaptive font size
  static double fontSize(
      BuildContext context, {
        required double mobile,
        double? tablet,
        double? desktop,
      }) =>
      adaptive(context, mobile: mobile, tablet: tablet, desktop: desktop);

  // Adaptive padding
  static EdgeInsets padding(
      BuildContext context, {
        EdgeInsets mobile = const EdgeInsets.all(16),
        EdgeInsets? tablet,
        EdgeInsets? desktop,
      }) =>
      adaptive(context, mobile: mobile, tablet: tablet, desktop: desktop);

  // Adaptive horizontal padding
  static EdgeInsets horizontalPadding(BuildContext context) {
    if (isDesktop(context)) return const EdgeInsets.symmetric(horizontal: 64);
    if (isTablet(context)) return const EdgeInsets.symmetric(horizontal: 32);
    return const EdgeInsets.symmetric(horizontal: 16);
  }

  // Adaptive grid cross axis count
  static int gridCrossAxisCount(
      BuildContext context, {
        int mobile = 2,
        int tablet = 3,
        int desktop = 4,
      }) =>
      adaptive(context, mobile: mobile, tablet: tablet, desktop: desktop);

  // Safe area helpers
  static double topPadding(BuildContext context) =>
      MediaQuery.paddingOf(context).top;

  static double bottomPadding(BuildContext context) =>
      MediaQuery.paddingOf(context).bottom;

  // Keyboard visibility
  static bool isKeyboardOpen(BuildContext context) =>
      MediaQuery.viewInsetsOf(context).bottom > 0;
}

// Extension on BuildContext for cleaner usage
extension ResponsiveExtension on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  bool get isMobile => Responsive.isMobile(this);
  bool get isTablet => Responsive.isTablet(this);
  bool get isDesktop => Responsive.isDesktop(this);

  double wp(double percent) => Responsive.wp(this, percent);
  double hp(double percent) => Responsive.hp(this, percent);

  EdgeInsets get horizontalPadding => Responsive.horizontalPadding(this);
}