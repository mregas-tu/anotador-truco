import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/live_match_state.dart';
import '../providers/score_provider.dart';
import '../services/live_match_service.dart';
import '../theme/app_theme.dart';
import '../widgets/truco_buttons.dart';

class LiveMatchScreen extends StatefulWidget {
  const LiveMatchScreen({super.key});

  @override
  State<LiveMatchScreen> createState() => _LiveMatchScreenState();
}

class _LiveMatchScreenState extends State<LiveMatchScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isStartingHost = false;
  bool _isScanning = false;
  bool _handledScan = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scoreProvider = context.watch<ScoreProvider>();
    final theme = scoreProvider.appTheme;

    return Scaffold(
      backgroundColor: theme.navy,
      appBar: AppBar(
        backgroundColor: theme.navy,
        foregroundColor: theme.cream,
        elevation: 0,
        title: const Text(
          'PARTIDA EN VIVO',
          style: TextStyle(
            fontFamily: AppFonts.oswald,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            _buildHostSection(scoreProvider, theme),
            const SizedBox(height: 18),
            Divider(color: theme.dialogSeparator),
            const SizedBox(height: 18),
            _buildSpectatorSection(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHostSection(ScoreProvider scoreProvider, TrucoTheme theme) {
    final shareValue = scoreProvider.liveShareValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          icon: Icons.qr_code_2,
          title: 'SOY ANFITRIÓN',
          color: theme.cream,
        ),
        const SizedBox(height: 10),
        Text(
          'Generá un QR para que otra app siga este tanteador en vivo.',
          style: TextStyle(
            fontFamily: AppFonts.oswald,
            fontSize: 15,
            color: theme.slate,
          ),
        ),
        const SizedBox(height: 16),
        if (shareValue == null)
          PrimaryButton(
            text: _isStartingHost ? 'Creando...' : 'Generar QR',
            width: double.infinity,
            onPressed: () async {
              if (_isStartingHost) return;
              setState(() => _isStartingHost = true);
              try {
                await scoreProvider.startLiveHosting();
              } catch (error) {
                if (mounted) {
                  _showMessage(_liveMatchErrorMessage(error));
                }
              } finally {
                if (mounted) setState(() => _isStartingHost = false);
              }
            },
          )
        else ...[
          Center(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: QrImageView(
                data: shareValue,
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SelectableText(
            shareValue,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.oswald,
              fontSize: 13,
              color: theme.slate,
            ),
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            text: 'Copiar link',
            width: double.infinity,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: shareValue));
              if (mounted) _showMessage('Link copiado.');
            },
          ),
          const SizedBox(height: 10),
          SecondaryButton(
            text: 'Detener vivo',
            width: double.infinity,
            onPressed: scoreProvider.stopLiveHosting,
          ),
        ],
      ],
    );
  }

  Widget _buildSpectatorSection(TrucoTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          icon: Icons.qr_code_scanner,
          title: 'SOY ESPECTADOR',
          color: theme.cream,
        ),
        const SizedBox(height: 10),
        Text(
          'Escaneá el QR de una partida para entrar al tanteador en vivo.',
          style: TextStyle(
            fontFamily: AppFonts.oswald,
            fontSize: 15,
            color: theme.slate,
          ),
        ),
        const SizedBox(height: 16),
        if (_isScanning) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 1,
              child: MobileScanner(
                controller: _scannerController,
                onDetect: _handleBarcode,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SecondaryButton(
            text: 'Cancelar escaneo',
            width: double.infinity,
            onPressed: () => setState(() {
              _isScanning = false;
              _handledScan = false;
            }),
          ),
        ] else
          PrimaryButton(
            text: 'Escanear QR',
            width: double.infinity,
            onPressed: () => setState(() {
              _isScanning = true;
              _handledScan = false;
            }),
          ),
      ],
    );
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (_handledScan) return;
    String? value;
    for (final barcode in capture.barcodes) {
      if (barcode.rawValue != null) {
        value = barcode.rawValue;
        break;
      }
    }
    final matchId = value == null ? null : LiveMatchService.parseMatchId(value);

    if (matchId == null) return;
    _handledScan = true;
    _scannerController.stop();
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => LiveMatchViewerScreen(matchId: matchId),
      ),
    )
        .then((_) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _handledScan = false;
      });
    });
  }

  void _showMessage(String message) {
    final theme = context.read<ScoreProvider>().appTheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: AppFonts.oswald),
        ),
        backgroundColor: theme.accentColor,
      ),
    );
  }

  String _liveMatchErrorMessage(Object error) {
    debugPrint('[LiveMatch] Create failed: $error');
    if (error is FirebaseException) {
      return 'No se pudo crear la partida (${error.code}).';
    }
    if (error is TimeoutException) {
      return 'No se pudo crear la partida: Firestore no respondió.';
    }
    return 'No se pudo crear la partida en vivo.';
  }
}

class LiveMatchViewerScreen extends StatelessWidget {
  final String matchId;

  const LiveMatchViewerScreen({
    super.key,
    required this.matchId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ScoreProvider>().appTheme;

    return Scaffold(
      backgroundColor: theme.navy,
      appBar: AppBar(
        backgroundColor: theme.navy,
        foregroundColor: theme.cream,
        elevation: 0,
        title: const Text(
          'ESPECTADOR',
          style: TextStyle(
            fontFamily: AppFonts.oswald,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<LiveMatchState?>(
          stream: LiveMatchService.watchMatch(matchId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: theme.cream),
              );
            }

            final state = snapshot.data;
            if (state == null) {
              return _ViewerMessage(
                icon: Icons.search_off,
                message: 'No encontramos esa partida.',
                theme: theme,
              );
            }

            return _LiveScoreBoard(state: state, theme: theme);
          },
        ),
      ),
    );
  }
}

class _LiveScoreBoard extends StatelessWidget {
  final LiveMatchState state;
  final TrucoTheme theme;

  const _LiveScoreBoard({
    required this.state,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            state.gameModeLabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.oswald,
              color: theme.slate,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _TeamScore(
                    name: state.nosotrosName,
                    score: state.nosotrosScore,
                    theme: theme,
                  ),
                ),
                Container(
                    width: 1, color: theme.dividerColor.withValues(alpha: 0.2)),
                Expanded(
                  child: _TeamScore(
                    name: state.ellosName,
                    score: state.ellosScore,
                    theme: theme,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            state.finished ? 'GANÓ ${state.winnerName}' : 'EN VIVO',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.oswald,
              color: state.finished ? theme.cream : theme.accentColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamScore extends StatelessWidget {
  final String name;
  final int score;
  final TrucoTheme theme;

  const _TeamScore({
    required this.name,
    required this.score,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: AppFonts.oswald,
            color: theme.teamNameColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          '$score',
          style: TextStyle(
            fontFamily: AppFonts.caminito,
            color: theme.teamScoreColor,
            fontSize: 96,
            height: 0.9,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontFamily: AppFonts.oswald,
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _ViewerMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final TrucoTheme theme;

  const _ViewerMessage({
    required this.icon,
    required this.message,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: theme.cream, size: 44),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.oswald,
              color: theme.cream,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}
