import 'package:flutter/material.dart';

/// Which hand-painted backdrop a venue scene uses.
enum VenueScene {
  classroom,
  plaza,
  church,
  park,
  cafe,
  bank,
  mall,
  garage,
  bookstore,
  supermarket,
  pizzeria,
  hospital,
  restaurant,
  laundry,
  police,
  computer,
  amusement,
  beach,
  fishing,
  hotel,
}

/// Effects that need a little more than the declarative fields on
/// [VenueAction] can express (quest bookkeeping, sleeping, the café shift…).
enum VenueSpecial {
  none,

  /// Updates attendance through [GameState.attendClass].
  attendance,

  /// Runs the gym activity and checks the gym-initiation objective.
  gymSession,

  /// Runs a paid café shift (work activity + salary).
  workShift,

  /// Adds the bank's pocket-money withdrawal.
  allowance,

  /// Settles the overdue rent / landlord debt.
  debt,

  /// Adds the supermarket pantry bundle.
  pantryRestock,

  /// Searches the plaza benches for Maria's wallet.
  walletSearch,

  /// Files a police report (charm + flag).
  report,

  /// Sleeps in a hotel room until the next morning.
  bookRoom,
}

/// One thing the player can do inside a venue scene.
///
/// The fields are declarative on purpose: [applyVenueAction] can be tested
/// without any widgets, and every scene uses the same currency/energy rules.
class VenueAction {
  const VenueAction({
    required this.id,
    required this.label,
    required this.blurb,
    required this.icon,
    this.detail,
    this.moneyCost = 0,
    this.moneyGain = 0,
    this.energyDelta = 0,
    this.minutes = 0,
    this.happiness = 0,
    this.charm = 0,
    this.intelligence = 0,
    this.strength = 0,
    this.education = 0,
    this.health = 0,
    this.itemId,
    this.itemCount = 0,
    this.setFlag,
    this.questId,
    this.objectiveId,
    this.relationshipNpc,
    this.relationshipDelta = 0,
    this.special = VenueSpecial.none,
  });

  final String id;
  final String label;

  /// What the notice board says after the action succeeds.
  final String blurb;

  /// Short line under the label explaining the moment.
  final String? detail;

  final IconData icon;
  final int moneyCost;
  final int moneyGain;
  final int energyDelta;
  final int minutes;
  final int happiness;
  final int charm;
  final int intelligence;
  final int strength;
  final int education;
  final int health;
  final String? itemId;
  final int itemCount;
  final String? setFlag;
  final String? questId;
  final String? objectiveId;
  final String? relationshipNpc;
  final int relationshipDelta;
  final VenueSpecial special;

  /// Compact chips shown on the action tile, e.g. `₱70 · 30 min · +10 energy`.
  List<String> get costChips {
    final chips = <String>[];
    if (moneyCost > 0) chips.add('₱$moneyCost');
    if (moneyGain > 0) chips.add('+₱$moneyGain');
    if (minutes > 0) chips.add('$minutes min');
    if (energyDelta < 0) chips.add('${energyDelta.abs()} energy');
    if (energyDelta > 0) chips.add('+$energyDelta energy');
    if (happiness != 0) chips.add('${happiness > 0 ? '+' : ''}$happiness mood');
    if (charm != 0) chips.add('${charm > 0 ? '+' : ''}$charm charm');
    if (intelligence != 0) {
      chips.add('${intelligence > 0 ? '+' : ''}$intelligence int');
    }
    if (strength != 0) {
      chips.add('${strength > 0 ? '+' : ''}$strength strength');
    }
    if (education != 0) {
      chips.add('${education > 0 ? '+' : ''}$education edu');
    }
    if (health != 0) chips.add('${health > 0 ? '+' : ''}$health health');
    if (itemId != null) chips.add('+$itemCount ${_prettyItem(itemId!)}');
    return chips;
  }

  static String _prettyItem(String id) {
    if (id.isEmpty) return 'item';
    return id
        .split('_')
        .map((part) => part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

/// A building's full-screen "step inside" scenario: art, copy and actions.
class Venue {
  const Venue({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.tagline,
    required this.intro,
    required this.icon,
    required this.scene,
    required this.background,
    required this.panel,
    required this.accent,
    required this.glow,
    required this.actions,
    this.ink = const Color(0xFFF7F2E7),
    this.muted = const Color(0xFFC8BFAF),
    this.accentInk = const Color(0xFF20160F),
  });

  final String id;
  final String title;

  /// Small line under the title, e.g. "Classroom 2-B".
  final String subtitle;
  final String tagline;
  final String intro;
  final IconData icon;
  final VenueScene scene;

  /// Scaffold colour behind everything.
  final Color background;

  /// Bottom/right control panel colour.
  final Color panel;
  final Color accent;
  final Color glow;
  final Color ink;
  final Color muted;
  final Color accentInk;
  final List<VenueAction> actions;
}

/// Every enterable building except Home (which already has its own living
/// room, kitchen, TV and wardrobe scenes).
class VenueCatalog {
  const VenueCatalog._();

  static const school = Venue(
    id: 'school',
    title: 'School',
    subtitle: 'Classroom 2-B',
    tagline: 'Chalk dust, sunlight, and a clock that never moves.',
    intro:
        'The room smells of chalk and rain-washed air. Thirty desks face the '
        'board, and yours is the one by the window.',
    icon: Icons.school_rounded,
    scene: VenueScene.classroom,
    background: Color(0xFF0D1820),
    panel: Color(0xFF12212C),
    accent: Color(0xFFFFC857),
    glow: Color(0xFF7FD1FF),
    actions: [
      VenueAction(
        id: 'attend_class',
        label: 'Sit through class',
        detail: 'Notes, bell, and a quiz you are almost ready for.',
        blurb: 'You fill two pages of notes before the bell. Education +2, Intelligence +1.',
        icon: Icons.co_present_rounded,
        minutes: 90,
        energyDelta: -8,
        education: 2,
        intelligence: 1,
        special: VenueSpecial.attendance,
      ),
      VenueAction(
        id: 'study_window',
        label: 'Study by the window',
        detail: 'Warm glass, quiet page turns.',
        blurb: 'The window light makes the algebra almost pleasant. Intelligence +1, Education +1.',
        icon: Icons.menu_book_rounded,
        minutes: 60,
        energyDelta: -10,
        intelligence: 1,
        education: 1,
        questId: 'study_group',
        objectiveId: 'go_library',
      ),
      VenueAction(
        id: 'ask_teacher',
        label: 'Ask the teacher for help',
        detail: 'She draws the proof out one line at a time.',
        blurb: 'A five-minute question becomes twenty. Something finally clicks.',
        icon: Icons.help_center_rounded,
        minutes: 25,
        energyDelta: -2,
        intelligence: 1,
        questId: 'study_group',
        objectiveId: 'join_group',
      ),
      VenueAction(
        id: 'lend_pen',
        label: 'Lend a classmate a pen',
        detail: 'Small kindness, loud gratitude.',
        blurb: 'You hand over your spare pen. A friendship is quietly renewed.',
        icon: Icons.edit_rounded,
        minutes: 5,
        happiness: 1,
        charm: 1,
      ),
    ],
  );

  static const plaza = Venue(
    id: 'plaza',
    title: 'Plaza',
    subtitle: 'Fountain square',
    tagline: 'The whole town passes through here.',
    intro:
        'Coins glint under the fountain water. Vendors call over one another, '
        'and the benches are still warm from the afternoon sun.',
    icon: Icons.location_city_rounded,
    scene: VenueScene.plaza,
    background: Color(0xFF121018),
    panel: Color(0xFF1C1824),
    accent: Color(0xFFFFB86B),
    glow: Color(0xFF9FE3D0),
    actions: [
      VenueAction(
        id: 'make_wish',
        label: 'Toss a coin in the fountain',
        detail: 'One wish, no receipt.',
        blurb: 'The coin turns over twice and vanishes. You feel a little lighter.',
        icon: Icons.water_drop_rounded,
        moneyCost: 5,
        minutes: 5,
        happiness: 2,
      ),
      VenueAction(
        id: 'find_wallet',
        label: 'Search the benches for Maria\'s wallet',
        detail: 'If she really did sit here.',
        blurb: 'You search under the benches. Crumbs, a bus ticket, and a coin.',
        icon: Icons.search_rounded,
        minutes: 20,
        special: VenueSpecial.walletSearch,
      ),
      VenueAction(
        id: 'vendor_stories',
        label: 'Trade stories with the vendors',
        detail: 'Someone always knows someone.',
        blurb: 'You hear three versions of the same rumour. Charm +2.',
        icon: Icons.forum_rounded,
        minutes: 45,
        energyDelta: -5,
        charm: 2,
        happiness: 1,
      ),
      VenueAction(
        id: 'buy_bread',
        label: 'Buy warm bread from the stall',
        detail: 'Still steaming through the paper.',
        blurb: 'The baker wraps it in paper. It is warm all the way home.',
        icon: Icons.bakery_dining_rounded,
        moneyCost: 25,
        minutes: 5,
        itemId: 'bread',
        itemCount: 1,
      ),
    ],
  );

  static const church = Venue(
    id: 'church',
    title: 'Church',
    subtitle: 'St. Agnes',
    tagline: 'Stained light and somewhere to sit.',
    intro:
        'Coloured light pools across the pews. Near the altar a candle '
        'sputters, and the quiet has a weight to it.',
    icon: Icons.church_rounded,
    scene: VenueScene.church,
    background: Color(0xFF0C0B16),
    panel: Color(0xFF171527),
    accent: Color(0xFFFFD98E),
    glow: Color(0xFFB69CFF),
    actions: [
      VenueAction(
        id: 'light_candle',
        label: 'Light a candle',
        detail: 'A small flame for a large hope.',
        blurb: 'The wick catches. You stand there until the flame stops shaking.',
        icon: Icons.local_fire_department_rounded,
        moneyCost: 10,
        minutes: 10,
        happiness: 2,
        setFlag: 'lit_church_candle',
      ),
      VenueAction(
        id: 'attend_service',
        label: 'Attend the service',
        detail: 'Hymns you half-remember.',
        blurb: 'You follow the familiar words. Charm +1, and the day feels slower.',
        icon: Icons.self_improvement_rounded,
        minutes: 90,
        energyDelta: -5,
        charm: 1,
        happiness: 2,
      ),
      VenueAction(
        id: 'volunteer',
        label: 'Help set up for the service',
        detail: 'Chairs, candles, and Maria\'s clipboard.',
        blurb: 'You carry chairs with Maria. She notices you stayed to help.',
        icon: Icons.volunteer_activism_rounded,
        minutes: 90,
        energyDelta: -8,
        charm: 1,
        relationshipNpc: 'maria',
        relationshipDelta: 2,
        setFlag: 'helped_church',
      ),
      VenueAction(
        id: 'quiet_pew',
        label: 'Sit quietly in a back pew',
        detail: 'No phone, no clock.',
        blurb: 'The building breathes around you. Energy +4, mood +1.',
        icon: Icons.airline_seat_recline_normal_rounded,
        minutes: 20,
        energyDelta: 4,
        happiness: 1,
      ),
    ],
  );

  static const park = Venue(
    id: 'park',
    title: 'Park',
    subtitle: 'Riverside green',
    tagline: 'Cut grass, birdsong, and the smell of the gym.',
    intro:
        'The path curves between the trees. Somewhere past the hedge, weights '
        'clank, and ducks argue over the pond.',
    icon: Icons.park_rounded,
    scene: VenueScene.park,
    background: Color(0xFF0B140F),
    panel: Color(0xFF132019),
    accent: Color(0xFF9CD67C),
    glow: Color(0xFFFFD27A),
    actions: [
      VenueAction(
        id: 'gym_session',
        label: 'Train at the outdoor gym',
        detail: 'Ben is already on the pull-up bar.',
        blurb: 'You finish your sets with shaking arms. Strength +2.',
        icon: Icons.fitness_center_rounded,
        minutes: 60,
        energyDelta: -15,
        strength: 2,
        special: VenueSpecial.gymSession,
      ),
      VenueAction(
        id: 'jog',
        label: 'Jog the riverside loop',
        detail: 'Two laps, then one more.',
        blurb: 'Your shoes find a rhythm. Strength +2, Health +1.',
        icon: Icons.directions_run_rounded,
        minutes: 60,
        energyDelta: -15,
        strength: 2,
        health: 1,
      ),
      VenueAction(
        id: 'meditate',
        label: 'Meditate under the old tree',
        detail: 'Listen to the leaves instead of your thoughts.',
        blurb: 'The ground is warm. Your shoulders drop an inch. Energy +20.',
        icon: Icons.spa_rounded,
        minutes: 30,
        energyDelta: 20,
        health: 1,
        happiness: 1,
        questId: 'weekend_hike',
        objectiveId: 'visit_beach_or_park',
      ),
      VenueAction(
        id: 'feed_ducks',
        label: 'Feed the ducks',
        detail: 'They have no manners and no shame.',
        blurb: 'A bold duck takes bread from your hand. You laugh out loud.',
        icon: Icons.emoji_nature_rounded,
        moneyCost: 5,
        minutes: 15,
        happiness: 2,
      ),
    ],
  );

  static const cafe = Venue(
    id: 'workplace',
    title: 'Sunbeam Café',
    subtitle: 'Corner of Maple & 3rd',
    tagline: 'The espresso machine never really stops.',
    intro:
        'Steam curls off the group head. The window seat is free, the '
        'pastry case is half full, and somebody has queued the good playlist.',
    icon: Icons.local_cafe_rounded,
    scene: VenueScene.cafe,
    background: Color(0xFF160F0A),
    panel: Color(0xFF241812),
    accent: Color(0xFFFFB35C),
    glow: Color(0xFFFFE1A6),
    actions: [
      VenueAction(
        id: 'order_flat_white',
        label: 'Order a flat white',
        detail: 'Extra shot, no sugar.',
        blurb: 'The first sip resets your whole afternoon. Energy +10.',
        icon: Icons.coffee_rounded,
        moneyCost: 45,
        minutes: 20,
        energyDelta: 10,
        happiness: 1,
      ),
      VenueAction(
        id: 'cafe_shift',
        label: 'Work the evening shift',
        detail: 'Five customers, one broken grinder.',
        blurb:
            'You close the till with flour on your sleeve. +₱240 (play the '
            'mini-game from the full menu for tips up to ₱320).',
        icon: Icons.work_history_rounded,
        minutes: 180,
        energyDelta: -25,
        moneyGain: 240,
        charm: 1,
        happiness: -1,
        special: VenueSpecial.workShift,
      ),
      VenueAction(
        id: 'bake_batch',
        label: 'Help bake the morning batch',
        detail: 'Flour, butter, and a very hot tray.',
        blurb: 'The baker pays you in cash and a misshapen croissant. +₱60.',
        icon: Icons.bakery_dining_rounded,
        minutes: 45,
        energyDelta: -8,
        moneyGain: 60,
        happiness: 1,
      ),
      VenueAction(
        id: 'window_seat',
        label: 'Take the window seat',
        detail: 'Watch the town hurry past without you.',
        blurb: 'You nurse the cup until it goes cold. Nobody asks you to move.',
        icon: Icons.chair_alt_rounded,
        minutes: 30,
        energyDelta: 8,
        happiness: 1,
      ),
    ],
  );

  static const bank = Venue(
    id: 'bank',
    title: 'First Bank',
    subtitle: 'Marble & brass',
    tagline: 'Quiet money, loud marble.',
    intro:
        'The queue rope makes a polite zigzag. Behind the grille a teller '
        'counts something you are not allowed to see.',
    icon: Icons.account_balance_rounded,
    scene: VenueScene.bank,
    background: Color(0xFF0B1116),
    panel: Color(0xFF13202A),
    accent: Color(0xFF8FD3E8),
    glow: Color(0xFFD9F4FF),
    actions: [
      VenueAction(
        id: 'withdraw_allowance',
        label: 'Withdraw your allowance',
        detail: '₱200, counted twice.',
        blurb: 'The teller slides the cash under the glass. Balance updated.',
        icon: Icons.payments_rounded,
        minutes: 5,
        moneyGain: 200,
        special: VenueSpecial.allowance,
      ),
      VenueAction(
        id: 'check_balance',
        label: 'Ask the teller for your balance',
        detail: 'She reads it without looking down.',
        blurb: 'Your balance is printed on a small, serious slip of paper.',
        icon: Icons.receipt_long_rounded,
        minutes: 2,
      ),
      VenueAction(
        id: 'open_savings',
        label: 'Open a student savings account',
        detail: 'A passbook and a promise to yourself.',
        blurb: 'You sign three forms and receive a passbook with your name in it.',
        icon: Icons.savings_rounded,
        minutes: 30,
        charm: 1,
        setFlag: 'opened_savings_account',
      ),
      VenueAction(
        id: 'marble_wait',
        label: 'Wait under the ceiling fan',
        detail: 'Cool air, low voices, no queue left.',
        blurb: 'You enjoy the air conditioning for a while. Energy +5.',
        icon: Icons.ac_unit_rounded,
        minutes: 15,
        energyDelta: 5,
      ),
      // The debt quest's missing ending. It is only usable while the rent is
      // unpaid; the venue system greys it out otherwise.
      VenueAction(
        id: 'pay_rent',
        label: 'Pay your rent',
        detail: '₱500 to the landlord, receipt in hand.',
        blurb:
            'The teller stamps your receipt. The knot in your chest loosens. '
            'Happiness +5.',
        icon: Icons.home_work_rounded,
        moneyCost: 500,
        minutes: 10,
        happiness: 5,
        questId: 'debt_repayment',
        objectiveId: 'pay_landlord',
        special: VenueSpecial.debt,
      ),
    ],
  );

  static const mall = Venue(
    id: 'mall',
    title: 'Grand Mall',
    subtitle: 'Atrium level',
    tagline: 'Muzak, neon, and fried dough.',
    intro:
        'The atrium smells of cinnamon and new sneakers. A fountain '
        'murmurs under the skylight while escalators carry everyone nowhere.',
    icon: Icons.storefront_rounded,
    scene: VenueScene.mall,
    background: Color(0xFF140E18),
    panel: Color(0xFF22172A),
    accent: Color(0xFFFF9EC4),
    glow: Color(0xFF9DE1FF),
    actions: [
      VenueAction(
        id: 'buy_snacks',
        label: 'Buy snacks from the kiosk',
        detail: 'Something salty, something sweet.',
        blurb: 'The cashier upsells you a drink. Worth it. +1 bread.',
        icon: Icons.fastfood_rounded,
        moneyCost: 30,
        minutes: 10,
        itemId: 'bread',
        itemCount: 1,
      ),
      VenueAction(
        id: 'window_shop',
        label: 'Window-shop the boutiques',
        detail: 'Try on confidence, leave the tags.',
        blurb: 'You build three outfits in your head and buy none of them. Charm +1.',
        icon: Icons.shopping_bag_rounded,
        minutes: 30,
        energyDelta: -4,
        charm: 1,
      ),
      VenueAction(
        id: 'food_court',
        label: 'Eat at the food court',
        detail: 'A tray, a table, a small kingdom.',
        blurb: 'A filling meal and a good view of the fountain. Energy +10.',
        icon: Icons.restaurant_rounded,
        moneyCost: 50,
        minutes: 30,
        energyDelta: 10,
      ),
      VenueAction(
        id: 'arcade',
        label: 'Spend a round at the arcade',
        detail: 'One more coin, one more try.',
        blurb: 'You beat the high score on the racing cabinet. Mood +2.',
        icon: Icons.sports_esports_rounded,
        moneyCost: 20,
        minutes: 30,
        happiness: 2,
      ),
    ],
  );

  static const garage = Venue(
    id: 'repair',
    title: 'Fix-It Repair',
    subtitle: 'Garage floor',
    tagline: 'Oil, rubber, and a radio stuck on oldies.',
    intro:
        'A bike hangs on the stand with its wheel off. Somewhere under the '
        'workbench, a wrench is missing its owner.',
    icon: Icons.build_rounded,
    scene: VenueScene.garage,
    background: Color(0xFF0F1114),
    panel: Color(0xFF1A1F24),
    accent: Color(0xFFFFA45C),
    glow: Color(0xFF8FD6FF),
    actions: [
      VenueAction(
        id: 'repair_bike',
        label: 'Have your bike repaired',
        detail: 'New chain, true wheel, honest price.',
        blurb: 'The mechanic spins the wheel and nods. Your bike rides like new.',
        icon: Icons.pedal_bike_rounded,
        moneyCost: 80,
        minutes: 30,
        setFlag: 'bike_tuned',
      ),
      VenueAction(
        id: 'help_repairs',
        label: 'Help around the shop',
        detail: 'Hold this. No, the other end.',
        blurb: 'You learn which wrench is which. Strength +1, +₱40.',
        icon: Icons.handyman_rounded,
        minutes: 45,
        energyDelta: -8,
        strength: 1,
        moneyGain: 40,
      ),
      VenueAction(
        id: 'browse_parts',
        label: 'Browse the spare-parts wall',
        detail: 'Bells, chains, and one very old horn.',
        blurb: 'You find a bell that sounds like a tiny doorbell. You do not buy it.',
        icon: Icons.settings_rounded,
        minutes: 10,
      ),
      VenueAction(
        id: 'radio_wait',
        label: 'Wait while the mechanic works',
        detail: 'Oldies on the radio, oil in the air.',
        blurb: 'You listen to three songs and a weather report. Energy +5.',
        icon: Icons.radio_rounded,
        minutes: 20,
        energyDelta: 5,
        happiness: 1,
      ),
    ],
  );

  static const bookstore = Venue(
    id: 'bookstore',
    title: 'Book Store',
    subtitle: 'Paper & ink',
    tagline: 'Quiet enough to hear the pages turn.',
    intro:
        'The shelves go higher than they should. A reading chair waits by the '
        'window with a book already open on its arm.',
    icon: Icons.auto_stories_rounded,
    scene: VenueScene.bookstore,
    background: Color(0xFF140F0A),
    panel: Color(0xFF241A12),
    accent: Color(0xFFF0C987),
    glow: Color(0xFFFFE6B8),
    actions: [
      VenueAction(
        id: 'read_manga',
        label: 'Read a manga volume',
        detail: 'You will stop after one chapter. Sure.',
        blurb: 'You finish the volume standing up. Intelligence +1.',
        icon: Icons.auto_stories_rounded,
        minutes: 30,
        energyDelta: -4,
        intelligence: 1,
      ),
      VenueAction(
        id: 'study_guide',
        label: 'Work through a study guide',
        detail: 'The answers are in the back. You do not look.',
        blurb: 'Two chapters, one highlighter, zero distractions. Intelligence +1, Education +1.',
        icon: Icons.menu_book_rounded,
        minutes: 60,
        energyDelta: -10,
        intelligence: 1,
        education: 1,
      ),
      VenueAction(
        id: 'buy_notebook',
        label: 'Buy a fresh notebook',
        detail: 'Blank pages are a kind of promise.',
        blurb: 'You pick a green one. The first page stays blank a little longer.',
        icon: Icons.edit_note_rounded,
        moneyCost: 20,
        minutes: 5,
        happiness: 1,
      ),
      VenueAction(
        id: 'sell_reviewers',
        label: 'Sell your old reviewers',
        detail: 'Someone else\'s turn to highlight.',
        blurb: 'The owner flips through them and pays you. +₱15.',
        icon: Icons.sell_rounded,
        minutes: 15,
        moneyGain: 15,
      ),
    ],
  );

  static const supermarket = Venue(
    id: 'supermarket',
    title: 'Super Market',
    subtitle: 'Aisle 4',
    tagline: 'Bright lights and freezer hum.',
    intro:
        'The air conditioning is set to arctic. Somewhere a shopping cart '
        'with one bad wheel squeaks toward the checkout.',
    icon: Icons.local_grocery_store_rounded,
    scene: VenueScene.supermarket,
    background: Color(0xFF0C1210),
    panel: Color(0xFF14211C),
    accent: Color(0xFF9BE38E),
    glow: Color(0xFFDEF7C8),
    actions: [
      VenueAction(
        id: 'buy_groceries',
        label: 'Buy a bag of groceries',
        detail: 'Bread, eggs, and something for later.',
        blurb: 'You bag two loaves and a receipt. +2 bread.',
        icon: Icons.shopping_basket_rounded,
        moneyCost: 60,
        minutes: 10,
        itemId: 'bread',
        itemCount: 2,
      ),
      VenueAction(
        id: 'stock_pantry',
        label: 'Stock the whole pantry',
        detail: 'The big shop. Bring the list.',
        blurb: 'Your pantry is full for the first time in weeks.',
        icon: Icons.kitchen_rounded,
        moneyCost: 120,
        minutes: 30,
        special: VenueSpecial.pantryRestock,
        questId: 'cooking_lesson',
        objectiveId: 'buy_ingredients',
      ),
      VenueAction(
        id: 'free_sample',
        label: 'Try the sample tray',
        detail: 'One tiny cup is not stealing.',
        blurb: 'A warm cube of something cheesy. The sample lady winks.',
        icon: Icons.icecream_rounded,
        minutes: 5,
        happiness: 1,
      ),
      VenueAction(
        id: 'browse_aisles',
        label: 'Browse the aisles',
        detail: 'You only needed one thing.',
        blurb: 'You leave with a list of things you forgot to buy.',
        icon: Icons.directions_walk_rounded,
        minutes: 20,
        energyDelta: -2,
      ),
    ],
  );

  static const pizzeria = Venue(
    id: 'pizzahut',
    title: 'Pizza Hut',
    subtitle: 'Corner booth',
    tagline: 'The oven runs hot all evening.',
    intro:
        'Cheese and tomato hang in the air. The oven door glows orange, and '
        'the red vinyl booth by the window is somehow always free.',
    icon: Icons.local_pizza_rounded,
    scene: VenueScene.pizzeria,
    background: Color(0xFF1A0C0C),
    panel: Color(0xFF2A1414),
    accent: Color(0xFFFF8C5C),
    glow: Color(0xFFFFD08A),
    actions: [
      VenueAction(
        id: 'eat_pizza',
        label: 'Order a personal pizza',
        detail: 'Extra cheese, no regrets.',
        blurb: 'The first slice burns the roof of your mouth. Worth it. Energy +10.',
        icon: Icons.local_pizza_rounded,
        moneyCost: 70,
        minutes: 30,
        energyDelta: 10,
        happiness: 1,
      ),
      VenueAction(
        id: 'garlic_knots',
        label: 'Share an order of garlic knots',
        detail: 'Fingers will smell like this for hours.',
        blurb: 'You eat four before they hit the table. Mood +2.',
        icon: Icons.bakery_dining_rounded,
        moneyCost: 25,
        minutes: 15,
        happiness: 2,
      ),
      VenueAction(
        id: 'dish_shift',
        label: 'Take a dishwashing shift',
        detail: 'Hot water, loud radio, fast cash.',
        blurb: 'You leave with pruned fingers and a folded tip. +₱120.',
        icon: Icons.wash_rounded,
        minutes: 90,
        energyDelta: -12,
        moneyGain: 120,
      ),
      VenueAction(
        id: 'booth_rest',
        label: 'Sink into the corner booth',
        detail: 'Nobody will hurry you out.',
        blurb: 'The vinyl squeaks as you settle in. Energy +6, mood +1.',
        icon: Icons.weekend_rounded,
        minutes: 30,
        energyDelta: 6,
        happiness: 1,
      ),
    ],
  );

  static const hospital = Venue(
    id: 'hospital',
    title: 'Hospital',
    subtitle: 'Outpatient wing',
    tagline: 'Antiseptic quiet and soft-soled shoes.',
    intro:
        'The reception desk glows under fluorescent panels. A nurse moves '
        'past with a clipboard, and somewhere a monitor beeps politely.',
    icon: Icons.local_hospital_rounded,
    scene: VenueScene.hospital,
    background: Color(0xFF0A1216),
    panel: Color(0xFF122229),
    accent: Color(0xFF7FE0C4),
    glow: Color(0xFFD8FFF4),
    actions: [
      VenueAction(
        id: 'checkup',
        label: 'Get a check-up',
        detail: 'Height, blood pressure, a tsk of concern.',
        blurb: 'The doctor signs you off with a clean bill. Energy +15, Health +5.',
        icon: Icons.medical_services_rounded,
        moneyCost: 100,
        minutes: 30,
        energyDelta: 15,
        health: 5,
      ),
      VenueAction(
        id: 'buy_vitamins',
        label: 'Buy vitamins at the pharmacy',
        detail: 'The orange ones taste like childhood.',
        blurb: 'You shake two into your palm and chew. Health +2, Energy +5.',
        icon: Icons.medication_rounded,
        moneyCost: 60,
        minutes: 10,
        health: 2,
        energyDelta: 5,
      ),
      VenueAction(
        id: 'hospital_volunteer',
        label: 'Volunteer for an hour',
        detail: 'Fold linen, refill water jugs, listen.',
        blurb: 'A patient thanks you for the water. The day feels useful. Charm +1.',
        icon: Icons.volunteer_activism_rounded,
        minutes: 60,
        energyDelta: -8,
        charm: 1,
        happiness: 2,
      ),
      VenueAction(
        id: 'waiting_chair',
        label: 'Rest in the waiting room',
        detail: 'The chairs are terrible. The quiet is not.',
        blurb: 'You close your eyes to the beeps and open them ten minutes later.',
        icon: Icons.event_seat_rounded,
        minutes: 20,
        energyDelta: 5,
      ),
    ],
  );

  static const restaurant = Venue(
    id: 'restaurant',
    title: 'Restaurant',
    subtitle: 'Table for one',
    tagline: 'Garlic, candlelight, and the good plates.',
    intro:
        'The window table is set for two, but one chair is already pulled out '
        'for you. A candle leans slightly to the left.',
    icon: Icons.restaurant_rounded,
    scene: VenueScene.restaurant,
    background: Color(0xFF160D0B),
    panel: Color(0xFF251612),
    accent: Color(0xFFFFB27A),
    glow: Color(0xFFFFE4B5),
    actions: [
      VenueAction(
        id: 'dinner',
        label: 'Order the house dinner',
        detail: 'Soup, something garlicky, a warm plate.',
        blurb: 'You eat slowly, because nobody is waiting for the table. Energy +10.',
        icon: Icons.dinner_dining_rounded,
        moneyCost: 60,
        minutes: 45,
        energyDelta: 10,
        happiness: 1,
      ),
      VenueAction(
        id: 'dessert',
        label: 'Order dessert',
        detail: 'Two spoons. One for later.',
        blurb: 'The caramel is still warm. Mood +3.',
        icon: Icons.cake_rounded,
        moneyCost: 35,
        minutes: 20,
        happiness: 3,
      ),
      VenueAction(
        id: 'compliment_chef',
        label: 'Compliment the chef',
        detail: 'Through the pass, briefly.',
        blurb: 'The chef looks up, surprised, then nods once. Charm +1, mood +1.',
        icon: Icons.thumb_up_rounded,
        minutes: 10,
        charm: 1,
        happiness: 1,
      ),
      VenueAction(
        id: 'ask_job',
        label: 'Ask about weekend work',
        detail: 'The owner is short-staffed.',
        blurb: 'They take your name and promise to call. A door opens a crack.',
        icon: Icons.badge_rounded,
        minutes: 20,
        charm: 1,
        setFlag: 'restaurant_contact',
      ),
    ],
  );

  static const laundry = Venue(
    id: 'laundry',
    title: 'Laundry Shop',
    subtitle: 'Spin cycle',
    tagline: 'Warm steam and the thump of drums.',
    intro:
        'Six washers turn in different rhythms. The dryer vent pours warm air '
        'into the room, and every plastic chair is taken but one.',
    icon: Icons.local_laundry_service_rounded,
    scene: VenueScene.laundry,
    background: Color(0xFF08121A),
    panel: Color(0xFF10212C),
    accent: Color(0xFF8FD8FF),
    glow: Color(0xFFE4F8FF),
    actions: [
      VenueAction(
        id: 'wash_clothes',
        label: 'Wash and fold your clothes',
        detail: 'A fresh start, by the kilo.',
        blurb: 'Everything comes back warm and clean. Charm +1.',
        icon: Icons.local_laundry_service_rounded,
        moneyCost: 30,
        minutes: 30,
        charm: 1,
      ),
      VenueAction(
        id: 'fold_for_tips',
        label: 'Help fold for tips',
        detail: 'Corner, corner, fold, stack.',
        blurb: 'You fold a mountain of towels. The owner slides you ₱25.',
        icon: Icons.dry_cleaning_rounded,
        minutes: 30,
        energyDelta: -5,
        moneyGain: 25,
      ),
      VenueAction(
        id: 'warm_up',
        label: 'Warm up by the dryers',
        detail: 'The best free heater in town.',
        blurb: 'You stand in the warm exhaust until your fingers thaw. Energy +5.',
        icon: Icons.air_rounded,
        minutes: 15,
        energyDelta: 5,
        happiness: 1,
      ),
      VenueAction(
        id: 'lost_sock',
        label: 'Check the lost-sock board',
        detail: 'A wall of lonely socks.',
        blurb: 'You find one of yours from three months ago. Mood +1.',
        icon: Icons.checkroom_rounded,
        minutes: 5,
        happiness: 1,
      ),
    ],
  );

  static const police = Venue(
    id: 'police',
    title: 'Police Station',
    subtitle: 'Front desk',
    tagline: 'Fluorescent calm and a squeaky chair.',
    intro:
        'A ceiling fan turns too slowly to help. The notice board is layered '
        'three notices deep, and the front desk has a fresh pot of coffee.',
    icon: Icons.local_police_rounded,
    scene: VenueScene.police,
    background: Color(0xFF0A1018),
    panel: Color(0xFF121E2A),
    accent: Color(0xFF7DB8FF),
    glow: Color(0xFFD6ECFF),
    actions: [
      VenueAction(
        id: 'file_report',
        label: 'File a report',
        detail: 'Lost phone, found lead, long form.',
        blurb: 'The officer stamps the form and slides it into a tray. Charm +1.',
        icon: Icons.assignment_rounded,
        minutes: 20,
        charm: 1,
        special: VenueSpecial.report,
      ),
      VenueAction(
        id: 'notice_board',
        label: 'Read the notice board',
        detail: 'Lost pets, found bikes, event permits.',
        blurb: 'You memorize the date of the next town meeting.',
        icon: Icons.push_pin_rounded,
        minutes: 10,
        intelligence: 1,
      ),
      VenueAction(
        id: 'desk_coffee',
        label: 'Accept a cup of station coffee',
        detail: 'Strong enough to file itself.',
        blurb: 'You hold the warm cup with both hands. Energy +4.',
        icon: Icons.coffee_maker_rounded,
        minutes: 10,
        energyDelta: 4,
      ),
      VenueAction(
        id: 'ask_safety',
        label: 'Ask about neighborhood safety',
        detail: 'Which streets, which hours.',
        blurb: 'The officer draws a small map on a sticky note. Intelligence +1.',
        icon: Icons.shield_rounded,
        minutes: 15,
        intelligence: 1,
        charm: 1,
      ),
    ],
  );

  static const computer = Venue(
    id: 'computer',
    title: 'Computer Center',
    subtitle: 'Row of monitors',
    tagline: 'Fans humming in a cool blue room.',
    intro:
        'The screens throw blue light across the desks. Somebody left a game '
        'paused, and the printer is making the sound it makes before it jams.',
    icon: Icons.computer_rounded,
    scene: VenueScene.computer,
    background: Color(0xFF0A0D18),
    panel: Color(0xFF11182A),
    accent: Color(0xFF9FB6FF),
    glow: Color(0xFF9DE9FF),
    actions: [
      VenueAction(
        id: 'internet_hour',
        label: 'Rent an internet hour',
        detail: 'Tutorials, forums, and typing drills.',
        blurb: 'You surface sixty minutes later with three useful tabs. Intelligence +1.',
        icon: Icons.language_rounded,
        moneyCost: 25,
        minutes: 60,
        intelligence: 1,
      ),
      VenueAction(
        id: 'print_homework',
        label: 'Print your homework',
        detail: 'Two copies, one for luck.',
        blurb: 'The printer works on the third try. Education +1.',
        icon: Icons.print_rounded,
        moneyCost: 10,
        minutes: 15,
        education: 1,
      ),
      VenueAction(
        id: 'lan_game',
        label: 'Join a LAN match',
        detail: 'One round. Best of one. Promise.',
        blurb: 'Your team wins on a lucky last shot. Mood +2.',
        icon: Icons.sports_esports_rounded,
        moneyCost: 20,
        minutes: 45,
        happiness: 2,
      ),
      VenueAction(
        id: 'fix_printer',
        label: 'Help untangle the printer',
        detail: 'Paper, patience, and a paperclip.',
        blurb: 'You clear the jam. The attendant gives you a free half-hour. +₱35.',
        icon: Icons.build_circle_rounded,
        minutes: 30,
        energyDelta: -5,
        moneyGain: 35,
        intelligence: 1,
      ),
    ],
  );

  static const amusement = Venue(
    id: 'amusement',
    title: 'Amusement Park',
    subtitle: 'Midway lights',
    tagline: 'Neon, sugar, and screaming from the coaster.',
    intro:
        'The ferris wheel turns against a violet sky. Every stall bulb is '
        'working, the cotton candy is spinning, and the coaster is already full.',
    icon: Icons.attractions_rounded,
    scene: VenueScene.amusement,
    background: Color(0xFF0C0A18),
    panel: Color(0xFF191333),
    accent: Color(0xFFFF9BD1),
    glow: Color(0xFFFFE27A),
    actions: [
      VenueAction(
        id: 'roller_coaster',
        label: 'Ride the roller coaster',
        detail: 'Front row, eyes open, mostly.',
        blurb: 'The first drop steals your voice. You get it back at the brake run. Charm +1.',
        icon: Icons.roller_skating_rounded,
        moneyCost: 50,
        minutes: 60,
        charm: 1,
        happiness: 2,
      ),
      VenueAction(
        id: 'midway_game',
        label: 'Play a midway game',
        detail: 'Three balls, one very smug bottle pyramid.',
        blurb: 'You knock down two bottles and win a keychain. Mood +2.',
        icon: Icons.sports_baseball_rounded,
        moneyCost: 20,
        minutes: 20,
        happiness: 2,
      ),
      VenueAction(
        id: 'cotton_candy',
        label: 'Buy cotton candy',
        detail: 'Pink, enormous, gone in minutes.',
        blurb: 'It dissolves before you can decide if it was worth it. Mood +1, Energy +2.',
        icon: Icons.icecream_rounded,
        moneyCost: 15,
        minutes: 10,
        happiness: 1,
        energyDelta: 2,
      ),
      VenueAction(
        id: 'photo_booth',
        label: 'Squeeze into the photo booth',
        detail: 'Four frames, one good one.',
        blurb: 'You keep the strip where you are laughing at yourself.',
        icon: Icons.photo_camera_rounded,
        moneyCost: 30,
        minutes: 15,
        happiness: 2,
        setFlag: 'amusement_photo',
      ),
    ],
  );

  static const beach = Venue(
    id: 'beach',
    title: 'Beach',
    subtitle: 'Low tide',
    tagline: 'Salt air and a horizon that keeps moving.',
    intro:
        'The water pulls back and returns with a soft crash. Gulls drift '
        'overhead, and somebody has left a striped umbrella standing in the sand.',
    icon: Icons.beach_access_rounded,
    scene: VenueScene.beach,
    background: Color(0xFF08131A),
    panel: Color(0xFF0F2430),
    accent: Color(0xFFFFD36E),
    glow: Color(0xFF9DEBFF),
    actions: [
      VenueAction(
        id: 'swim',
        label: 'Swim out past the break',
        detail: 'Cold at first, then perfect.',
        blurb: 'You ride one wave back to shore. Strength +2, Health +1.',
        icon: Icons.pool_rounded,
        minutes: 60,
        energyDelta: -15,
        strength: 2,
        health: 1,
      ),
      VenueAction(
        id: 'sunbathe',
        label: 'Stretch out under the umbrella',
        detail: 'Hat over your face, phone in your bag.',
        blurb: 'The sun moves slowly across your legs. Energy +20, Health +1.',
        icon: Icons.wb_sunny_rounded,
        minutes: 30,
        energyDelta: 20,
        health: 1,
        happiness: 1,
      ),
      VenueAction(
        id: 'sandcastle',
        label: 'Build a sandcastle',
        detail: 'A moat, a tower, a tiny flag.',
        blurb: 'The tide takes it before you leave. You do not mind. Mood +3.',
        icon: Icons.castle_rounded,
        minutes: 30,
        energyDelta: -5,
        happiness: 3,
        questId: 'weekend_hike',
        objectiveId: 'visit_beach_or_park',
      ),
      VenueAction(
        id: 'coconut',
        label: 'Buy a cold coconut',
        detail: 'Straw in, feet in the sand.',
        blurb: 'The water is sweet and colder than the sea. Energy +8.',
        icon: Icons.local_drink_rounded,
        moneyCost: 25,
        minutes: 10,
        energyDelta: 8,
        happiness: 1,
      ),
    ],
  );

  static const fishing = Venue(
    id: 'fishing',
    title: 'Fishing Area',
    subtitle: 'Old pier',
    tagline: 'The water is doing something quiet.',
    intro:
        'The pier planks are warm and uneven. A float bobs twenty meters out, '
        'and the hills across the water have gone soft at the edges.',
    icon: Icons.phishing_rounded,
    scene: VenueScene.fishing,
    background: Color(0xFF08131A),
    panel: Color(0xFF102229),
    accent: Color(0xFF83DCC8),
    glow: Color(0xFFFFD98A),
    actions: [
      VenueAction(
        id: 'fish_hour',
        label: 'Fish for an hour',
        detail: 'Patience, then a sharp tug.',
        blurb: 'A decent catch, sold to the stall by the road. +₱40.',
        icon: Icons.phishing_rounded,
        minutes: 60,
        energyDelta: -6,
        moneyGain: 40,
        happiness: 1,
      ),
      VenueAction(
        id: 'cast_for_fun',
        label: 'Cast and release',
        detail: 'No bucket, no pressure.',
        blurb: 'You catch a small silver fish, hold it up, and let it go. Mood +2.',
        icon: Icons.waves_rounded,
        minutes: 20,
        energyDelta: -3,
        happiness: 2,
      ),
      VenueAction(
        id: 'buy_bait',
        label: 'Buy a box of bait',
        detail: 'The smell is part of the experience.',
        blurb: 'You leave the box on the pier. The fish do not seem to mind.',
        icon: Icons.inventory_2_rounded,
        moneyCost: 15,
        minutes: 10,
        setFlag: 'bought_bait',
      ),
      VenueAction(
        id: 'watch_water',
        label: 'Sit and watch the water',
        detail: 'Nothing to catch, nowhere to be.',
        blurb: 'The ripples rearrange themselves. Energy +5, mood +1.',
        icon: Icons.visibility_rounded,
        minutes: 15,
        energyDelta: 5,
        happiness: 1,
      ),
    ],
  );

  static const hotel = Venue(
    id: 'hotel',
    title: 'Hotel',
    subtitle: 'Grand lobby',
    tagline: 'Jazz, chandeliers, and a very soft carpet.',
    intro:
        'The chandelier throws a hundred small lights across the marble. '
        'Someone is playing piano badly, and somehow it helps.',
    icon: Icons.hotel_rounded,
    scene: VenueScene.hotel,
    background: Color(0xFF0F0B16),
    panel: Color(0xFF1D1629),
    accent: Color(0xFFE0B4FF),
    glow: Color(0xFFFFE2A8),
    actions: [
      VenueAction(
        id: 'lobby_rest',
        label: 'Rest in a lobby armchair',
        detail: 'Deep cushions, quiet jazz.',
        blurb: 'You sink into the chair and let the piano do the thinking. Energy +30.',
        icon: Icons.chair_rounded,
        moneyCost: 150,
        minutes: 60,
        energyDelta: 30,
        happiness: 1,
      ),
      VenueAction(
        id: 'room_service',
        label: 'Order room service',
        detail: 'A covered tray and a tiny flower.',
        blurb: 'The sandwich is cut into triangles. It tastes like a holiday. Energy +15.',
        icon: Icons.room_service_rounded,
        moneyCost: 80,
        minutes: 30,
        energyDelta: 15,
        happiness: 2,
      ),
      VenueAction(
        id: 'book_room',
        label: 'Book a room for the night',
        detail: 'Check in now, wake up tomorrow.',
        blurb: 'You sleep until morning in a bed that is too big for one. Energy restored.',
        icon: Icons.bed_rounded,
        moneyCost: 300,
        special: VenueSpecial.bookRoom,
      ),
      VenueAction(
        id: 'lobby_jazz',
        label: 'Listen to the lobby pianist',
        detail: 'Every song is slightly too slow.',
        blurb: 'You lean on the rail and let the last chord hang. Mood +1.',
        icon: Icons.piano_rounded,
        minutes: 20,
        happiness: 1,
      ),
    ],
  );

  /// Every venue keyed by the town location id.
  static const Map<String, Venue> _byId = {
    'school': school,
    'plaza': plaza,
    'church': church,
    'park': park,
    'workplace': cafe,
    'bank': bank,
    'mall': mall,
    'repair': garage,
    'bookstore': bookstore,
    'supermarket': supermarket,
    'pizzahut': pizzeria,
    'hospital': hospital,
    'restaurant': restaurant,
    'laundry': laundry,
    'police': police,
    'computer': computer,
    'amusement': amusement,
    'beach': beach,
    'fishing': fishing,
    'hotel': hotel,
  };

  /// All non-home venues, in town order.
  static List<Venue> get all => _byId.values.toList(growable: false);

  /// Venue for [locationId], or null for Home / unknown rooms.
  static Venue? forId(String locationId) => _byId[locationId];
}
