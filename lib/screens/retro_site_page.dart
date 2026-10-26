import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/web_site.dart';
import 'retro_web_kit.dart';

/// One rendered RetroWeb destination.
///
/// Every site shares a masthead and a set of editorial blocks, then adds a
/// small interactive module based on its [WebKind]. State is local to the
/// page and survives cursor movement because the browser keys each page by
/// its site id.
class RetroSitePage extends StatefulWidget {
  const RetroSitePage({
    super.key,
    required this.site,
    required this.onOpenSite,
    required this.onToast,
    required this.isBookmarked,
    required this.onToggleBookmark,
    required this.onOpenDirectory,
    this.scrollController,
  });

  final WebSite site;
  final ValueChanged<String> onOpenSite;
  final ValueChanged<String> onToast;
  final bool isBookmarked;
  final VoidCallback onToggleBookmark;
  final VoidCallback onOpenDirectory;
  final ScrollController? scrollController;

  @override
  State<RetroSitePage> createState() => _RetroSitePageState();
}

class _RetroSitePageState extends State<RetroSitePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  final Map<int, int> _quizAnswers = <int, int>{};
  final Set<int> _lessons = <int>{};
  final Set<String> _basket = <String>{};
  final Map<int, int> _postVotes = <int, int>{};
  int _thumbs = 0;
  bool _benchRun = false;
  bool _playing = false;
  int _volume = 2;
  int _claps = 0;
  int _guestbook = 0;
  int _tile = 0;

  WebSite get site => widget.site;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    );
    if (site.kind == WebKind.radio) {
      _playing = true;
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(RetroSitePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.site.kind != site.kind) {
      if (site.kind == WebKind.radio) {
        _pulse.repeat(reverse: true);
      } else {
        _pulse.stop();
      }
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  int get _score {
    var score = 0;
    for (var i = 0; i < site.questions.length; i++) {
      final picked = _quizAnswers[i];
      if (picked != null && picked == site.questions[i].answer) score++;
    }
    return score;
  }

  int get _basketCents => site.products
      .where((product) => _basket.contains(product.name))
      .fold(0, (sum, product) => sum + product.priceCents);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 640;
        return SingleChildScrollView(
          controller: widget.scrollController,
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _masthead(wide),
                  const SizedBox(height: 12),
                  ..._kindBody(wide),
                  const SizedBox(height: 16),
                  _links(),
                  const SizedBox(height: 14),
                  _footer(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------- masthead

  Widget _masthead(bool wide) {
    final tint = site.tint;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tint.withAlpha(30),
            webPanel.withAlpha(230),
            site.shade.withAlpha(220),
          ],
        ),
        border: Border.all(color: tint.withAlpha(105)),
        boxShadow: [
          BoxShadow(color: tint.withAlpha(24), blurRadius: 22, spreadRadius: 1),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [tint.withAlpha(220), site.shade],
              ),
              border: Border.all(color: Colors.white.withAlpha(40)),
            ),
            child: Center(
              child: Text(site.glyph, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        site.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    WebChip(
                      label: site.category.toUpperCase(),
                      color: tint,
                      filled: true,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  site.tagline,
                  maxLines: wide ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: webMuted,
                    fontSize: 10.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          BrowserHitBox(
            id: 'bookmark_site_${site.id}',
            onTap: () {
              widget.onToggleBookmark();
              widget.onToast(
                widget.isBookmarked
                    ? 'Removed ${site.name} from bookmarks.'
                    : 'Bookmarked ${site.name}.',
              );
            },
            radius: 9,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(60),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: widget.isBookmarked ? webAmber : webLine,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    size: 14,
                    color: widget.isBookmarked ? webAmber : webMuted,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    site.domain,
                    style: const TextStyle(
                      color: webMuted,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------- page bodies

  List<Widget> _kindBody(bool wide) {
    switch (site.kind) {
      case WebKind.news:
        return _news(wide);
      case WebKind.tech:
        return _tech(wide);
      case WebKind.wiki:
        return _wiki(wide);
      case WebKind.forum:
        return _forum(wide);
      case WebKind.quiz:
        return _quiz(wide);
      case WebKind.shop:
        return _shop(wide);
      case WebKind.blog:
        return _blog(wide);
      case WebKind.radio:
        return _radio(wide);
      case WebKind.archive:
        return _archive(wide);
      case WebKind.gallery:
        return _gallery(wide);
      case WebKind.learn:
        return _learn(wide);
      case WebKind.portal:
        return _blog(wide);
    }
  }

  Widget _lead({String? kicker}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (kicker != null) ...[
          Row(
            children: [
              Container(
                width: 14,
                height: 2,
                color: site.tint,
                margin: const EdgeInsets.only(right: 6),
              ),
              Text(
                kicker,
                style: TextStyle(
                  color: site.tint,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        Text(
          site.headline,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            height: 1.14,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          site.summary,
          style: const TextStyle(
            color: Color(0xFFC6D8DC),
            fontSize: 12,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Container(width: 3, height: 12, color: site.tint),
          const SizedBox(width: 7),
          Text(
            text.toUpperCase(),
            style: const TextStyle(
              color: webMuted,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _factsStrip() {
    if (site.facts.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        for (final fact in site.facts)
          Container(
            padding: const EdgeInsets.fromLTRB(9, 6, 10, 6),
            decoration: BoxDecoration(
              color: webPanelHi.withAlpha(170),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: webLine),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fact.label.toUpperCase(),
                  style: const TextStyle(
                    color: webMuted,
                    fontSize: 7.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fact.value,
                  style: const TextStyle(
                    color: webText,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _bulletList({String marker = '▸', bool boxed = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < site.bullets.length; i++)
          Container(
            margin: EdgeInsets.only(
              bottom: i == site.bullets.length - 1 ? 0 : 6,
            ),
            padding: boxed
                ? const EdgeInsets.fromLTRB(10, 8, 10, 8)
                : const EdgeInsets.only(left: 2, top: 1, bottom: 1),
            decoration: boxed
                ? BoxDecoration(
                    color: webPanel.withAlpha(200),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: webLine.withAlpha(180)),
                  )
                : null,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  marker,
                  style: TextStyle(
                    color: site.tint,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    height: 1.5,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    site.bullets[i],
                    style: const TextStyle(
                      color: Color(0xFFC9DADD),
                      fontSize: 11,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _interactivePill({
    required String id,
    required String label,
    required VoidCallback onTap,
    IconData? icon,
    Color? color,
  }) {
    final tint = color ?? site.tint;
    return BrowserHitBox(
      id: id,
      onTap: onTap,
      radius: 999,
      glowColor: tint,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: tint.withAlpha(24),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: tint.withAlpha(120)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: tint),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: tint,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------- news

  List<Widget> _news(bool wide) {
    final reactions = _thumbs == 0
        ? 'Was this edition useful?'
        : _thumbs > 0
        ? 'Thanks — the newsroom is pleased.'
        : 'Noted. Tomorrow’s edition will try harder.';
    return [
      _lead(kicker: '${site.category} · today’s edition'),
      const SizedBox(height: 10),
      if (wide)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _newsBody()),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: _newsSidebar(reactions)),
          ],
        )
      else ...[
        _newsBody(),
        const SizedBox(height: 10),
        _newsSidebar(reactions),
      ],
      const SizedBox(height: 12),
      _reactions(reactions),
    ];
  }

  Widget _newsBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('The details'),
        _bulletList(marker: '●', boxed: true),
        const SizedBox(height: 10),
        _factsStrip(),
      ],
    );
  }

  Widget _newsSidebar(String reactions) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: site.tint.withAlpha(18),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: site.tint.withAlpha(70)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FROM THE DESK',
            style: TextStyle(
              color: site.tint,
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '“${site.tagline}”',
            style: const TextStyle(
              color: webText,
              fontSize: 11,
              height: 1.4,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Reported locally. Corrected promptly. Read slowly.',
            style: TextStyle(color: webMuted.withAlpha(220), fontSize: 9.5),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Icon(Icons.verified_rounded, size: 12, color: site.tint),
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  'Two sources, one kettle',
                  style: TextStyle(color: webMuted, fontSize: 9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reactions(String reactions) {
    return Row(
      children: [
        Expanded(
          child: Text(
            reactions,
            style: const TextStyle(color: webMuted, fontSize: 10),
          ),
        ),
        BrowserHitBox(
          id: 'news_${site.id}_up',
          onTap: () {
            setState(() => _thumbs = 1);
            widget.onToast('Feedback filed under "useful".');
          },
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              _thumbs > 0 ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
              size: 17,
              color: _thumbs > 0 ? webMint : webMuted,
            ),
          ),
        ),
        BrowserHitBox(
          id: 'news_${site.id}_down',
          onTap: () {
            setState(() => _thumbs = -1);
            widget.onToast('Feedback filed under "more cats".');
          },
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              _thumbs < 0
                  ? Icons.thumb_down_rounded
                  : Icons.thumb_down_outlined,
              size: 17,
              color: _thumbs < 0 ? webCoral : webMuted,
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------- tech

  List<Widget> _tech(bool wide) {
    final score = _benchRun ? 94 : 61;
    return [
      _lead(kicker: '${site.kind.name} desk · hands on'),
      const SizedBox(height: 10),
      if (wide)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _bulletList(boxed: true)),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: _benchPanel(score)),
          ],
        )
      else ...[
        _benchPanel(score),
        const SizedBox(height: 10),
        _bulletList(boxed: true),
      ],
      const SizedBox(height: 10),
      _factsStrip(),
      const SizedBox(height: 10),
      Row(
        children: [
          _interactivePill(
            id: 'tech_${site.id}_run',
            label: _benchRun ? 'Test complete · 94 pts' : 'Run the benchmark',
            icon: Icons.play_arrow_rounded,
            onTap: () {
              setState(() => _benchRun = true);
              widget.onToast('Benchmark finished. Thermal throttling: minor.');
            },
          ),
          const SizedBox(width: 8),
          _interactivePill(
            id: 'tech_${site.id}_comments',
            label: '42 comments',
            icon: Icons.forum_outlined,
            color: webMuted,
            onTap: () =>
                widget.onToast('Comments are read-only in RetroWeb Lite.'),
          ),
        ],
      ),
    ];
  }

  Widget _benchPanel(int score) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFF08131F),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: site.tint.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _benchRun ? webMint : webAmber,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                _benchRun ? 'TEST COMPLETE' : 'READY TO TEST',
                style: TextStyle(
                  color: _benchRun ? webMint : webAmber,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              const Spacer(),
              Text(
                '$score pts',
                style: const TextStyle(
                  color: webText,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 46,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 8; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 420),
                        curve: Curves.easeOutCubic,
                        height: _benchRun
                            ? 18 + (math.sin(i * 1.7) + 1) * 12
                            : 10 + (i % 3) * 5,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [site.tint.withAlpha(120), site.tint],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          Text(
            _benchRun
                ? 'Idle 2.1 W · load 8.4 W · fan: audible'
                : 'Press the button. We will keep the receipts.',
            style: const TextStyle(color: webMuted, fontSize: 8.5, height: 1.4),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------- wiki

  List<Widget> _wiki(bool wide) {
    final article = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _lead(kicker: 'encyclopedia · ${site.category}'),
        const SizedBox(height: 10),
        _sectionLabel('Contents'),
        _bulletList(marker: '§', boxed: true),
        const SizedBox(height: 10),
        _sectionLabel('Notes'),
        Text(
          site.summary,
          style: const TextStyle(
            color: Color(0xFFC9DADD),
            fontSize: 11,
            height: 1.5,
          ),
        ),
      ],
    );
    final infobox = Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: webPanelHi.withAlpha(190),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: webLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            site.name,
            style: const TextStyle(
              color: webText,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          for (final fact in site.facts) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  flex: 3,
                  child: Text(
                    fact.label,
                    style: const TextStyle(color: webMuted, fontSize: 9.5),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  flex: 4,
                  child: Text(
                    fact.value,
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: webText,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          const SizedBox(height: 4),
          Text(
            'Last edited by a volunteer who cares.',
            style: TextStyle(
              color: webMuted.withAlpha(200),
              fontSize: 8.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
    return [
      if (wide)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 7, child: article),
            const SizedBox(width: 12),
            SizedBox(width: 210, child: infobox),
          ],
        )
      else ...[
        article,
        const SizedBox(height: 10),
        infobox,
      ],
      const SizedBox(height: 10),
      Row(
        children: [
          _interactivePill(
            id: 'wiki_${site.id}_cite',
            label: 'Cite this page',
            icon: Icons.format_quote_rounded,
            onTap: () =>
                widget.onToast('Citation copied to an imaginary clipboard.'),
          ),
          const SizedBox(width: 8),
          _interactivePill(
            id: 'wiki_${site.id}_talk',
            label: 'Talk page · 18',
            icon: Icons.chat_bubble_outline_rounded,
            color: webMuted,
            onTap: () =>
                widget.onToast('The talk page is mostly people being polite.'),
          ),
        ],
      ),
    ];
  }

  // ------------------------------------------------------------------- forum

  List<Widget> _forum(bool wide) {
    return [
      _lead(kicker: 'community board · ${site.category}'),
      const SizedBox(height: 8),
      _factsStrip(),
      const SizedBox(height: 10),
      _sectionLabel('In this thread'),
      for (var i = 0; i < site.bullets.length; i++) _post(i, wide),
      const SizedBox(height: 4),
      Row(
        children: [
          _interactivePill(
            id: 'forum_${site.id}_reply',
            label: 'Write a reply',
            icon: Icons.reply_rounded,
            onTap: () =>
                widget.onToast('Reply box opened. Be kind, be specific.'),
          ),
          const SizedBox(width: 8),
          _interactivePill(
            id: 'forum_${site.id}_watch',
            label: 'Watch thread',
            icon: Icons.visibility_outlined,
            color: webMuted,
            onTap: () =>
                widget.onToast('You will be notified by carrier pigeon.'),
          ),
        ],
      ),
    ];
  }

  Widget _post(int index, bool wide) {
    const names = [
      'maple_byte',
      'quietengine',
      'Mossy',
      'nine_volts',
      'pixelpilot',
    ];
    final votes = _postVotes[index] ?? 0;
    final replies = 3 + index * 7;
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
      decoration: BoxDecoration(
        color: index == 0 ? site.tint.withAlpha(18) : webPanel.withAlpha(190),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: index == 0 ? site.tint.withAlpha(80) : webLine,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                colors: [site.tint.withAlpha(180), site.shade],
              ),
            ),
            child: Center(
              child: Text(
                names[index % names.length].substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      names[index % names.length],
                      style: TextStyle(
                        color: site.tint,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '· ${index == 0 ? 'OP' : '${replies}d ago'}',
                      style: const TextStyle(color: webMuted, fontSize: 8.5),
                    ),
                    const Spacer(),
                    Text(
                      '$replies replies',
                      style: const TextStyle(color: webMuted, fontSize: 8.5),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  site.bullets[index],
                  style: const TextStyle(
                    color: Color(0xFFC9DADD),
                    fontSize: 10.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          BrowserHitBox(
            id: 'post_${site.id}_$index',
            onTap: () {
              setState(() => _postVotes[index] = votes + 1);
              widget.onToast('Upvoted. The duck approves.');
            },
            radius: 7,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
              child: Column(
                children: [
                  Icon(
                    Icons.arrow_upward_rounded,
                    size: 14,
                    color: votes > 0 ? webMint : webMuted,
                  ),
                  Text(
                    '${12 + index * 5 + votes}',
                    style: const TextStyle(color: webMuted, fontSize: 8),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------- quiz

  List<Widget> _quiz(bool wide) {
    final answered = _quizAnswers.length;
    return [
      _lead(kicker: 'quiz · ${site.questions.length} questions'),
      const SizedBox(height: 8),
      Row(
        children: [
          WebChip(
            label: '$answered / ${site.questions.length} answered',
            color: webAmber,
            filled: true,
            icon: Icons.edit_note_rounded,
          ),
          const SizedBox(width: 7),
          WebChip(
            label: 'Score $_score',
            color: webMint,
            filled: true,
            icon: Icons.stars_rounded,
          ),
          const Spacer(),
          BrowserHitBox(
            id: 'quiz_${site.id}_reset',
            onTap: () {
              setState(_quizAnswers.clear);
              widget.onToast('Fresh questions, same jar.');
            },
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Text(
                'RESET',
                style: TextStyle(
                  color: webMuted,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      for (var q = 0; q < site.questions.length; q++) _question(q, wide),
      if (answered == site.questions.length)
        Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: BoxDecoration(
            color: webMint.withAlpha(18),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: webMint.withAlpha(80)),
          ),
          child: Text(
            _score == site.questions.length
                ? 'Perfect score. The jar is impressed.'
                : 'Round complete: $_score of ${site.questions.length}. '
                      'Every fact is worth keeping anyway.',
            style: const TextStyle(
              color: webMint,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
    ];
  }

  Widget _question(int index, bool wide) {
    final question = site.questions[index];
    final picked = _quizAnswers[index];
    final correct = picked != null && picked == question.answer;
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: BoxDecoration(
        color: webPanel.withAlpha(220),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: picked == null
              ? webLine
              : (correct ? webMint.withAlpha(120) : webCoral.withAlpha(110)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QUESTION ${index + 1}',
            style: TextStyle(
              color: site.tint,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            question.prompt,
            style: const TextStyle(
              color: webText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var option = 0; option < question.options.length; option++)
                _quizOption(index, option, question, picked),
            ],
          ),
          if (picked != null) ...[
            const SizedBox(height: 7),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  correct ? Icons.check_circle_rounded : Icons.info_rounded,
                  size: 13,
                  color: correct ? webMint : webAmber,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    correct ? question.fact : 'Not quite. ${question.fact}',
                    style: TextStyle(
                      color: correct ? webMint : webAmber,
                      fontSize: 9.5,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _quizOption(
    int questionIndex,
    int option,
    WebQuizQuestion question,
    int? picked,
  ) {
    final isPicked = picked == option;
    final isAnswer = question.answer == option;
    final reveal = picked != null;
    final color = !reveal
        ? webMuted
        : isAnswer
        ? webMint
        : (isPicked ? webCoral : webMuted);
    return BrowserHitBox(
      id: 'quiz_${site.id}_${questionIndex}_$option',
      onTap: () {
        if (picked != null) return;
        setState(() => _quizAnswers[questionIndex] = option);
        final right = option == question.answer;
        widget.onToast(
          right ? 'Correct. ${question.fact}' : 'Answered. The fact is below.',
        );
      },
      radius: 8,
      glowColor: color,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isPicked ? color.withAlpha(28) : Colors.white.withAlpha(6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isPicked ? color.withAlpha(150) : webLine),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              String.fromCharCode(65 + option),
              style: TextStyle(
                color: isPicked ? color : webMuted,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              question.options[option],
              style: TextStyle(
                color: isPicked ? color : webText,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------- shop

  List<Widget> _shop(bool wide) {
    final count = _basket.length;
    final total = (_basketCents / 100).toStringAsFixed(2);
    return [
      _lead(kicker: 'independent shop · ${site.category.toLowerCase()}'),
      const SizedBox(height: 10),
      Row(
        children: [
          WebChip(
            label: count == 1 ? '1 item in basket' : '$count items in basket',
            color: webAmber,
            filled: true,
            icon: Icons.shopping_basket_outlined,
          ),
          const Spacer(),
          Text(
            '\$$total',
            style: const TextStyle(
              color: webText,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
      const SizedBox(height: 9),
      for (var i = 0; i < site.products.length; i++)
        _productCard(site.products[i], i, wide),
      const SizedBox(height: 3),
      Row(
        children: [
          _interactivePill(
            id: 'shop_${site.id}_checkout',
            label: count == 0 ? 'Basket is empty' : 'Checkout · \$$total',
            icon: Icons.shopping_bag_outlined,
            color: count == 0 ? webMuted : webMint,
            onTap: () {
              if (_basket.isEmpty) {
                widget.onToast('Add something first. The shelves are patient.');
                return;
              }
              final receipt = _basket.length;
              setState(_basket.clear);
              widget.onToast(
                'Ordered $receipt item(s). Wrapped in reused paper.',
              );
            },
          ),
          const SizedBox(width: 8),
          _interactivePill(
            id: 'shop_${site.id}_shipping',
            label: 'Shipping & returns',
            icon: Icons.local_shipping_outlined,
            color: webMuted,
            onTap: () =>
                widget.onToast('Ships Tuesday. Returns accepted with a note.'),
          ),
        ],
      ),
      const SizedBox(height: 10),
      _factsStrip(),
    ];
  }

  Widget _productCard(WebProduct product, int index, bool wide) {
    final added = _basket.contains(product.name);
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
      decoration: BoxDecoration(
        color: webPanel.withAlpha(210),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: added ? webMint.withAlpha(100) : webLine),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [site.tint.withAlpha(50), site.shade.withAlpha(180)],
              ),
            ),
            child: Center(
              child: Text(product.emoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    color: webText,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  product.blurb,
                  style: const TextStyle(
                    color: webMuted,
                    fontSize: 9.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            product.priceLabel,
            style: const TextStyle(
              color: webAmber,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          BrowserHitBox(
            id: 'shop_${site.id}_$index',
            onTap: () {
              setState(() {
                if (added) {
                  _basket.remove(product.name);
                } else {
                  _basket.add(product.name);
                }
              });
              widget.onToast(
                added ? 'Removed ${product.name}.' : 'Added ${product.name}.',
              );
            },
            radius: 7,
            glowColor: added ? webCoral : webMint,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: added ? webCoral.withAlpha(28) : webMint.withAlpha(26),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: (added ? webCoral : webMint).withAlpha(120),
                ),
              ),
              child: Text(
                added ? 'Remove' : 'Add',
                style: TextStyle(
                  color: added ? webCoral : webMint,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------- blog

  List<Widget> _blog(bool wide) {
    final date = site.facts.isNotEmpty ? site.facts.first.value : 'This week';
    return [
      _lead(kicker: 'journal · ${site.category.toLowerCase()}'),
      const SizedBox(height: 8),
      Row(
        children: [
          Icon(Icons.event_rounded, size: 12, color: site.tint),
          const SizedBox(width: 4),
          Text(date, style: const TextStyle(color: webMuted, fontSize: 9.5)),
          const SizedBox(width: 12),
          const Icon(Icons.schedule_rounded, size: 12, color: webMuted),
          const SizedBox(width: 4),
          const Text(
            '5 min read',
            style: TextStyle(color: webMuted, fontSize: 9.5),
          ),
          const Spacer(),
          WebChip(
            label: '${(site.bullets.length * 3 + 12)} reactions',
            color: site.tint,
          ),
        ],
      ),
      const SizedBox(height: 10),
      for (var i = 0; i < site.bullets.length; i++)
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.only(left: 10),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: i == 0 ? site.tint : webLine, width: 2),
            ),
          ),
          child: Text(
            site.bullets[i],
            style: const TextStyle(
              color: Color(0xFFC9DADD),
              fontSize: 11.5,
              height: 1.5,
            ),
          ),
        ),
      const SizedBox(height: 2),
      _factsStrip(),
      const SizedBox(height: 11),
      Row(
        children: [
          _interactivePill(
            id: 'blog_${site.id}_clap',
            label: _claps == 0 ? 'Appreciate this' : '$_claps appreciations',
            icon: Icons.favorite_rounded,
            color: webCoral,
            onTap: () {
              setState(() => _claps++);
              widget.onToast('Appreciated. The writer felt that.');
            },
          ),
          const SizedBox(width: 8),
          _interactivePill(
            id: 'blog_${site.id}_bookmark',
            label: widget.isBookmarked ? 'Bookmarked' : 'Save for later',
            icon: widget.isBookmarked
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            color: widget.isBookmarked ? webAmber : webMuted,
            onTap: () {
              widget.onToggleBookmark();
              widget.onToast(
                widget.isBookmarked ? 'Removed bookmark.' : 'Saved for later.',
              );
            },
          ),
        ],
      ),
    ];
  }

  // ------------------------------------------------------------------- radio

  List<Widget> _radio(bool wide) {
    return [
      _lead(kicker: 'live radio · ${site.category.toLowerCase()}'),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [site.shade.withAlpha(220), webPanel],
          ),
          border: Border.all(color: site.tint.withAlpha(90)),
        ),
        child: Row(
          children: [
            BrowserHitBox(
              id: 'radio_${site.id}_tune',
              onTap: () {
                setState(() => _playing = !_playing);
                if (_playing) {
                  _pulse.repeat(reverse: true);
                } else {
                  _pulse.stop();
                }
                widget.onToast(_playing ? 'Tuned in.' : 'Radio paused.');
              },
              radius: 999,
              glowColor: site.tint,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: site.tint,
                  boxShadow: [
                    BoxShadow(color: site.tint.withAlpha(90), blurRadius: 18),
                  ],
                ),
                child: Icon(
                  _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: webInk,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _playing ? webCoral : webMuted,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _playing ? 'ON AIR' : 'PAUSED',
                        style: TextStyle(
                          color: _playing ? webCoral : webMuted,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${String.fromCharCode(65 + _volume * 3)}${82 + _volume} FM',
                        style: const TextStyle(
                          color: webMuted,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    site.headline.replaceFirst('Now playing: ', ''),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: webText,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) {
                return SizedBox(
                  width: 62,
                  height: 32,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      for (var i = 0; i < 7; i++)
                        Container(
                          width: 4,
                          height: _playing
                              ? 6 +
                                    (math.sin(
                                              (_pulse.value * math.pi * 2) +
                                                  i * 0.9,
                                            ) +
                                            1) *
                                        8
                              : 5 + (i % 3) * 2,
                          decoration: BoxDecoration(
                            color: site.tint.withAlpha(_playing ? 230 : 70),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      const SizedBox(height: 9),
      Row(
        children: [
          const Text(
            'VOL',
            style: TextStyle(
              color: webMuted,
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 5),
          BrowserHitBox(
            id: 'radio_${site.id}_vol_down',
            onTap: () {
              setState(() => _volume = math.max(0, _volume - 1));
              widget.onToast('Volume ${_volume + 1}/5');
            },
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.remove_rounded, size: 14, color: webMuted),
            ),
          ),
          const SizedBox(width: 2),
          for (var i = 0; i < 5; i++)
            Container(
              width: 12,
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              color: i < _volume ? site.tint : webLine,
            ),
          const SizedBox(width: 2),
          BrowserHitBox(
            id: 'radio_${site.id}_vol_up',
            onTap: () {
              setState(() => _volume = math.min(5, _volume + 1));
              widget.onToast('Volume ${_volume + 1}/5');
            },
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.add_rounded, size: 14, color: webMuted),
            ),
          ),
          const Spacer(),
          Text(
            'LISTENERS ${site.facts.isNotEmpty ? site.facts.first.value : '1,204'}',
            style: const TextStyle(
              color: webMuted,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      _sectionLabel('Coming up'),
      for (var i = 0; i < site.bullets.length; i++)
        Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.fromLTRB(9, 7, 9, 7),
          decoration: BoxDecoration(
            color: webPanel.withAlpha(180),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: webLine),
          ),
          child: Row(
            children: [
              Text(
                '0${21 + i}:00',
                style: TextStyle(
                  color: site.tint,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  site.bullets[i],
                  style: const TextStyle(
                    color: Color(0xFFC9DADD),
                    fontSize: 10,
                    height: 1.35,
                  ),
                ),
              ),
              const Icon(Icons.graphic_eq_rounded, size: 13, color: webMuted),
            ],
          ),
        ),
    ];
  }

  // ----------------------------------------------------------------- archive

  List<Widget> _archive(bool wide) {
    final visitors = 1337 + _guestbook;
    return [
      Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: const Color(0xFF151021),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: site.tint.withAlpha(90)),
        ),
        child: Row(
          children: [
            Text('★', style: TextStyle(color: site.tint, fontSize: 17)),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                site.headline.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: site.tint,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 7),
            Text('★', style: TextStyle(color: site.tint, fontSize: 17)),
          ],
        ),
      ),
      const SizedBox(height: 9),
      _lead(kicker: 'archive · est. 1998'),
      const SizedBox(height: 10),
      if (wide)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _bulletList(marker: '›', boxed: true)),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: _archiveSidebar(visitors)),
          ],
        )
      else ...[
        _bulletList(marker: '›', boxed: true),
        const SizedBox(height: 9),
        _archiveSidebar(visitors),
      ],
      const SizedBox(height: 10),
      Row(
        children: [
          _interactivePill(
            id: 'archive_${site.id}_guestbook',
            label: _guestbook == 0
                ? 'Sign the guestbook'
                : 'Signed · thank you',
            icon: Icons.edit_rounded,
            color: site.tint,
            onTap: () {
              setState(() => _guestbook++);
              widget.onToast('Signed. The webmaster will reply in 1999.');
            },
          ),
          const SizedBox(width: 8),
          _interactivePill(
            id: 'archive_${site.id}_email',
            label: 'Email the webmaster',
            icon: Icons.alternate_email_rounded,
            color: webMuted,
            onTap: () =>
                widget.onToast('Address is valid. Reply time: geological.'),
          ),
        ],
      ),
    ];
  }

  Widget _archiveSidebar(int visitors) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF120E1B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: site.tint.withAlpha(55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VISITORS',
            style: TextStyle(
              color: site.tint,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            visitors.toString().padLeft(6, '0'),
            style: TextStyle(
              color: site.tint,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 6),
          for (final fact in site.facts)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                '${fact.label}: ${fact.value}',
                style: const TextStyle(color: webMuted, fontSize: 9),
              ),
            ),
          const SizedBox(height: 4),
          Text(
            'Best viewed in any browser\nthat still remembers how.',
            style: TextStyle(
              color: webMuted.withAlpha(180),
              fontSize: 8,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------- gallery

  List<Widget> _gallery(bool wide) {
    final count = math.max(1, site.bullets.length);
    final safeTile = _tile.clamp(0, count - 1);
    return [
      _lead(kicker: 'gallery · ${site.category.toLowerCase()}'),
      const SizedBox(height: 10),
      Row(
        children: [
          for (var i = 0; i < count; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == count - 1 ? 0 : 7),
                child: _artTile(i, safeTile == i),
              ),
            ),
        ],
      ),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: webPanel.withAlpha(210),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: webLine),
        ),
        child: Row(
          children: [
            Text(
              'FIG. ${(safeTile + 1).toString().padLeft(2, '0')}',
              style: TextStyle(
                color: site.tint,
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                site.bullets[safeTile],
                style: const TextStyle(
                  color: Color(0xFFC9DADD),
                  fontSize: 10,
                  height: 1.4,
                ),
              ),
            ),
            BrowserHitBox(
              id: 'gallery_${site.id}_next',
              onTap: () {
                setState(() => _tile = (safeTile + 1) % count);
                widget.onToast('Next plate, please.');
              },
              child: const Padding(
                padding: EdgeInsets.all(5),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 15,
                  color: webMint,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      _factsStrip(),
      const SizedBox(height: 8),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final tag in site.tags) WebChip(label: tag, color: site.tint),
        ],
      ),
    ];
  }

  Widget _artTile(int index, bool selected) {
    final base = HSLColor.fromColor(site.tint);
    final color = base
        .withHue((base.hue + index * 34) % 360)
        .withSaturation(math.min(1, base.saturation + 0.12))
        .toColor();
    return BrowserHitBox(
      id: 'gallery_${site.id}_$index',
      onTap: () {
        setState(() => _tile = index);
        widget.onToast(site.bullets[index]);
      },
      radius: 10,
      glowColor: color,
      child: Container(
        height: 92,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withAlpha(220), site.shade],
          ),
          border: Border.all(
            color: selected ? Colors.white.withAlpha(180) : webLine,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -12,
              child: Text(
                site.glyph,
                style: TextStyle(
                  fontSize: 54,
                  color: Colors.white.withAlpha(40),
                ),
              ),
            ),
            Positioned(
              left: 8,
              top: 7,
              child: Text(
                '0${index + 1}',
                style: TextStyle(
                  color: Colors.white.withAlpha(180),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            if (selected)
              Positioned(
                right: 7,
                top: 7,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------- learn

  List<Widget> _learn(bool wide) {
    final total = site.bullets.length;
    final done = _lessons.length;
    final progress = total == 0 ? 0.0 : done / total;
    return [
      _lead(kicker: 'free course · ${site.category.toLowerCase()}'),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
        decoration: BoxDecoration(
          color: webPanel.withAlpha(210),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: webLine),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'COURSE PROGRESS',
                  style: TextStyle(
                    color: site.tint,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                Text(
                  '$done / $total',
                  style: const TextStyle(
                    color: webText,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: webLine.withAlpha(120),
                valueColor: AlwaysStoppedAnimation<Color>(site.tint),
              ),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < total; i++) _lessonRow(i),
            const SizedBox(height: 5),
            Row(
              children: [
                _interactivePill(
                  id: 'learn_${site.id}_next',
                  label: done >= total ? 'Course complete' : 'Mark next lesson',
                  icon: done >= total
                      ? Icons.workspace_premium_rounded
                      : Icons.check_circle_outline_rounded,
                  color: done >= total ? webAmber : webMint,
                  onTap: () {
                    if (_lessons.length >= total) {
                      widget.onToast(
                        'Certificate: printed, folded, imaginary.',
                      );
                      return;
                    }
                    setState(() => _lessons.add(_lessons.length));
                    widget.onToast(
                      _lessons.length >= total
                          ? 'Course complete. Very good.'
                          : 'Lesson ${_lessons.length} complete.',
                    );
                  },
                ),
                const SizedBox(width: 8),
                if (done > 0)
                  _interactivePill(
                    id: 'learn_${site.id}_reset',
                    label: 'Reset',
                    icon: Icons.restart_alt_rounded,
                    color: webMuted,
                    onTap: () {
                      setState(_lessons.clear);
                      widget.onToast('Progress reset. No shame in it.');
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 9),
      _factsStrip(),
    ];
  }

  Widget _lessonRow(int index) {
    final done = _lessons.contains(index);
    return BrowserHitBox(
      id: 'learn_${site.id}_lesson_$index',
      onTap: () {
        setState(() {
          if (done) {
            _lessons.remove(index);
          } else {
            _lessons.add(index);
          }
        });
      },
      radius: 8,
      child: Container(
        margin: const EdgeInsets.only(bottom: 5),
        padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
        decoration: BoxDecoration(
          color: done ? webMint.withAlpha(14) : Colors.white.withAlpha(4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: done ? webMint.withAlpha(70) : webLine),
        ),
        child: Row(
          children: [
            Icon(
              done ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 14,
              color: done ? webMint : webMuted,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                site.bullets[index],
                style: TextStyle(
                  color: done ? webMint : const Color(0xFFC9DADD),
                  fontSize: 10,
                  height: 1.35,
                ),
              ),
            ),
            Text(
              '0${index + 1}',
              style: const TextStyle(
                color: webMuted,
                fontSize: 8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------ shared footer

  Widget _links() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionLabel('Keep browsing'),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final link in site.links)
              BrowserHitBox(
                id: 'link_${site.id}_${link.siteId}',
                onTap: () => widget.onOpenSite(link.siteId),
                radius: 9,
                glowColor: site.tint,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: webPanel.withAlpha(220),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: webLine),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.link_rounded, size: 12, color: site.tint),
                      const SizedBox(width: 5),
                      Text(
                        link.label,
                        style: const TextStyle(
                          color: webText,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 11,
                        color: webMuted.withAlpha(180),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _footer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(40),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: webLine.withAlpha(160)),
      ),
      child: Row(
        children: [
          WebChip(label: site.category, color: site.tint, filled: true),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              'Hand-indexed by RetroWeb · page ${site.id.hashCode.abs() % 900 + 100}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: webMuted, fontSize: 8.5),
            ),
          ),
          BrowserHitBox(
            id: 'footer_directory_${site.id}',
            onTap: widget.onOpenDirectory,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(
                'DIRECTORY',
                style: TextStyle(
                  color: webMint,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
