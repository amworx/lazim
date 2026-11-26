import 'package:flutter/material.dart';

/// Lazim's visual language.
///
/// Warm clay/terracotta primary with a deep ink neutral. Deliberately not the
/// default Material purple, and tuned so Arabic (Cairo) and Latin text sit at
/// the same optical weight.
class LazimColors {
  const LazimColors._();

  static const clay = Color(0xFFC2553A);
  static const clayDeep = Color(0xFF9A3C26);
  static const claySoft = Color(0xFFF6E7E2);

  static const ink = Color(0xFF1C1A19);
  static const inkSoft = Color(0xFF3D3937);
  static const muted = Color(0xFF7A736F);
  static const line = Color(0xFFE8E2DE);
  static const canvas = Color(0xFFFBF9F7);
  static const surface = Color(0xFFFFFFFF);

  static const sage = Color(0xFF4F7A5E);
  static const sageSoft = Color(0xFFE6F0E9);
  static const amber = Color(0xFFB7791F);
  static const amberSoft = Color(0xFFFBF0DC);
  static const danger = Color(0xFFB4342A);
  static const dangerSoft = Color(0xFFFBE9E7);

  // Dark palette
  static const darkCanvas = Color(0xFF141312);
  static const darkSurface = Color(0xFF1E1C1B);
  static const darkLine = Color(0xFF302C2A);
  static const darkMuted = Color(0xFF9C938E);
}

class LazimTheme {
  const LazimTheme._();

  static const _radius = 18.0;

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: LazimColors.clay,
      brightness: Brightness.light,
    ).copyWith(
      primary: LazimColors.clay,
      onPrimary: Colors.white,
      surface: LazimColors.surface,
      onSurface: LazimColors.ink,
      error: LazimColors.danger,
    );

    return _base(scheme, LazimColors.canvas);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: LazimColors.clay,
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFFE07A5F),
      onPrimary: const Color(0xFF2B120B),
      surface: LazimColors.darkSurface,
      onSurface: const Color(0xFFF2EDEA),
      error: const Color(0xFFE57373),
    );

    return _base(scheme, LazimColors.darkCanvas);
  }

  static ThemeData _base(ColorScheme scheme, Color canvas) {
    final isDark = scheme.brightness == Brightness.dark;
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Cairo',
      scaffoldBackgroundColor: canvas,
      visualDensity: VisualDensity.standard,
    );

    final text = base.textTheme;

    return base.copyWith(
      textTheme: text.copyWith(
        displaySmall: text.displaySmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          height: 1.25,
        ),
        headlineMedium: text.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          height: 1.25,
        ),
        headlineSmall: text.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
        titleLarge: text.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 19,
          height: 1.35,
        ),
        titleMedium: text.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 16,
          height: 1.4,
        ),
        bodyLarge: text.bodyLarge?.copyWith(fontSize: 16, height: 1.55),
        bodyMedium: text.bodyMedium?.copyWith(fontSize: 14.5, height: 1.55),
        labelLarge: text.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: isDark ? LazimColors.darkSurface : LazimColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
          side: BorderSide(color: isDark ? LazimColors.darkLine : LazimColors.line),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          side: BorderSide(color: isDark ? LazimColors.darkLine : LazimColors.line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? LazimColors.darkSurface : LazimColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? LazimColors.darkLine : LazimColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? LazimColors.darkLine : LazimColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
        labelStyle: TextStyle(color: isDark ? LazimColors.darkMuted : LazimColors.muted),
        hintStyle: TextStyle(color: isDark ? LazimColors.darkMuted : LazimColors.muted),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? LazimColors.darkSurface : LazimColors.surface,
        selectedColor: scheme.primary,
        side: BorderSide(color: isDark ? LazimColors.darkLine : LazimColors.line),
        labelStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w700,
          fontSize: 13.5,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? LazimColors.darkLine : LazimColors.line,
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? LazimColors.darkSurface : LazimColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        showDragHandle: true,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? LazimColors.darkSurface : LazimColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFF322D2B) : LazimColors.ink,
        contentTextStyle: const TextStyle(fontFamily: 'Cairo', color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? LazimColors.darkSurface : LazimColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primary.withValues(alpha: 0.14),
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            color: selected ? scheme.primary : (isDark ? LazimColors.darkMuted : LazimColors.muted),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? scheme.primary : (isDark ? LazimColors.darkMuted : LazimColors.muted),
          );
        }),
      ),
    );
  }
}
