import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();
  static const brand = Color(0xFF147D64);
  static const brandDark = Color(0xFF0D5B49);
  static const ink = Color(0xFF172522);
  static const muted = Color(0xFF75827D);
  static const canvas = Color(0xFFF4F7F5);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE6ECE8);
  static const income = Color(0xFF16845F);
  static const expense = Color(0xFFD46A4C);
  static const softGreen = Color(0xFFE6F3ED);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: brand,
      brightness: Brightness.light,
    ).copyWith(
      primary: brand,
      onPrimary: Colors.white,
      secondary: const Color(0xFFB9DCCB),
      onSecondary: ink,
      surface: surface,
      onSurface: ink,
      error: const Color(0xFFCB514B),
      outline: border,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      visualDensity: VisualDensity.standard,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: ink, fontSize: 30, height: 1.12, fontWeight: FontWeight.w800, letterSpacing: -0.9),
        headlineMedium: TextStyle(color: ink, fontSize: 25, height: 1.15, fontWeight: FontWeight.w800, letterSpacing: -0.6),
        titleLarge: TextStyle(color: ink, fontSize: 18, height: 1.25, fontWeight: FontWeight.w700, letterSpacing: -0.25),
        titleMedium: TextStyle(color: ink, fontSize: 15, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(color: ink, fontSize: 14, height: 1.35),
        bodyMedium: TextStyle(color: muted, fontSize: 12.5, height: 1.35),
        labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: canvas, foregroundColor: ink, surfaceTintColor: Colors.transparent,
        elevation: 0, scrolledUnderElevation: 0, centerTitle: false,
        titleTextStyle: TextStyle(color: ink, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4),
      ),
      cardTheme: CardThemeData(
        color: surface, surfaceTintColor: Colors.transparent, elevation: 0,
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: border, width: 0.8)),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 0.8, space: 1),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        minVerticalPadding: 7, horizontalTitleGap: 11, minLeadingWidth: 36, iconColor: muted,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: surface, isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        labelStyle: const TextStyle(color: muted, fontSize: 13),
        hintStyle: const TextStyle(color: muted, fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: brand, width: 1.5)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(backgroundColor: brand, foregroundColor: Colors.white, minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 11),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(foregroundColor: brandDark, minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11), side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: brand, textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: brand, foregroundColor: Colors.white, elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: surface, indicatorColor: softGreen, elevation: 0, height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStatePropertyAll(TextStyle(fontSize: 10, fontWeight: FontWeight.w700))),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: brand, linearTrackColor: border),
      dialogTheme: DialogThemeData(
        backgroundColor: surface, surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: const TextStyle(color: ink, fontSize: 18, fontWeight: FontWeight.w800)),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating, backgroundColor: ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      }),
    );
  }
}