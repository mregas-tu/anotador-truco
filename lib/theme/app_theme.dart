import 'package:flutter/material.dart';

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
  
  // FIXED WOOD COLORS (Independent of theme)
  static const Color woodLight = Color(0xFFE6D2B5);
  static const Color woodMedium = Color(0xFFD2B48C);
  static const Color woodDark = Color(0xFFB89B74);

  // NEW ASSETS AND SPECIFIC COLORS
  final String headerAsset;
  final String footerAsset;
  final Color dividerColor;
  final Color accentColor; // For special elements like the score circle/glow
  final String? backgroundAsset; // Optional background image

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
    required this.headerAsset,
    required this.footerAsset,
    required this.dividerColor,
    required this.accentColor,
    this.backgroundAsset,
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
    headerAsset: 'assets/images/header.svg',
    footerAsset: 'assets/images/footer.svg',
    dividerColor: Color(0xFFEFEBE2),
    accentColor: Color(0xFF718C9C), // Slate for consistency
    backgroundAsset: null,
  );

  static const TrucoTheme argentinaTheme = TrucoTheme(
    name: "ARGENTINA",
    navy: Color(0xFF74ACDF), // Celeste
    navyLight: Color(0xFF8EBEEC), 
    slate: Colors.white, // Letras de equipo blancas
    cream: Colors.white,
    white: Colors.white,
    navyAccent: Color(0xFF5A91C5),
    buenas: Colors.white, // Fase blanca
    malas: Colors.white, // Fase blanca
    headerAsset: 'assets/images/header.svg',
    footerAsset: 'assets/images/footer.svg',
    dividerColor: Colors.white, // Línea blanca y número del medio blanco
    accentColor: Color(0xFFF6B000), // Amarillo Sol solo para el círculo y brillo
    backgroundAsset: null,
  );

  static const List<TrucoTheme> allThemes = [
    navyTheme,
    argentinaTheme,
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
