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

  /// When true, interacting makes the player sit and rest (+energy).
  /// Benches/pews/sofas/chairs are auto-detected even without this flag.
  final bool? sit;

  /// When true, interacting puts the player to sleep until next morning
  /// (full energy, clock jumps to 07:00). Used by the home bed.
  final bool sleep;

  /// Optional sprite art for the prop (asset file under assets/images/,
  /// e.g. 'home_bed.png'). Loaded in the background by [InteriorWorld];
  /// the flat color rect is the fallback until it arrives. When art is
  /// set, it replaces the rect + text label (the art speaks for itself).
  final String? art;

  /// Quarter-turns counter-clockwise applied to [art] when rendering
  /// (the collision rect is expected to already match the rotated
  /// footprint). 0 = upright.
  final int artTurns;

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
    this.sit,
    this.sleep = false,
    this.art,
    this.artTurns = 0,
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
        // Realistic setup: bedroom row on top (bed by the left wall,
        // closet beside it, kitchen anchored top-right), living row below
        // (sofa west, TV scene center facing it, dining table east).
        // Rects match each art's aspect so contain-fit renders full-bleed.
        // The middle band stays open as a walkway; the door approach is
        // clear so spawning in still targets the exit.
        props: [
          InteriorProp(
            x: 70,
            y: 160,
            w: 240,
            h: 360,
            color: 0xFF8E7CC3,
            label: 'BED',
            interactLabel: 'Sleep in bed',
            sleep: true,
            art: 'home_bed.png',
          ),
          InteriorProp(
            x: 340,
            y: 160,
            w: 190,
            h: 235,
            color: 0xFFA68A64,
            label: 'CLOSET',
            interactLabel: 'Open the closet',
            message: 'Two school uniforms and a hoodie.',
            art: 'home_closet.png',
          ),
          InteriorProp(
            x: 1116,
            y: 170,
            w: 460,
            h: 400,
            color: 0xFFB7B7B7,
            label: 'KITCHEN',
            interactLabel: 'Open Home menu',
            opensMenu: true,
            art: 'home_kitchen.png',
          ),
          InteriorProp(
            x: 40,
            y: 690,
            w: 116,
            h: 265,
            color: 0xFF6D9EEB,
            label: 'SOFA',
            interactLabel: 'Sit on the sofa',
            message: 'A couch facing an old TV set.',
            art: 'home_sofa.png',
            // Landscape art turned portrait like the table: faces the TV
            // across the living zone, flush to the far left wall.
            artTurns: 1,
          ),
          InteriorProp(
            x: 570,
            y: 460,
            w: 410,
            h: 350,
            color: 0xFF444444,
            label: 'TV',
            interactLabel: 'Turn on the TV',
            message: 'Static. The antenna needs fixing.',
            art: 'home_tv.png',
          ),
          InteriorProp(
            x: 1400,
            y: 640,
            w: 160,
            h: 265,
            color: 0xFFC79A6B,
            label: 'TABLE',
            interactLabel: 'Look at the table',
            message: 'Dinner is served at seven.',
            art: 'home_table.png',
            // Landscape art turned portrait: rect matches the rotated
            // footprint (dining nook under the kitchen, clear of the TV
            // and the door approach).
            artTurns: 1,
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
    case 'bank':
      return const InteriorLayout(
        id: 'bank',
        title: 'Bank',
        floorColor: 0xFFE8E4DA,
        wallColor: 0xFFB7C9E2,
        trimColor: 0xFF5B7FA6,
        entryMessage: 'Cool air and polished marble. A queue rope snakes ahead.',
        exitMessage: 'You step back outside.',
        props: [
          InteriorProp(
            x: 600,
            y: 150,
            w: 400,
            h: 170,
            color: 0xFF5B7FA6,
            label: 'TELLER',
            interactLabel: 'Open Bank menu',
            opensMenu: true,
          ),
          InteriorProp(
            x: 200,
            y: 180,
            w: 220,
            h: 200,
            color: 0xFF8E8E8E,
            label: 'VAULT',
            interactLabel: 'Look at the vault',
            message: 'A massive steel door. Best not to touch it.',
          ),
          InteriorProp(
            x: 1150,
            y: 220,
            w: 220,
            h: 260,
            color: 0xFF2E7D5B,
            label: 'ATM',
            interactLabel: 'Use the indoor ATM',
            message: 'Withdraw cash from the Bank menu instead.',
          ),
          InteriorProp(
            x: 400,
            y: 560,
            w: 800,
            h: 90,
            color: 0xFFB45F06,
            label: 'QUEUE',
            interactLabel: 'Wait in line',
            message: 'The line barely moves. Classic.',
          ),
        ],
      );

    case 'mall':
      return const InteriorLayout(
        id: 'mall',
        title: 'Mall',
        floorColor: 0xFFF1E8D8,
        wallColor: 0xFFD5A6BD,
        trimColor: 0xFF8E7CC3,
        entryMessage: 'Music, chatter, and the smell of fried snacks.',
        exitMessage: 'You head back to the street.',
        props: [
          InteriorProp(
            x: 620,
            y: 200,
            w: 360,
            h: 220,
            color: 0xFFE69138,
            label: 'FOOD CRT',
            interactLabel: 'Open Mall menu',
            opensMenu: true,
          ),
          InteriorProp(
            x: 140,
            y: 200,
            w: 300,
            h: 220,
            color: 0xFF6FA8DC,
            label: 'GADGETS',
            interactLabel: 'Browse gadgets',
            message: 'Phones and consoles behind glass. Out of budget.',
          ),
          InteriorProp(
            x: 1140,
            y: 220,
            w: 300,
            h: 220,
            color: 0xFFE06666,
            label: 'FASHION',
            interactLabel: 'Browse clothes',
            message: 'Uniforms are not in fashion this season.',
          ),
          InteriorProp(
            x: 420,
            y: 620,
            w: 760,
            h: 110,
            color: 0xFFC79A6B,
            label: 'BENCH',
            interactLabel: 'Sit on the bench',
            message: 'Shoppers stream past in both directions.',
          ),
        ],
      );
    case 'repair':
      return const InteriorLayout(
        id: 'repair',
        title: 'Repair Shop',
        floorColor: 0xFFD9D9D9,
        wallColor: 0xFF8E9E9E,
        trimColor: 0xFF5B5B5B,
        entryMessage: 'Oil, rubber, and the clang of tools.',
        exitMessage: 'You step back outside.',
        props: [
          InteriorProp(
            x: 600,
            y: 200,
            w: 400,
            h: 220,
            color: 0xFFB45F06,
            label: 'WORKBENCH',
            interactLabel: 'Open Repair menu',
            opensMenu: true,
          ),
          InteriorProp(
            x: 180,
            y: 240,
            w: 240,
            h: 200,
            color: 0xFF444444,
            label: 'BIKE',
            interactLabel: 'Look at the bike',
            message: 'A bike waiting on a repair stand.',
          ),
          InteriorProp(
            x: 1150,
            y: 260,
            w: 260,
            h: 180,
            color: 0xFF8E8E8E,
            label: 'SPARES',
            interactLabel: 'Browse spare parts',
            message: 'Shelves of chains, tires and bells.',
          ),
        ],
      );

    case 'bookstore':
      return const InteriorLayout(
        id: 'bookstore',
        title: 'Book Store',
        floorColor: 0xFFEFE3C6,
        wallColor: 0xFFB45F06,
        trimColor: 0xFF7A3E00,
        entryMessage: 'Paper, ink, and quiet.',
        exitMessage: 'You step back outside.',
        props: [
          InteriorProp(
            x: 620,
            y: 200,
            w: 360,
            h: 200,
            color: 0xFF2E7D5B,
            label: 'COUNTER',
            interactLabel: 'Open Book Store menu',
            opensMenu: true,
          ),
          InteriorProp(
            x: 150,
            y: 220,
            w: 220,
            h: 340,
            color: 0xFF8E7CC3,
            label: 'MANGA',
            interactLabel: 'Browse manga',
            message: 'Rows of well-thumbed volumes.',
          ),
          InteriorProp(
            x: 1220,
            y: 220,
            w: 220,
            h: 340,
            color: 0xFF4A86E8,
            label: 'STUDY',
            interactLabel: 'Browse study guides',
            message: 'Algebra guides, slightly cheaper than school.',
          ),
        ],
      );

    case 'supermarket':
      return const InteriorLayout(
        id: 'supermarket',
        title: 'Super Market',
        floorColor: 0xFFF5F5F5,
        wallColor: 0xFF6AA84F,
        trimColor: 0xFF38761D,
        entryMessage: 'Bright aisles and freezer hum.',
        exitMessage: 'You step back outside.',
        props: [
          InteriorProp(
            x: 620,
            y: 200,
            w: 360,
            h: 200,
            color: 0xFFE69138,
            label: 'CHECKOUT',
            interactLabel: 'Open Super Market menu',
            opensMenu: true,
          ),
          InteriorProp(
            x: 150,
            y: 220,
            w: 300,
            h: 160,
            color: 0xFFE06666,
            label: 'PRODUCE',
            interactLabel: 'Look at the produce',
            message: 'Fresh fruit, cheap and sweet.',
          ),
          InteriorProp(
            x: 1150,
            y: 220,
            w: 300,
            h: 160,
            color: 0xFF6FA8DC,
            label: 'FREEZER',
            interactLabel: 'Look in the freezer',
            message: 'Ice cream you cannot afford yet.',
          ),
        ],
      );

    case 'pizzahut':
      return const InteriorLayout(
        id: 'pizzahut',
        title: 'Pizza Hut',
        floorColor: 0xFFE8D5B7,
        wallColor: 0xFFE06666,
        trimColor: 0xFF922B21,
        entryMessage: 'Cheese, tomato, and a roaring oven.',
        exitMessage: 'You step back outside.',
        props: [
          InteriorProp(
            x: 600,
            y: 200,
            w: 400,
            h: 200,
            color: 0xFFB45F06,
            label: 'COUNTER',
            interactLabel: 'Open Pizza Hut menu',
            opensMenu: true,
          ),
          InteriorProp(
            x: 200,
            y: 500,
            w: 260,
            h: 170,
            color: 0xFFC79A6B,
            label: 'BOOTH',
            interactLabel: 'Sit in the booth',
            message: 'Red vinyl seats, slightly sticky.',
          ),
          InteriorProp(
            x: 1150,
            y: 500,
            w: 260,
            h: 170,
            color: 0xFFC79A6B,
            label: 'BOOTH',
            interactLabel: 'Sit in the booth',
            message: 'A view of the oven from here.',
          ),
        ],
      );

    case 'hospital':
      return const InteriorLayout(
        id: 'hospital',
        title: 'Hospital',
        floorColor: 0xFFF5F5F5,
        wallColor: 0xFFF1F1F1,
        trimColor: 0xFFE06666,
        entryMessage: 'Antiseptic quiet. A reception desk glows ahead.',
        exitMessage: 'You step back outside.',
        props: [
          InteriorProp(
            x: 620,
            y: 200,
            w: 360,
            h: 200,
            color: 0xFF6FA8DC,
            label: 'RECEPTION',
            interactLabel: 'Open Hospital menu',
            opensMenu: true,
          ),
          InteriorProp(
            x: 200,
            y: 500,
            w: 300,
            h: 150,
            color: 0xFFB7B7B7,
            label: 'BEDS',
            interactLabel: 'Look at the ward',
            message: 'Neat rows of empty beds.',
          ),
          InteriorProp(
            x: 1100,
            y: 500,
            w: 300,
            h: 150,
            color: 0xFFA8DADC,
            label: 'PHARMACY',
            interactLabel: 'Look at the pharmacy',
            message: 'Vitamins behind glass.',
          ),
        ],
      );

    case 'restaurant':
      return const InteriorLayout(
        id: 'restaurant',
        title: 'Restaurant',
        floorColor: 0xFFE8D5B7,
        wallColor: 0xFFE69138,
        trimColor: 0xFFB45F06,
        entryMessage: 'Sizzling garlic and warm lights.',
        exitMessage: 'You step back outside.',
        props: [
          InteriorProp(
            x: 600,
            y: 200,
            w: 400,
            h: 180,
            color: 0xFFB45F06,
            label: 'COUNTER',
            interactLabel: 'Open Restaurant menu',
            opensMenu: true,
          ),
          InteriorProp(
            x: 240,
            y: 500,
            w: 210,
            h: 170,
            color: 0xFFC79A6B,
            label: 'TABLE',
            interactLabel: 'Look at the table',
            message: 'Set for two, candles unlit.',
          ),
          InteriorProp(
            x: 1150,
            y: 500,
            w: 210,
            h: 170,
            color: 0xFFC79A6B,
            label: 'TABLE',
            interactLabel: 'Look at the table',
            message: 'A family finishing dessert.',
          ),
        ],
      );

    case 'laundry':
      return const InteriorLayout(
        id: 'laundry',
        title: 'Laundry Shop',
        floorColor: 0xFFE8F4FD,
        wallColor: 0xFF6FA8DC,
        trimColor: 0xFF2E5F8A,
        entryMessage: 'Warm steam and detergent.',
        exitMessage: 'You step back outside.',
        props: [
          InteriorProp(
            x: 600,
            y: 200,
            w: 400,
            h: 200,
            color: 0xFF8E7CC3,
            label: 'COUNTER',
            interactLabel: 'Open Laundry menu',
            opensMenu: true,
          ),
          InteriorProp(
            x: 200,
            y: 480,
            w: 500,
            h: 160,
            color: 0xFFB7B7B7,
            label: 'WASHERS',
            interactLabel: 'Watch the washers',
            message: 'Hypnotic spinning drums.',
          ),
          InteriorProp(
            x: 900,
            y: 480,
            w: 500,
            h: 160,
            color: 0xFF999999,
            label: 'DRYERS',
            interactLabel: 'Feel the warm air',
            message: 'Warm air and lint.',
          ),
        ],
      );

    case 'police':
      return const InteriorLayout(
        id: 'police',
        title: 'Police Station',
        floorColor: 0xFFE0E6ED,
        wallColor: 0xFF4A86E8,
        trimColor: 0xFF1D3557,
        entryMessage: 'A calm front desk under fluorescent lights.',
        exitMessage: 'You step back outside.',
        props: [
          InteriorProp(
            x: 600,
            y: 200,
            w: 400,
            h: 200,
            color: 0xFF1D3557,
            label: 'DESK',
            interactLabel: 'Open Police menu',
            opensMenu: true,
          ),
          InteriorProp(
            x: 200,
            y: 500,
            w: 300,
            h: 170,
            color: 0xFF8E8E8E,
            label: 'NOTICE',
            interactLabel: 'Read the notice board',
            message: 'Lost pets, found bikes, event permits.',
          ),
          InteriorProp(
            x: 1100,
            y: 500,
            w: 300,
            h: 170,
            color: 0xFFB7B7B7,
            label: 'CELLS',
            interactLabel: 'Glance at the cells',
            message: 'Empty. Stay out of trouble.',
          ),
        ],
      );

    case 'computer':
      return const InteriorLayout(
        id: 'computer',
        title: 'Computer Center',
        floorColor: 0xFFE8E4F0,
        wallColor: 0xFF8E7CC3,
        trimColor: 0xFF5B4B8A,
        entryMessage: 'Rows of monitors hum softly.',
        exitMessage: 'You step back outside.',
        props: [
          InteriorProp(
            x: 600,
            y: 200,
            w: 400,
            h: 200,
            color: 0xFF444444,
            label: 'COUNTER',
            interactLabel: 'Open Computer menu',
            opensMenu: true,
          ),
          InteriorProp(
            x: 180,
            y: 500,
            w: 480,
            h: 150,
            color: 0xFF2B2B2B,
            label: 'PCS',
            interactLabel: 'Use a PC',
            message: 'Someone left a game paused.',
          ),
          InteriorProp(
            x: 940,
            y: 500,
            w: 480,
            h: 150,
            color: 0xFF2B2B2B,
            label: 'PCS',
            interactLabel: 'Use a PC',
            message: 'Homework tabs and chat windows.',
          ),
        ],
      );

    case 'amusement':
      return const InteriorLayout(
        id: 'amusement',
        title: 'Amusement Park',
        floorColor: 0xFFFFF3D6,
        wallColor: 0xFFFFD966,
        trimColor: 0xFFE69138,
        entryMessage: 'Music, spinning lights, popcorn.',
        exitMessage: 'You step back outside.',
        props: [
          InteriorProp(
            x: 600,
            y: 200,
            w: 400,
            h: 220,
            color: 0xFFE06666,
            label: 'TICKETS',
            interactLabel: 'Open Amusement menu',
            opensMenu: true,
          ),
          InteriorProp(
            x: 150,
            y: 520,
            w: 350,
            h: 170,
            color: 0xFF6FA8DC,
            label: 'RIDES',
            interactLabel: 'Watch the rides',
            message: 'The coaster rattles overhead.',
          ),
          InteriorProp(
            x: 1100,
            y: 520,
            w: 350,
            h: 170,
            color: 0xFF93C47D,
            label: 'GAMES',
            interactLabel: 'Play a midway game',
            message: 'Nobody ever wins the giant plush.',
          ),
        ],
      );

    case 'beach':
      return const InteriorLayout(
        id: 'beach',
        title: 'Beach',
        floorColor: 0xFFFFF3D6,
        wallColor: 0xFF4DD0E1,
        trimColor: 0xFF2E9BB5,
        entryMessage: 'Salt air, gulls, warm sand.',
        exitMessage: 'You step back outside.',
        props: [
          InteriorProp(
            x: 620,
            y: 240,
            w: 360,
            h: 220,
            color: 0xFF4A86E8,
            label: 'LIFEGUARD',
            interactLabel: 'Open Beach menu',
            opensMenu: true,
          ),
          InteriorProp(
            x: 200,
            y: 560,
            w: 320,
            h: 150,
            color: 0xFFE69138,
            label: 'UMBRELLA',
            interactLabel: 'Rest in the shade',
            message: 'Striped shade and a cool breeze.',
          ),
          InteriorProp(
            x: 1080,
            y: 560,
            w: 320,
            h: 150,
            color: 0xFFA8DADC,
            label: 'SHORE',
            interactLabel: 'Watch the waves',
            message: 'Waves fold over each other endlessly.',
          ),
        ],
      );

    case 'fishing':
      return const InteriorLayout(
        id: 'fishing',
        title: 'Fishing Area',
        floorColor: 0xFFD9E8D0,
        wallColor: 0xFF6D9EEB,
        trimColor: 0xFF3E6FB0,
        entryMessage: 'Quiet water and bobbing floats.',
        exitMessage: 'You step back outside.',
        props: [
          InteriorProp(
            x: 600,
            y: 220,
            w: 400,
            h: 200,
            color: 0xFF8C6239,
            label: 'PIER',
            interactLabel: 'Open Fishing menu',
            opensMenu: true,
          ),
          InteriorProp(
            x: 200,
            y: 560,
            w: 300,
            h: 150,
            color: 0xFF5B5B5B,
            label: 'TACKLE',
            interactLabel: 'Check the tackle box',
            message: 'Hooks, sinkers, and tangled line.',
          ),
          InteriorProp(
            x: 1100,
            y: 560,
            w: 300,
            h: 150,
            color: 0xFF4A86E8,
            label: 'WATER',
            interactLabel: 'Watch the water',
            message: 'Something large just surfaced.',
          ),
        ],
      );

    case 'hotel':
      return const InteriorLayout(
        id: 'hotel',
        title: 'Hotel',
        floorColor: 0xFFEFE3E8,
        wallColor: 0xFFB39DDB,
        trimColor: 0xFF7E57C2,
        entryMessage: 'A grand lobby with a chandelier.',
        exitMessage: 'You step back outside.',
        props: [
          InteriorProp(
            x: 600,
            y: 200,
            w: 400,
            h: 200,
            color: 0xFF7E57C2,
            label: 'FRONT DESK',
            interactLabel: 'Open Hotel menu',
            opensMenu: true,
          ),
          InteriorProp(
            x: 220,
            y: 520,
            w: 280,
            h: 170,
            color: 0xFFC79A6B,
            label: 'LOUNGE',
            interactLabel: 'Sit in the lounge',
            message: 'Deep armchairs and quiet jazz.',
          ),
          InteriorProp(
            x: 1100,
            y: 520,
            w: 280,
            h: 170,
            color: 0xFFFFD966,
            label: 'ELEVATOR',
            interactLabel: 'Ride the elevator',
            message: 'Floors 1 to 12. You stay on 1.',
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
