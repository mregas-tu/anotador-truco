import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class SupportService {
  static const String _supportEmail = 'martoregas@gmail.com';
  static const String betaFeedbackEmail = 'contact@martostudio.com';
  static const String _appUrlAndroid =
      'https://play.google.com/store/apps/details?id=com.mregas.truco.anotador';
  static const String _appUrlIOS = 'https://apps.apple.com/app/idYOUR_APP_ID';

  static String get appUrl => Platform.isAndroid ? _appUrlAndroid : _appUrlIOS;

  static Future<void> sendFeedbackEmail({
    String email = _supportEmail,
    String subject = 'Puro Truco - Dudas y sugerencias',
  }) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      query: _encodeQueryParameters(<String, String>{
        'subject': subject,
      }),
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      }
    } catch (e) {
      debugPrint("Error al abrir el mail: $e");
    }
  }

  static void shareApp() {
    Share.share("#AnotadorDeTruco\n$appUrl");
  }

  static String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}
