import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'player/player_component.dart';
import 'world/feet_collision.dart';
import 'world/town_world.dart';
import 'world/interior_world.dart';
import 'world/interior_data.dart';
import 'world/interactable.dart';
import 'world/life_world.dart';
import 'world/mini_map_scene.dart';

class LifeGame extends FlameGame {
  final void Function(Interactable?) onNearestChanged;

  /// Called whenever the player walks through a door into a building.
  final void Function(String locationId) onEnterLocation;

  /// Called when a room's activity point opens the location action menu.
  final void Function(String locationId) onOpenLocationMenu;

  /// Called when the player leaves a building.
  final void Function(String locationId) onLeftLocation;

  final void Function(String npcId) onTalkTo;
  final void Function(String message) onMessage;

  /// Randomness for the wandering townspeople (seed it in tests).
  final Random random;

  PlayerComponent? player;
  TownWorld? town;
  JoystickComponent? joystick;

  LifeWorld? _activeWorld;
  String? _interiorId;

  Interactable? _nearest;

  /// Where the player is right now, for the "you are here" minimap dot.
  final ValueNotifier<Vector2> playerMapPosition = ValueNotifier(
    Vector2.zero(),
  );

  /// The map currently on screen: the town, or the room the player is in.
  /// Kept in step with the active scene so the minimap always matches.
  final ValueNotifier<MiniMapScene> miniMapScene = ValueNotifier(
    buildMiniMapScene(null),
  );

  static const double dayNightAlphaDay = 0.0;
  static const double dayNightAlphaNight = 0.45;
  double nightAlpha = 0.0;

  LifeGame({
    required this.onNearestChanged,
    required this.onEnterLocation,
    required this.onOpenLocationMenu,
    required this.onLeftLocation,
    required this.onTalkTo,
    required this.onMessage,
    Random? random,
  }) : random = random ?? Random();

  LifeInteractContext get interactContext => LifeInteractContext(
    showMessage: onMessage,
    enterLocation: enterLocation,
    openLocationMenu: onOpenLocationMenu,
    exitLocation: exitLocation,
    talkTo: onTalkTo,
    pickUp: onMessage,
  );

  bool get isReady => isLoaded && player != null && _activeWorld != null;

  /// The scene currently being rendered: the town or a building interior.
  LifeWorld? get activeWorld => _activeWorld;

  /// True while the player is inside a building scene.
  bool get isInsideBuilding => _interiorId != null;

  String? get currentLocationId => _interiorId;

  @override
  Color backgroundColor() => const Color(0xFFEFE8D5);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final newTown = TownWorld(onNearestChanged: _handleNearest, random: random);
    // Assign as the game's active world so the camera renders it.
    // (Previously `add(newWorld)` left the camera pointed at the default
    // empty World, and `isReady` polling before GameWidget mount
    // deadlocked the loading screen.)
    world = newTown;
    town = newTown;
    _activeWorld = newTown;

    // Start in front of the home door, not on top of the building.
    final hero = PlayerComponent(spawn: newTown.doorSpawn('home'));
    player = hero;
    await world.add(hero);

    final knobPaint = Paint()..color = Colors.white.withAlpha(200);
    final bgPaint = Paint()..color = Colors.black.withAlpha(90);
    final stick = JoystickComponent(
      knob: CircleComponent(radius: 28, paint: knobPaint),
      background: CircleComponent(radius: 64, paint: bgPaint),
      // Symmetric with ActionButtons (right: 12, bottom: 12) so the
      // left and right gutters match on landscape phones.
      margin: const EdgeInsets.only(left: 12, bottom: 12),
    );
    joystick = stick;
    camera.viewport.add(stick);

    camera.viewfinder.anchor = Anchor.center;
    // Force full screen width on any landscape phone: constrain the
    // visible width to 1280 world units and leave height unconstrained
    // (0). Flame then picks zoom = viewportWidth / 1280, so the map
    // always stretches edge-to-edge with no left/right bars.
    camera.viewfinder.visibleGameSize = Vector2(1280, 0);
    _applyCameraBounds(newTown);
    camera.follow(hero);
  }

  /// Walk through a building door: swap the town for that building's interior.
  Future<void> enterLocation(String locationId) async {
    final hero = player;
    if (hero == null || !isLoaded || _interiorId == locationId) return;
    final layout = buildInterior(locationId);
    final interior = InteriorWorld(
      layout: layout,
      onNearestChanged: _handleNearest,
    );
    _interiorId = layout.id;
    _activeWorld = interior;
    miniMapScene.value = buildMiniMapScene(layout.id);
    world = interior;
    // Move the figure into the room first so it never renders for a frame at
    // its old town coordinates.
    hero.position = interior.entrySpawn;
    hero.moveInput = Vector2.zero();
    await interior.add(hero);
    _applyCameraBounds(interior);
    _handleNearest(null);
    onMessage(layout.entryMessage);
    onEnterLocation(layout.id);
  }

  /// Leave the current interior and return to the town, in front of its door.
  Future<void> exitLocation() async {
    final townWorld = town;
    final hero = player;
    final from = _activeWorld;
    final locationId = _interiorId;
    if (hero == null || townWorld == null || locationId == null) return;
    final message = from is InteriorWorld
        ? from.layout.exitMessage
        : 'You step back outside.';
    _interiorId = null;
    _activeWorld = townWorld;
    miniMapScene.value = buildMiniMapScene(null);
    world = townWorld;
    hero.position = townWorld.doorSpawn(locationId);
    hero.moveInput = Vector2.zero();
    await townWorld.add(hero);
    _applyCameraBounds(townWorld);
    _handleNearest(null);
    onMessage(message);
    onLeftLocation(locationId);
  }

  void _applyCameraBounds(LifeWorld target) {
    final size = target.worldSize;
    camera.setBounds(
      Rectangle.fromLTRB(0, 0, size.x, size.y),
      considerViewport: true,
    );
  }

  void _handleNearest(Interactable? value) {
    _nearest = value;
    onNearestChanged(value);
  }

  void setRunning(bool value) {
    player?.running = value;
  }

  Future<void> interactNearest() async {
    final target = _nearest;
    if (target != null) await target.onInteract(interactContext);
  }

  void spawnNpcMarkers(
    Map<String, Vector2> positions,
    Map<String, String> names,
  ) {
    // NPCs only ever stand in the town, never inside a building.
    final world = town;
    if (world == null) return;
    for (final child in world.children.whereType<NpcMarker>().toList()) {
      child.removeFromParent();
    }
    positions.forEach((id, pos) {
      world.add(NpcMarker(npcId: id, npcName: names[id] ?? id, at: pos));
    });
  }

  @override
  void update(double dt) {
    // Feed this frame's joystick input to the player before it moves.
    final hero = player;
    final stick = joystick;
    if (hero != null && stick != null) hero.moveInput = stick.relativeDelta;

    super.update(dt);

    final world = _activeWorld;
    if (!isLoaded || hero == null || world == null) return;

    // Report the position for the minimap (no rebuild while standing still).
    playerMapPosition.value = Vector2(hero.position.x, hero.position.y);

    // Keep the figure inside the current scene.
    final bounds = world.worldSize;
    void clampToScene() {
      hero.position.x = hero.position.x.clamp(42.0, bounds.x - 42);
      hero.position.y = hero.position.y.clamp(hero.size.y, bounds.y - 26);
    }

    clampToScene();
    // Slide along walls instead of being snapped back and forth, which used
    // to make the player shake on contact with a building.
    resolveFeetCollision(
      position: hero.position,
      previous: hero.previousPosition,
      solids: world.solidBounds(),
    );
    clampToScene();

    Interactable? best;
    var bestDist = 150.0;
    void consider(Interactable target) {
      final d = target.interactPosition.distanceTo(hero.position);
      if (d < bestDist) {
        bestDist = d;
        best = target;
      }
    }

    for (final solid in world.solidBounds()) {
      if (solid is Interactable) consider(solid as Interactable);
    }
    for (final target in world.interactables()) {
      consider(target);
    }
    if (world is TownWorld) {
      for (final m in world.children.whereType<NpcMarker>()) {
        final d = m.interactPosition.distanceTo(hero.position);
        if (d < bestDist) {
          bestDist = d;
          best = m;
        }
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
