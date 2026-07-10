import 'package:flutter/material.dart';

enum MatchstickBoxType { classic, soccer, wood }

enum ThemeBackgroundType { generic, mate }

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
  final double highlightOpacity;

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
  final bool tintHeader;
  final bool tintFooter;
  final List<Shadow>? headerShadows;
  final List<Shadow>? footerShadows;
  final Color scoreColor;
  final Color teamScoreColor;
  final Color dividerColor;
  final Color accentColor;
  final String? backgroundAsset;
  final String? thumbnailAsset;
  final ThemeBackgroundType backgroundType;

  // CENTER ORNAMENT
  final String? centerOrnamentAsset;
  final bool hideCenterCircleBorder;
  final double centerOrnamentScale;
  final List<Shadow>? centerOrnamentShadows;

  // ASSET BELOW TOTAL SCORE
  final String? belowScoreAsset;
  final double belowScoreAssetSize;
  final double belowScoreAssetOffset;

  // FINE-TUNING FOR SCORE
  final double scoreFontSize;
  final double scoreVerticalOffset;
  final double centerSectionOffset;
  final double nosotrosMarginRight;
  final double ellosMarginLeft;

  final MatchstickBoxType matchstickBoxType;
  final double matchstickBoxOpacity;
  final Color? teamNameColorOverride;
  Color get teamNameColor => teamNameColorOverride ?? slate;

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
    this.tintHeader = true,
    this.tintFooter = true,
    this.headerShadows,
    this.footerShadows,
    required this.scoreColor,
    required this.teamScoreColor,
    required this.dividerColor,
    required this.accentColor,
    this.backgroundAsset,
    this.thumbnailAsset,
    this.backgroundType = ThemeBackgroundType.generic,
    this.centerOrnamentAsset,
    this.hideCenterCircleBorder = false,
    this.centerOrnamentScale = 1.0,
    this.centerOrnamentShadows,
    this.belowScoreAsset,
    this.belowScoreAssetSize = 28,
    this.belowScoreAssetOffset = 6,
    required this.scoreFontSize,
    required this.scoreVerticalOffset,
    required this.centerSectionOffset,
    this.nosotrosMarginRight = 0.0,
    this.ellosMarginLeft = 0.0,
    required this.matchstickBoxType,
    this.matchstickBoxOpacity = 1.0,
    this.teamNameColorOverride,
    required this.classicButtonColor,
    required this.classicButtonShadowColor,
    this.highlightOpacity = 0.1,
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
    headerAsset: 'assets/images/themes/navy_header.svg',
    footerAsset: 'assets/images/themes/navy_footer.svg',
    dividerColor: Color(0xFFEFEBE2),
    scoreColor: Color(0xFFEFEBE2),
    teamScoreColor: Color(0xFFEFEBE2),
    accentColor: Color(0xFF718C9C),
    backgroundAsset: null,
    thumbnailAsset: 'assets/images/themes/thumbnails/navy.png',
    centerOrnamentAsset: null,
    hideCenterCircleBorder: false,
    scoreFontSize: 26,
    scoreVerticalOffset: 5.0,
    centerSectionOffset: 10.0,
    matchstickBoxType: MatchstickBoxType.classic,
    highlightOpacity: 0.05,
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
    headerAsset: 'assets/images/themes/argentina_header.png',
    footerAsset: 'assets/images/themes/argentina_footer.png',
    tintHeader: false,
    tintFooter: false,
    dividerColor: Colors.white,
    scoreColor: Colors.white,
    teamScoreColor: Colors.white,
    accentColor: Color(0xFFF6B000),
    backgroundAsset: null,
    thumbnailAsset: 'assets/images/themes/thumbnails/argentina.png',
    centerOrnamentAsset: 'assets/images/themes/argentina_center_ornament.png',
    hideCenterCircleBorder: true,
    centerOrnamentScale: 1.7,
    scoreFontSize: 18,
    scoreVerticalOffset: -7.0,
    centerSectionOffset: 35.0,
    matchstickBoxType: MatchstickBoxType.classic,
    highlightOpacity: 0.1,
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
    footerAsset: 'assets/images/themes/soccer_footer_dibu.svg',
    footerHeight: 75,
    tintFooter: false,
    dividerColor: Colors.transparent,
    scoreColor: Color(0xFF07007A),
    teamScoreColor: Colors.white,
    accentColor: Color(0xFF07007A),
    backgroundAsset: 'assets/images/themes/soccer_background.jpg',
    thumbnailAsset: 'assets/images/themes/thumbnails/soccer.png',
    centerOrnamentAsset: 'assets/images/themes/soccer_center_ornament.svg',
    hideCenterCircleBorder: true,
    centerOrnamentScale: 2.2,
    scoreFontSize: 28,
    scoreVerticalOffset: 40.0,
    centerSectionOffset: 0.0,
    nosotrosMarginRight: 32.0,
    ellosMarginLeft: 32.0,
    matchstickBoxType: MatchstickBoxType.soccer,
    highlightOpacity: 0.1,
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
    backgroundAsset: 'assets/images/themes/wood_background.jpg',
    thumbnailAsset: 'assets/images/themes/thumbnails/wood.png',
    centerOrnamentAsset: 'assets/images/themes/wood_center_ornament.svg',
    hideCenterCircleBorder: true,
    scoreFontSize: 32,
    scoreVerticalOffset: 5.0,
    centerSectionOffset: 35.0,
    matchstickBoxType: MatchstickBoxType.wood,
    highlightOpacity: 0.08,
  );

  static const TrucoTheme malvinasTheme = TrucoTheme(
    name: "MALVINAS",
    navy: Color(0xFF283648),
    navyLight: Color(0xFF283648),
    slate: Color(0xFF283648),
    cream: Colors.white,
    white: Colors.white,
    navyAccent: Color(0xFF283648),
    buenas: Color(0xFFF6B000),
    malas: Colors.white,
    centerCircleColor: Colors.transparent,
    primaryBackgroundButton: Color(0xFF5A91C5),
    primaryTextButton: Colors.white,
    secondaryButtonBorder: Colors.white,
    secondaryButtonText: Colors.white,
    classicButtonColor: Color(0xFF5A91C5),
    classicButtonShadowColor: Color(0x14000000),
    headerAsset: null,
    footerAsset: 'assets/images/themes/malvinas_footer.png',
    footerHeight: 75,
    tintHeader: false,
    tintFooter: false,
    dividerColor: Colors.white,
    scoreColor: Colors.white,
    teamScoreColor: Colors.white,
    accentColor: Color(0xFFF6B000),
    backgroundAsset: 'assets/images/themes/malvinas_background.png',
    thumbnailAsset: 'assets/images/themes/thumbnails/malvinas.png',
    centerOrnamentAsset: null,
    hideCenterCircleBorder: true,
    scoreFontSize: 22,
    scoreVerticalOffset: 5.0,
    centerSectionOffset: 10.0,
    belowScoreAsset: 'assets/images/themes/argentina_sun.png',
    belowScoreAssetSize: 90,
    belowScoreAssetOffset: 0,
    matchstickBoxType: MatchstickBoxType.classic,
    matchstickBoxOpacity: 0.1,
    teamNameColorOverride: Color(0xFF5A91C5),
    highlightOpacity: 0.1,
  );

  static const TrucoTheme mateTheme = TrucoTheme(
    name: "MATE",
    navy: Color(0xFF3D2F1F),
    navyLight: Color(0xFF3D2F1F),
    slate: Color(0xFF3D2F1F),
    cream: Colors.white,
    white: Colors.white,
    navyAccent: Color(0xFF3D2F1F),
    buenas: Color(0xFFB6A35A),
    malas: Color(0xFFA05A38),
    centerCircleColor: Colors.transparent,
    primaryBackgroundButton: Color(0xFF6F7A3A),
    primaryTextButton: Colors.white,
    secondaryButtonBorder: Colors.white,
    secondaryButtonText: Colors.white,
    classicButtonColor: Color(0xFF6F7A3A),
    classicButtonShadowColor: Color(0x14000000),
    headerAsset: null,
    footerAsset: null,
    footerHeight: 85,
    tintHeader: false,
    tintFooter: false,
    dividerColor: Color(0xFFE2D2B4),
    scoreColor: Color(0xFFF5EFE3),
    teamScoreColor: Color(0xFFF5EFE3),
    accentColor: Color(0xFFB6A35A),
    backgroundAsset: 'assets/images/themes/mate_background.png',
    thumbnailAsset: 'assets/images/themes/thumbnails/mate.png',
    backgroundType: ThemeBackgroundType.mate,
    centerOrnamentAsset: null,
    hideCenterCircleBorder: true,
    scoreFontSize: 22,
    scoreVerticalOffset: 5.0,
    centerSectionOffset: 10.0,
    matchstickBoxType: MatchstickBoxType.classic,
    matchstickBoxOpacity: 0.1,
    teamNameColorOverride: Color(0xFFE2D2B4),
    highlightOpacity: 0.1,
  );

  static const List<TrucoTheme> allThemes = [
    navyTheme,
    argentinaTheme,
    soccerTheme,
    woodTheme,
    malvinasTheme,
    mateTheme,
  ];
}

class AppFonts {
  static const String oswald = 'Oswald';
  static const String oswaldSemiBold = 'Oswald-SemiBold';
  static const String oswaldRegular = 'Oswald-Regular';
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
