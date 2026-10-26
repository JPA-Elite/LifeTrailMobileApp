import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The layout a site uses inside the RetroWeb browser.
enum WebKind {
  portal,
  news,
  tech,
  wiki,
  forum,
  quiz,
  shop,
  blog,
  radio,
  archive,
  gallery,
  learn,
}

/// A link from one page to another site in the RetroWeb directory.
class WebLink {
  const WebLink(this.label, this.siteId);

  final String label;
  final String siteId;
}

/// A small label/value pair shown in infoboxes and stat grids.
class WebFact {
  const WebFact(this.label, this.value);

  final String label;
  final String value;
}

/// Something that can be dropped into the basket on a shop page.
class WebProduct {
  const WebProduct(this.name, this.priceCents, this.emoji, this.blurb);

  final String name;
  final int priceCents;
  final String emoji;
  final String blurb;

  String get priceLabel => '\$${(priceCents / 100).toStringAsFixed(2)}';
}

/// One multiple-choice question on a quiz site.
class WebQuizQuestion {
  const WebQuizQuestion(this.prompt, this.options, this.answer, this.fact);

  final String prompt;
  final List<String> options;
  final int answer;
  final String fact;
}

/// A single destination in the RetroWeb directory.
///
/// Sites are deliberately data-only: [WebKind] picks the page template and
/// the browser supplies all of the chrome and trivia state.
class WebSite {
  const WebSite({
    required this.id,
    required this.name,
    required this.domain,
    required this.category,
    required this.kind,
    required this.tagline,
    required this.headline,
    required this.summary,
    this.bullets = const [],
    this.tags = const [],
    this.links = const [],
    this.facts = const [],
    this.questions = const [],
    this.products = const [],
    this.emoji,
    this.accent,
    this.secondary,
  });

  final String id;
  final String name;
  final String domain;
  final String category;
  final WebKind kind;
  final String tagline;
  final String headline;
  final String summary;
  final List<String> bullets;
  final List<String> tags;
  final List<WebLink> links;
  final List<WebFact> facts;
  final List<WebQuizQuestion> questions;
  final List<WebProduct> products;
  final String? emoji;
  final Color? accent;
  final Color? secondary;

  String get glyph => emoji ?? WebSiteCatalog.categoryEmoji[category] ?? '🌐';

  Color get tint => accent ?? WebSiteCatalog.categoryColor[category] ?? _mint;

  Color get shade =>
      secondary ?? Color.lerp(tint, const Color(0xFF0B1020), 0.62)!;

  String get searchText =>
      '$name $domain $category $tagline $headline $summary '
              '${tags.join(' ')} ${bullets.join(' ')}'
          .toLowerCase();

  bool get linksResolve =>
      links.every((link) => WebSiteCatalog.maybeById(link.siteId) != null);
}

const Color _mint = Color(0xFF5EEAD4);

const List<WebSite> _techSites = [
  WebSite(
    id: 'silicon_sand',
    name: 'Silicon Sand',
    domain: 'siliconsand.net',
    category: 'Tech',
    kind: WebKind.tech,
    tagline: 'Teardowns, solder smoke, and honest benchmarks.',
    headline: 'The \$12 router that thinks it is a server',
    summary:
        'We flashed open firmware onto a bargain-bin router and pointed a '
        'webcam at it. Three weeks later it is still serving this website.',
    bullets: [
      'A 400 MHz chip, 64 MB of RAM, and one very optimistic fan.',
      'Idle power draw measured at 2.1 watts — cheaper than a nightlight.',
      'The stock firmware phones home 43 times an hour. Ours calls nobody.',
    ],
    tags: ['teardown', 'firmware', 'homelab'],
    facts: [
      WebFact('Test bench', 'Kitchen table'),
      WebFact('Uptime', '21 days, 4 hrs'),
      WebFact('Cost', '\$12 + shipping'),
    ],
    links: [
      WebLink('Packet Garden: routing basics', 'packet_garden'),
      WebLink('OpenBench: router scores', 'openbench'),
      WebLink('Byte Bazaar: secondhand gear', 'byte_bazaar'),
    ],
  ),
  WebSite(
    id: 'packet_garden',
    name: 'Packet Garden',
    domain: 'packetgarden.org',
    category: 'Tech',
    kind: WebKind.wiki,
    tagline: 'A field guide to the invisible.',
    headline: 'How packets find their way home',
    summary:
        'Every click becomes a small convoy of numbered envelopes. This '
        'illustrated guide follows one of them from a laptop to a garden '
        'sensor and back again.',
    bullets: [
      'Routers do not know the whole path — only the next good step.',
      'A packet can arrive twice, late, or not at all. Software copes.',
      'The garden sensor answers in fewer bytes than this headline.',
    ],
    tags: ['networking', 'explainer', 'diagrams'],
    facts: [
      WebFact('Reading time', '8 minutes'),
      WebFact('Diagrams', '14 hand-drawn'),
      WebFact('Last edited', 'Tuesday'),
    ],
    links: [
      WebLink('Silicon Sand: router teardown', 'silicon_sand'),
      WebLink('Null Pointer: subnet questions', 'null_pointer'),
      WebLink('OpenBench: latency tests', 'openbench'),
    ],
  ),
  WebSite(
    id: 'mech_keys',
    name: 'Mech Keys Quarterly',
    domain: 'mechkeys.press',
    category: 'Tech',
    kind: WebKind.shop,
    tagline: 'Clicky things, tested by hand.',
    headline: 'The 1987 board that still types like butter',
    summary:
        'Forty years of dust, one careful cleaning, and a buckling-spring '
        'keyboard that embarrassed every modern board on our desk.',
    bullets: [
      'Every key tested 10,000 times by a very patient intern.',
      'Sound profile: thunderous, delighted, mildly antisocial.',
      'Free switch samples with every order over \$40.',
    ],
    tags: ['keyboards', 'repair', 'reviews'],
    facts: [
      WebFact('Boards reviewed', '312'),
      WebFact('Typing speed', '94 wpm'),
    ],
    products: [
      WebProduct(
        'Buckling Spring 87',
        12900,
        '⌨️',
        'Loud, proud, rebuildable.',
      ),
      WebProduct(
        'Teal Tactile Switches',
        2400,
        '🟢',
        'A 36-pack of gentle clicks.',
      ),
      WebProduct('Coiled Cable, Soot', 1900, '🔌', 'USB-C, 1.8 m, braided.'),
    ],
    links: [
      WebLink('Byte Bazaar: vintage boards', 'byte_bazaar'),
      WebLink('Terminal & Tea: keyboard confessions', 'terminal_tea'),
      WebLink('Tiny Machines: macro pad build', 'tiny_machines'),
    ],
  ),
  WebSite(
    id: 'terminal_tea',
    name: 'Terminal & Tea',
    domain: 'terminaltea.dev',
    category: 'Tech',
    kind: WebKind.blog,
    tagline: 'Small programs, strong tea.',
    headline: 'I deleted 4,000 lines and shipped on Friday',
    summary:
        'A rewrite story without heroics: one developer, a stubborn build '
        'script, and the quiet joy of a codebase that finally fits in your head.',
    bullets: [
      'The old build took nine minutes; the new one takes eleven seconds.',
      'We kept the ugly parts that work and deleted the clever parts that did not.',
      'Tea consumed: 19 cups. Regrets: two, both about naming things.',
    ],
    tags: ['programming', 'refactoring', 'journal'],
    facts: [
      WebFact('Posted', 'Friday, 18:42'),
      WebFact('Read time', '6 minutes'),
    ],
    links: [
      WebLink('Null Pointer: review thread', 'null_pointer'),
      WebLink('OpenBench: build speed study', 'openbench'),
      WebLink('Silicon Sand: dev laptop teardown', 'silicon_sand'),
    ],
  ),
  WebSite(
    id: 'openbench',
    name: 'OpenBench',
    domain: 'openbench.io',
    category: 'Tech',
    kind: WebKind.tech,
    tagline: 'Numbers, but you can check our work.',
    headline: 'Benchmark: tiny computers under \$100',
    summary:
        'Twelve boards, one reproducible test suite, and a spreadsheet we '
        'refuse to hide. Every score links back to the script that made it.',
    bullets: [
      'The cheapest board wins on idle power by a wide margin.',
      'Fastest compile: the one with the noisy fan, obviously.',
      'All raw logs are downloadable as a 3 MB zip.',
    ],
    tags: ['benchmarks', 'hardware', 'open data'],
    facts: [
      WebFact('Boards tested', '12'),
      WebFact('Runs per board', '50'),
      WebFact('Test suite', 'v3.2.1'),
    ],
    links: [
      WebLink('Silicon Sand: router experiment', 'silicon_sand'),
      WebLink('Packet Garden: latency explained', 'packet_garden'),
      WebLink('Repair Radar: right to repair', 'repair_radar'),
    ],
  ),
  WebSite(
    id: 'repair_radar',
    name: 'Repair Radar',
    domain: 'repairradar.news',
    category: 'Tech',
    kind: WebKind.news,
    tagline: 'The fight for things that last.',
    headline: 'City opens its first tool library',
    summary:
        'A former print shop now lends drills, multimeters, and cake tins. '
        'The waiting list is already three weeks long.',
    bullets: [
      'Membership is \$18 a year; nobody is turned away for inability to pay.',
      'Volunteers repaired 61 appliances during the opening weekend.',
      'The next workshop covers laptop batteries and stubborn screws.',
    ],
    tags: ['repair', 'community', 'policy'],
    facts: [WebFact('Tools lent', '842'), WebFact('Volunteers', '37')],
    links: [
      WebLink('Harbor Herald: the opening', 'harbor_herald'),
      WebLink('Fix It Room: beginner skills', 'fix_it_room'),
      WebLink('Byte Bazaar: spare parts', 'byte_bazaar'),
    ],
  ),
  WebSite(
    id: 'byte_bazaar',
    name: 'Byte Bazaar',
    domain: 'bytebazaar.shop',
    category: 'Tech',
    kind: WebKind.shop,
    tagline: 'Secondhand silicon, first-rate stories.',
    headline: 'Fresh stock from a retired arcade',
    summary:
        'Six cabinets, forty joysticks, and a box of mystery boards arrived '
        'this morning. Everything is tested, most of it works, all of it is loud.',
    bullets: [
      'Every item ships with a handwritten note about where it came from.',
      '30-day returns, no questions, though we will ask one out of curiosity.',
      'New drop every Thursday at noon.',
    ],
    tags: ['secondhand', 'arcade', 'parts'],
    facts: [WebFact('Orders packed', '1,204'), WebFact('Rating', '4.8 / 5')],
    products: [
      WebProduct(
        'Mystery Logic Board',
        1400,
        '🧩',
        'Tested as far as we dare.',
      ),
      WebProduct(
        'Arcade Joystick, Red',
        3200,
        '🕹️',
        'Clicky. Slightly sticky.',
      ),
      WebProduct(
        'Box of Assorted Cables',
        900,
        '🧵',
        'At least one is useful.',
      ),
    ],
    links: [
      WebLink('Mech Keys Quarterly: keyboard sale', 'mech_keys'),
      WebLink('Silicon Sand: teardown targets', 'silicon_sand'),
      WebLink('Arcade Alley: cabinet history', 'arcade_alley'),
    ],
  ),
  WebSite(
    id: 'null_pointer',
    name: 'Null Pointer',
    domain: 'nullpointer.club',
    category: 'Tech',
    kind: WebKind.forum,
    tagline: 'Ask better questions. Get surprisingly good answers.',
    headline: 'Why does my subnet mask break at exactly 3 a.m.?',
    summary:
        'The thread that started as a typo and ended with a lesson about '
        'scheduling, clocks, and one very tired home router.',
    bullets: [
      'Moderators here will ask for logs before they ask for opinions.',
      'The monthly "explain it like a rubber duck" thread is a local treasure.',
      'No recruiter posts. No exceptions. The duck is watching.',
    ],
    tags: ['programming', 'help', 'community'],
    facts: [
      WebFact('Members', '18,906'),
      WebFact('Solved this week', '241'),
      WebFact('Ducks', '1,000,000'),
    ],
    links: [
      WebLink('Packet Garden: routing guide', 'packet_garden'),
      WebLink('Terminal & Tea: deletion story', 'terminal_tea'),
      WebLink('OpenBench: reproducible tests', 'openbench'),
    ],
  ),
  WebSite(
    id: 'tiny_machines',
    name: 'Tiny Machines',
    domain: 'tinymachines.gallery',
    category: 'Tech',
    kind: WebKind.gallery,
    tagline: 'Microcontrollers with big feelings.',
    headline: 'This week: nine machines smaller than a biscuit',
    summary:
        'A gallery of projects built on kitchen tables: a plant-watering '
        'badger, a tiny traffic jam, and a clock made from a single LED.',
    bullets: [
      'The plant badger waters on schedule and sulks when overfilled.',
      'Every project lists parts, code size, and total build time.',
      'Submissions open on the first of each month.',
    ],
    tags: ['microcontrollers', 'projects', 'gallery'],
    facts: [WebFact('Projects', '486'), WebFact('Smallest build', '11 mm')],
    links: [
      WebLink('Silicon Sand: chip teardown', 'silicon_sand'),
      WebLink('OpenBench: board scores', 'openbench'),
      WebLink('Puzzle Parlor: logic lessons', 'puzzle_parlor'),
    ],
  ),
];

const List<WebSite> _newsSites = [
  WebSite(
    id: 'harbor_herald',
    name: 'The Harbor Herald',
    domain: 'harborherald.local',
    category: 'News',
    kind: WebKind.news,
    tagline: 'The city, one cup at a time.',
    headline: 'Ferry strike ends with a handshake and free coffee',
    summary:
        'After eleven days, the harbor line is running again. Both sides '
        'credit a midnight conversation and a very persistent baker.',
    bullets: [
      'First ferry leaves at 06:10; extra sailings run through Sunday.',
      'The bakery that hosted the talks gave away 300 cinnamon rolls.',
      'Commuters describe a mood somewhere between relief and exhaustion.',
    ],
    tags: ['local', 'transit', 'morning edition'],
    facts: [
      WebFact('Weather', '18°C, bright'),
      WebFact('Tide', 'High 15:42'),
      WebFact('Edition', 'No. 8,412'),
    ],
    links: [
      WebLink('Civic Ledger: strike timeline', 'civic_ledger'),
      WebLink('Harbor Bulletin: commuter photos', 'harbor_bulletin'),
      WebLink('Pier Market: bakery reopens', 'pier_market'),
    ],
  ),
  WebSite(
    id: 'wire_eleven',
    name: 'Wire Eleven',
    domain: 'wireeleven.world',
    category: 'News',
    kind: WebKind.news,
    tagline: 'The world, in eleven lines.',
    headline: 'Mountain towns share a solar grid — and a snowplow',
    summary:
        'Three villages pooled their budgets and discovered that cooperation '
        'is cheaper than three separate backup generators.',
    bullets: [
      'The shared battery bank carried the towns through a two-day storm.',
      'One snowplow now serves all three valleys on a rotating schedule.',
      'Two neighboring regions have asked for the blueprint.',
    ],
    tags: ['world', 'energy', 'cooperation'],
    facts: [
      WebFact('Briefing', '12:00 UTC'),
      WebFact('Bureau', 'Nine correspondents'),
    ],
    links: [
      WebLink('Quiet Press: longer version', 'quiet_press'),
      WebLink('Market Bell: energy prices', 'market_bell'),
      WebLink('Weather Window: storm tracker', 'weather_window'),
    ],
  ),
  WebSite(
    id: 'quiet_press',
    name: 'The Quiet Press',
    domain: 'quietpress.story',
    category: 'News',
    kind: WebKind.news,
    tagline: 'Slow news for fast lives.',
    headline: 'The last lighthouse keeper has a new apprentice',
    summary:
        'The light has been automatic for twenty years. Someone still has to '
        'climb the stairs, and this spring, someone new is learning how.',
    bullets: [
      'A six-minute read about maintenance, memory, and a very steep ladder.',
      'The apprentice is nineteen and had never seen the sea before April.',
      'No ads, no autoplay, one photograph by the keeper herself.',
    ],
    tags: ['longform', 'people', 'coast'],
    facts: [
      WebFact('Read time', '6 minutes'),
      WebFact('Photos', '1, printed twice'),
    ],
    links: [
      WebLink('Tide Pool: photo essay', 'tide_pool'),
      WebLink('Slow Route: the walk there', 'slow_route'),
      WebLink('Night Desk: editor’s note', 'night_desk'),
    ],
  ),
  WebSite(
    id: 'market_bell',
    name: 'Market Bell',
    domain: 'marketbell.biz',
    category: 'News',
    kind: WebKind.news,
    tagline: 'Money, minus the shouting.',
    headline: 'The tiny bakery index is up for a third month',
    summary:
        'Our unscientific basket of six local staples says prices are holding '
        'steady, except for butter, which has opinions.',
    bullets: [
      'A loaf, a dozen eggs, and a coffee now cost \$11.40.',
      'Butter is the only item to rise more than five percent this quarter.',
      'The index has been published every Friday since 1998.',
    ],
    tags: ['business', 'prices', 'local'],
    facts: [
      WebFact('Index', '114.2'),
      WebFact('Change', '+0.8%'),
      WebFact('Published', 'Fridays'),
    ],
    links: [
      WebLink('Penny Ledger: index explained', 'penny_ledger'),
      WebLink('Pier Market: butter shortage', 'pier_market'),
      WebLink('Wire Eleven: markets abroad', 'wire_eleven'),
    ],
  ),
  WebSite(
    id: 'the_sideline',
    name: 'The Sideline',
    domain: 'sideline.sport',
    category: 'News',
    kind: WebKind.news,
    tagline: 'The game behind the game.',
    headline: 'Fourth-division keeper saves a penalty and a season',
    summary:
        'Harbor Town needed one stop to stay up. Their keeper, a plumber on '
        'weekdays, guessed correctly and then apologized to the striker.',
    bullets: [
      'The final score was 1–1; the save came in the 94th minute.',
      'Attendance: 612, including the keeper’s entire plumbing crew.',
      'Harbor Town will play in the third division for the first time since 2004.',
    ],
    tags: ['football', 'local', 'match report'],
    facts: [
      WebFact('Venue', 'Meadow End'),
      WebFact('Attendance', '612'),
      WebFact('Pint after', 'Earned'),
    ],
    links: [
      WebLink('Pace Line: season preview', 'pace_line'),
      WebLink('Stat Pitch: keeper numbers', 'stat_pitch'),
      WebLink('Weekend League: fixtures', 'weekend_league'),
    ],
  ),
  WebSite(
    id: 'civic_ledger',
    name: 'Civic Ledger',
    domain: 'civicledger.gov',
    category: 'News',
    kind: WebKind.archive,
    tagline: 'Every vote, minuted.',
    headline: 'Council archive: the ferry debate, 1994–2026',
    summary:
        'Thirty-two years of minutes, scanned and searchable. The font '
        'changes, the arguments do not, and the tea budget is remarkably stable.',
    bullets: [
      'Search by year, ward, or the phrase "further discussion".',
      'The 2003 bicycle lane debate remains the most downloaded file.',
      'New minutes appear within five working days of each meeting.',
    ],
    tags: ['public record', 'council', 'archive'],
    facts: [
      WebFact('Documents', '11,482'),
      WebFact('Oldest', '1891'),
      WebFact('Updated', 'Today'),
    ],
    links: [
      WebLink('Harbor Herald: strike ends', 'harbor_herald'),
      WebLink('Town Hall Live: next meeting', 'town_hall_live'),
      WebLink('Neighbors Almanac: ward notes', 'neighbors_almanac'),
    ],
  ),
  WebSite(
    id: 'weather_window',
    name: 'Weather Window',
    domain: 'weatherwindow.co',
    category: 'News',
    kind: WebKind.news,
    tagline: 'Look outside, then look here.',
    headline: 'A bright week, a cool evening, and one stubborn cloud',
    summary:
        'High pressure settles in for six days. The cloud over the west hill '
        'has been there since Tuesday and shows no interest in moving.',
    bullets: [
      'Today: 18°C, light wind, UV moderate. Bring a layer for the evening.',
      'Tomorrow: fog until 09:00, then the best picnic weather of the month.',
      'The weekend looks dry; the garden could use a watering can.',
    ],
    tags: ['forecast', 'local', 'outdoors'],
    facts: [
      WebFact('Now', '18°C'),
      WebFact('Sunset', '19:48'),
      WebFact('Rain', '0 mm'),
    ],
    links: [
      WebLink('Corner Plot: watering guide', 'corner_plot'),
      WebLink('Field Notes: what blooms now', 'field_notes'),
      WebLink('Wire Eleven: regional storm', 'wire_eleven'),
    ],
  ),
  WebSite(
    id: 'night_desk',
    name: 'Night Desk',
    domain: 'nightdesk.press',
    category: 'News',
    kind: WebKind.blog,
    tagline: 'Filed after midnight.',
    headline: 'The stories that did not fit before deadline',
    summary:
        'A reporter’s notebook of loose ends: the wrong ferry timetable, the '
        'right bakery, and a quote that arrived four hours late.',
    bullets: [
      'The baker’s full quote was better than the one we printed.',
      'A correction about the 1994 ferry map, with apologies to the archivist.',
      'Tomorrow’s edition will finally explain the west-hill cloud.',
    ],
    tags: ['notebook', 'corrections', 'late edition'],
    facts: [WebFact('Filed', '01:12'), WebFact('Coffee', 'Decaf, regrettably')],
    links: [
      WebLink('Harbor Herald: front page', 'harbor_herald'),
      WebLink('Civic Ledger: the 1994 map', 'civic_ledger'),
      WebLink('Quiet Press: lighthouse story', 'quiet_press'),
    ],
  ),
];

const List<WebSite> _scienceSites = [
  WebSite(
    id: 'orbital_notes',
    name: 'Orbital Notes',
    domain: 'orbitalnotes.space',
    category: 'Science',
    kind: WebKind.wiki,
    tagline: 'A notebook kept above the weather.',
    headline: 'Why satellites do not fall down',
    summary:
        'They are falling, constantly. The trick is moving sideways fast '
        'enough that the ground keeps curving away beneath you.',
    bullets: [
      'Low orbit is crowded; the useful altitudes have waiting lists.',
      'A screwdriver lost in 2007 is tracked to this day.',
      'The station sees sixteen sunrises before you finish a workday.',
    ],
    tags: ['space', 'orbits', 'explainer'],
    facts: [
      WebFact('Altitude', '408 km'),
      WebFact('Speed', '7.66 km/s'),
      WebFact('Sunrises', '16 / day'),
    ],
    links: [
      WebLink('Deep Field: new telescope images', 'deep_field'),
      WebLink('Telescope Tonight: backyard guide', 'telescope_tonight'),
      WebLink('Field Trip: visit the observatory', 'field_trip'),
    ],
  ),
  WebSite(
    id: 'deep_field',
    name: 'Deep Field',
    domain: 'deepfield.photo',
    category: 'Science',
    kind: WebKind.gallery,
    tagline: 'Light that left home before you did.',
    headline: 'Six new images from the edge of the visible',
    summary:
        'A gallery of smudges, spirals, and one extraordinarily patient '
        'exposure that took eleven nights to collect.',
    bullets: [
      'Each image includes the exposure time and the telescope’s mood.',
      'The faintest smudge is a galaxy 13 billion years old.',
      'All images are free to download at full resolution.',
    ],
    tags: ['astronomy', 'photography', 'gallery'],
    facts: [
      WebFact('Exposures', '11 nights'),
      WebFact('Faintest object', 'mag 29.4'),
    ],
    links: [
      WebLink('Orbital Notes: orbit basics', 'orbital_notes'),
      WebLink('Telescope Tonight: how to look', 'telescope_tonight'),
      WebLink('Museum of Almost: odd specimens', 'museum_of_almost'),
    ],
  ),
  WebSite(
    id: 'lab_window',
    name: 'Lab Window',
    domain: 'labwindow.sci',
    category: 'Science',
    kind: WebKind.news,
    tagline: 'Peer review, with the blinds open.',
    headline: 'A paper about paper is retracted, then reinstated',
    summary:
        'The study on folding stiffness was pulled over a statistical typo. '
        'The correction makes the folds slightly stiffer, and the authors '
        'slightly more famous.',
    bullets: [
      'The retraction lasted nine days and produced 400 memes.',
      'A graduate student found the typo while folding a map.',
      'The journal now requires a second pair of scissors for review.',
    ],
    tags: ['research', 'publishing', 'corrections'],
    facts: [WebFact('Retracted', '9 days'), WebFact('Citations', '+61')],
    links: [
      WebLink('Element of the Week: carbon', 'element_of_week'),
      WebLink('Quark Corner: peer review thread', 'quark_corner'),
      WebLink('Quiet Press: the human story', 'quiet_press'),
    ],
  ),
  WebSite(
    id: 'element_of_week',
    name: 'Element of the Week',
    domain: 'elements.weekly',
    category: 'Science',
    kind: WebKind.wiki,
    tagline: '118 characters, one at a time.',
    headline: 'Bismuth: the rainbow metal in your medicine cabinet',
    summary:
        'It forms staircase crystals, it soothes upset stomachs, and it is '
        'technically not a heavy metal despite its reputation.',
    bullets: [
      'The colorful oxide layer is only a few atoms thick.',
      'Ancient alchemists mistook it for lead with ambitions.',
      'It is the last naturally stable element on the periodic table.',
    ],
    tags: ['chemistry', 'elements', 'crystals'],
    facts: [
      WebFact('Symbol', 'Bi'),
      WebFact('Number', '83'),
      WebFact('Melts at', '271°C'),
    ],
    links: [
      WebLink('Periodic Table: full index', 'packet_garden'),
      WebLink('Lab Window: chemistry news', 'lab_window'),
      WebLink('Field Trip: the mine museum', 'field_trip'),
    ],
  ),
  WebSite(
    id: 'field_trip',
    name: 'Field Trip',
    domain: 'fieldtrip.edu',
    category: 'Science',
    kind: WebKind.learn,
    tagline: 'Learning with mud on your boots.',
    headline: 'A four-week course in noticing',
    summary:
        'No textbook, no exam. Four walks, one notebook, and a final project '
        'that consists entirely of things you found within a kilometer of home.',
    bullets: [
      'Week one: tracks, trails, and the art of standing still.',
      'Week two: water, weather, and what the puddles remember.',
      'The course is free and runs every season.',
    ],
    tags: ['course', 'nature', 'notebook'],
    facts: [
      WebFact('Lessons', '4'),
      WebFact('Students', '2,318'),
      WebFact('Certificate', 'Paper, folded'),
    ],
    links: [
      WebLink('Moss Map: local species', 'moss_map'),
      WebLink('Bird Call: sound library', 'bird_call'),
      WebLink('Field Notes: seasonal diary', 'field_notes'),
    ],
  ),
  WebSite(
    id: 'quark_corner',
    name: 'Quark Corner',
    domain: 'quarkcorner.edu',
    category: 'Science',
    kind: WebKind.forum,
    tagline: 'Small particles, large arguments.',
    headline: 'Can a vacuum have a temperature?',
    summary:
        'A 47-post thread that begins with a shower thought and ends with a '
        'surprisingly civil discussion of entropy and empty space.',
    bullets: [
      'Physicists and enthusiastic amateurs are equally welcome.',
      'Threads are archived after six months; good ones are pinned forever.',
      'The weekly "dumb question" slot is the most popular on the board.',
    ],
    tags: ['physics', 'discussion', 'questions'],
    facts: [WebFact('Threads', '9,041'), WebFact('Answers', 'Mostly')],
    links: [
      WebLink('Orbital Notes: satellite guide', 'orbital_notes'),
      WebLink('Lab Window: research news', 'lab_window'),
      WebLink('Pocket Professor: physics primer', 'pocket_professor'),
    ],
  ),
  WebSite(
    id: 'telescope_tonight',
    name: 'Telescope Tonight',
    domain: 'telescopetonight.org',
    category: 'Science',
    kind: WebKind.blog,
    tagline: 'Look up. Then check the forecast.',
    headline: 'Three things to see with cheap binoculars',
    summary:
        'The Moon, a fuzzy patch in Orion, and four tiny moons around '
        'Jupiter — all before the streetlights win the evening.',
    bullets: [
      'Best window this week: 21:10 to 22:30, before moonrise.',
      'A tripod made from a broom handle is genuinely good enough.',
      'If it is cloudy, the site posts a consolation photograph.',
    ],
    tags: ['astronomy', 'beginner', 'backyard'],
    facts: [WebFact('Seeing', 'Good'), WebFact('Moon', 'Waxing gibbous')],
    links: [
      WebLink('Deep Field: deep-sky gallery', 'deep_field'),
      WebLink('Orbital Notes: orbit guide', 'orbital_notes'),
      WebLink('Weather Window: cloud forecast', 'weather_window'),
    ],
  ),
];

const List<WebSite> _quizSites = [
  WebSite(
    id: 'quiz_jar',
    name: 'The Quiz Jar',
    domain: 'quizjar.fun',
    category: 'Quizzes',
    kind: WebKind.quiz,
    tagline: 'Ten questions. No pressure. Some pressure.',
    headline: 'The general knowledge jar, shaken',
    summary:
        'A mixed handful of questions about oceans, inventions, and things '
        'that are technically vegetables. Answers are revealed immediately.',
    bullets: [
      'A new jar is shaken every morning at 07:00.',
      'No timers, no leaderboards, no reason to panic.',
      'Each answer comes with a small, useful fact.',
    ],
    tags: ['general knowledge', 'daily', 'casual'],
    questions: [
      WebQuizQuestion(
        'Which ocean is the largest by surface area?',
        ['Atlantic', 'Indian', 'Pacific', 'Arctic'],
        2,
        'The Pacific covers about a third of the planet.',
      ),
      WebQuizQuestion(
        'What is the only metal that is liquid at room temperature?',
        ['Mercury', 'Gallium', 'Sodium', 'Tin'],
        0,
        'Gallium melts in your hand, but it needs a warm day.',
      ),
    ],
    links: [
      WebLink('Trivia Attic: harder questions', 'trivia_attic'),
      WebLink('Brain Bakery: timed rounds', 'brain_bakery'),
      WebLink('Flags & Facts: geography', 'flags_and_facts'),
    ],
  ),
  WebSite(
    id: 'trivia_attic',
    name: 'Trivia Attic',
    domain: 'triviaattic.net',
    category: 'Quizzes',
    kind: WebKind.quiz,
    tagline: 'Dusty facts, carefully labelled.',
    headline: 'The history round nobody asked for',
    summary:
        'Questions about forgotten inventions, ancient snack food, and the '
        'only war started by a bucket. The attic rewards patient readers.',
    bullets: [
      'Difficulty: cheerful pedant.',
      'Every question has a source, and the source has a footnote.',
      'Perfect scores receive a digital certificate of dubious value.',
    ],
    tags: ['history', 'inventions', 'hard'],
    questions: [
      WebQuizQuestion(
        'Which ancient civilization built the Antikythera mechanism?',
        ['Egyptians', 'Greeks', 'Romans', 'Phoenicians'],
        1,
        'The bronze gear device is roughly 2,000 years old.',
      ),
      WebQuizQuestion(
        'What was the first product sold with a barcode?',
        ['Chewing gum', 'Cereal', 'Soda', 'Soap'],
        0,
        'Wrigley’s gum was scanned in 1974, in Ohio.',
      ),
    ],
    links: [
      WebLink('Museum of Almost: odd objects', 'museum_of_almost'),
      WebLink('Quiz Jar: a gentler round', 'quiz_jar'),
      WebLink('Page & Ink: history books', 'page_and_ink'),
    ],
  ),
  WebSite(
    id: 'brain_bakery',
    name: 'Brain Bakery',
    domain: 'brainbakery.fun',
    category: 'Quizzes',
    kind: WebKind.quiz,
    tagline: 'Fresh questions, baked hourly.',
    headline: 'The sixty-second speed round',
    summary:
        'Five quick questions, one gentle timer, and a score you are invited '
        'to ignore. The bakery’s specialty is the "almost obvious" answer.',
    bullets: [
      'Rounds are short enough for a tea break.',
      'Questions get slightly harder as the week goes on.',
      'The high-score board resets every Monday.',
    ],
    tags: ['speed', 'daily', 'mixed'],
    questions: [
      WebQuizQuestion(
        'How many sides does a heptagon have?',
        ['Five', 'Six', 'Seven', 'Eight'],
        2,
        'Hepta- means seven, as in seven-sided and slightly smug.',
      ),
      WebQuizQuestion(
        'Which planet has the shortest day?',
        ['Mercury', 'Jupiter', 'Mars', 'Venus'],
        1,
        'Jupiter spins once in under ten hours, despite its size.',
      ),
    ],
    links: [
      WebLink('Number Nook: maths puzzles', 'number_nook'),
      WebLink('Science Sprint: science round', 'science_sprint'),
      WebLink('Quiz Jar: unhurried version', 'quiz_jar'),
    ],
  ),
  WebSite(
    id: 'flags_and_facts',
    name: 'Flags & Facts',
    domain: 'flagsandfacts.world',
    category: 'Quizzes',
    kind: WebKind.quiz,
    tagline: 'Geography, without the passport.',
    headline: 'Countries with confusing capitals',
    summary:
        'Six questions about places where the biggest city is not the '
        'capital, and one about a country with three of them.',
    bullets: [
      'Maps are optional but encouraged.',
      'Every answer links to a longer country profile.',
      'The site is maintained by two geography teachers and a cat.',
    ],
    tags: ['geography', 'capitals', 'maps'],
    questions: [
      WebQuizQuestion(
        'What is the capital of Australia?',
        ['Sydney', 'Melbourne', 'Canberra', 'Perth'],
        2,
        'Canberra was purpose-built as a compromise capital in 1913.',
      ),
      WebQuizQuestion(
        'Which country has three official capitals?',
        ['South Africa', 'Bolivia', 'Switzerland', 'Malaysia'],
        0,
        'Pretoria, Cape Town, and Bloemfontein share the role.',
      ),
    ],
    links: [
      WebLink('Slow Route: travel notebooks', 'slow_route'),
      WebLink('Postcard Press: photo atlas', 'postcard_press'),
      WebLink('Quiz Jar: general round', 'quiz_jar'),
    ],
  ),
  WebSite(
    id: 'number_nook',
    name: 'Number Nook',
    domain: 'numbernook.club',
    category: 'Quizzes',
    kind: WebKind.quiz,
    tagline: 'Small puzzles, satisfying clicks.',
    headline: 'Three sequences and a trick question',
    summary:
        'A pocket-sized maths quiz that rewards pattern-spotting more than '
        'memorization. Pencil and scrap paper are part of the experience.',
    bullets: [
      'New puzzles every weekday; solutions on Sunday.',
      'Hints are available but cost you a perfectly good minute.',
      'The trick question is clearly labelled. Nobody believes it.',
    ],
    tags: ['maths', 'patterns', 'puzzles'],
    questions: [
      WebQuizQuestion(
        'What comes next: 2, 3, 5, 7, 11, ___?',
        ['12', '13', '14', '15'],
        1,
        'They are the primes; 13 follows 11.',
      ),
      WebQuizQuestion(
        'A clock shows 3:15. What is the angle between its hands?',
        ['0°', '7.5°', '15°', '22.5°'],
        1,
        'The hour hand has moved a quarter of the way to 4.',
      ),
    ],
    links: [
      WebLink('Puzzle Parlor: logic grids', 'puzzle_parlor'),
      WebLink('Brain Bakery: speed round', 'brain_bakery'),
      WebLink('Open Classroom: maths course', 'open_classroom'),
    ],
  ),
  WebSite(
    id: 'word_ladder',
    name: 'Word Ladder',
    domain: 'wordladder.press',
    category: 'Quizzes',
    kind: WebKind.quiz,
    tagline: 'Climb one letter at a time.',
    headline: 'From COLD to WARM in four steps',
    summary:
        'A word puzzle dressed as a quiz. Change one letter each rung and '
        'try not to invent any new languages along the way.',
    bullets: [
      'Solutions are accepted in either direction.',
      'The daily ladder is hand-checked by a retired librarian.',
      'No proper nouns, no abbreviations, no nonsense.',
    ],
    tags: ['words', 'puzzles', 'daily'],
    questions: [
      WebQuizQuestion(
        'Which word means "a fear of words"?',
        ['Logophobia', 'Lexiconia', 'Verbaphobia', 'Scribbleitis'],
        0,
        'Logophobia, from logos, meaning word or speech.',
      ),
      WebQuizQuestion(
        'What is a group of crows called?',
        ['A choir', 'A murder', 'A parliament', 'A flutter'],
        1,
        'A murder of crows; a parliament is owls.',
      ),
    ],
    links: [
      WebLink('Poem Post: words in the wild', 'poem_post'),
      WebLink('Page & Ink: reading list', 'page_and_ink'),
      WebLink('Trivia Attic: etymology corner', 'trivia_attic'),
    ],
  ),
  WebSite(
    id: 'science_sprint',
    name: 'Science Sprint',
    domain: 'sciencesprint.edu',
    category: 'Quizzes',
    kind: WebKind.quiz,
    tagline: 'Five minutes of wondering.',
    headline: 'The body edition: bones, blood, and blinking',
    summary:
        'A quick tour of the strange machinery you carry around all day. '
        'No lab coat required, though the answers are properly sourced.',
    bullets: [
      'Questions are reviewed by a working biologist.',
      'Each round includes one fact that sounds made up but is not.',
      'Best enjoyed with a glass of water and a straight spine.',
    ],
    tags: ['biology', 'body', 'science'],
    questions: [
      WebQuizQuestion(
        'How many bones does an adult human have?',
        ['186', '206', '226', '246'],
        1,
        'Babies have more; many fuse together as we grow.',
      ),
      WebQuizQuestion(
        'What is the largest organ in the human body?',
        ['Liver', 'Brain', 'Skin', 'Lungs'],
        2,
        'Skin covers roughly two square meters in an adult.',
      ),
    ],
    links: [
      WebLink('Sleep Lab: rest explained', 'sleep_lab'),
      WebLink('Steady Breath: calming exercises', 'steady_breath'),
      WebLink('Lab Window: research news', 'lab_window'),
    ],
  ),
  WebSite(
    id: 'movie_memory',
    name: 'Movie Memory',
    domain: 'moviememory.film',
    category: 'Quizzes',
    kind: WebKind.quiz,
    tagline: 'For people who quote films badly.',
    headline: 'Name the film from one prop',
    summary:
        'A quiz built entirely around objects: a red stapler, a floating '
        'pen, a very specific pair of shoes. Bonus points for restraint.',
    bullets: [
      'No trailers, no clips, no spoilers for the endings.',
      'One prop per question, one guess per customer.',
      'The archive of past rounds is free to browse.',
    ],
    tags: ['film', 'props', 'trivia'],
    questions: [
      WebQuizQuestion(
        'A glowing briefcase appears in which film?',
        ['Pulp Fiction', 'Heat', 'Se7en', 'Fargo'],
        0,
        'The briefcase’s contents are never shown on screen.',
      ),
      WebQuizQuestion(
        'A typewriter on a snowy hotel desk features in which film?',
        ['The Shining', 'Misery', 'Barton Fink', 'The Post'],
        0,
        'Jack Torrance’s pages repeat one sentence, endlessly.',
      ),
    ],
    links: [
      WebLink('Silver Screen: reviews', 'silver_screen'),
      WebLink('Prop House: objects on film', 'prop_house'),
      WebLink('Lamplight Cinema: repertory listings', 'lamplight_cinema'),
    ],
  ),
];

const List<WebSite> _gameSites = [
  WebSite(
    id: 'pixel_pasture',
    name: 'Pixel Pasture',
    domain: 'pixelpasture.games',
    category: 'Games',
    kind: WebKind.gallery,
    tagline: 'Cozy worlds, sharp pixels.',
    headline: 'Seven farms that fit on a floppy disk',
    summary:
        'A gallery of tiny farming games made for machines older than their '
        'players. Every screenshot comes with the story behind the harvest.',
    bullets: [
      'All featured games are free and legally downloadable.',
      'The smallest entry is 41 KB, including the chickens.',
      'New pasture every other Friday.',
    ],
    tags: ['indie', 'pixel art', 'cozy'],
    facts: [WebFact('Featured', '7 games'), WebFact('Smallest', '41 KB')],
    links: [
      WebLink('Arcade Alley: cabinet history', 'arcade_alley'),
      WebLink('Cozy Quests: developer diary', 'cozy_quests'),
      WebLink('Puzzle Parlor: level design', 'puzzle_parlor'),
    ],
  ),
  WebSite(
    id: 'arcade_alley',
    name: 'Arcade Alley',
    domain: 'arcadealley.org',
    category: 'Games',
    kind: WebKind.archive,
    tagline: 'The cabinets remember.',
    headline: 'A photo archive of every arcade on the coast',
    summary:
        'Forty years of neon, sticky carpets, and high scores. The archive '
        'started with one shoebox of photographs and now fills nine pages.',
    bullets: [
      'Browse by town, decade, or cabinet manufacturer.',
      'Visitors have contributed 218 photographs and 60 corrections.',
      'The oldest image is from 1981, taken with the wrong film.',
    ],
    tags: ['arcade', 'history', 'photographs'],
    facts: [WebFact('Cabinets', '1,106'), WebFact('Photos', '2,840')],
    links: [
      WebLink('Pixel Pasture: tiny games', 'pixel_pasture'),
      WebLink('Byte Bazaar: arcade parts', 'byte_bazaar'),
      WebLink('Lamplight Cinema: coastal venues', 'lamplight_cinema'),
    ],
  ),
  WebSite(
    id: 'dice_and_daub',
    name: 'Dice & Daub',
    domain: 'diceanddaub.club',
    category: 'Games',
    kind: WebKind.forum,
    tagline: 'Board games, painted badly, played often.',
    headline: 'What is the friendliest board game for four people?',
    summary:
        'A long-running recommendation thread with strong opinions about '
        'turn order, snack compatibility, and the correct way to lose.',
    bullets: [
      'Monthly painting challenge: one miniature, any skill level.',
      'The trading board has a strict no-scalping rule.',
      'Game night listings are sorted by distance and snack policy.',
    ],
    tags: ['board games', 'community', 'painting'],
    facts: [WebFact('Members', '3,441'), WebFact('Games owned', 'Too many')],
    links: [
      WebLink('Puzzle Parlor: solo puzzles', 'puzzle_parlor'),
      WebLink('Hostel Notes: game nights abroad', 'hostel_notes'),
      WebLink('Shelf Help: game storage', 'shelf_help'),
    ],
  ),
  WebSite(
    id: 'speedrun_society',
    name: 'Speedrun Society',
    domain: 'speedrunsociety.tv',
    category: 'Games',
    kind: WebKind.forum,
    tagline: 'Going fast, explaining slowly.',
    headline: 'The 12-second glitch that took four years to find',
    summary:
        'A runner explains how a misplaced wall collision shaved eleven '
        'seconds off a game nobody had played seriously since 1998.',
    bullets: [
      'Every record includes a full video and input display.',
      'Newcomers get a mentor within a week, no experience needed.',
      'The community wiki is the largest of its kind.',
    ],
    tags: ['speedrunning', 'records', 'technique'],
    facts: [WebFact('Records', '2,109'), WebFact('Games tracked', '608')],
    links: [
      WebLink('Pixel Pasture: retro games', 'pixel_pasture'),
      WebLink('Arcade Alley: cabinet archive', 'arcade_alley'),
      WebLink('OpenBench: timing tools', 'openbench'),
    ],
  ),
  WebSite(
    id: 'puzzle_parlor',
    name: 'The Puzzle Parlor',
    domain: 'puzzleparlor.net',
    category: 'Games',
    kind: WebKind.learn,
    tagline: 'Logic, gently unlocked.',
    headline: 'Learn to solve a logic grid without guessing',
    summary:
        'A short course in deduction: read the clues, draw the grid, and '
        'resist the urge to scribble question marks everywhere.',
    bullets: [
      'Five lessons, each with one worked example.',
      'Printable grids are provided in three sizes.',
      'The final puzzle has exactly one solution. We checked. Twice.',
    ],
    tags: ['logic', 'course', 'puzzles'],
    facts: [WebFact('Lessons', '5'), WebFact('Puzzles', '42')],
    links: [
      WebLink('Number Nook: maths puzzles', 'number_nook'),
      WebLink('Dice & Daub: tabletop friends', 'dice_and_daub'),
      WebLink('Tiny Machines: build a puzzle box', 'tiny_machines'),
    ],
  ),
  WebSite(
    id: 'cozy_quests',
    name: 'Cozy Quests',
    domain: 'cozyquests.blog',
    category: 'Games',
    kind: WebKind.blog,
    tagline: 'Games that tuck you in.',
    headline: 'How to make a village feel lived in',
    summary:
        'A developer diary about benches, doorways, and the small details '
        'that turn a level into a place you want to return to.',
    bullets: [
      'The best decoration is a path worn into the grass.',
      'Every villager has a favorite bench, even if nobody uses it.',
      'The next update adds rain, umbrellas, and one shy cat.',
    ],
    tags: ['game design', 'diary', 'cozy'],
    facts: [WebFact('Posted', 'Sunday'), WebFact('Read time', '7 minutes')],
    links: [
      WebLink('Pixel Pasture: cozy gallery', 'pixel_pasture'),
      WebLink('Tiny Machines: prop builds', 'tiny_machines'),
      WebLink('Sketch Daily: environment art', 'sketch_daily'),
    ],
  ),
];

const List<WebSite> _musicSites = [
  WebSite(
    id: 'nightwave_fm',
    name: 'Nightwave FM',
    domain: 'nightwave.fm',
    category: 'Music',
    kind: WebKind.radio,
    tagline: 'Low lights, warm signal.',
    headline: 'Now playing: Harbor Lights, by The Long Way Home',
    summary:
        'A late-night station for slow drives and open windows. No ads, no '
        'shouting, just a DJ who sounds like they are reading a letter.',
    bullets: [
      'Live sets every night from 22:00 to 01:00.',
      'Requests are taken by electronic mail and carrier pigeon.',
      'The playlist is archived; the silences are not.',
    ],
    tags: ['radio', 'latenight', 'ambient'],
    facts: [
      WebFact('Listeners', '4,208'),
      WebFact('Signal', '88.3 FM'),
      WebFact('Genre', 'Slowcore'),
    ],
    links: [
      WebLink('Tape Rotation: album reviews', 'tape_rotation'),
      WebLink('Liner Notes: label archive', 'liner_notes'),
      WebLink('Bassment: louder station', 'bassment'),
    ],
  ),
  WebSite(
    id: 'tape_rotation',
    name: 'Tape Rotation',
    domain: 'taperotation.net',
    category: 'Music',
    kind: WebKind.blog,
    tagline: 'One album, many opinions.',
    headline: 'The cassette that survived a flood and a divorce',
    summary:
        'A review of a 1991 self-released album found in a box of soggy '
        'belongings, plus an interview with the bassist, now a dentist.',
    bullets: [
      'The tape still plays, though side B wobbles charmingly.',
      'The band reunited for one show in a laundromat.',
      'Download includes scans of the original handwritten sleeve.',
    ],
    tags: ['albums', 'reviews', 'cassette'],
    facts: [WebFact('Reviewed', '1,204 albums'), WebFact('Rating', '9.1 / 10')],
    links: [
      WebLink('Nightwave FM: late-night radio', 'nightwave_fm'),
      WebLink('Vinyl Vault: buy the reissue', 'vinyl_vault'),
      WebLink('Liner Notes: label history', 'liner_notes'),
    ],
  ),
  WebSite(
    id: 'bassment',
    name: 'Bassment',
    domain: 'bassment.club',
    category: 'Music',
    kind: WebKind.radio,
    tagline: 'The floor is moving. That is the point.',
    headline: 'Live from a basement: four hours of house',
    summary:
        'A community station broadcasting from a room with too many '
        'speakers and not enough ventilation. Every set is recorded.',
    bullets: [
      'Resident DJs rotate on Fridays; guests take Saturdays.',
      'Sets are archived for two weeks, then retired with honors.',
      'The station runs on donations and borrowed cables.',
    ],
    tags: ['house', 'live sets', 'community'],
    facts: [
      WebFact('BPM', '124'),
      WebFact('Speakers', '7'),
      WebFact('Ventilation', 'Optional'),
    ],
    links: [
      WebLink('Nightwave FM: after-hours', 'nightwave_fm'),
      WebLink('Chord Cafe: learn production', 'chord_cafe'),
      WebLink('Dice & Daub: game night playlists', 'dice_and_daub'),
    ],
  ),
  WebSite(
    id: 'liner_notes',
    name: 'Liner Notes',
    domain: 'linernotes.archive',
    category: 'Music',
    kind: WebKind.archive,
    tagline: 'The small print behind the big sound.',
    headline: 'Every sleeve note from a defunct jazz label',
    summary:
        'Scanned, transcribed, and searchable. The label released 312 records '
        'and folded in 1978; the notes are better than the sales figures.',
    bullets: [
      'Search by session musician, studio, or recording date.',
      'The archive includes 41 uncredited photographs.',
      'Volunteers are digitizing the master tapes next.',
    ],
    tags: ['jazz', 'archive', 'history'],
    facts: [WebFact('Records', '312'), WebFact('Scans', '6,004')],
    links: [
      WebLink('Tape Rotation: modern reviews', 'tape_rotation'),
      WebLink('Vinyl Vault: jazz reissues', 'vinyl_vault'),
      WebLink('Nightwave FM: nightly show', 'nightwave_fm'),
    ],
  ),
  WebSite(
    id: 'chord_cafe',
    name: 'Chord Cafe',
    domain: 'chordcafe.edu',
    category: 'Music',
    kind: WebKind.learn,
    tagline: 'Music theory with cake.',
    headline: 'Why four chords feel like home',
    summary:
        'A beginner-friendly tour of progressions: why some changes resolve, '
        'why others wander, and how to borrow a chord from a neighbor.',
    bullets: [
      'No notation required; audio examples for every idea.',
      'Six short lessons, each under ten minutes.',
      'The final exercise is to write one chorus. That is all.',
    ],
    tags: ['theory', 'beginner', 'course'],
    facts: [WebFact('Lessons', '6'), WebFact('Exercises', '18')],
    links: [
      WebLink('Bassment: hear it live', 'bassment'),
      WebLink('Tape Rotation: songwriting stories', 'tape_rotation'),
      WebLink('Pocket Professor: sound science', 'pocket_professor'),
    ],
  ),
  WebSite(
    id: 'vinyl_vault',
    name: 'Vinyl Vault',
    domain: 'vinylvault.shop',
    category: 'Music',
    kind: WebKind.shop,
    tagline: 'Records with history, sleeves with character.',
    headline: 'This week’s crate: quiet folk and loud sleeves',
    summary:
        'Twenty-nine records from one collection, all graded honestly and '
        'priced for people who actually play them.',
    bullets: [
      'Every record is play-tested and graded by hand.',
      'Shipping is free over \$50; crates are recycled.',
      'New arrivals every Wednesday at 09:00.',
    ],
    tags: ['vinyl', 'shop', 'collecting'],
    facts: [
      WebFact('In stock', '1,482'),
      WebFact('Grading', 'Honest, sometimes harsh'),
    ],
    products: [
      WebProduct('Harbor Lights — LP', 2800, '💿', 'Original 1991 pressing.'),
      WebProduct(
        'Basement Tapes — 2LP',
        3400,
        '🎚️',
        'Live set, slight crackle.',
      ),
      WebProduct('Sunday Folk — 7"', 1200, '🎵', 'Two songs, one regret.'),
    ],
    links: [
      WebLink('Tape Rotation: the review', 'tape_rotation'),
      WebLink('Liner Notes: label archive', 'liner_notes'),
      WebLink('Nightwave FM: request a track', 'nightwave_fm'),
    ],
  ),
];

const List<WebSite> _filmSites = [
  WebSite(
    id: 'silver_screen',
    name: 'Silver Screen',
    domain: 'silverscreen.reviews',
    category: 'Film',
    kind: WebKind.news,
    tagline: 'Reviews from the back row.',
    headline: 'A quiet film about a loud town wins the festival',
    summary:
        'Ninety minutes of conversations in kitchens, shot on 16 mm. The '
        'jury called it "a small miracle with excellent sound design".',
    bullets: [
      'The director sold her car to finish the final sound mix.',
      'Four of the five leads had never acted before.',
      'A wider release is planned for autumn, one screen at a time.',
    ],
    tags: ['reviews', 'festival', 'independent'],
    facts: [
      WebFact('Runtime', '94 min'),
      WebFact('Format', '16 mm'),
      WebFact('Rating', '★★★★☆'),
    ],
    links: [
      WebLink('Director’s Cut: interview', 'directors_cut'),
      WebLink('Lamplight Cinema: showtimes', 'lamplight_cinema'),
      WebLink('Matinee Map: filming locations', 'matinee_map'),
    ],
  ),
  WebSite(
    id: 'directors_cut',
    name: 'Director’s Cut',
    domain: 'directorscut.blog',
    category: 'Film',
    kind: WebKind.blog,
    tagline: 'Notes from behind the monitor.',
    headline: 'We built the kitchen before we wrote the argument',
    summary:
        'A production diary about shooting a family scene in a real house, '
        'with a real kettle, and a neighbor who kept mowing the lawn.',
    bullets: [
      'The kettle was louder than the dialogue, so we kept the kettle.',
      'The kitchen set now lives in the director’s garage.',
      'The lawn mower appears in the final cut, briefly and gloriously.',
    ],
    tags: ['production', 'diary', 'filmmaking'],
    facts: [WebFact('Shoot days', '18'), WebFact('Takes', 'Mostly 3')],
    links: [
      WebLink('Silver Screen: festival review', 'silver_screen'),
      WebLink('Prop House: the kettle', 'prop_house'),
      WebLink('Script Dust: early draft', 'script_dust'),
    ],
  ),
  WebSite(
    id: 'matinee_map',
    name: 'Matinee Map',
    domain: 'matineemap.gallery',
    category: 'Film',
    kind: WebKind.gallery,
    tagline: 'Places that played themselves.',
    headline: 'Six filming locations you can visit on a Sunday',
    summary:
        'A map of the coast through the movies: the pier, the diner, the '
        'stairs, and the bench where everything was almost said.',
    bullets: [
      'Each location includes bus routes and nearby coffee.',
      'The diner still serves the pie from the 1987 film.',
      'Photographs are welcome; tripods are not.',
    ],
    tags: ['locations', 'travel', 'photography'],
    facts: [WebFact('Locations', '6'), WebFact('Nearest bus', 'Line 4')],
    links: [
      WebLink('Lamplight Cinema: the season', 'lamplight_cinema'),
      WebLink('Slow Route: walk the coast', 'slow_route'),
      WebLink('Postcard Press: pier photos', 'postcard_press'),
    ],
  ),
  WebSite(
    id: 'prop_house',
    name: 'The Prop House',
    domain: 'prophouse.gallery',
    category: 'Film',
    kind: WebKind.gallery,
    tagline: 'Objects that stole the scene.',
    headline: 'Twelve props with better careers than their actors',
    summary:
        'The briefcase, the typewriter, the impossible staircase. A museum '
        'of objects that became more famous than the films around them.',
    bullets: [
      'Every entry lists the film, the maker, and the current owner.',
      'The briefcase is empty. We checked, carefully, with gloves.',
      'Submissions from collectors are welcome and thoroughly vetted.',
    ],
    tags: ['props', 'design', 'film history'],
    facts: [WebFact('Objects', '12'), WebFact('Loans', '3')],
    links: [
      WebLink('Movie Memory: prop quiz', 'movie_memory'),
      WebLink('Director’s Cut: the kettle story', 'directors_cut'),
      WebLink('Museum of Almost: odd collections', 'museum_of_almost'),
    ],
  ),
  WebSite(
    id: 'script_dust',
    name: 'Script Dust',
    domain: 'scriptdust.archive',
    category: 'Film',
    kind: WebKind.archive,
    tagline: 'Drafts that never made it to set.',
    headline: 'The first draft of a film everyone quotes',
    summary:
        'The original script had a different ending, a talking dog, and a '
        'much longer scene about parking. It is published here in full.',
    bullets: [
      'Compare the first and final drafts side by side.',
      'Annotations come from the script supervisor’s notebook.',
      'The talking dog was cut for budgetary and tonal reasons.',
    ],
    tags: ['scripts', 'archive', 'drafts'],
    facts: [WebFact('Pages', '148'), WebFact('Drafts', '7')],
    links: [
      WebLink('Silver Screen: the finished film', 'silver_screen'),
      WebLink('Page & Ink: screenwriting books', 'page_and_ink'),
      WebLink('Director’s Cut: production diary', 'directors_cut'),
    ],
  ),
];

const List<WebSite> _bookSites = [
  WebSite(
    id: 'page_and_ink',
    name: 'Page & Ink',
    domain: 'pageandink.blog',
    category: 'Books',
    kind: WebKind.blog,
    tagline: 'Reading slowly, on purpose.',
    headline: 'The book I keep buying and never finishing',
    summary:
        'A confession about a 900-page novel that has moved house with me '
        'three times and remains, stubbornly, at page 112.',
    bullets: [
      'The bookmark has not moved since 2019.',
      'Chapter four is genuinely wonderful. I remember it fondly.',
      'Recommendations for shorter books are welcome.',
    ],
    tags: ['reading', 'essay', 'books'],
    facts: [
      WebFact('Page', '112'),
      WebFact('Moves', '3'),
      WebFact('Years', '7'),
    ],
    links: [
      WebLink('Shelf Life: buy a shorter book', 'shelf_life'),
      WebLink('Margin Notes: reading group', 'margin_notes'),
      WebLink('Chapter One: first chapters', 'chapter_one'),
    ],
  ),
  WebSite(
    id: 'shelf_life',
    name: 'Shelf Life',
    domain: 'shelflife.books',
    category: 'Books',
    kind: WebKind.shop,
    tagline: 'Secondhand books with first-rate margins.',
    headline: 'A crate of paperbacks from a retired teacher',
    summary:
        'Three hundred books, many annotated, all smelling faintly of '
        'chalk and black tea. The notes are half the reason to buy them.',
    bullets: [
      'Every order includes a random bookmark from the shop jar.',
      'Books are graded by readability, not collectability.',
      'Local pickup saves the postage and gains you a biscuit.',
    ],
    tags: ['bookshop', 'secondhand', 'annotations'],
    facts: [WebFact('Titles', '3,012'), WebFact('Marginalia', 'Plentiful')],
    products: [
      WebProduct(
        'The Long Orchard',
        1400,
        '📗',
        'Paperback, underlined twice.',
      ),
      WebProduct(
        'A Field Guide to Clouds',
        1800,
        '📘',
        'Includes a pressed leaf.',
      ),
      WebProduct(
        'Collected Short Stories',
        1100,
        '📕',
        'Spine cracked, text intact.',
      ),
    ],
    links: [
      WebLink('Page & Ink: the unread confession', 'page_and_ink'),
      WebLink('Chapter One: opening lines', 'chapter_one'),
      WebLink('Poem Post: verse archive', 'poem_post'),
    ],
  ),
  WebSite(
    id: 'margin_notes',
    name: 'Margin Notes',
    domain: 'marginnotes.club',
    category: 'Books',
    kind: WebKind.forum,
    tagline: 'A reading group that never agrees.',
    headline: 'This month: the ending of a very divisive novel',
    summary:
        'Forty-seven readers, one ambiguous final chapter, and a poll that '
        'has been tied for eleven days. Spoilers are hidden behind a click.',
    bullets: [
      'Spoiler tags are enforced gently but firmly.',
      'The group reads one book a month and one short story a week.',
      'Meetings happen online, with tea and occasional arguing.',
    ],
    tags: ['book club', 'discussion', 'spoilers'],
    facts: [WebFact('Readers', '2,610'), WebFact('Poll', 'Tied')],
    links: [
      WebLink('Page & Ink: reading diary', 'page_and_ink'),
      WebLink('Poem Post: weekly poem', 'poem_post'),
      WebLink('Shelf Life: bookshop', 'shelf_life'),
    ],
  ),
  WebSite(
    id: 'poem_post',
    name: 'Poem Post',
    domain: 'poempost.lit',
    category: 'Books',
    kind: WebKind.archive,
    tagline: 'One poem, posted every morning.',
    headline: 'Archive: 2,400 mornings of verse',
    summary:
        'A daily poem project that started as a email to three friends and '
        'became a small, quiet institution. Every poem stays online.',
    bullets: [
      'Browse by season, theme, or the year you needed it most.',
      'Poems are short enough to read before the kettle boils.',
      'Submissions open for one week each spring.',
    ],
    tags: ['poetry', 'daily', 'archive'],
    facts: [WebFact('Poems', '2,400'), WebFact('Since', '2004')],
    links: [
      WebLink('Page & Ink: reading slowly', 'page_and_ink'),
      WebLink('Word Ladder: word puzzles', 'word_ladder'),
      WebLink('Pigment Press: art and text', 'pigment_press'),
    ],
  ),
  WebSite(
    id: 'chapter_one',
    name: 'Chapter One',
    domain: 'chapterone.learn',
    category: 'Books',
    kind: WebKind.learn,
    tagline: 'A writing course with its sleeves rolled up.',
    headline: 'How to start a story without clearing your throat',
    summary:
        'A practical lesson on openings: cut the weather, trust the reader, '
        'and begin where the trouble starts.',
    bullets: [
      'Three exercises, each designed to be finished in one sitting.',
      'Examples range from mystery novels to instruction manuals.',
      'Feedback circles run every second Tuesday.',
    ],
    tags: ['writing', 'course', 'craft'],
    facts: [WebFact('Lessons', '8'), WebFact('Exercises', '24')],
    links: [
      WebLink('Script Dust: film drafts', 'script_dust'),
      WebLink('Poem Post: short forms', 'poem_post'),
      WebLink('Pigment Press: illustrated stories', 'pigment_press'),
    ],
  ),
];

const List<WebSite> _foodSites = [
  WebSite(
    id: 'skillet_club',
    name: 'The Skillet Club',
    domain: 'skilletclub.cooking',
    category: 'Food',
    kind: WebKind.blog,
    tagline: 'Dinner, without the drama.',
    headline: 'One pan, five nights, no leftovers',
    summary:
        'A week of dinners built from the same base: onions, a sturdy pan, '
        'and whatever the market had too much of on Monday.',
    bullets: [
      'Monday’s roast vegetables become Thursday’s soup.',
      'The shopping list totals \$31 and fits on a receipt.',
      'Every recipe includes a "too tired to cook" shortcut.',
    ],
    tags: ['recipes', 'weeknight', 'budget'],
    facts: [
      WebFact('Recipes', '5'),
      WebFact('Total cost', '\$31'),
      WebFact('Pans', '1'),
    ],
    links: [
      WebLink('Proof & Crumb: bread for the week', 'proof_and_crumb'),
      WebLink('Night Market: shopping list', 'night_market'),
      WebLink('Tiny Kitchen: small-space tips', 'tiny_kitchen'),
    ],
  ),
  WebSite(
    id: 'proof_and_crumb',
    name: 'Proof & Crumb',
    domain: 'proofandcrumb.bake',
    category: 'Food',
    kind: WebKind.blog,
    tagline: 'Flour, water, patience, repeat.',
    headline: 'The sourdough starter that survived a heatwave',
    summary:
        'A jar, a spoon, and a week of questionable smells. The starter '
        'made it; the kitchen thermometer did not.',
    bullets: [
      'Feed it once a day and it will forgive most mistakes.',
      'The heatwave bake had a tighter crumb and a better story.',
      'A printable feeding chart is tucked at the bottom of the post.',
    ],
    tags: ['baking', 'sourdough', 'diary'],
    facts: [WebFact('Starter age', '4 years'), WebFact('Hydration', '72%')],
    links: [
      WebLink('Skillet Club: use the loaf', 'skillet_club'),
      WebLink('Pier Market: local flour', 'pier_market'),
      WebLink('Bean Counter: food science', 'bean_counter'),
    ],
  ),
  WebSite(
    id: 'night_market',
    name: 'Night Market',
    domain: 'nightmarket.food',
    category: 'Food',
    kind: WebKind.shop,
    tagline: 'Open when the restaurants close.',
    headline: 'This week’s stall: noodles, pickles, and strange jam',
    summary:
        'A rotating shop from a real night market. Everything is packed to '
        'travel and labeled with the stallholder’s name.',
    bullets: [
      'Orders placed before 18:00 go out the same evening.',
      'Every jar comes with a suggestion, never an instruction.',
      'The strange jam is plum and black pepper. It is excellent.',
    ],
    tags: ['market', 'pantry', 'small batch'],
    facts: [WebFact('Stalls', '6'), WebFact('Delivery', 'Same night')],
    products: [
      WebProduct('Chili Oil, Mild', 900, '🌶️', 'Fragrant, not punishing.'),
      WebProduct(
        'Plum & Pepper Jam',
        1100,
        '🫙',
        'Good with cheese, better with toast.',
      ),
      WebProduct(
        'Hand-Pulled Noodles',
        1300,
        '🍜',
        'Two portions, five minutes.',
      ),
    ],
    links: [
      WebLink('Skillet Club: weeknight recipes', 'skillet_club'),
      WebLink('Soup of the Day: late supper', 'soup_of_day'),
      WebLink('Pier Market: Saturday stalls', 'pier_market'),
    ],
  ),
  WebSite(
    id: 'soup_of_day',
    name: 'Soup of the Day',
    domain: 'soupoftheday.kitchen',
    category: 'Food',
    kind: WebKind.blog,
    tagline: 'A pot, a plan, a little patience.',
    headline: 'The soup that tastes like a Sunday afternoon',
    summary:
        'A simple broth with too many onions and a parmesan rind. The kind '
        'of recipe you learn once and then stop measuring.',
    bullets: [
      'The rind is not optional; it is the whole point.',
      'Freezes well for three months, or one busy week.',
      'Serve with bread that is slightly too warm to slice.',
    ],
    tags: ['soup', 'comfort', 'recipe'],
    facts: [
      WebFact('Simmer', '45 minutes'),
      WebFact('Serves', '4, generously'),
    ],
    links: [
      WebLink('Proof & Crumb: the bread', 'proof_and_crumb'),
      WebLink('Tiny Kitchen: one-pot meals', 'tiny_kitchen'),
      WebLink('Frugal Kitchen: pantry basics', 'frugal_kitchen'),
    ],
  ),
  WebSite(
    id: 'tiny_kitchen',
    name: 'Tiny Kitchen',
    domain: 'tinykitchen.learn',
    category: 'Food',
    kind: WebKind.learn,
    tagline: 'Big meals from very small counters.',
    headline: 'Cooking well with one burner and no oven',
    summary:
        'A practical course for rented rooms, tiny flats, and kitchens that '
        'double as offices. Constraint is the curriculum.',
    bullets: [
      'Every lesson includes a shopping list for one person.',
      'Equipment is limited to a pan, a pot, and a sharp knife.',
      'The final project is a dinner for three in under an hour.',
    ],
    tags: ['small spaces', 'course', 'cooking'],
    facts: [WebFact('Lessons', '5'), WebFact('Equipment', '3 items')],
    links: [
      WebLink('Skillet Club: one-pan dinners', 'skillet_club'),
      WebLink('Soup of the Day: pot cooking', 'soup_of_day'),
      WebLink('Corner Plot: windowsill herbs', 'corner_plot'),
    ],
  ),
  WebSite(
    id: 'bean_counter',
    name: 'Bean Counter',
    domain: 'beancounter.wiki',
    category: 'Food',
    kind: WebKind.wiki,
    tagline: 'The facts behind the flavour.',
    headline: 'Why onions make you cry (and how to stop)',
    summary:
        'A patient explanation of sulfur compounds, sharp knives, and the '
        'surprisingly effective trick of chilling an onion first.',
    bullets: [
      'A sharp knife does more than a cold onion, but both help.',
      'The tears are a defense mechanism, not a personal insult.',
      'Cooking tames the compounds and sweetens the result.',
    ],
    tags: ['food science', 'onions', 'explainer'],
    facts: [
      WebFact('Compound', 'Syn-propanethial-S-oxide'),
      WebFact('Chill time', '15 minutes'),
    ],
    links: [
      WebLink('Soup of the Day: put it to use', 'soup_of_day'),
      WebLink('Tiny Kitchen: knife skills', 'tiny_kitchen'),
      WebLink('Lab Window: chemistry news', 'lab_window'),
    ],
  ),
];

const List<WebSite> _sportSites = [
  WebSite(
    id: 'final_whistle',
    name: 'Final Whistle',
    domain: 'finalwhistle.sport',
    category: 'Sport',
    kind: WebKind.news,
    tagline: 'The score, then the story.',
    headline: 'Harbor Town held to a draw by a team of teenagers',
    summary:
        'A youthful midfield ran the show for eighty minutes. Harbor Town '
        'equalized in stoppage time and looked relieved to escape.',
    bullets: [
      'The visitors fielded four players under nineteen.',
      'Harbor’s captain limped off at halftime but returned for the last ten.',
      'Next fixture is away, on a pitch with a noticeable slope.',
    ],
    tags: ['football', 'match report', 'local'],
    facts: [
      WebFact('Score', '2–2'),
      WebFact('Attendance', '1,104'),
      WebFact('Pitch', 'Slightly uphill'),
    ],
    links: [
      WebLink('The Sideline: keeper story', 'the_sideline'),
      WebLink('Pace Line: tactical notes', 'pace_line'),
      WebLink('Weekend League: full table', 'weekend_league'),
    ],
  ),
  WebSite(
    id: 'pace_line',
    name: 'Pace Line',
    domain: 'paceline.blog',
    category: 'Sport',
    kind: WebKind.blog,
    tagline: 'Cycling, mostly uphill.',
    headline: 'The hill that teaches you to pace',
    summary:
        'A climb of 2.4 kilometers, average gradient seven percent, and one '
        'lesson: start slower than feels sensible.',
    bullets: [
      'The first kilometer is a trap; ignore it.',
      'Gearing matters less than breathing rhythm.',
      'The café at the top closes at four, so start early.',
    ],
    tags: ['cycling', 'training', 'routes'],
    facts: [
      WebFact('Distance', '2.4 km'),
      WebFact('Gradient', '7%'),
      WebFact('Café', 'Closes 16:00'),
    ],
    links: [
      WebLink('Sport Stat Pitch: rider data', 'stat_pitch'),
      WebLink('Slow Route: coastal paths', 'slow_route'),
      WebLink('Move Daily: mobility work', 'move_daily'),
    ],
  ),
  WebSite(
    id: 'stat_pitch',
    name: 'Stat Pitch',
    domain: 'statpitch.wiki',
    category: 'Sport',
    kind: WebKind.wiki,
    tagline: 'Numbers for people who watch the game twice.',
    headline: 'Expected goals, explained without the spreadsheet',
    summary:
        'A clear guide to the metric everyone quotes and few define. What '
        'it measures, what it misses, and when to ignore it entirely.',
    bullets: [
      'A tap-in and a thirty-yard volley are not the same chance.',
      'xG describes the average shooter, not the one you are watching.',
      'The glossary links every term to a worked example.',
    ],
    tags: ['analytics', 'football', 'explainer'],
    facts: [WebFact('Terms', '84'), WebFact('Examples', '120')],
    links: [
      WebLink('Final Whistle: match reports', 'final_whistle'),
      WebLink('Pace Line: training diary', 'pace_line'),
      WebLink('OpenBench: data methods', 'openbench'),
    ],
  ),
  WebSite(
    id: 'weekend_league',
    name: 'Weekend League',
    domain: 'weekendleague.local',
    category: 'Sport',
    kind: WebKind.news,
    tagline: 'Grassroots fixtures, rain or shine.',
    headline: 'Title race goes to the last weekend',
    summary:
        'Three teams can still win the league. Two of them play each other, '
        'and the third is away to the team that has not lost since January.',
    bullets: [
      'All fixtures kick off at 14:00 on Saturday.',
      'The league needs two volunteer linesmen. Free tea provided.',
      'Results are posted here by 18:00, usually.',
    ],
    tags: ['fixtures', 'grassroots', 'local'],
    facts: [WebFact('Teams', '12'), WebFact('Matchday', 'Saturday')],
    links: [
      WebLink('Final Whistle: first team news', 'final_whistle'),
      WebLink('The Sideline: keeper interview', 'the_sideline'),
      WebLink('Harbor Bulletin: club notices', 'harbor_bulletin'),
    ],
  ),
];

const List<WebSite> _travelSites = [
  WebSite(
    id: 'slow_route',
    name: 'Slow Route',
    domain: 'slowroute.travel',
    category: 'Travel',
    kind: WebKind.blog,
    tagline: 'The long way, on purpose.',
    headline: 'A coastal walk with no timetable',
    summary:
        'Three days, two villages, one bus that arrives when it arrives. A '
        'notebook from a walk along the invisible edge of the map.',
    bullets: [
      'The path is marked with painted stones, not signs.',
      'There is exactly one place to eat after 18:00.',
      'Bring a rain jacket and no expectations.',
    ],
    tags: ['walking', 'coast', 'notebook'],
    facts: [
      WebFact('Distance', '38 km'),
      WebFact('Days', '3'),
      WebFact('Buses', 'Whenever'),
    ],
    links: [
      WebLink('Postcard Press: coast gallery', 'postcard_press'),
      WebLink('Platform Nine: train times', 'platform_nine'),
      WebLink('Hostel Notes: where to sleep', 'hostel_notes'),
    ],
  ),
  WebSite(
    id: 'platform_nine',
    name: 'Platform Nine',
    domain: 'platformnine.archive',
    category: 'Travel',
    kind: WebKind.archive,
    tagline: 'Timetables, tickets, and small adventures.',
    headline: 'The branch line that survived three closure notices',
    summary:
        'A photographic history of a railway that nobody expected to last, '
        'told through tickets, signs, and the people who kept it running.',
    bullets: [
      'The archive includes every timetable since 1954.',
      'The station cat has its own folder, meticulously dated.',
      'A restored waiting room opens on summer weekends.',
    ],
    tags: ['railways', 'history', 'archive'],
    facts: [WebFact('Timetables', '72'), WebFact('Stations', '9')],
    links: [
      WebLink('Slow Route: walk from the station', 'slow_route'),
      WebLink('Lamplight Cinema: coastal films', 'lamplight_cinema'),
      WebLink('Neighbors Almanac: branch line news', 'neighbors_almanac'),
    ],
  ),
  WebSite(
    id: 'postcard_press',
    name: 'Postcard Press',
    domain: 'postcardpress.photos',
    category: 'Travel',
    kind: WebKind.gallery,
    tagline: 'Wish you were here. We are.',
    headline: 'Postcards from towns with one traffic light',
    summary:
        'A gallery of small places photographed at the hour when the light '
        'is good and the streets are almost empty.',
    bullets: [
      'Each postcard includes the time of day and the reason for visiting.',
      'Prints are made locally and shipped in a rigid envelope.',
      'Submissions are open to anyone with a camera and a bus ticket.',
    ],
    tags: ['photography', 'small towns', 'gallery'],
    facts: [WebFact('Postcards', '340'), WebFact('Towns', '87')],
    links: [
      WebLink('Slow Route: the walk', 'slow_route'),
      WebLink('Matinee Map: filming spots', 'matinee_map'),
      WebLink('Tide Pool: coastal close-ups', 'tide_pool'),
    ],
  ),
  WebSite(
    id: 'hostel_notes',
    name: 'Hostel Notes',
    domain: 'hostelnotes.club',
    category: 'Travel',
    kind: WebKind.forum,
    tagline: 'Honest beds, honest reviews.',
    headline: 'Which hostel has the best kitchen, really?',
    summary:
        'A thread comparing communal kitchens across forty cities. The '
        'answers are specific, opinionated, and occasionally alarming.',
    bullets: [
      'Reviews must mention the state of the shared fridge.',
      'The community maintains a quiet-hostel map for light sleepers.',
      'No affiliate links. Recommendations cannot be bought.',
    ],
    tags: ['hostels', 'reviews', 'travel'],
    facts: [WebFact('Reviews', '7,402'), WebFact('Cities', '40')],
    links: [
      WebLink('Slow Route: coastal itinerary', 'slow_route'),
      WebLink('Night Market: late food', 'night_market'),
      WebLink('Platform Nine: rail archive', 'platform_nine'),
    ],
  ),
];

const List<WebSite> _homeSites = [
  WebSite(
    id: 'corner_plot',
    name: 'Corner Plot',
    domain: 'cornerplot.garden',
    category: 'Home',
    kind: WebKind.blog,
    tagline: 'A garden the size of a rug.',
    headline: 'Everything I learned from three pots and a windowsill',
    summary:
        'A year of growing herbs, one stubborn tomato, and a radish that '
        'achieved sentience. Small-space gardening without the smugness.',
    bullets: [
      'Basil wants more sun than the packet admits.',
      'The tomato was happier when I stopped helping.',
      'A saucer of water beats a fancy watering can.',
    ],
    tags: ['gardening', 'small spaces', 'diary'],
    facts: [WebFact('Pots', '3'), WebFact('Harvest', 'Mostly basil')],
    links: [
      WebLink('Tiny Kitchen: cook the herbs', 'tiny_kitchen'),
      WebLink('Field Notes: seasonal guide', 'field_notes'),
      WebLink('Linen & Light: balcony styling', 'linen_and_light'),
    ],
  ),
  WebSite(
    id: 'fix_it_room',
    name: 'The Fix-It Room',
    domain: 'fixitroom.learn',
    category: 'Home',
    kind: WebKind.learn,
    tagline: 'Repair is a skill, not a personality.',
    headline: 'Start with a loose hinge, not a broken heart',
    summary:
        'A beginner’s course in household repair: tighten, clean, lubricate, '
        'and know when to stop before the screw strips.',
    bullets: [
      'Five lessons covering hinges, taps, lamps, and squeaks.',
      'Every lesson lists the tools and the likely mistakes.',
      'No project requires a workshop or a heroic budget.',
    ],
    tags: ['repair', 'course', 'home'],
    facts: [WebFact('Lessons', '5'), WebFact('Tools', '6 basics')],
    links: [
      WebLink('Repair Radar: tool library', 'repair_radar'),
      WebLink('Shelf Help: mounting shelves', 'shelf_help'),
      WebLink('Penny Ledger: repair vs replace', 'penny_ledger'),
    ],
  ),
  WebSite(
    id: 'shelf_help',
    name: 'Shelf Help',
    domain: 'shelfhelp.club',
    category: 'Home',
    kind: WebKind.forum,
    tagline: 'Measure twice, ask the internet once.',
    headline: 'How do I hang shelves in a wall I do not understand?',
    summary:
        'A patient thread about stud finders, plaster, and the difference '
        'between "probably fine" and "definitely anchored".',
    bullets: [
      'Photos of your wall are more useful than a paragraph of panic.',
      'The community keeps a list of trusted local handypeople.',
      'Rental-friendly solutions get their own tag.',
    ],
    tags: ['diy', 'shelves', 'rentals'],
    facts: [
      WebFact('Members', '8,220'),
      WebFact('Shelves hung', 'Unknown, but many'),
    ],
    links: [
      WebLink('Fix It Room: repair basics', 'fix_it_room'),
      WebLink('Linen & Light: shelf styling', 'linen_and_light'),
      WebLink('Corner Plot: windowsill shelves', 'corner_plot'),
    ],
  ),
  WebSite(
    id: 'linen_and_light',
    name: 'Linen & Light',
    domain: 'linenandlight.shop',
    category: 'Home',
    kind: WebKind.shop,
    tagline: 'Soft things for hard-working rooms.',
    headline: 'The small-batch textiles shop upstairs',
    summary:
        'Tea towels, cushion covers, and one very good apron, woven in a '
        'workshop above the shop. Colors are named after weather.',
    bullets: [
      'Every piece is cut and sewn within ten kilometers of the shop.',
      'Seconds are sold at cost, with the flaw described honestly.',
      'Orders are wrapped in reused paper and tied with string.',
    ],
    tags: ['textiles', 'home', 'small batch'],
    facts: [
      WebFact('Made in', 'The upstairs room'),
      WebFact('Fabrics', 'Linen, cotton'),
    ],
    products: [
      WebProduct('Tea Towel, Fog', 1600, '🧺', 'Absorbent, slightly moody.'),
      WebProduct(
        'Cushion Cover, Dusk',
        3200,
        '🪡',
        'Hidden zip, visible charm.',
      ),
      WebProduct('Apron, Wet Stone', 4800, '🥣', 'Two pockets, one good knot.'),
    ],
    links: [
      WebLink('Corner Plot: balcony makeover', 'corner_plot'),
      WebLink('Shelf Help: hanging textiles', 'shelf_help'),
      WebLink('Pier Market: Saturday stall', 'pier_market'),
    ],
  ),
];

const List<WebSite> _moneySites = [
  WebSite(
    id: 'penny_ledger',
    name: 'Penny Ledger',
    domain: 'pennyledger.money',
    category: 'Money',
    kind: WebKind.blog,
    tagline: 'Small numbers, carefully watched.',
    headline: 'The envelope system, but for people with phones',
    summary:
        'A practical budget method for irregular income: four envelopes, '
        'one boring spreadsheet, and a monthly walk to the bank.',
    bullets: [
      'The first envelope is rent. It does not negotiate.',
      'The fun envelope is real; deprivation budgets fail.',
      'A printable ledger is included for the analog-minded.',
    ],
    tags: ['budgeting', 'personal finance', 'practical'],
    facts: [WebFact('Envelopes', '4'), WebFact('Months tested', '26')],
    links: [
      WebLink('Compound Club: saving course', 'compound_club'),
      WebLink('Frugal Kitchen: food budget', 'frugal_kitchen'),
      WebLink('Market Bell: price index', 'market_bell'),
    ],
  ),
  WebSite(
    id: 'compound_club',
    name: 'Compound Club',
    domain: 'compoundclub.learn',
    category: 'Money',
    kind: WebKind.learn,
    tagline: 'Interest, explained without a suit.',
    headline: 'A five-lesson course in letting money sit still',
    summary:
        'No hot tips, no crypto, no yacht. Just how compounding works, why '
        'fees matter, and how to start with an amount that feels small.',
    bullets: [
      'Lesson one begins with \$10 and a calendar.',
      'Every example shows the boring arithmetic in full.',
      'The course is free; the calculator is a spreadsheet.',
    ],
    tags: ['saving', 'interest', 'course'],
    facts: [WebFact('Lessons', '5'), WebFact('Maths', 'Shown')],
    links: [
      WebLink('Penny Ledger: budgeting', 'penny_ledger'),
      WebLink('Market Microscope: market news', 'market_microscope'),
      WebLink('Pocket Professor: numbers primer', 'pocket_professor'),
    ],
  ),
  WebSite(
    id: 'market_microscope',
    name: 'Market Microscope',
    domain: 'marketmicroscope.biz',
    category: 'Money',
    kind: WebKind.news,
    tagline: 'The economy, up close.',
    headline: 'Why the price of a haircut never goes back down',
    summary:
        'A short explainer on sticky prices: the barber, the landlord, and '
        'the menu at the café all have reasons not to move first.',
    bullets: [
      'Prices are stories people tell about the future.',
      'The café raised its prices once and never mentioned it again.',
      'Nobody in this article is a villain, which is the interesting part.',
    ],
    tags: ['economy', 'prices', 'explainer'],
    facts: [
      WebFact('Read time', '4 minutes'),
      WebFact('Sources', '3 economists, 1 barber'),
    ],
    links: [
      WebLink('Market Bell: local index', 'market_bell'),
      WebLink('Penny Ledger: household budget', 'penny_ledger'),
      WebLink('Wire Eleven: world markets', 'wire_eleven'),
    ],
  ),
  WebSite(
    id: 'frugal_kitchen',
    name: 'Frugal Kitchen',
    domain: 'frugalkitchen.wiki',
    category: 'Money',
    kind: WebKind.wiki,
    tagline: 'Good food, sensible arithmetic.',
    headline: 'The cheapest seven meals in the house',
    summary:
        'Beans, rice, eggs, cabbage, and the many ways they can pretend not '
        'to be the same dinner. Costs are calculated per portion.',
    bullets: [
      'Every recipe is costed at current market prices.',
      'The bean page has been updated 41 times since 2019.',
      'Nothing here requires a special ingredient you will use once.',
    ],
    tags: ['budget', 'cooking', 'reference'],
    facts: [WebFact('Meals', '7'), WebFact('Cost / portion', '\$1.10–\$2.40')],
    links: [
      WebLink('Skillet Club: weeknight dinners', 'skillet_club'),
      WebLink('Penny Ledger: envelope budget', 'penny_ledger'),
      WebLink('Night Market: pantry restock', 'night_market'),
    ],
  ),
];

const List<WebSite> _natureSites = [
  WebSite(
    id: 'moss_map',
    name: 'Moss Map',
    domain: 'mossmap.wiki',
    category: 'Nature',
    kind: WebKind.wiki,
    tagline: 'Small green things, carefully described.',
    headline: 'The moss on the north side of your wall',
    summary:
        'A field guide to the plants that grow where the light is thin and '
        'the rain stays a while. Identification starts with a photograph.',
    bullets: [
      'Mosses have no roots; they drink through their leaves.',
      'The same wall can host six species in six patches.',
      'A hand lens is more useful than a camera here.',
    ],
    tags: ['moss', 'field guide', 'identification'],
    facts: [
      WebFact('Species', '124'),
      WebFact('Habitat', 'Shade, damp, patience'),
    ],
    links: [
      WebLink('Field Notes: seasonal diary', 'field_notes'),
      WebLink('Field Trip: noticing course', 'field_trip'),
      WebLink('Tide Pool: coastal life', 'tide_pool'),
    ],
  ),
  WebSite(
    id: 'bird_call',
    name: 'Bird Call',
    domain: 'birdcall.radio',
    category: 'Nature',
    kind: WebKind.radio,
    tagline: 'The dawn chorus, on demand.',
    headline: 'Now playing: a morning in the reed beds',
    summary:
        'Forty minutes of unedited field recording: water, wind, and an '
        'argument between two very small birds.',
    bullets: [
      'Recordings are dated and geotagged with the recorder’s permission.',
      'The archive includes a quiet version for sleeping.',
      'Headphones reveal three layers you will miss on a phone speaker.',
    ],
    tags: ['birdsong', 'field recording', 'ambient'],
    facts: [
      WebFact('Recorded', '05:12'),
      WebFact('Length', '41 min'),
      WebFact('Microphones', '2'),
    ],
    links: [
      WebLink('Moss Map: wall life', 'moss_map'),
      WebLink('Field Notes: what to look for', 'field_notes'),
      WebLink('Tide Pool: coastal sounds', 'tide_pool'),
    ],
  ),
  WebSite(
    id: 'tide_pool',
    name: 'Tide Pool',
    domain: 'tidepool.photo',
    category: 'Nature',
    kind: WebKind.gallery,
    tagline: 'A world that appears twice a day.',
    headline: 'Six small creatures in one square meter',
    summary:
        'Anemones, crabs, and a snail with strong opinions about property. '
        'Photographed at low tide, returned exactly where found.',
    bullets: [
      'Every image notes the tide height and the time.',
      'The photographer works with a local marine survey.',
      'Never move a rock you cannot put back the same way.',
    ],
    tags: ['coast', 'marine life', 'photography'],
    facts: [WebFact('Tide', '0.4 m'), WebFact('Species', '6')],
    links: [
      WebLink('Moss Map: field guide', 'moss_map'),
      WebLink('Quiet Press: lighthouse story', 'quiet_press'),
      WebLink('Postcard Press: coast towns', 'postcard_press'),
    ],
  ),
  WebSite(
    id: 'field_notes',
    name: 'Field Notes',
    domain: 'fieldnotes.diary',
    category: 'Nature',
    kind: WebKind.blog,
    tagline: 'One walk, written down.',
    headline: 'The week the swallows came back',
    summary:
        'A dated entry from a kitchen window: first arrivals, nest repairs, '
        'and the cat being firmly asked to reconsider her hobbies.',
    bullets: [
      'Arrival dates are within two days of last year’s.',
      'The nest under the eaves has been rebuilt three times.',
      'The cat has been issued a strongly worded look.',
    ],
    tags: ['birds', 'diary', 'seasons'],
    facts: [WebFact('First seen', 'Tuesday, 07:20'), WebFact('Nests', '3')],
    links: [
      WebLink('Bird Call: listen to the chorus', 'bird_call'),
      WebLink('Moss Map: garden life', 'moss_map'),
      WebLink('Weather Window: week ahead', 'weather_window'),
    ],
  ),
];

const List<WebSite> _localSites = [
  WebSite(
    id: 'harbor_bulletin',
    name: 'Harbor Bulletin',
    domain: 'harborbulletin.local',
    category: 'Local',
    kind: WebKind.news,
    tagline: 'Notices from the noticeboard.',
    headline: 'Lost cat found asleep in the ferry ticket office',
    summary:
        'A black cat with a red collar spent two nights behind the ticket '
        'counter. Staff have named him Inspector and deny feeding him.',
    bullets: [
      'The owner was reunited with the cat on Wednesday morning.',
      'Inspector has been given a cardboard box and a job title.',
      'The ferry office asks that future visitors bring no additional cats.',
    ],
    tags: ['noticeboard', 'local', 'animals'],
    facts: [
      WebFact('Missing', '2 nights'),
      WebFact('Treats', 'Denied, suspiciously'),
    ],
    links: [
      WebLink('Harbor Herald: ferry news', 'harbor_herald'),
      WebLink('Neighbors Almanac: community diary', 'neighbors_almanac'),
      WebLink('Pier Market: the ticket office café', 'pier_market'),
    ],
  ),
  WebSite(
    id: 'lamplight_cinema',
    name: 'Lamplight Cinema',
    domain: 'lamplightcinema.local',
    category: 'Local',
    kind: WebKind.archive,
    tagline: 'One screen, many decades.',
    headline: 'This month’s repertory season, on paper',
    summary:
        'The cinema’s hand-drawn posters, scanned and dated. Every screening '
        'since 1962, including the night the projector caught fire.',
    bullets: [
      'Posters are searchable by year and by accidentally funny typo.',
      'The 1998 season was programmed entirely by a raffle.',
      'Tickets are still printed on the same pink paper.',
    ],
    tags: ['cinema', 'posters', 'local history'],
    facts: [
      WebFact('Screenings', '4,188'),
      WebFact('Seats', '112'),
      WebFact('Projector', 'New, finally'),
    ],
    links: [
      WebLink('Silver Screen: reviews', 'silver_screen'),
      WebLink('Matinee Map: filming locations', 'matinee_map'),
      WebLink('Platform Nine: how to get here', 'platform_nine'),
    ],
  ),
  WebSite(
    id: 'pier_market',
    name: 'Pier Market',
    domain: 'piermarket.local',
    category: 'Local',
    kind: WebKind.shop,
    tagline: 'Saturday mornings, salt in the air.',
    headline: 'The stalls opening this weekend',
    summary:
        'Bread, butter, bruised apples, and a fishmonger who will tell you '
        'exactly what to do with the strange-looking one.',
    bullets: [
      'Pre-orders close on Friday at noon.',
      'Bring your own bag; the market has run out again.',
      'The bakery’s second batch arrives at 09:30 sharp.',
    ],
    tags: ['market', 'local food', 'weekend'],
    facts: [WebFact('Stalls', '14'), WebFact('Opens', 'Saturday 08:00')],
    products: [
      WebProduct('Country Loaf', 600, '🍞', 'Baked at 05:00, gone by 11:00.'),
      WebProduct('Salted Butter', 700, '🧈', 'Wrapped in wax paper.'),
      WebProduct('Bruised Apple Bag', 400, '🍎', 'Perfect for a crumble.'),
    ],
    links: [
      WebLink('Proof & Crumb: use the loaf', 'proof_and_crumb'),
      WebLink('Harbor Bulletin: market notices', 'harbor_bulletin'),
      WebLink('Harbor Herald: ferry times', 'harbor_herald'),
    ],
  ),
  WebSite(
    id: 'town_hall_live',
    name: 'Town Hall Live',
    domain: 'townhalllive.gov',
    category: 'Local',
    kind: WebKind.news,
    tagline: 'Local government, without the fog.',
    headline: 'Council approves the bench strategy, finally',
    summary:
        'After eighteen months and four consultations, the town now has a '
        'plan for where to put benches. The first one arrives in June.',
    bullets: [
      'The plan includes shade, armrests, and one bench facing the sea.',
      'Two residents asked for more bins; the council agreed.',
      'Meetings are streamed live and archived with searchable minutes.',
    ],
    tags: ['council', 'local government', 'benches'],
    facts: [
      WebFact('Consultations', '4'),
      WebFact('Benches', '26 planned'),
      WebFact('Next meeting', 'Tuesday 19:00'),
    ],
    links: [
      WebLink('Civic Ledger: full minutes', 'civic_ledger'),
      WebLink('Neighbors Almanac: ward notes', 'neighbors_almanac'),
      WebLink('Harbor Herald: the bench debate', 'harbor_herald'),
    ],
  ),
  WebSite(
    id: 'neighbors_almanac',
    name: 'Neighbors Almanac',
    domain: 'neighborsalmanac.local',
    category: 'Local',
    kind: WebKind.blog,
    tagline: 'Who is doing what, and when.',
    headline: 'The street party checklist nobody follows',
    summary:
        'A cheerful, slightly chaotic guide to the annual street party: '
        'borrowed tables, disputed playlists, and the cake raffle.',
    bullets: [
      'The road closes at noon; the bunting goes up at eleven.',
      'This year’s playlist is being negotiated in the comments.',
      'Bring a chair, a plate, and a tolerant attitude to weather.',
    ],
    tags: ['community', 'events', 'street life'],
    facts: [WebFact('Tables', '9 borrowed'), WebFact('Raffle', '3 cakes')],
    links: [
      WebLink('Harbor Bulletin: notices', 'harbor_bulletin'),
      WebLink('Pier Market: supplies', 'pier_market'),
      WebLink('Lamplight Cinema: evening screening', 'lamplight_cinema'),
    ],
  ),
];

const List<WebSite> _weirdSites = [
  WebSite(
    id: 'cryptid_times',
    name: 'Cryptid Times',
    domain: 'cryptidtimes.news',
    category: 'Weird',
    kind: WebKind.news,
    tagline: 'Sightings, skeptics, and very blurry photos.',
    headline: 'The lake monster is probably a log, says log expert',
    summary:
        'A retired forester has identified the shape in the latest photograph. '
        'The monster society says the log is "unusually mobile".',
    bullets: [
      'The photograph was taken from a moving bus in the rain.',
      'Local tourism has doubled since the sighting.',
      'The forester has offered to examine the lake in person.',
    ],
    tags: ['cryptids', 'sightings', 'humor'],
    facts: [WebFact('Sightings', '61'), WebFact('Confirmed logs', '60')],
    links: [
      WebLink('Unexplained Post: case files', 'unexplained_post'),
      WebLink('Museum of Almost: odd specimens', 'museum_of_almost'),
      WebLink('Conspiracy Tea: lively thread', 'conspiracy_tea'),
    ],
  ),
  WebSite(
    id: 'museum_of_almost',
    name: 'Museum of Almost',
    domain: 'museumofalmost.org',
    category: 'Weird',
    kind: WebKind.gallery,
    tagline: 'Objects that nearly changed the world.',
    headline: 'The almost-bicycle, the almost-bridge, and a very odd spoon',
    summary:
        'A collection of prototypes, failed patents, and inventions that '
        'were one small decision away from being everywhere.',
    bullets: [
      'Every object has a label written by the person who found it.',
      'The spoon was designed for soup; it works better for jam.',
      'The museum is open in a garage by appointment.',
    ],
    tags: ['inventions', 'prototypes', 'museum'],
    facts: [WebFact('Objects', '212'), WebFact('Open', 'By appointment')],
    links: [
      WebLink('Byte Bazaar: mystery boards', 'byte_bazaar'),
      WebLink('Cryptid Times: the lake log', 'cryptid_times'),
      WebLink('Prop House: film objects', 'prop_house'),
    ],
  ),
  WebSite(
    id: 'glitch_garden',
    name: 'Glitch Garden',
    domain: 'glitchgarden.art',
    category: 'Weird',
    kind: WebKind.gallery,
    tagline: 'Beautiful mistakes, grown on purpose.',
    headline: 'Twelve images made by breaking a scanner',
    summary:
        'The artist fed photographs, leaves, and a slice of bread through a '
        'flatbed scanner until it started making its own decisions.',
    bullets: [
      'No image has been retouched; the scanner did the work.',
      'The bread image is the most popular and the least appetizing.',
      'Prints are made in editions of nine.',
    ],
    tags: ['glitch', 'art', 'scanner'],
    facts: [WebFact('Images', '12'), WebFact('Scanners killed', '3')],
    links: [
      WebLink('Gallery Nine: contemporary art', 'gallery_nine'),
      WebLink('Pigment Press: process notes', 'pigment_press'),
      WebLink('Museum of Almost: strange objects', 'museum_of_almost'),
    ],
  ),
  WebSite(
    id: 'conspiracy_tea',
    name: 'Conspiracy Tea',
    domain: 'conspiracytea.club',
    category: 'Weird',
    kind: WebKind.forum,
    tagline: 'Question everything. Especially this tagline.',
    headline: 'Who keeps moving the recycling bins?',
    summary:
        'A 300-post investigation into a neighborhood mystery with no '
        'evidence, three suspects, and a surprising amount of warmth.',
    bullets: [
      'The thread has a strict "no real accusations" rule.',
      'A spreadsheet of bin movements is maintained by a volunteer.',
      'The current leading theory involves the wind and a dog.',
    ],
    tags: ['mystery', 'neighborhood', 'silly'],
    facts: [WebFact('Posts', '312'), WebFact('Solved', 'No')],
    links: [
      WebLink('Cryptid Times: lake monster', 'cryptid_times'),
      WebLink('Harbor Bulletin: local notices', 'harbor_bulletin'),
      WebLink('Unexplained Post: archive', 'unexplained_post'),
    ],
  ),
  WebSite(
    id: 'unexplained_post',
    name: 'The Unexplained Post',
    domain: 'unexplainedpost.archive',
    category: 'Weird',
    kind: WebKind.archive,
    tagline: 'Filed under: probably nothing.',
    headline: 'The archive of letters nobody could answer',
    summary:
        'A post office box received strange, polite letters for eleven years. '
        'They are digitized here, along with the envelopes and stamps.',
    bullets: [
      'The letters are addressed to a street that does not exist.',
      'Each one is signed with a different, careful hand.',
      'The final letter arrived in 2011 and said only "thank you".',
    ],
    tags: ['letters', 'mystery', 'archive'],
    facts: [WebFact('Letters', '48'), WebFact('Years', '11')],
    links: [
      WebLink('Quiet Press: the story behind it', 'quiet_press'),
      WebLink('Cryptid Times: more mysteries', 'cryptid_times'),
      WebLink('Poem Post: found words', 'poem_post'),
    ],
  ),
];

const List<WebSite> _learningSites = [
  WebSite(
    id: 'open_classroom',
    name: 'Open Classroom',
    domain: 'openclassroom.edu',
    category: 'Learning',
    kind: WebKind.learn,
    tagline: 'Free lessons, no enrollment queue.',
    headline: 'A gentle introduction to statistics',
    summary:
        'Means, medians, and the difference between a pattern and a '
        'coincidence. Designed for people who disliked maths at school.',
    bullets: [
      'Twelve short lessons, each with one worked example.',
      'No prior algebra required; we check.',
      'Progress is stored in your browser, not an account.',
    ],
    tags: ['statistics', 'course', 'free'],
    facts: [
      WebFact('Lessons', '12'),
      WebFact('Students', '41,200'),
      WebFact('Cost', 'Free'),
    ],
    links: [
      WebLink('OpenBench: data methods', 'openbench'),
      WebLink('Pocket Professor: quick answers', 'pocket_professor'),
      WebLink('Lab Window: research news', 'lab_window'),
    ],
  ),
  WebSite(
    id: 'pocket_professor',
    name: 'Pocket Professor',
    domain: 'pocketprofessor.edu',
    category: 'Learning',
    kind: WebKind.learn,
    tagline: 'One idea, explained properly.',
    headline: 'What is a sound wave, actually?',
    summary:
        'A five-minute lesson with animations, a slinky, and an honest '
        'admission that "wave" is a useful metaphor rather than a thing.',
    bullets: [
      'Lessons are written by subject teachers, not marketers.',
      'Each page includes a one-sentence summary at the top.',
      'There is a quiz at the end, but nobody is watching.',
    ],
    tags: ['science', 'short lessons', 'explainers'],
    facts: [WebFact('Lessons', '84'), WebFact('Read time', '5 minutes')],
    links: [
      WebLink('Open Classroom: statistics', 'open_classroom'),
      WebLink('Chord Cafe: music theory', 'chord_cafe'),
      WebLink('Orbital Notes: space', 'orbital_notes'),
    ],
  ),
  WebSite(
    id: 'language_lab',
    name: 'Language Lab',
    domain: 'languagelab.edu',
    category: 'Learning',
    kind: WebKind.learn,
    tagline: 'A few words, every day.',
    headline: 'Ordering breakfast in four languages',
    summary:
        'A practical micro-lesson: coffee, bread, please, and thank you, '
        'with pronunciation notes that do not require a linguistics degree.',
    bullets: [
      'Audio is recorded by native speakers at a normal speed.',
      'Lessons are organized by situation, not grammar tables.',
      'A printable phrase card fits in a coat pocket.',
    ],
    tags: ['languages', 'travel', 'practice'],
    facts: [WebFact('Languages', '4'), WebFact('Phrases', '18')],
    links: [
      WebLink('Slow Route: travel notebook', 'slow_route'),
      WebLink('Hostel Notes: travel advice', 'hostel_notes'),
      WebLink('Word Ladder: word puzzles', 'word_ladder'),
    ],
  ),
];

const List<WebSite> _healthSites = [
  WebSite(
    id: 'steady_breath',
    name: 'Steady Breath',
    domain: 'steadybreath.care',
    category: 'Health',
    kind: WebKind.learn,
    tagline: 'A minute is enough to start.',
    headline: 'A breathing exercise for a busy head',
    summary:
        'Four counts in, six counts out, repeated for one minute. No app, no '
        'subscription, and no need to sit in a particular way.',
    bullets: [
      'The longer exhale is the part that helps.',
      'Stop if you feel dizzy; breathing is not a competition.',
      'The printable card is designed for a desk drawer.',
    ],
    tags: ['breathing', 'calm', 'practice'],
    facts: [WebFact('Time', '1 minute'), WebFact('Counts', '4 in / 6 out')],
    links: [
      WebLink('Sleep Lab: better rest', 'sleep_lab'),
      WebLink('Move Daily: gentle movement', 'move_daily'),
      WebLink('Nightwave FM: quiet radio', 'nightwave_fm'),
    ],
  ),
  WebSite(
    id: 'sleep_lab',
    name: 'Sleep Lab',
    domain: 'sleep.lab',
    category: 'Health',
    kind: WebKind.wiki,
    tagline: 'The science of doing nothing well.',
    headline: 'Why your brain wakes up at 3 a.m.',
    summary:
        'A clear explanation of sleep cycles, stress, and the very common '
        'habit of lying awake while solving tomorrow’s problems.',
    bullets: [
      'Brief awakenings are normal; clock-watching is not helpful.',
      'A cool, dark room does more than most gadgets.',
      'The page avoids promising a perfect night’s sleep.',
    ],
    tags: ['sleep', 'science', 'wellbeing'],
    facts: [WebFact('Cycles', '4–6 / night'), WebFact('Room temp', '18°C')],
    links: [
      WebLink('Steady Breath: wind down', 'steady_breath'),
      WebLink('Move Daily: daytime activity', 'move_daily'),
      WebLink('Quiet Press: slow reading', 'quiet_press'),
    ],
  ),
  WebSite(
    id: 'move_daily',
    name: 'Move Daily',
    domain: 'movedaily.blog',
    category: 'Health',
    kind: WebKind.blog,
    tagline: 'Small movement, most days.',
    headline: 'The seven-minute routine I actually keep doing',
    summary:
        'No equipment, no jumping, no promises about abs. Seven minutes of '
        'mobility for people who sit down for a living.',
    bullets: [
      'The routine starts with the shoulders and ends with the feet.',
      'Every movement has an easier version.',
      'Missing a day is fine; the routine will still be here.',
    ],
    tags: ['mobility', 'routine', 'gentle'],
    facts: [WebFact('Minutes', '7'), WebFact('Equipment', 'A wall')],
    links: [
      WebLink('Steady Breath: recovery', 'steady_breath'),
      WebLink('Pace Line: hill training', 'pace_line'),
      WebLink('Sleep Lab: rest science', 'sleep_lab'),
    ],
  ),
];

const List<WebSite> _artSites = [
  WebSite(
    id: 'gallery_nine',
    name: 'Gallery Nine',
    domain: 'gallerynine.art',
    category: 'Art',
    kind: WebKind.gallery,
    tagline: 'Nine rooms, one small gallery.',
    headline: 'This month: paintings made from garden dye',
    summary:
        'Onion skins, marigolds, and a stubborn beet have been turned into '
        'pigment. The results are warmer than any art shop tube.',
    bullets: [
      'Every work lists the plants used and the mordant.',
      'The gallery is free and open Thursday to Sunday.',
      'A workshop runs on the last Saturday of the month.',
    ],
    tags: ['painting', 'natural dye', 'exhibition'],
    facts: [
      WebFact('Works', '23'),
      WebFact('Rooms', '2, actually'),
      WebFact('Entry', 'Free'),
    ],
    links: [
      WebLink('Pigment Press: dye recipes', 'pigment_press'),
      WebLink('Sketch Daily: drawing practice', 'sketch_daily'),
      WebLink('Frame by Frame: framing course', 'frame_by_frame'),
    ],
  ),
  WebSite(
    id: 'pigment_press',
    name: 'Pigment Press',
    domain: 'pigmentpress.art',
    category: 'Art',
    kind: WebKind.blog,
    tagline: 'Color, cooked slowly.',
    headline: 'Beetroot is a liar (and other dye notes)',
    summary:
        'A studio diary about natural pigments: what the books promise, what '
        'the pot delivers, and why everything turns brown eventually.',
    bullets: [
      'Beetroot fades; madder holds. The notebook explains why.',
      'Recipes are written in grams and vague hand gestures.',
      'The failures are posted alongside the successes.',
    ],
    tags: ['pigment', 'studio', 'natural dye'],
    facts: [WebFact('Dyes tested', '38'), WebFact('Failures', 'Many')],
    links: [
      WebLink('Gallery Nine: the exhibition', 'gallery_nine'),
      WebLink('Glitch Garden: accidental art', 'glitch_garden'),
      WebLink('Frame by Frame: presentation', 'frame_by_frame'),
    ],
  ),
  WebSite(
    id: 'sketch_daily',
    name: 'Sketch Daily',
    domain: 'sketchdaily.club',
    category: 'Art',
    kind: WebKind.gallery,
    tagline: 'One drawing, every day, no excuses.',
    headline: 'Thirty days of drawing the same chair',
    summary:
        'A month-long exercise in looking properly. The chair did not move; '
        'the drawings changed completely.',
    bullets: [
      'Prompts are posted at midnight and stay up forever.',
      'All skill levels share the same gallery.',
      'The only rule is that the drawing has to be finished.',
    ],
    tags: ['drawing', 'challenge', 'sketchbook'],
    facts: [WebFact('Sketches', '30'), WebFact('Chairs', '1')],
    links: [
      WebLink('Gallery Nine: exhibition', 'gallery_nine'),
      WebLink('Cozy Quests: environment art', 'cozy_quests'),
      WebLink('Pigment Press: color notes', 'pigment_press'),
    ],
  ),
  WebSite(
    id: 'frame_by_frame',
    name: 'Frame by Frame',
    domain: 'framebyframe.learn',
    category: 'Art',
    kind: WebKind.learn,
    tagline: 'The craft around the picture.',
    headline: 'How to frame a print without ruining it',
    summary:
        'A short course in matting, glazing, and hanging: the unglamorous '
        'skills that make a good picture look cared for.',
    bullets: [
      'Acid-free materials are explained without jargon.',
      'The measuring lesson includes a printable cutting plan.',
      'One lesson is entirely about avoiding crooked hooks.',
    ],
    tags: ['framing', 'course', 'prints'],
    facts: [
      WebFact('Lessons', '4'),
      WebFact('Tools', 'Ruler, knife, patience'),
    ],
    links: [
      WebLink('Gallery Nine: see it hung', 'gallery_nine'),
      WebLink('Sketch Daily: fill the frame', 'sketch_daily'),
      WebLink('Shelf Help: wall anchors', 'shelf_help'),
    ],
  ),
];

/// The complete RetroWeb directory plus the browser's start page.
class WebSiteCatalog {
  const WebSiteCatalog._();

  static const WebSite home = WebSite(
    id: 'retroweb_home',
    name: 'RetroWeb Start',
    domain: 'start.retroweb',
    category: 'Portal',
    kind: WebKind.portal,
    tagline: 'The small web, hand-indexed.',
    headline: 'One hundred places worth a look',
    summary:
        'No feed, no algorithm, no autoplay. Pick a category, search the '
        'directory, or let the browser surprise you.',
    bullets: [
      'Every site is hand-written and safe for a rainy afternoon.',
      'Everything is one tap away: stories, quizzes, shops, and radio.',
      'Bookmarks are kept for this visit only.',
    ],
    tags: ['directory', 'portal', 'start'],
    links: [
      WebLink('The Harbor Herald', 'harbor_herald'),
      WebLink('Silicon Sand', 'silicon_sand'),
      WebLink('The Quiz Jar', 'quiz_jar'),
      WebLink('Nightwave FM', 'nightwave_fm'),
    ],
  );

  /// All 100 destinations, in directory order.
  static const List<WebSite> directory = [
    ..._techSites,
    ..._newsSites,
    ..._scienceSites,
    ..._quizSites,
    ..._gameSites,
    ..._musicSites,
    ..._filmSites,
    ..._bookSites,
    ..._foodSites,
    ..._sportSites,
    ..._travelSites,
    ..._homeSites,
    ..._moneySites,
    ..._natureSites,
    ..._localSites,
    ..._weirdSites,
    ..._learningSites,
    ..._healthSites,
    ..._artSites,
  ];

  static const List<String> categoryOrder = [
    'Tech',
    'News',
    'Science',
    'Quizzes',
    'Games',
    'Music',
    'Film',
    'Books',
    'Food',
    'Sport',
    'Travel',
    'Home',
    'Money',
    'Nature',
    'Local',
    'Weird',
    'Learning',
    'Health',
    'Art',
  ];

  static const Map<String, Color> categoryColor = {
    'Tech': Color(0xFF5EEAD4),
    'News': Color(0xFFFFB067),
    'Science': Color(0xFF7DD3FC),
    'Quizzes': Color(0xFFFDE68A),
    'Games': Color(0xFFC4B5FD),
    'Music': Color(0xFFF9A8D4),
    'Film': Color(0xFFFDA4AF),
    'Books': Color(0xFFD6B98C),
    'Food': Color(0xFFFFA94D),
    'Sport': Color(0xFF86EFAC),
    'Travel': Color(0xFF67E8F9),
    'Home': Color(0xFFFBCFE8),
    'Money': Color(0xFFFACC15),
    'Nature': Color(0xFFA3E635),
    'Local': Color(0xFF99F6E4),
    'Weird': Color(0xFFD8B4FE),
    'Learning': Color(0xFF93C5FD),
    'Health': Color(0xFFBEF264),
    'Art': Color(0xFFF0ABFC),
  };

  static const Map<String, String> categoryEmoji = {
    'Tech': '🔧',
    'News': '📰',
    'Science': '🔬',
    'Quizzes': '🧠',
    'Games': '🎮',
    'Music': '🎧',
    'Film': '🎬',
    'Books': '📚',
    'Food': '🍳',
    'Sport': '⚽',
    'Travel': '🧭',
    'Home': '🏡',
    'Money': '🪙',
    'Nature': '🌿',
    'Local': '🏙️',
    'Weird': '👁️',
    'Learning': '🎓',
    'Health': '🫀',
    'Art': '🎨',
  };

  static List<WebSite> get categories => [
    for (final name in categoryOrder) ...inCategory(name),
  ];

  static WebSite? maybeById(String id) {
    if (id == home.id) return home;
    for (final site in directory) {
      if (site.id == id) return site;
    }
    return null;
  }

  static WebSite byId(String id) => maybeById(id) ?? home;

  static List<WebSite> inCategory(String category) => [
    for (final site in directory)
      if (site.category == category) site,
  ];

  static List<WebSite> search(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return directory;
    return [
      for (final site in directory)
        if (site.searchText.contains(needle)) site,
    ];
  }

  static WebSite random(math.Random random) =>
      directory[random.nextInt(directory.length)];

  static int countIn(String category) => inCategory(category).length;
}
