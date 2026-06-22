import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  // En modo lowLatency, audioplayers usa SoundPool en Android.
  // Cada AudioPlayer mantiene UN sample cargado en memoria — no toca cache.
  final AudioPlayer _stickPlayer = AudioPlayer();
  final AudioPlayer _beanPlayer = AudioPlayer();
  final AudioPlayer _packPlayer = AudioPlayer();
  final AudioPlayer _beanPackPlayer = AudioPlayer();
  final AudioPlayer _clearPlayer = AudioPlayer();
  final AudioPlayer _buenasPlayer = AudioPlayer();

  bool _loaded = false;

  Future<void> _setup(AudioPlayer player, String asset) async {
    await player.setPlayerMode(PlayerMode.lowLatency);
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setSource(AssetSource(asset));
  }

  Future<void> preload() async {
    if (_loaded) return;
    await Future.wait([
      _setup(_stickPlayer, 'sounds/stick.wav'),
      _setup(_beanPlayer, 'sounds/bean.wav'),
      _setup(_packPlayer, 'sounds/pack.wav'),
      _setup(_beanPackPlayer, 'sounds/bean_pack.wav'),
      _setup(_clearPlayer, 'sounds/clear.wav'),
      _setup(_buenasPlayer, 'sounds/buenas.wav'),
    ]);
    _loaded = true;
  }

  Future<void> _safePlay(AudioPlayer player) async {
    try {
      await player.stop();
      await player.resume();
    } catch (_) {
      // Si por algún motivo fallara, no crashea la UI.
    }
  }

  Future<void> playMarker(bool isBean) =>
      _safePlay(isBean ? _beanPlayer : _stickPlayer);

  Future<void> playPack(bool isBean) =>
      _safePlay(isBean ? _beanPackPlayer : _packPlayer);

  Future<void> playClear() => _safePlay(_clearPlayer);

  Future<void> playBuenas() => _safePlay(_buenasPlayer);

  void dispose() {
    _stickPlayer.dispose();
    _beanPlayer.dispose();
    _packPlayer.dispose();
    _beanPackPlayer.dispose();
    _clearPlayer.dispose();
    _buenasPlayer.dispose();
  }
}
