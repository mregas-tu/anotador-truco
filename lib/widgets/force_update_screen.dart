import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'truco_buttons.dart';

class ForceUpdateScreen extends StatelessWidget {
  final String storeUrl;

  const ForceUpdateScreen({super.key, required this.storeUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D121F),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/about.png',
              width: 250,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.system_update,
                size: 100,
                color: Colors.white24,
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              '¡NUEVA VERSIÓN DISPONIBLE!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Oswald',
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'Sumamos mejoras para que tu partida sea perfecta. Actualizá para mezclar, cortar y repartir.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 50),
            PrimaryButton(
              text: 'DESCARGAR AHORA',
              height: 55,
              width: 280,
              fontSize: 20,
              onPressed: () async {
                final Uri url = Uri.parse(storeUrl);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
