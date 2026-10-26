import 'package:shared_preferences/shared_preferences.dart';

/// Tiny audio facade for the game.
///
/// The current build is silent (no audio assets yet), but the mute switch is
/// real: it persists across launches and every call site already respects
/// [enabled], so wiring sound later only needs to fill in the bodies below.
class AudioService {
  static final AudioService _instance = AudioService._();
  factory AudioService() => _instance;
  AudioService._();

  static const String prefsKey = 'lifetrail_sound_enabled';

  bool enabled = true;
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      enabled = prefs.getBool(prefsKey) ?? true;
    } catch (_) {
      enabled = true;
    }
    _ready = true;
  }

  Future<void> setEnabled(bool value) async {
    enabled = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefsKey, value);
    } catch (_) {
      // A missing store should never crash the settings screen.
    }
  }

  void uiTap() {
    if (!enabled) return;
  }

  void interact() {
    if (!enabled) return;
  }

  void coins() {
    if (!enabled) return;
  }

  void sleep() {
    if (!enabled) return;
  }

  Future<void> playBgm(String track) async {
    if (!enabled) return;
  }

  Future<void> stopBgm() async {}
}
