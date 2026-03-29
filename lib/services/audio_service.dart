import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _stickPlayer = AudioPlayer();
  final AudioPlayer _clearPlayer = AudioPlayer();
  final AudioPlayer _milestonePlayer = AudioPlayer();

  Future<void> playStick() async {
    await _stickPlayer.stop();
    await _stickPlayer.play(AssetSource('sounds/stick.wav'));
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
    _stickPlayer.dispose();
    _clearPlayer.dispose();
    _milestonePlayer.dispose();
  }
}
