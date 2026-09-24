/// Layout data for the scenes *inside* the town buildings.
///
/// Each location gets its own room: size, colours, furniture (props) and the
/// doorway the player leaves through. The room is built by `InteriorWorld`.
class InteriorProp {
  final double x;
  final double y;
  final double w;
  final double h;
  final int color;
  final String? label;

  /// Hint shown on the interact button, e.g. "Use the bed".
  final String? interactLabel;

  /// Flavour text shown when interacting (examine-style).
  final String? message;

  /// When true, interacting opens the location's action menu instead of
  /// showing [message].
  final bool opensMenu;

  const InteriorProp({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.color,
    this.label,
    this.interactLabel,
    this.message,
    this.opensMenu = false,
  });
}

class InteriorLayout {
  final String id;
  final String title;

  /// Room size in world units.
  final double width;
  final double height;

  final int floorColor;
  final int wallColor;
  final int trimColor;

  /// Width of the doorway gap in the bottom wall.
  final double doorWidth;

  final List<InteriorProp> props;

  final String entryMessage;
  final String exitMessage;

  const InteriorLayout({
    required this.id,
    required this.title,
    required this.floorColor,
    required this.wallColor,
    required this.trimColor,
    required this.props,
    required this.entryMessage,
    required this.exitMessage,
    this.width = 1600,
    this.height = 1000,
    this.doorWidth = 240,
  });

  /// Where the player appears when they walk in (just inside the door).
  double get entryY => height - 96;
}

/// Returns the interior for [locationId], falling back to a plain room for
/// anything without a hand-made layout.
InteriorLayout buildInterior(String locationId) {
  switch (locationId) {
    case 'home':
      return const InteriorLayout(
        id: 'home',
        title: 'Home',
        floorColor: 0xFFE8D5B7,
        wallColor: 0xFFE6B8AF,
        trimColor: 0xFFC79A6B,
        entryMessage: 'You step inside. It smells like home.',
        exitMessage: 'You head back outside.',
        props: [
          InteriorProp(
            x: 120,
            y: 200,
            w: 320,
            h: 220,
            color: 0xFF8E7CC3,
            label: 'BED',
            interactLabel: 'Use the bed',
            message: 'Your bed. Open the Home menu to sleep or rest.',
          ),
          InteriorProp(
            x: 520,
            y: 180,
            w: 200,
            h: 260,
            color: 0xFFA68A64,
            label: 'CLOSET',
            interactLabel: 'Open the closet',
            message: 'Two school uniforms and a hoodie.',
          ),
          InteriorProp(
            x: 980,
            y: 190,
            w: 480,
            h: 150,
            color: 0xFFB7B7B7,
            label: 'KITCHEN',
            interactLabel: 'Open Home menu',
            opensMenu: true,
          ),
          InteriorProp(
            x: 300,
            y: 620,
            w: 340,
            h: 150,
            color: 0xFF6D9EEB,
            label: 'SOFA',
            interactLabel: 'Sit on the sofa',
            message: 'A couch facing an old TV set.',
          ),
          InteriorProp(
            x: 760,
            y: 650,
            w: 220,
            h: 100,
            color: 0xFF444444,
            label: 'TV',
            interactLabel: 'Turn on the TV',
            message: 'Static. The antenna needs fixing.',
          ),
          InteriorProp(
            x: 1120,
            y: 560,
            w: 300,
            h: 190,
            color: 0xFFC79A6B,
            label: 'TABLE',
            interactLabel: 'Look at the table',
            message: 'Dinner is served at seven.',
          ),
        ],
      );

    case 'school':
      return const InteriorLayout(
        id: 'school',
        title: 'School',
        floorColor: 0xFFEFE3C6,
        wallColor: 0xFF6FA8DC,
        trimColor: 0xFFB45F06,
        entryMessage: 'Classroom 2-B. Chalk dust and quiet.',
        exitMessage: 'You walk out into the corridor.',
        props: [
          InteriorProp(
            x: 500,
            y: 30,
            w: 600,
            h: 90,
            color: 0xFF2B2B2B,
            label: 'BLACKBOARD',
            interactLabel: 'Read the blackboard',
            message: 'Tomorrow: long quiz on algebra.',
          ),
          InteriorProp(
            x: 620,
            y: 200,
            w: 360,
            h: 130,
            color: 0xFFB45F06,
            label: 'TEACHER',
            interactLabel: 'Open School menu',
            opensMenu: true,
          ),
          InteriorProp(
            x: 200,
            y: 420,
            w: 180,
            h: 120,
            color: 0xFFC79A6B,
            label: 'DESK',
            interactLabel: 'Sit at the desk',
            message: 'Someone carved a heart into the wood.',
          ),
          InteriorProp(
            x: 520,
            y: 420,
            w: 180,
            h: 120,
            color: 0xFFC79A6B,
            label: 'DESK',
            interactLabel: 'Sit at the desk',
            message: 'Your seat. The window seat, if you are lucky.',
          ),
          InteriorProp(
            x: 840,
            y: 420,
            w: 180,
            h: 120,
            color: 0xFFC79A6B,
            label: 'DESK',
            interactLabel: 'Sit at the desk',
            message: 'Chewing gum under the lid. Gross.',
          ),
          InteriorProp(
            x: 1160,
            y: 420,
            w: 180,
            h: 120,
            color: 0xFFC79A6B,
            label: 'DESK',
            interactLabel: 'Sit at the desk',
            message: 'A desk by the wall.',
          ),
          InteriorProp(
            x: 60,
            y: 640,
            w: 140,
            h: 300,
            color: 0xFF93C47D,
            label: 'LOCKERS',
            interactLabel: 'Check the lockers',
            message: 'Rows of dented lockers.',
          ),
          InteriorProp(
            x: 1280,
            y: 600,
            w: 220,
            h: 340,
            color: 0xFF8E7CC3,
            label: 'LIBRARY',
            interactLabel: 'Browse the shelf',
            message: 'Textbooks older than you are.',
          ),
        ],
      );

    case 'plaza':
      return const InteriorLayout(
        id: 'plaza',
        title: 'Plaza',
        floorColor: 0xFFD9D9D9,
        wallColor: 0xFF93C47D,
        trimColor: 0xFF93C47D,
        entryMessage: 'The plaza is busy with students and vendors.',
        exitMessage: 'You leave the plaza.',
        props: [
          InteriorProp(
            x: 620,
            y: 340,
            w: 360,
            h: 300,
            color: 0xFF6FA8DC,
            label: 'FOUNTAIN',
            interactLabel: 'Look in the fountain',
            message: 'Coins glitter at the bottom.',
          ),
          InteriorProp(
            x: 120,
            y: 190,
            w: 340,
            h: 170,
            color: 0xFFE06666,
            label: 'VENDOR',
            interactLabel: 'Open Plaza menu',
            opensMenu: true,
          ),
          InteriorProp(
            x: 1090,
            y: 300,
            w: 300,
            h: 110,
            color: 0xFFC79A6B,
            label: 'BENCH',
            interactLabel: 'Search the bench',
            message: 'Maria said she sat near a bench like this.',
          ),
          InteriorProp(
            x: 1090,
            y: 560,
            w: 300,
            h: 110,
            color: 0xFFC79A6B,
            label: 'BENCH',
            interactLabel: 'Search the bench',
            message: 'Just crumbs and an old newspaper.',
          ),
          InteriorProp(
            x: 220,
            y: 640,
            w: 320,
            h: 170,
            color: 0xFFFFD966,
            label: 'STALL',
            interactLabel: 'Browse the stall',
            message: 'Fresh fruit, cheap and sweet.',
          ),
        ],
      );

    case 'church':
      return const InteriorLayout(
        id: 'church',
        title: 'Church',
        floorColor: 0xFFE0E0E0,
        wallColor: 0xFFD9D2E9,
        trimColor: 0xFF8E7CC3,
        entryMessage: 'Stained light falls across the pews.',
        exitMessage: 'You step back outside.',
        props: [
          InteriorProp(
            x: 600,
            y: 190,
            w: 400,
            h: 130,
            color: 0xFFF1F1F1,
            label: 'ALTAR',
            interactLabel: 'Open Church menu',
            opensMenu: true,
          ),
          InteriorProp(
            x: 120,
            y: 200,
            w: 180,
            h: 170,
            color: 0xFFFFD966,
            label: 'CANDLES',
            interactLabel: 'Light a candle',
            message: 'Warm candlelight. It feels calmer here.',
          ),
          InteriorProp(
            x: 420,
            y: 420,
            w: 760,
            h: 90,
            color: 0xFFB45F06,
            label: 'PEW',
            interactLabel: 'Sit in the pew',
            message: 'You bow your head for a moment.',
          ),
          InteriorProp(
            x: 420,
            y: 560,
            w: 760,
            h: 90,
            color: 0xFFB45F06,
            label: 'PEW',
            interactLabel: 'Sit in the pew',
            message: 'The wood creaks under you.',
          ),
          InteriorProp(
            x: 420,
            y: 700,
            w: 760,
            h: 90,
            color: 0xFFB45F06,
            label: 'PEW',
            interactLabel: 'Sit in the pew',
            message: 'Near the back, close to the door.',
          ),
        ],
      );

    case 'park':
      return const InteriorLayout(
        id: 'park',
        title: 'Park',
        floorColor: 0xFF9CCC65,
        wallColor: 0xFF38761D,
        trimColor: 0xFF6AA84F,
        entryMessage: 'Birdsong, cut grass, a faint smell of sweat.',
        exitMessage: 'You walk back to the street.',
        props: [
          InteriorProp(
            x: 140,
            y: 200,
            w: 280,
            h: 210,
            color: 0xFF666666,
            label: 'GYM',
            interactLabel: 'Open Park menu',
            opensMenu: true,
          ),
          InteriorProp(
            x: 900,
            y: 590,
            w: 480,
            h: 250,
            color: 0xFF4A86E8,
            label: 'POND',
            interactLabel: 'Watch the pond',
            message: 'Ducks paddle past without a care.',
          ),
          InteriorProp(
            x: 620,
            y: 180,
            w: 220,
            h: 220,
            color: 0xFF2E7D32,
            label: 'TREE',
            interactLabel: 'Rest under the tree',
            message: 'Shade, and a breeze through the leaves.',
          ),
          InteriorProp(
            x: 1220,
            y: 200,
            w: 200,
            h: 200,
            color: 0xFF2E7D32,
            label: 'TREE',
            interactLabel: 'Look at the tree',
            message: 'Some initials carved into the bark.',
          ),
          InteriorProp(
            x: 540,
            y: 700,
            w: 300,
            h: 110,
            color: 0xFFC79A6B,
            label: 'BENCH',
            interactLabel: 'Sit on the bench',
            message: 'Ben sometimes trains right here.',
          ),
        ],
      );

    case 'workplace':
      return const InteriorLayout(
        id: 'workplace',
        title: 'Café',
        floorColor: 0xFFE8D5B7,
        wallColor: 0xFFFFD966,
        trimColor: 0xFFB45F06,
        entryMessage: 'The café smells of coffee and warm bread.',
        exitMessage: 'You push the café door open and leave.',
        props: [
          InteriorProp(
            x: 680,
            y: 40,
            w: 240,
            h: 90,
            color: 0xFF999999,
            label: 'ESPRESSO',
            interactLabel: 'Check the machine',
            message: 'Steam hisses from the group head.',
          ),
          InteriorProp(
            x: 500,
            y: 190,
            w: 620,
            h: 160,
            color: 0xFFB45F06,
            label: 'COUNTER',
            interactLabel: 'Open Café menu',
            opensMenu: true,
          ),
          InteriorProp(
            x: 240,
            y: 500,
            w: 210,
            h: 170,
            color: 0xFFC79A6B,
            label: 'TABLE',
            interactLabel: 'Wipe the table',
            message: 'Crumbs, and a tip left behind.',
          ),
          InteriorProp(
            x: 700,
            y: 500,
            w: 210,
            h: 170,
            color: 0xFFC79A6B,
            label: 'TABLE',
            interactLabel: 'Wipe the table',
            message: 'A couple of regulars sit here.',
          ),
          InteriorProp(
            x: 1160,
            y: 500,
            w: 210,
            h: 170,
            color: 0xFFC79A6B,
            label: 'TABLE',
            interactLabel: 'Wipe the table',
            message: 'The window table. Best light in the shop.',
          ),
        ],
      );
  }

  return InteriorLayout(
    id: locationId,
    title: locationId,
    floorColor: 0xFFE8D5B7,
    wallColor: 0xFFAAAAAA,
    trimColor: 0xFF888888,
    entryMessage: 'You step inside.',
    exitMessage: 'You step back out.',
    props: const [
      InteriorProp(
        x: 200,
        y: 220,
        w: 400,
        h: 200,
        color: 0xFFB7B7B7,
        label: 'ROOM',
        interactLabel: 'Look around',
        message: 'An empty room.',
      ),
    ],
  );
}
