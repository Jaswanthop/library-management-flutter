import 'package:flutter/material.dart';

/// Extra semantic colours that Material's [ColorScheme] does not provide.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.danger,
    required this.dangerSoft,
    required this.info,
    required this.infoSoft,
    required this.border,
    required this.muted,
    required this.sidebar,
    required this.chart,
  });

  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color danger;
  final Color dangerSoft;
  final Color info;
  final Color infoSoft;
  final Color border;
  final Color muted;
  final Color sidebar;
  final List<Color> chart;

  @override
  AppColors copyWith({
    Color? success,
    Color? successSoft,
    Color? warning,
    Color? warningSoft,
    Color? danger,
    Color? dangerSoft,
    Color? info,
    Color? infoSoft,
    Color? border,
    Color? muted,
    Color? sidebar,
    List<Color>? chart,
  }) {
    return AppColors(
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      warning: warning ?? this.warning,
      warningSoft: warningSoft ?? this.warningSoft,
      danger: danger ?? this.danger,
      dangerSoft: dangerSoft ?? this.dangerSoft,
      info: info ?? this.info,
      infoSoft: infoSoft ?? this.infoSoft,
      border: border ?? this.border,
      muted: muted ?? this.muted,
      sidebar: sidebar ?? this.sidebar,
      chart: chart ?? this.chart,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      successSoft: Color.lerp(successSoft, other.successSoft, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSoft: Color.lerp(warningSoft, other.warningSoft, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerSoft: Color.lerp(dangerSoft, other.dangerSoft, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoSoft: Color.lerp(infoSoft, other.infoSoft, t)!,
      border: Color.lerp(border, other.border, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      sidebar: Color.lerp(sidebar, other.sidebar, t)!,
      chart: chart,
    );
  }
}

/// Colour tokens and [ThemeData] for Shelfwise.
abstract final class AppTheme {
  static const Color brand = Color(0xFF1F5A4A);
  static const Color brass = Color(0xFFB5832F);

  static const AppColors _lightColors = AppColors(
    success: Color(0xFF1E7A4D),
    successSoft: Color(0xFFE2F2E9),
    warning: Color(0xFF9A6412),
    warningSoft: Color(0xFFFBF0DA),
    danger: Color(0xFFB3261E),
    dangerSoft: Color(0xFFFBE6E4),
    info: Color(0xFF2B4C7E),
    infoSoft: Color(0xFFE6EDF8),
    border: Color(0xFFE3DED2),
    muted: Color(0xFF6B7269),
    sidebar: Color(0xFFFFFFFF),
    chart: <Color>[
      Color(0xFF1F5A4A),
      Color(0xFF3C7C68),
      Color(0xFFB5832F),
      Color(0xFF2B4C7E),
      Color(0xFF7A3E48),
      Color(0xFF5C3D6E),
      Color(0xFF2D6A6A),
    ],
  );

  static const AppColors _darkColors = AppColors(
    success: Color(0xFF7FD1A7),
    successSoft: Color(0xFF17352A),
    warning: Color(0xFFE8C07A),
    warningSoft: Color(0xFF33290F),
    danger: Color(0xFFF2A7A1),
    dangerSoft: Color(0xFF3A1D1B),
    info: Color(0xFFA8C2EA),
    infoSoft: Color(0xFF1B2536),
    border: Color(0xFF2B3B35),
    muted: Color(0xFF9BAAA3),
    sidebar: Color(0xFF14211D),
    chart: <Color>[
      Color(0xFF7FC6AE),
      Color(0xFF5FA98F),
      Color(0xFFE0B563),
      Color(0xFF8FB2E0),
      Color(0xFFD08C97),
      Color(0xFFB79BD0),
      Color(0xFF79BCBC),
    ],
  );

  static ThemeData light() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: brand,
      brightness: Brightness.light,
    ).copyWith(
      primary: brand,
      onPrimary: Colors.white,
      secondary: brass,
      surface: Colors.white,
      onSurface: const Color(0xFF1A2622),
      surfaceContainerHighest: const Color(0xFFF1EDE3),
      outline: const Color(0xFFCFC9BB),
    );
    return _build(scheme, const Color(0xFFF6F4EE), _lightColors);
  }

  static ThemeData dark() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: brand,
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFF7FC6AE),
      onPrimary: const Color(0xFF06231B),
      secondary: const Color(0xFFE0B563),
      surface: const Color(0xFF16221E),
      onSurface: const Color(0xFFE7EEE9),
      surfaceContainerHighest: const Color(0xFF223029),
      outline: const Color(0xFF3A4A43),
    );
    return _build(scheme, const Color(0xFF101A17), _darkColors);
  }

  static ThemeData _build(
    ColorScheme scheme,
    Color background,
    AppColors colors,
  ) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      dividerColor: colors.border,
      extensions: <ThemeExtension<dynamic>>[colors],
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          side: BorderSide(color: colors.border),
          foregroundColor: scheme.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: colors.border),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.onSurface,
        contentTextStyle: TextStyle(color: scheme.surface, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.onSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(color: scheme.surface, fontSize: 12),
      ),
    );
  }
}

/// Shorthand for the semantic palette.
extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
