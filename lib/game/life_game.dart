import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' hide DayPeriod;
import '../models/game_time.dart';
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

  /// Sitting restores energy via the app's GameState (wired in GameScreen).
  /// Defaults to a no-op so unit tests can construct LifeGame without it.
  final void Function() onSitDown;

  /// Sleeping in the home bed: fades to morning via GameScreen.
  /// Defaults to a no-op so unit tests can construct LifeGame without it.
  final void Function() onSleepInBed;

  /// Using the town ATM (wired in GameScreen, no-op in tests).
  final void Function() onUseAtm;

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

  /// Tint drawn with [nightAlpha]. Changes per DayPeriod so morning reads
  /// bright, evening reads dusk-orange, and night reads dark blue — both
  /// in town and inside buildings (render overlay covers the active world).
  Color dayNightTint = const Color.fromRGBO(10, 10, 60, 1.0);

  /// Optional gate checked before swapping to an interior (wired in
  /// GameScreen to GameState.canEnterBuilding). When it returns false the
  /// door shows [onMessage] and the player stays outside.
  bool Function(String locationId)? canEnterLocation;

  /// Default (fitted) zoom captured on the first pinch; the clamp stays
  /// relative to this across gestures so repeated pinches can't creep
  /// the range outward.
  double _defaultZoom = 0;

  /// Last orientation class seen in [onGameResize] (null until the first
  /// layout). Rotating between portrait and landscape refits the camera;
  /// staying in one class preserves the player's pinch zoom.
  bool? _wasLandscape;

  /// Smoothed zoom target. Finger events only move the target; update()
  /// eases the real zoom toward it every frame, so delayed or dropped
  /// touch events on a phone read as glide instead of stutter.
  /// 0 = no active pinch target (zoom stays where it is).
  double _targetZoom = 0;

  /// False while the user is free-looking (drag-panned away from the
  /// player). Walking via the joystick glides smoothly back to follow.
  bool _followingPlayer = true;

  /// Pending pan distance (world units). Drag events accumulate here;
  /// update() glides through it each frame so free-look moves smoothly
  /// instead of jumping with every raw touch event.
  Vector2 _pendingPan = Vector2.zero();

  /// True while the camera is animating home after free-look. Follow
  /// stays off until the glide converges, so there is never a snap.
  bool _snappingBack = false;

  LifeGame({
    required this.onNearestChanged,
    required this.onEnterLocation,
    required this.onOpenLocationMenu,
    required this.onLeftLocation,
    required this.onTalkTo,
    required this.onMessage,
    void Function()? onSitDown,
    void Function()? onSleepInBed,
    void Function()? onUseAtm,
    Random? random,
    this.canEnterLocation,
  }) : onSitDown = onSitDown ?? (() {}),
       onSleepInBed = onSleepInBed ?? (() {}),
       onUseAtm = onUseAtm ?? (() {}),
       random = random ?? Random();

  LifeInteractContext get interactContext => LifeInteractContext(
    showMessage: onMessage,
    enterLocation: enterLocation,
    openLocationMenu: onOpenLocationMenu,
    exitLocation: exitLocation,
    sitDown: onSitDown,
    sleepInBed: onSleepInBed,
    useAtm: onUseAtm,
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
    // Fit the world to the current orientation (auto-rotate): landscape
    // constrains width to 1280 world units (edge-to-edge, no side bars),
    // portrait constrains height instead so the view stays at the same
    // world scale instead of shrinking to a postage stamp.
    _applyVisibleFit();
    _applyCameraBounds(newTown);
    camera.follow(hero);
  }

  /// Fits the camera to the current canvas orientation. Landscape locks
  /// the visible width (Flame derives zoom from it); portrait locks the
  /// visible height. Resets the smoothed pinch target so it can't fight
  /// the new fit. No-op before the first layout (size 0).
  void _applyVisibleFit() {
    final s = size;
    if (s.x <= 0 || s.y <= 0) return;
    if (s.x >= s.y) {
      camera.viewfinder.visibleGameSize = Vector2(1280, 0);
    } else {
      camera.viewfinder.visibleGameSize = Vector2(0, 1280);
    }
    _defaultZoom = camera.viewfinder.zoom;
    _targetZoom = 0;
  }

  /// Walk through a building door: swap the town for that building's interior.
  /// Blocked at night for every building except home (see GameState).
  Future<void> enterLocation(String locationId) async {
    if (canEnterLocation != null && !(canEnterLocation!(locationId))) {
      onMessage(
        'It\'s night time. $locationId is closed. Go home and sleep until morning.',
      );
      return;
    }
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
    town?.playerPosition = null;
    // Move the figure into the room first so it never renders for a frame at
    // its old town coordinates.
    hero.position = interior.entrySpawn;
    hero.moveInput = Vector2.zero();
    await interior.add(hero);
    _applyCameraBounds(interior);
    _followPlayer(instant: true);
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
    _followPlayer(instant: true);
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
    // Clamp wild time steps after hitches (shader compiles on a fresh
    // interior entry, GC, app resume): an unclamped dt teleports the
    // player deep into furniture and the snap-back correction reads as
    // screen shake. 50ms keeps motion smooth without visible slowdown.
    if (dt > 0.05) dt = 0.05;
    // Feed this frame's joystick input to the player before it moves.
    final hero = player;
    final stick = joystick;
    if (hero != null && stick != null) hero.moveInput = stick.relativeDelta;

    super.update(dt);

    // Ease the camera toward the pinch target (~10/s): smooth glide
    // even when touch events arrive late or drop on a real phone.
    if (_targetZoom > 0) {
      final z = camera.viewfinder.zoom;
      final diff = _targetZoom - z;
      if (diff.abs() < 0.0005) {
        camera.viewfinder.zoom = _targetZoom;
      } else {
        camera.viewfinder.zoom = z + diff * (1 - pow(0.5, dt * 10));
      }
    }

    // Glide through the pending drag distance (~14/s): free-look
    // moves smoothly even when touch events arrive in bursts.
    // Skipped while snapping home so the two motions never fight.
    if (!_snappingBack &&
        (_pendingPan.x.abs() > 0.05 || _pendingPan.y.abs() > 0.05)) {
      final step = _pendingPan * (1 - pow(0.5, dt * 14)).toDouble();
      camera.viewfinder.position += step;
      _pendingPan -= step;
    }

    // Joystick walk/run glides a free-looked camera back onto the
    // player instead of snapping.
    if (hero != null && hero.isMoving) _followPlayer();
    if (_snappingBack && hero != null) {
      final toPlayer = hero.position - camera.viewfinder.position;
      if (toPlayer.length < 3) {
        _snappingBack = false;
        _followingPlayer = true;
        camera.follow(hero);
      } else {
        camera.viewfinder.position +=
            toPlayer * (1 - pow(0.5, dt * 6)).toDouble();
      }
    }

    final world = _activeWorld;
    if (!isLoaded || hero == null || world == null) return;

    // Report the position for the minimap (no rebuild while standing still).
    playerMapPosition.value = Vector2(hero.position.x, hero.position.y);

    // Feed the town's traffic: cars halt when the player is on a zebra.
    // Feed interiors too: furniture depth-sorts against the player.
    if (world == town) {
      town?.playerPosition = hero.position;
    } else if (world is InteriorWorld) {
      world.playerPosition = hero.position;
    }

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
    // No fixed radius cap: candidacy is gated by feet-overlap with the
    // target's touch zone (below), and the nearest overlapping target
    // wins. A fixed cap broke big furniture: the bed/kitchen/TV centers
    // sit 170-270px from any reachable touch point, so they could never
    // trigger no matter how the player rubbed against them.
    var bestDist = double.infinity;
    // Touch-only: the player's feet box must overlap the target's touch
    // zone. Same rule for benches, doors, NPCs and furniture — no
    // long-range "nearby" popups.
    final feet = hero.feetRect;
    void consider(Interactable target) {
      // Scenery StreetProps (trees / lamps / hydrants) never trigger:
      // only benches surface an action button.
      if (target is StreetProp && !target.isInteractable) return;
      if (!feet.overlaps(target.touchRect)) return;
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
        // Same touch-only rule as everything else (see comment above):
        // without the overlap gate, dropping the radius cap would let a
        // distant NPC hijack the action button.
        if (!feet.overlaps(m.touchRect)) continue;
        final d = m.interactPosition.distanceTo(hero.position);
        if (d < bestDist) {
          bestDist = d;
          best = m;
        }
      }
    }
    // Hysteresis: while the current target is still touched, a challenger
    // must be clearly closer (40px) to dethrone it. Without this, standing
    // on a zone boundary flips the target every frame, spamming full-screen
    // rebuilds (visible stutter) and making the action button flicker.
    final current = _nearest;
    if (best?.interactId != current?.interactId) {
      var keepCurrent = false;
      if (current != null && best != null) {
        final stillTouching =
            !(current is StreetProp && !current.isInteractable) &&
            feet.overlaps(current.touchRect);
        if (stillTouching) {
          final currentDist = current.interactPosition.distanceTo(
            hero.position,
          );
          if (bestDist > currentDist - 40.0) keepCurrent = true;
        }
      }
      _handleNearest(keepCurrent ? current : best);
    }
  }

  void setNightAlpha(double alpha) {
    nightAlpha = alpha.clamp(0.0, 0.55);
  }

  /// Day scenario visuals: morning = bright, afternoon = bright warm,
  /// evening = dusk orange, night = dark blue. Called every frame from
  /// GameScreen with the current GameTime period so town + interiors
  /// always match the clock. Keeps [setNightAlpha] working for tests.
  void setDayPeriod(DayPeriod period) {
    switch (period) {
      case DayPeriod.morning:
        dayNightTint = const Color.fromRGBO(255, 244, 214, 1.0);
        nightAlpha = 0.0;
        break;
      case DayPeriod.afternoon:
        dayNightTint = const Color.fromRGBO(255, 250, 235, 1.0);
        nightAlpha = 0.0;
        break;
      case DayPeriod.evening:
        dayNightTint = const Color.fromRGBO(150, 70, 20, 1.0);
        nightAlpha = 0.22;
        break;
      case DayPeriod.night:
        dayNightTint = const Color.fromRGBO(10, 10, 60, 1.0);
        nightAlpha = 0.45;
        break;
    }
  }

  /// Drag-pan the view (single finger on the open map): stops following
  /// the player so the user can explore. Cancels any snap-back glide.
  /// The distance accumulates and update() glides through it smoothly.
  /// World bounds still clamp the camera. Walking via the joystick
  /// glides smoothly back to the player.
  void panBy(Offset screenDelta) {
    if (!isLoaded) return;
    _snappingBack = false;
    if (_followingPlayer) {
      _followingPlayer = false;
      camera.stop();
    }
    _pendingPan +=
        Vector2(-screenDelta.dx, -screenDelta.dy) / camera.viewfinder.zoom;
  }

  void _followPlayer({bool instant = false}) {
    final hero = player;
    if (hero == null || !isLoaded) return;
    if (instant) {
      _snappingBack = false;
      _followingPlayer = true;
      camera.follow(hero);
      return;
    }
    // Animated: glide home in update(), engage follow on arrival.
    // Leftover drag distance is dropped so it can't fight the glide.
    if (!_followingPlayer) {
      _pendingPan = Vector2.zero();
      _snappingBack = true;
    }
  }

  /// Called when two fingers land on the open map: anchors the smoothed
  /// zoom target. Driven by raw pointer tracking in GameScreen scoped to
  /// the GameWidget, with no gesture-arena slop or dead zones.
  void pinchStart() {
    if (!isLoaded) return;
    if (_defaultZoom <= 0) _defaultZoom = camera.viewfinder.zoom;
    _targetZoom = camera.viewfinder.zoom;
  }

  /// Applies one incremental finger-distance ratio to the zoom target.
  /// Single-finger drags and UI taps never reach here (GameScreen only
  /// calls this with exactly two pointers down on the map), so the
  /// joystick is unaffected.
  void pinchZoomBy(double factor) {
    if (!isLoaded || factor <= 0 || !factor.isFinite) return;
    if (_defaultZoom <= 0) _defaultZoom = camera.viewfinder.zoom;
    if (_targetZoom <= 0) _targetZoom = camera.viewfinder.zoom;
    _targetZoom = (_targetZoom * factor).clamp(
      _defaultZoom * 0.5,
      _defaultZoom * 3.0,
    );
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Rotating between portrait and landscape refits the camera to the
    // new orientation class so the world scale stays right. Resizing
    // within one class preserves the player's pinch zoom instead.
    final landscape = size.x >= size.y;
    if (_wasLandscape == null || _wasLandscape != landscape) {
      _wasLandscape = landscape;
      _applyVisibleFit();
      return;
    }
    // Rotation/resize refits the zoom from visibleGameSize: carry the
    // user's relative zoom over to the new fit instead of dropping it,
    // so a walked/zoomed view stays put (permanent) instead of
    // snapping back to the default while playing.
    final fitted = camera.viewfinder.zoom;
    _defaultZoom = fitted;
    if (_targetZoom > 0) {
      _targetZoom = _targetZoom.clamp(
        _defaultZoom * 0.5,
        _defaultZoom * 3.0,
      );
      camera.viewfinder.zoom = _targetZoom;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (nightAlpha > 0.01) {
      final size = canvasSize;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()
          ..color = dayNightTint.withValues(alpha: nightAlpha),
      );
    }
  }
}
