import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'player/player_component.dart';
import 'world/town_world.dart';
import 'world/interactable.dart';

class LifeGame extends FlameGame {
  final void Function(Interactable?) onNearestChanged;
  final void Function(String locationId) onEnterLocation;
  final void Function(String npcId) onTalkTo;
  final void Function(String message) onMessage;

  late final PlayerComponent player;
  late final TownWorld town;
  late final JoystickComponent joystick;

  Interactable? _nearest;

  static const double dayNightAlphaDay = 0.0;
  static const double dayNightAlphaNight = 0.45;
  double nightAlpha = 0.0;

  LifeGame({
    required this.onNearestChanged,
    required this.onEnterLocation,
    required this.onTalkTo,
    required this.onMessage,
  });

  LifeInteractContext get interactContext => LifeInteractContext(
    showMessage: onMessage,
    enterLocation: onEnterLocation,
    talkTo: onTalkTo,
    pickUp: onMessage,
  );

  @override
  Future<void> onLoad() async {
    town = TownWorld(onNearestChanged: _handleNearest);
    add(town);

    player = PlayerComponent(spawn: Vector2(1600, 1310));
    await town.add(player);

    final knobPaint = Paint()..color = Colors.white.withAlpha(200);
    final bgPaint = Paint()..color = Colors.black.withAlpha(90);
    joystick = JoystickComponent(
      knob: CircleComponent(radius: 28, paint: knobPaint),
      background: CircleComponent(radius: 64, paint: bgPaint),
      margin: const EdgeInsets.only(left: 24, bottom: 24),
    );
    add(joystick);

    camera.viewfinder.visibleGameSize = Vector2(1280, 720);
    camera.viewfinder.zoom = 1.0;
    camera.follow(player);
  }

  void _handleNearest(Interactable? value) {
    _nearest = value;
    onNearestChanged(value);
  }

  void setRunning(bool value) => player.running = value;

  Future<void> interactNearest() async {
    final target = _nearest;
    if (target != null) await target.onInteract(interactContext);
  }

  void spawnNpcMarkers(
    Map<String, Vector2> positions,
    Map<String, String> names,
  ) {
    for (final child in town.children.whereType<NpcMarker>().toList()) {
      child.removeFromParent();
    }
    positions.forEach((id, pos) {
      town.add(NpcMarker(npcId: id, npcName: names[id] ?? id, at: pos));
    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isLoaded) return;
    player.moveInput = joystick.relativeDelta;

    final solids = town.solidBounds();
    for (final solid in solids) {
      if (player.toRect().overlaps(solid.toRect())) {
        final center = solid.center;
        final diff = player.position - center;
        if (diff.x.abs() > diff.y.abs()) {
          player.position.x =
              center.x +
              (diff.x > 0 ? solid.width / 2 + 26 : -solid.width / 2 - 26);
        } else {
          player.position.y =
              center.y +
              (diff.y > 0 ? solid.height / 2 + 26 : -solid.height / 2 - 26);
        }
      }
    }

    Interactable? best;
    var bestDist = 150.0;
    for (final b in solids.whereType<Interactable>()) {
      final d = (b as PositionComponent).center.distanceTo(player.position);
      if (d < bestDist) {
        bestDist = d;
        best = b;
      }
    }
    for (final m in town.children.whereType<NpcMarker>()) {
      final d = m.position.distanceTo(player.position);
      if (d < bestDist) {
        bestDist = d;
        best = m;
      }
    }
    if (best?.interactId != _nearest?.interactId) {
      _handleNearest(best);
    }
  }

  void setNightAlpha(double alpha) {
    nightAlpha = alpha.clamp(0.0, 0.55);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (nightAlpha > 0.01) {
      final size = canvasSize;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = Color.fromRGBO(10, 10, 60, nightAlpha),
      );
    }
  }
}
