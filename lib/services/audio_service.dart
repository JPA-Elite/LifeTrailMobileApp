class AudioService {
  static final AudioService _instance = AudioService._();
  factory AudioService() => _instance;
  AudioService._();

  bool enabled = true;
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    _ready = true;
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
