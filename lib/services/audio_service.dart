import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _markerPlayer = AudioPlayer();
  final AudioPlayer _clearPlayer = AudioPlayer();
  final AudioPlayer _milestonePlayer = AudioPlayer();

  Future<void> playMarker(bool isBean) async {
    await _markerPlayer.stop();
    final String source = isBean ? 'sounds/bean.wav' : 'sounds/stick.wav';
    await _markerPlayer.play(AssetSource(source));
  }

  Future<void> playPack(bool isBean) async {
    await _markerPlayer.stop();
    final String source = isBean ? 'sounds/bean_pack.wav' : 'sounds/pack.wav';
    await _markerPlayer.play(AssetSource(source));
  }

  Future<void> playClear() async {
    await _clearPlayer.stop();
    await _clearPlayer.play(AssetSource('sounds/clear.wav'));
  }

  Future<void> playBuenas() async {
    await _milestonePlayer.stop();
    await _milestonePlayer.play(AssetSource('sounds/buenas.wav'));
  }

  void dispose() {
    _markerPlayer.dispose();
    _clearPlayer.dispose();
    _milestonePlayer.dispose();
  }
}
