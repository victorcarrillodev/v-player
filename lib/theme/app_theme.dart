import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class AppColors {
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color primary;
  final Color accent;
  final Color onSurface;
  final Color onSurfaceMuted;
  final Color cardGlow;
  final LinearGradient primaryGradient;
  final bool isNeon;
  final Color? neonGlow;

  AppColors({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.primary,
    required this.accent,
    required this.onSurface,
    required this.onSurfaceMuted,
    required this.cardGlow,
    required this.primaryGradient,
    this.isNeon = false,
    this.neonGlow,
  });
}

extension ThemeContext on BuildContext {
  AppColors get appColors => watch<ThemeProvider>().currentColors;
  ThemeProvider get themeProvider => read<ThemeProvider>();
}

class AppTheme {
  static ThemeData getTheme(AppColors colors, bool isDarkMode, bool animationsEnabled) {
    return ThemeData(
      useMaterial3: true,
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: colors.background,
      colorScheme: (isDarkMode ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(
        primary: colors.primary,
        secondary: colors.accent,
        surface: colors.surface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: colors.onSurface,
      ),
      textTheme: GoogleFonts.interTextTheme(
        isDarkMode ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ).apply(
        bodyColor: colors.onSurface,
        displayColor: colors.onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          color: colors.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: colors.onSurface),
      ),
      iconTheme: IconThemeData(color: colors.onSurface),
      pageTransitionsTheme: animationsEnabled 
          ? const PageTransitionsTheme()
          : const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: NoAnimationPageTransitionsBuilder(),
                TargetPlatform.iOS: NoAnimationPageTransitionsBuilder(),
                TargetPlatform.linux: NoAnimationPageTransitionsBuilder(),
                TargetPlatform.macOS: NoAnimationPageTransitionsBuilder(),
                TargetPlatform.windows: NoAnimationPageTransitionsBuilder(),
              },
            ),
    );
  }
}

class NoAnimationPageTransitionsBuilder extends PageTransitionsBuilder {
  const NoAnimationPageTransitionsBuilder();
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
