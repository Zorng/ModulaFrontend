class AppBreakpoints {
  const AppBreakpoints._();

  /// Mobile-first breakpoint.
  static const double small = 640;

  /// Tablet/desktop breakpoint.
  static const double medium = 1024;

  /// Very compact layouts (e.g., narrow mobile).
  static const double compact = 520;

  static bool isSmall(double width) => width < small;
  static bool isMedium(double width) => width >= small && width < medium;
  static bool isLarge(double width) => width >= medium;
}
