import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const Color pastelBlue = Color(0xFFC2ECFA);
  static const Color tacticalBlue = Color(0xFF8DB4FA);
  static const Color pastelGreen = Color(0xFFC3F4CD);
  static const Color pastelPeach = Color(0xFFFFDDCC);
  static const Color pastelRose = Color(0xFFFFBED8);
  static const Color academyLilac = Color(0xFFE1DAFF);
  static const Color graphite = Color(0xFF7890DE);
  static const Color graphiteSoft = Color(0xFFA3B0F0);
  static const Color signalYellow = Color(0xFFFFE38F);
  static const Color surfaceWhite = Color(0xFFFAFDFF);
  static const Color ink = Color(0xFF5873C8);

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.notoSansKrTextTheme(
      ThemeData.light().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      scaffoldBackgroundColor: surfaceWhite,
      fontFamily: GoogleFonts.notoSansKr().fontFamily,
      fontFamilyFallback: const <String>[
        'Noto Sans KR',
        'Noto Sans CJK KR',
        'Malgun Gothic',
        'Apple SD Gothic Neo',
        'NanumGothic',
        'Arial Unicode MS',
        'sans-serif',
      ],
      textTheme: baseTextTheme.apply(bodyColor: ink, displayColor: ink),
      splashFactory: InkSparkle.splashFactory,
      colorScheme: ColorScheme.fromSeed(
        seedColor: pastelBlue,
        brightness: Brightness.light,
        primary: tacticalBlue,
        secondary: pastelGreen,
        tertiary: pastelRose,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white.withValues(alpha: 0.86),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: tacticalBlue.withValues(alpha: 0.42)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 66,
        backgroundColor: Colors.white.withValues(alpha: 0.90),
        indicatorColor: academyLilac.withValues(alpha: 0.44),
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? ink : ink.withValues(alpha: 0.54),
            fontSize: 12,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? tacticalBlue : ink.withValues(alpha: 0.46),
            size: selected ? 25 : 22,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tacticalBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.90),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        prefixIconColor: tacticalBlue,
        hintStyle: TextStyle(
          color: graphite.withValues(alpha: 0.42),
          fontWeight: FontWeight.w700,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: tacticalBlue.withValues(alpha: 0.18)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: tacticalBlue.withValues(alpha: 0.22)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: tacticalBlue, width: 1.4),
        ),
      ),
    );
  }

  /// Glassmorphism 패널에서 반복 사용하는 blur 값입니다.
  static ImageFilter get glassBlur => ImageFilter.blur(sigmaX: 12, sigmaY: 12);
}
