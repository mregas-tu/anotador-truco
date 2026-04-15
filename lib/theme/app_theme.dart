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
  final Color centerCircleColor;

  // New Button specific colors
  final Color primaryBackgroundButton;
  final Color primaryTextButton;
  final Color secondaryButtonBorder;
  final Color secondaryButtonText;
  final Color classicButtonColor;
  final Color classicButtonShadowColor;

  // Aesthetic Enhancements
  final List<Shadow>? teamNameShadow;
  final BoxDecoration? topIconDecoration;
  final Color? topIconColor;
  final BoxDecoration? centerCircleDecoration;

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
  final List<Shadow>? centerOrnamentShadows;

  // FINE-TUNING FOR SCORE
  final double scoreFontSize;
  final double scoreVerticalOffset;
  final double centerSectionOffset;
  final double nosotrosMarginRight;
  final double ellosMarginLeft;

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
    required this.primaryBackgroundButton,
    required this.primaryTextButton,
    required this.secondaryButtonBorder,
    required this.secondaryButtonText,
    this.teamNameShadow,
    this.topIconDecoration,
    this.topIconColor,
    this.centerCircleDecoration,
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
    this.centerOrnamentShadows,
    required this.scoreFontSize,
    required this.scoreVerticalOffset,
    required this.centerSectionOffset,
    this.nosotrosMarginRight = 0.0,
    this.ellosMarginLeft = 0.0,
    required this.matchstickBoxType,
    required this.classicButtonColor,
    required this.classicButtonShadowColor,
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
    centerCircleColor: Color(0xFF161931),
    primaryBackgroundButton: Color(0xFF718C9C),
    primaryTextButton: Color(0xFFEFEBE2),
    secondaryButtonBorder: Color(0xFFEFEBE2),
    secondaryButtonText: Color(0xFFEFEBE2),
    classicButtonColor: Color(0xFF718C9C),
    classicButtonShadowColor: Colors.black26,
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
    centerCircleColor: Color(0xFF74ACDF),
    primaryBackgroundButton: Color(0xFF5A91C5),
    primaryTextButton: Colors.white,
    secondaryButtonBorder: Colors.white,
    secondaryButtonText: Colors.white,
    classicButtonColor: Color(0xFF5A91C5),
    classicButtonShadowColor: Color(0x14000000), // black with 0.08 opacity
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
    navy: Color(0xFF1B5E20),
    navyLight: Color(0xFF388E3C),
    slate: Colors.white,
    cream: Colors.white,
    white: Colors.white,
    navyAccent: Color(0xFF388E3C),
    buenas: Color(0xFF07007A),
    malas: Color(0xFFFF5252),
    centerCircleColor: Colors.transparent,
    primaryBackgroundButton: Color(0xFF07007A),
    primaryTextButton: Colors.white,
    secondaryButtonBorder: Colors.white,
    secondaryButtonText: Colors.white,
    classicButtonColor: Color(0xFF07007A),
    classicButtonShadowColor: Colors.black38,
    headerAsset: null,
    footerAsset: 'assets/images/dibu.svg',
    footerHeight: 75,
    dividerColor: Colors.transparent,
    scoreColor: Color(0xFF07007A),
    teamScoreColor: Colors.white,
    accentColor: Color(0xFF07007A),
    backgroundAsset: 'assets/images/background_2.jpg',
    centerOrnamentAsset: 'assets/images/afa.svg',
    hideCenterCircleBorder: true,
    centerOrnamentScale: 2.2,
    scoreFontSize: 28,
    scoreVerticalOffset: 40.0,
    centerSectionOffset: 0.0,
    nosotrosMarginRight: 32.0,
    ellosMarginLeft: 32.0,
    matchstickBoxType: MatchstickBoxType.soccer,
  );

  static const TrucoTheme woodTheme = TrucoTheme(
    name: "MESA DE MADERA",
    navy: Color(0xFF3E2723),
    navyLight: Color(0xFF5D4037),
    slate: Color(0xFFEFEBE2), // Fully opaque again
    cream: Color(0xFFEFEBE2), // Fully opaque again
    white: Colors.white,
    navyAccent: Color(0xFF4E342E),
    buenas: Color(0xFFADB199),
    malas: Color(0xFFC8BDB8),
    centerCircleColor: Colors.transparent,
    primaryBackgroundButton: Color(0xFFA48C83),
    primaryTextButton: Color(0xFFEFEBE2),
    secondaryButtonBorder: Color(0xFFFFF3E0),
    secondaryButtonText: Color(0xFFFFF3E0),
    classicButtonColor: Color(0xFFA48C83),
    classicButtonShadowColor: Colors.black45,
    teamNameShadow: [
      Shadow(offset: Offset(-1.0, -1.0), blurRadius: 1.0, color: Colors.black),
      Shadow(offset: Offset(1.0, 1.0), blurRadius: 1.0, color: Colors.white10),
    ],
    topIconDecoration: null,
    topIconColor: Color(0xFFEFEBE2), // Fully opaque again
    centerCircleDecoration: null,
    headerAsset: null,
    footerAsset: null,
    dividerColor: Colors.transparent,
    scoreColor: Color(0xFFEFEBE2), // Fully opaque again
    teamScoreColor: Color(0xFFEFEBE2), // Fully opaque again
    accentColor: Color(0xFFA48C83),
    backgroundAsset: 'assets/images/background_1.jpg',
    centerOrnamentAsset: 'assets/images/wood.svg',
    hideCenterCircleBorder: true,
    scoreFontSize: 32,
    scoreVerticalOffset: 5.0,
    centerSectionOffset: 35.0,
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
