import 'package:flutter/material.dart';

enum MatchstickBoxType { classic, soccer, wood }

class TrucoTheme {
  final String name;
  final Color navy;
  final Color navyLight;
  final Color slate;
  final Color cream;
  final Color white;
  final Color navyAccent;
  final Color buenas;
  final Color malas;
  final Color
  centerCircleColor; // NEW: Specific color for the center ornament background

  // FIXED WOOD COLORS (Independent of theme)
  static const Color woodLight = Color(0xFFE6D2B5);
  static const Color woodMedium = Color(0xFFD2B48C);
  static const Color woodDark = Color(0xFFB89B74);

  // ASSETS AND SPECIFIC COLORS
  final String? headerAsset;
  final String? footerAsset;
  final double footerHeight;
  final Color scoreColor;
  final Color teamScoreColor;
  final Color dividerColor;
  final Color accentColor;
  final String? backgroundAsset;

  // CENTER ORNAMENT
  final String? centerOrnamentAsset;
  final bool hideCenterCircleBorder;
  final double centerOrnamentScale;

  // FINE-TUNING FOR SCORE
  final double scoreFontSize;
  final double scoreVerticalOffset;
  final double
  centerSectionOffset; // NEW: Vertical position of the whole center stack

  final MatchstickBoxType matchstickBoxType;

  const TrucoTheme({
    required this.name,
    required this.navy,
    required this.navyLight,
    required this.slate,
    required this.cream,
    required this.white,
    required this.navyAccent,
    required this.buenas,
    required this.malas,
    required this.centerCircleColor,
    this.headerAsset,
    this.footerAsset,
    this.footerHeight = 45,
    required this.scoreColor,
    required this.teamScoreColor,
    required this.dividerColor,
    required this.accentColor,
    this.backgroundAsset,
    this.centerOrnamentAsset,
    this.hideCenterCircleBorder = false,
    this.centerOrnamentScale = 1.0,
    required this.scoreFontSize,
    required this.scoreVerticalOffset,
    required this.centerSectionOffset,
    required this.matchstickBoxType,
  });

  // PRESETS
  static const TrucoTheme navyTheme = TrucoTheme(
    name: "NAVY PROFUNDO",
    navy: Color(0xFF161931),
    navyLight: Color(0xFF1C203E),
    slate: Color(0xFF718C9C),
    cream: Color(0xFFEFEBE2),
    white: Colors.white,
    navyAccent: Color(0xFF252A50),
    buenas: Color(0xFF888D71),
    malas: Color(0xFFF47580),
    centerCircleColor: Color(0xFF161931), // Same as navy
    headerAsset: 'assets/images/header.svg',
    footerAsset: 'assets/images/footer.svg',
    dividerColor: Color(0xFFEFEBE2),
    scoreColor: Color(0xFFEFEBE2),
    teamScoreColor: Color(0xFFEFEBE2),
    accentColor: Color(0xFF718C9C),
    backgroundAsset: null,
    centerOrnamentAsset: null,
    hideCenterCircleBorder: false,
    scoreFontSize: 26,
    scoreVerticalOffset: 5.0,
    centerSectionOffset: 10.0,
    matchstickBoxType: MatchstickBoxType.classic,
  );

  static const TrucoTheme argentinaTheme = TrucoTheme(
    name: "ARGENTINA",
    navy: Color(0xFF74ACDF),
    navyLight: Color(0xFF8EBEEC),
    slate: Color(0xFF5A91C5),
    cream: Colors.white,
    white: Colors.white,
    navyAccent: Color(0xFF5A91C5),
    buenas: Color(0xFFF6B000),
    malas: Colors.white,
    centerCircleColor: Color(0xFF74ACDF), // Same as navy
    headerAsset: 'assets/images/header.svg',
    footerAsset: 'assets/images/footer.svg',
    dividerColor: Colors.white,
    scoreColor: Colors.white,
    teamScoreColor: Colors.white,
    accentColor: Color(0xFFF6B000),
    backgroundAsset: null,
    centerOrnamentAsset: 'assets/images/sun.svg',
    hideCenterCircleBorder: true,
    centerOrnamentScale: 1.7,
    scoreFontSize: 18,
    scoreVerticalOffset: 2.0,
    centerSectionOffset: 35.0,
    matchstickBoxType: MatchstickBoxType.classic,
  );

  static const TrucoTheme soccerTheme = TrucoTheme(
    name: "LA CANCHA",
    navy: Color(0xFF1B5E20), // Solid green background
    navyLight: Color(0xFF388E3C),
    slate: Colors.white,
    cream: Colors.white,
    white: Colors.white,
    navyAccent: Color(0xFF388E3C),
    buenas: Color(0xFFFFD600),
    malas: Color(0xFFFF5252),
    centerCircleColor: Colors.transparent, // No circle background
    headerAsset: null,
    footerAsset: 'assets/images/dibu.svg',
    footerHeight: 75,
    dividerColor: Colors.transparent,
    scoreColor: Color(0xFF2E4393),
    teamScoreColor: Colors.white,
    accentColor: Color(0xFF2E4393),
    backgroundAsset: 'assets/images/background_2.jpg',
    centerOrnamentAsset: 'assets/images/afa.svg',
    hideCenterCircleBorder: true,
    centerOrnamentScale: 2.2,
    scoreFontSize: 28,
    scoreVerticalOffset: 40.0,
    centerSectionOffset: 0.0,
    matchstickBoxType: MatchstickBoxType.soccer,
  );

  static const TrucoTheme woodTheme = TrucoTheme(
    name: "MESA DE MADERA",
    navy: Color(0xFF3E2723), // Marrón oscuro
    navyLight: Color(0xFF5D4037),
    slate: Color(0xFFD7CCC8),
    cream: Color(0xFFFFF3E0),
    white: Colors.white,
    navyAccent: Color(0xFF4E342E),
    buenas: Color(0xFF8D6E63),
    malas: Color(0xFFBCAAA4),
    centerCircleColor: Colors.transparent,
    headerAsset: null,
    footerAsset: null,
    dividerColor: Colors.transparent,
    scoreColor: Color(0xFFFFF3E0),
    teamScoreColor: Color(0xFFE0E0E0),
    accentColor: Color(0xFFD7CCC8),
    backgroundAsset: 'assets/images/background_1.jpg',
    centerOrnamentAsset: null,
    hideCenterCircleBorder: true,
    scoreFontSize: 26,
    scoreVerticalOffset: 5.0,
    centerSectionOffset: 10.0,
    matchstickBoxType: MatchstickBoxType.wood,
  );

  static const List<TrucoTheme> allThemes = [
    navyTheme,
    argentinaTheme,
    soccerTheme,
    woodTheme,
  ];
}

class AppFonts {
  static const String oswald = 'Oswald';
  static const String oswaldSemiBold = 'Oswald-SemiBold';
  static const String oswaldRegular = 'Oswald';
  static const String caminito = 'CaminitoBase';
}

// Deprecated AppColors for transition (will be removed after refactor)
class AppColors {
  static Color get navy => TrucoTheme.navyTheme.navy;
  static Color get navyLight => TrucoTheme.navyTheme.navyLight;
  static Color get slate => TrucoTheme.navyTheme.slate;
  static Color get cream => TrucoTheme.navyTheme.cream;
  static Color get white => Colors.white;
  static Color get navyAccent => TrucoTheme.navyTheme.navyAccent;
  static Color get woodLight => TrucoTheme.woodLight;
  static Color get woodMedium => TrucoTheme.woodMedium;
  static Color get woodDark => TrucoTheme.woodDark;
  static Color get buenas => TrucoTheme.navyTheme.buenas;
  static Color get malas => TrucoTheme.navyTheme.malas;
}
