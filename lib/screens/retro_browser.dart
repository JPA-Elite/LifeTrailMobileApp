import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../models/web_site.dart';
import 'retro_site_page.dart';
import 'retro_web_kit.dart';

enum _BrowserOverlay { none, search, directory, bookmarks }

/// A fully clickable RetroWeb browser for the living-room television.
///
/// Steer the corner joystick, drag anywhere in the page, or tap to move the
/// arrow cursor. A tap clicks whatever sits under the cursor; every clickable
/// thing is registered with a [WebCursorController], including links, quiz
/// answers, and browser chrome. The parent television supplies [onExit] and
/// receives the number of destination pages opened through [onPagesVisited].
class RetroBrowser extends StatefulWidget {
  const RetroBrowser({super.key, required this.onExit, this.onPagesVisited});

  final VoidCallback onExit;
  final ValueChanged<int>? onPagesVisited;

  @override
  State<RetroBrowser> createState() => _RetroBrowserState();
}

class _RetroBrowserState extends State<RetroBrowser>
    with SingleTickerProviderStateMixin {
  final WebCursorController _cursor = WebCursorController();
  final ScrollController _scroll = ScrollController();
  final ScrollController _directoryScroll = ScrollController();
  final GlobalKey _viewportKey = GlobalKey();
  final GlobalKey _pageAreaKey = GlobalKey();
  final TextEditingController _search = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final math.Random _random = math.Random();

  /// Joystick: a fixed base in the lower-right corner that steers the cursor
  /// while held. The knob offset is published separately so steering only
  /// repaints the stick, never the whole page.
  static const double _stickRadius = 27;
  static const double _stickHitRadius = 34;
  static const double _stickKnobRadius = 11;
  static const double _stickMaxSpeed = 340;
  static const double _stickDeadzone = 0.2;

  /// Distance from the anchored corner: the right edge and the bottom edge of
  /// the page area. 64 keeps the ring and its touch zone clear of the rail.
  static const Offset _stickInset = Offset(64, 44);

  late final Ticker _stickTicker;
  final ValueNotifier<Offset?> _stickKnob = ValueNotifier<Offset?>(null);
  int? _stickPointer;
  Offset _stickVector = Offset.zero;
  Duration _stickLastTick = Duration.zero;

  final List<String> _history = <String>[WebSiteCatalog.home.id];
  final Set<String> _bookmarks = <String>{};

  int _historyIndex = 0;
  int _pages = 0;
  int _epoch = 0;
  String? _toast;
  Timer? _toastTimer;
  _BrowserOverlay _overlay = _BrowserOverlay.none;
  String? _directoryCategory;

  int? _dragPointer;
  Offset? _dragStart;
  Offset? _dragCursorStart;
  bool _dragging = false;
  bool _cursorReady = false;

  WebSite get _site => WebSiteCatalog.byId(_history[_historyIndex]);

  bool get _canGoBack => _historyIndex > 0;

  bool get _canGoForward => _historyIndex < _history.length - 1;

  @override
  void initState() {
    super.initState();
    _stickTicker = createTicker(_onStickTick);
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _stickTicker.dispose();
    _stickKnob.dispose();
    _cursor.dispose();
    _scroll.dispose();
    _directoryScroll.dispose();
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------------- toasts

  void _showToast(String message) {
    _toastTimer?.cancel();
    if (!mounted) return;
    setState(() => _toast = message);
    _toastTimer = Timer(const Duration(milliseconds: 2400), () {
      if (mounted && _toast == message) setState(() => _toast = null);
    });
  }

  // --------------------------------------------------------------- navigation

  void _open(String id, {bool push = true}) {
    final site = WebSiteCatalog.byId(id);
    if (push) {
      if (_history[_historyIndex] != site.id) {
        _history.removeRange(_historyIndex + 1, _history.length);
        _history.add(site.id);
        _historyIndex = _history.length - 1;
      }
      if (site.id != WebSiteCatalog.home.id) {
        _pages += 1;
        widget.onPagesVisited?.call(_pages);
      }
    }
    _resetPage();
    HapticFeedback.selectionClick();
    _showToast('${site.domain} loaded');
  }

  void _step(int delta) {
    final target = _historyIndex + delta;
    if (target < 0 || target >= _history.length) {
      _showToast(delta < 0 ? 'No earlier page.' : 'No later page.');
      return;
    }
    _historyIndex = target;
    _resetPage();
    HapticFeedback.selectionClick();
    _showToast('${_site.domain} from history');
  }

  void _reload() {
    _epoch += 1;
    _resetPage();
    _showToast('Reloaded ${_site.domain}');
  }

  void _home() {
    if (_site.id == WebSiteCatalog.home.id) {
      _resetPage();
      return;
    }
    _open(WebSiteCatalog.home.id);
  }

  void _surprise() {
    var site = WebSiteCatalog.random(_random);
    for (var attempt = 0; attempt < 5 && site.id == _site.id; attempt++) {
      site = WebSiteCatalog.random(_random);
    }
    _open(site.id);
  }

  void _resetPage() {
    _endStick();
    _cursor.clearHover();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final position in _scroll.positions) {
        if (position.hasContentDimensions) position.jumpTo(0);
      }
    });
    setState(() {
      _overlay = _BrowserOverlay.none;
      _directoryCategory = null;
      _search.clear();
      _toast = null;
    });
  }

  void _toggleBookmark(String id, {bool announce = true}) {
    final site = WebSiteCatalog.byId(id);
    final added = _bookmarks.add(site.id);
    if (!added) _bookmarks.remove(site.id);
    if (announce) {
      _showToast(
        added ? 'Bookmarked ${site.name}.' : 'Removed ${site.name} bookmark.',
      );
    }
    setState(() {});
  }

  // ----------------------------------------------------------------- overlays

  void _openSearch([String? query]) {
    _endStick();
    if (query != null) _search.text = query;
    setState(() => _overlay = _BrowserOverlay.search);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _overlay == _BrowserOverlay.search) {
        _searchFocus.requestFocus();
      }
    });
  }

  void _openDirectory([String? category]) {
    _endStick();
    setState(() {
      _overlay = _BrowserOverlay.directory;
      _directoryCategory = category;
    });
    _cursor.clearHover();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_directoryScroll.hasClients) _directoryScroll.jumpTo(0);
    });
  }

  void _openBookmarks() {
    _endStick();
    setState(() => _overlay = _BrowserOverlay.bookmarks);
    _cursor.clearHover();
  }

  void _closeOverlay() {
    _endStick();
    FocusScope.of(context).unfocus();
    _cursor.clearHover();
    setState(() => _overlay = _BrowserOverlay.none);
  }

  void _submitSearch() {
    final results = WebSiteCatalog.search(_search.text);
    if (results.isEmpty) {
      _showToast('No site matches "${_search.text.trim()}".');
      return;
    }
    _open(results.first.id);
  }

  // ------------------------------------------------------------------- cursor

  void _moveCursorTo(Offset local) {
    _cursor.position.value = _clampCursor(local);
    _updateHover();
  }

  void _setCursor(Offset local) {
    _cursor.position.value = _clampCursor(local);
    _updateHover();
  }

  Offset _clampCursor(Offset local) {
    final box = _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return local;
    return Offset(
      local.dx.clamp(2, math.max(2, box.size.width - 2)).toDouble(),
      local.dy.clamp(2, math.max(2, box.size.height - 2)).toDouble(),
    );
  }

  void _updateHover() {
    final box = _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    _cursor.updateHover(box.localToGlobal(_cursor.position.value));
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (_stickPointer == null &&
        _overlay == _BrowserOverlay.none &&
        _inStickZone(event.position)) {
      _stickPointer = event.pointer;
      _beginStick(event.position);
      return;
    }
    if (_dragPointer != null) return;
    _dragPointer = event.pointer;
    _dragStart = event.localPosition;
    _dragCursorStart = _cursor.position.value;
    _dragging = false;
    _moveCursorTo(event.localPosition);
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (event.pointer == _stickPointer) {
      _steerStick(event.position);
      return;
    }
    if (event.pointer != _dragPointer) return;
    final start = _dragStart;
    if (start == null) {
      _moveCursorTo(event.localPosition);
      return;
    }
    final travel = event.localPosition - start;
    if (!_dragging && travel.distance > 7) _dragging = true;
    if (_dragging) {
      _setCursor((_dragCursorStart ?? start) + travel);
      _edgeScroll(event.localPosition);
    } else {
      _moveCursorTo(event.localPosition);
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (event.pointer == _stickPointer) {
      _endStick();
      return;
    }
    if (event.pointer != _dragPointer) return;
    _dragPointer = null;
    final wasDragging = _dragging;
    _dragStart = null;
    _dragCursorStart = null;
    _dragging = false;
    if (wasDragging) return;
    _moveCursorTo(event.localPosition);
    _clickAt(event.localPosition);
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (event.pointer == _stickPointer) {
      _endStick();
      return;
    }
    if (event.pointer != _dragPointer) return;
    _dragPointer = null;
    _dragStart = null;
    _dragCursorStart = null;
    _dragging = false;
  }

  // ---------------------------------------------------------------- joystick

  /// The stick lives in the page area (between the toolbar and the status
  /// bar), so its centre is resolved from that box in global coordinates:
  /// the same point the painter uses, with no chrome arithmetic to drift.
  Offset? _stickCenterGlobal() {
    final box = _pageAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(
      Offset(
        box.size.width - _stickInset.dx,
        math.max(_stickInset.dy, box.size.height - _stickInset.dy),
      ),
    );
  }

  bool _inStickZone(Offset global) {
    final center = _stickCenterGlobal();
    if (center == null) return false;
    return (global - center).distance <= _stickHitRadius;
  }

  void _beginStick(Offset global) {
    HapticFeedback.selectionClick();
    _stickLastTick = Duration.zero;
    _stickTicker.start();
    _steerStick(global);
  }

  void _steerStick(Offset global) {
    final center = _stickCenterGlobal();
    if (center == null) return;
    final delta = global - center;
    final distance = delta.distance;
    final knob = distance > _stickRadius
        ? delta / distance * _stickRadius
        : delta;
    _stickKnob.value = knob;
    final magnitude = distance / _stickRadius;
    if (magnitude <= _stickDeadzone) {
      _stickVector = Offset.zero;
      return;
    }
    final eased =
        (magnitude.clamp(0.0, 1.0) - _stickDeadzone) / (1 - _stickDeadzone);
    _stickVector = delta / distance * eased;
  }

  void _endStick() {
    _stickPointer = null;
    _stickVector = Offset.zero;
    _stickLastTick = Duration.zero;
    _stickKnob.value = null;
    if (_stickTicker.isActive) _stickTicker.stop();
  }

  void _onStickTick(Duration elapsed) {
    if (_stickPointer == null || _stickVector == Offset.zero) return;
    final last = _stickLastTick;
    _stickLastTick = elapsed;
    if (last == Duration.zero) return;
    final dt = ((elapsed - last).inMicroseconds / 1000000).clamp(0.0, 0.08);
    if (dt <= 0) return;
    _setCursor(
      _cursor.position.value + _stickVector * _stickMaxSpeed * dt.toDouble(),
    );
  }

  void _clickAt(Offset local) {
    final box = _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final global = box.localToGlobal(local);
    final hit = _cursor.hitAt(global);
    if (hit == null) return;
    HapticFeedback.selectionClick();
    hit.onTap();
  }

  void _edgeScroll(Offset local) {
    final box = _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    const chromeTop = 42.0;
    const chromeBottom = 21.0;
    if (local.dy < chromeTop + 20) {
      _scrollBy(-9);
    } else if (local.dy > box.size.height - chromeBottom - 20) {
      _scrollBy(9);
    }
  }

  ScrollController? get _activeScroll {
    if (_overlay == _BrowserOverlay.directory ||
        _overlay == _BrowserOverlay.bookmarks) {
      return _directoryScroll;
    }
    if (_overlay == _BrowserOverlay.search) return null;
    return _scroll;
  }

  void _scrollBy(double delta) {
    final controller = _activeScroll;
    if (controller == null) return;
    final positions = controller.positions;
    if (positions.isEmpty) return;
    final position = positions.last;
    final target = (position.pixels + delta).clamp(
      0.0,
      position.maxScrollExtent,
    );
    position.jumpTo(target.toDouble());
  }

  // --------------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    _scheduleInitialCursor();
    return WebCursorScope(
      controller: _cursor,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (_overlay != _BrowserOverlay.none) {
            _closeOverlay();
          } else if (_canGoBack) {
            _step(-1);
          } else {
            widget.onExit();
          }
        },
        child: Scaffold(
          backgroundColor: webInk,
          resizeToAvoidBottomInset: false,
          body: SafeArea(
            minimum: const EdgeInsets.fromLTRB(5, 4, 5, 4),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: webLine, width: 1),
                color: webInk,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: _handlePointerDown,
                  onPointerMove: _handlePointerMove,
                  onPointerUp: _handlePointerUp,
                  onPointerCancel: _handlePointerCancel,
                  child: Stack(
                    key: _viewportKey,
                    fit: StackFit.expand,
                    children: [
                      Column(
                        children: [
                          _toolbar(),
                          Expanded(
                            child: Stack(
                              key: _pageAreaKey,
                              fit: StackFit.expand,
                              children: [
                                _pageView(),
                                _scrollRail(),
                                if (_overlay == _BrowserOverlay.none)
                                  _joystick(),
                                if (_overlay != _BrowserOverlay.none)
                                  Positioned.fill(child: _overlayView()),
                                if (_toast != null)
                                  Positioned(
                                    left: 46,
                                    right: 46,
                                    bottom: 8,
                                    child: IgnorePointer(
                                      child: _toastPill(_toast!),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          _statusBar(),
                        ],
                      ),
                      Positioned.fill(child: _cursorOverlay()),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cursorOverlay() {
    return IgnorePointer(
      child: ValueListenableBuilder<Offset>(
        valueListenable: _cursor.position,
        builder: (context, position, child) {
          return Stack(
            children: [
              Positioned(
                left: position.dx - 2,
                top: position.dy - 2,
                child: ValueListenableBuilder<String?>(
                  valueListenable: _cursor.hovered,
                  builder: (context, hovered, _) {
                    return SizedBox(
                      key: const ValueKey('retroweb_cursor'),
                      width: 30,
                      height: 32,
                      child: CustomPaint(
                        painter: WebCursorPainter(active: hovered != null),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _scheduleInitialCursor() {
    if (_cursorReady) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _cursorReady) return;
      final box = _viewportKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return;
      _cursorReady = true;
      const chrome = 42.0 + 21.0;
      _cursor.position.value = Offset(
        box.size.width * 0.46,
        42.0 + math.max(40.0, box.size.height - chrome) * 0.52,
      );
      _updateHover();
    });
  }

  Widget _pageView() {
    final site = _site;
    if (site.kind == WebKind.portal) {
      return _PortalPage(
        key: ValueKey('portal_$_epoch'),
        scrollController: _scroll,
        pagesVisited: _pages,
        bookmarks: _bookmarks,
        onOpenSite: _open,
        onSearch: _openSearch,
        onSurprise: _surprise,
        onDirectory: _openDirectory,
        onBookmarks: _openBookmarks,
      );
    }
    return RetroSitePage(
      key: ValueKey('${site.id}_${_historyIndex}_$_epoch'),
      site: site,
      scrollController: _scroll,
      onOpenSite: _open,
      onToast: _showToast,
      isBookmarked: _bookmarks.contains(site.id),
      onToggleBookmark: () => _toggleBookmark(site.id, announce: false),
      onOpenDirectory: _openDirectory,
    );
  }

  // ------------------------------------------------------------------- chrome

  Widget _toolbar() {
    final site = _site;
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF12242F), Color(0xFF091520)],
        ),
        border: Border(bottom: BorderSide(color: webLine, width: 0.8)),
      ),
      child: Row(
        children: [
          _toolButton(
            id: 'power',
            icon: Icons.power_settings_new_rounded,
            color: webCoral,
            tooltip: 'Back to channels',
            onTap: widget.onExit,
          ),
          const SizedBox(width: 5),
          _toolButton(
            id: 'back',
            icon: Icons.arrow_back_rounded,
            onTap: () => _step(-1),
            enabled: _canGoBack,
          ),
          _toolButton(
            id: 'forward',
            icon: Icons.arrow_forward_rounded,
            onTap: () => _step(1),
            enabled: _canGoForward,
          ),
          _toolButton(
            id: 'reload',
            icon: Icons.refresh_rounded,
            onTap: _reload,
          ),
          _toolButton(id: 'home', icon: Icons.home_rounded, onTap: _home),
          const SizedBox(width: 6),
          Expanded(
            child: BrowserHitBox(
              key: const ValueKey('retroweb_address'),
              id: 'address',
              onTap: _openSearch,
              radius: 999,
              child: Container(
                height: 29,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF06101A),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: webLine),
                ),
                child: Row(
                  children: [
                    Icon(
                      site.domain.endsWith('.gov')
                          ? Icons.account_balance_rounded
                          : Icons.lock_rounded,
                      size: 11,
                      color: webMint,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        site.domain,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFD6E7E9),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'SEARCH',
                        style: TextStyle(
                          color: webMuted,
                          fontSize: 7.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 5),
          _toolButton(
            id: 'bookmark',
            icon: _bookmarks.contains(site.id)
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            color: _bookmarks.contains(site.id) ? webAmber : webMuted,
            tooltip: 'Bookmark this page',
            onTap: () => _toggleBookmark(site.id),
          ),
          _toolButton(
            id: 'directory',
            icon: Icons.grid_view_rounded,
            color: webMint,
            tooltip: 'Open the directory',
            onTap: _openDirectory,
          ),
          _toolButton(
            id: 'bookmarks',
            icon: Icons.bookmarks_rounded,
            color: webAmber,
            tooltip: 'Bookmarks',
            onTap: _openBookmarks,
          ),
          _toolButton(
            id: 'surprise',
            icon: Icons.casino_rounded,
            color: webAmber,
            tooltip: 'Surprise me',
            onTap: _surprise,
          ),
        ],
      ),
    );
  }

  Widget _toolButton({
    required String id,
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
    Color color = webMuted,
    bool enabled = true,
  }) {
    return BrowserHitBox(
      id: id,
      onTap: enabled ? onTap : () => _showToast('Nothing to $id.'),
      radius: 7,
      glowColor: color,
      child: SizedBox(
        width: 27,
        height: 28,
        child: Icon(
          icon,
          size: 16,
          color: enabled ? color : color.withAlpha(70),
        ),
      ),
    );
  }

  Widget _scrollRail() {
    return Positioned(
      right: 2,
      top: 6,
      bottom: 6,
      width: 22,
      child: IgnorePointer(
        ignoring: _overlay != _BrowserOverlay.none,
        child: Opacity(
          opacity: _overlay == _BrowserOverlay.none ? 1 : 0,
          child: Column(
            children: [
              _railButton(Icons.keyboard_arrow_up_rounded, 'scroll_up', -120),
              const SizedBox(height: 2),
              Expanded(child: _scrollThumb(_scroll)),
              const SizedBox(height: 2),
              _railButton(
                Icons.keyboard_arrow_down_rounded,
                'scroll_down',
                120,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _joystick() {
    return Positioned.fill(
      child: IgnorePointer(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final center = Offset(
              constraints.maxWidth - _stickInset.dx,
              math.max(_stickInset.dy, constraints.maxHeight - _stickInset.dy),
            );
            return ValueListenableBuilder<Offset?>(
              valueListenable: _stickKnob,
              builder: (context, knob, _) {
                final active = knob != null;
                final offset = knob ?? Offset.zero;
                return Stack(
                  children: [
                    Positioned(
                      left: center.dx - _stickRadius,
                      top: center.dy - _stickRadius,
                      width: _stickRadius * 2,
                      height: _stickRadius * 2,
                      child: CustomPaint(
                        key: const ValueKey('retroweb_stick_base'),
                        painter: _StickFacePainter(active: active),
                      ),
                    ),
                    Positioned(
                      left: center.dx + offset.dx - _stickKnobRadius,
                      top: center.dy + offset.dy - _stickKnobRadius,
                      width: _stickKnobRadius * 2,
                      height: _stickKnobRadius * 2,
                      child: DecoratedBox(
                        key: const ValueKey('retroweb_stick_knob'),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: webMint.withAlpha(active ? 235 : 95),
                          border: Border.all(
                            color: Colors.black.withAlpha(active ? 120 : 60),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: webMint.withAlpha(active ? 110 : 30),
                              blurRadius: active ? 10 : 5,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _railButton(IconData icon, String id, double delta) {
    return BrowserHitBox(
      id: id,
      onTap: () => _scrollBy(delta),
      radius: 5,
      child: Container(
        width: 20,
        height: 18,
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(80),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: webLine.withAlpha(160)),
        ),
        child: Icon(icon, size: 13, color: webMuted),
      ),
    );
  }

  Widget _scrollThumb(ScrollController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            var fraction = 0.0;
            var visible = 0.45;
            final positions = controller.positions;
            if (positions.isNotEmpty) {
              final position = positions.last;
              if (position.maxScrollExtent > 0) {
                fraction = (position.pixels / position.maxScrollExtent)
                    .clamp(0.0, 1.0)
                    .toDouble();
                visible =
                    (position.viewportDimension /
                            (position.maxScrollExtent +
                                position.viewportDimension))
                        .clamp(0.12, 1.0)
                        .toDouble();
              }
            }
            final track = constraints.maxHeight;
            final height = math.max(12.0, track * visible);
            final top = (track - height) * fraction;
            return Stack(
              children: [
                Positioned.fill(
                  child: Center(
                    child: Container(width: 2, color: webLine.withAlpha(120)),
                  ),
                ),
                Positioned(
                  top: top,
                  left: 7,
                  child: Container(
                    width: 6,
                    height: height,
                    decoration: BoxDecoration(
                      color: webMint.withAlpha(170),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _statusBar() {
    final site = _site;
    return Container(
      height: 21,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF08121B),
        border: Border(top: BorderSide(color: webLine, width: 0.8)),
      ),
      child: Row(
        children: [
          const Text(
            'RETROWEB',
            style: TextStyle(
              color: webMint,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '100 sites',
            style: TextStyle(color: webMuted.withAlpha(200), fontSize: 8),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${site.domain} · ${site.category}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: webMuted, fontSize: 8),
            ),
          ),
          Text(
            '$_pages ${_pages == 1 ? 'page' : 'pages'} visited',
            style: const TextStyle(
              color: webAmber,
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'JOYSTICK or DRAG · TAP click',
            style: TextStyle(color: webMuted, fontSize: 8),
          ),
        ],
      ),
    );
  }

  Widget _toastPill(String message) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 160),
      child: Container(
        key: ValueKey(message),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF0D2A32).withAlpha(245),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: webMint.withAlpha(110)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.travel_explore_rounded, size: 12, color: webMint),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                message,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: webText,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------- overlays

  Widget _overlayView() {
    return Stack(
      children: [
        Positioned.fill(
          child: BrowserHitBox(
            id: 'overlay_scrim',
            onTap: _closeOverlay,
            radius: 0,
            glowColor: Colors.transparent,
            hoverColor: Colors.transparent,
            child: Container(color: Colors.black.withAlpha(155)),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: BrowserHitBox(
              id: 'overlay_panel_block',
              onTap: () {},
              radius: 13,
              glowColor: Colors.transparent,
              hoverColor: Colors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 760,
                  maxHeight: 400,
                ),
                child: switch (_overlay) {
                  _BrowserOverlay.search => _searchOverlay(),
                  _BrowserOverlay.directory => _directoryOverlay(),
                  _BrowserOverlay.bookmarks => _bookmarksOverlay(),
                  _BrowserOverlay.none => const SizedBox.shrink(),
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _panel({
    required String title,
    required IconData icon,
    required Widget body,
    Widget? actions,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A1722),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: webMint.withAlpha(90)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 28,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(5),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(13),
              ),
              border: const Border(bottom: BorderSide(color: webLine)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 15, color: webMint),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: webText,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (actions != null) ...[actions, const SizedBox(width: 5)],
                BrowserHitBox(
                  id: 'overlay_close',
                  onTap: _closeOverlay,
                  radius: 6,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded, size: 16, color: webMuted),
                  ),
                ),
              ],
            ),
          ),
          Flexible(child: body),
        ],
      ),
    );
  }

  Widget _searchOverlay() {
    final query = _search.text.trim();
    final results = WebSiteCatalog.search(query).take(5).toList();
    return _panel(
      title: 'Search the directory',
      icon: Icons.search_rounded,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF050D15),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: webMint.withAlpha(80)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.travel_explore_rounded,
                    size: 15,
                    color: webMint,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: TextField(
                      key: const ValueKey('retroweb_search_field'),
                      controller: _search,
                      focusNode: _searchFocus,
                      autofocus: true,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _submitSearch(),
                      style: const TextStyle(
                        color: webText,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      cursorColor: webMint,
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText:
                            'Search 100 sites — try "bread", "space", "quiz"',
                        hintStyle: TextStyle(
                          color: webMuted.withAlpha(150),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                  if (_search.text.isNotEmpty)
                    BrowserHitBox(
                      id: 'search_clear',
                      onTap: () {
                        _search.clear();
                        setState(() {});
                        _searchFocus.requestFocus();
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(3),
                        child: Icon(
                          Icons.backspace_outlined,
                          size: 14,
                          color: webMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      query.isEmpty
                          ? 'POPULAR RIGHT NOW'
                          : '${WebSiteCatalog.search(query).length} MATCHES',
                      style: const TextStyle(
                        color: webMuted,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    if (results.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.sentiment_dissatisfied_rounded,
                              size: 22,
                              color: webMuted,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'No site found for "$query".',
                              style: const TextStyle(
                                color: webMuted,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'Try a category, a topic, or part of a domain.',
                              style: TextStyle(color: webMuted, fontSize: 8.5),
                            ),
                          ],
                        ),
                      )
                    else
                      for (final site in results) _searchResult(site),
                    if (query.isEmpty) ...[
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: [
                          for (final word in const [
                            'recipe',
                            'space',
                            'quiz',
                            'radio',
                            'repair',
                            'film',
                          ])
                            BrowserHitBox(
                              id: 'search_suggest_$word',
                              onTap: () {
                                _search.text = word;
                                setState(() {});
                                _searchFocus.requestFocus();
                              },
                              radius: 999,
                              child: WebChip(label: word, color: webMuted),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                _overlayAction(
                  id: 'search_enter',
                  label: 'Open first result',
                  icon: Icons.keyboard_return_rounded,
                  onTap: _submitSearch,
                ),
                const Spacer(),
                const Text(
                  'ENTER to open · ESC closes',
                  style: TextStyle(color: webMuted, fontSize: 7.5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchResult(WebSite site) {
    return BrowserHitBox(
      id: 'search_result_${site.id}',
      onTap: () => _open(site.id),
      radius: 8,
      glowColor: site.tint,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: webLine.withAlpha(140)),
        ),
        child: Row(
          children: [
            Text(site.glyph, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    site.name,
                    style: const TextStyle(
                      color: webText,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    site.domain,
                    style: const TextStyle(color: webMuted, fontSize: 8),
                  ),
                ],
              ),
            ),
            WebChip(label: site.category, color: site.tint),
            const SizedBox(width: 5),
            const Icon(Icons.arrow_forward_rounded, size: 12, color: webMuted),
          ],
        ),
      ),
    );
  }

  Widget _overlayAction({
    required String id,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    Color color = webMint,
  }) {
    return BrowserHitBox(
      id: id,
      onTap: onTap,
      radius: 8,
      glowColor: color,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(22),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(110)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _directoryOverlay() {
    final sites = _directoryCategory == null
        ? WebSiteCatalog.directory
        : WebSiteCatalog.inCategory(_directoryCategory!);
    return _panel(
      title: 'The directory · ${sites.length} sites',
      icon: Icons.grid_view_rounded,
      actions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _railButton(Icons.keyboard_arrow_up_rounded, 'directory_up', -120),
          const SizedBox(width: 3),
          _railButton(Icons.keyboard_arrow_down_rounded, 'directory_down', 120),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 25,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _categoryChip(null, 'All', WebSiteCatalog.directory.length),
                  for (final category in WebSiteCatalog.categoryOrder)
                    _categoryChip(
                      category,
                      category,
                      WebSiteCatalog.countIn(category),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 7),
            Flexible(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 640 ? 3 : 2;
                  return GridView.builder(
                    controller: _directoryScroll,
                    padding: const EdgeInsets.only(right: 18),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 5,
                      crossAxisSpacing: 5,
                      mainAxisExtent: 36,
                    ),
                    itemCount: sites.length,
                    itemBuilder: (context, index) {
                      final site = sites[index];
                      return BrowserHitBox(
                        id: 'directory_${site.id}',
                        onTap: () => _open(site.id),
                        radius: 7,
                        glowColor: site.tint,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(4),
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(color: webLine.withAlpha(150)),
                          ),
                          child: Row(
                            children: [
                              Text(
                                site.glyph,
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      site.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: webText,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      site.domain,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: webMuted,
                                        fontSize: 7,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: site.tint,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                WebChip(
                  label: '$_pages pages visited',
                  color: webAmber,
                  icon: Icons.explore_rounded,
                ),
                const Spacer(),
                const Text(
                  'Tap a category to filter',
                  style: TextStyle(color: webMuted, fontSize: 8),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryChip(String? category, String label, int count) {
    final selected = _directoryCategory == category;
    final tint = category == null
        ? webMint
        : (WebSiteCatalog.categoryColor[category] ?? webMint);
    return BrowserHitBox(
      id: 'category_${category ?? 'all'}',
      onTap: () {
        setState(() => _directoryCategory = category);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_directoryScroll.hasClients) _directoryScroll.jumpTo(0);
        });
      },
      radius: 999,
      glowColor: tint,
      child: Container(
        margin: const EdgeInsets.only(right: 5),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? tint.withAlpha(40) : Colors.white.withAlpha(5),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? tint : webLine),
        ),
        child: Text(
          '$label $count',
          style: TextStyle(
            color: selected ? tint : webMuted,
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _bookmarksOverlay() {
    final sites = [for (final id in _bookmarks) WebSiteCatalog.byId(id)];
    return _panel(
      title: 'Bookmarks · ${sites.length}',
      icon: Icons.bookmarks_rounded,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: sites.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 22),
                child: Column(
                  children: [
                    const Icon(
                      Icons.bookmark_border_rounded,
                      size: 26,
                      color: webMuted,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'No bookmarks yet.',
                      style: TextStyle(
                        color: webText,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Tap the bookmark icon while reading a site.',
                      style: TextStyle(
                        color: webMuted.withAlpha(220),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          for (final site in sites)
                            BrowserHitBox(
                              id: 'bookmark_row_${site.id}',
                              onTap: () => _open(site.id),
                              radius: 8,
                              glowColor: site.tint,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 5),
                                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(4),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: webLine.withAlpha(150),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      site.glyph,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(width: 7),
                                    Expanded(
                                      child: Text(
                                        '${site.name} · ${site.domain}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: webText,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                    WebChip(
                                      label: site.category,
                                      color: site.tint,
                                    ),
                                    const SizedBox(width: 5),
                                    BrowserHitBox(
                                      id: 'bookmark_remove_${site.id}',
                                      onTap: () => _toggleBookmark(site.id),
                                      child: const Padding(
                                        padding: EdgeInsets.all(3),
                                        child: Icon(
                                          Icons.delete_outline_rounded,
                                          size: 14,
                                          color: webCoral,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// The hand-indexed start page.
class _PortalPage extends StatelessWidget {
  const _PortalPage({
    super.key,
    required this.scrollController,
    required this.pagesVisited,
    required this.bookmarks,
    required this.onOpenSite,
    required this.onSearch,
    required this.onSurprise,
    required this.onDirectory,
    required this.onBookmarks,
  });

  final ScrollController scrollController;
  final int pagesVisited;
  final Set<String> bookmarks;
  final ValueChanged<String> onOpenSite;
  final VoidCallback onSearch;
  final VoidCallback onSurprise;
  final ValueChanged<String?> onDirectory;
  final VoidCallback onBookmarks;

  @override
  Widget build(BuildContext context) {
    final picks = [
      WebSiteCatalog.byId('harbor_herald'),
      WebSiteCatalog.byId('silicon_sand'),
      WebSiteCatalog.byId('quiz_jar'),
      WebSiteCatalog.byId('nightwave_fm'),
      WebSiteCatalog.byId('skillet_club'),
      WebSiteCatalog.byId('moss_map'),
    ];
    return SingleChildScrollView(
      controller: scrollController,
      // The browser's drag gesture moves the cursor, so the portal must
      // not steal it: scrolling happens through the rail or the edges.
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 12, 34, 22),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _hero(),
              const SizedBox(height: 10),
              _actions(),
              const SizedBox(height: 12),
              _categoryRow(),
              const SizedBox(height: 12),
              const Text(
                'TODAY’S PICKS',
                style: TextStyle(
                  color: webMuted,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 6),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 700 ? 3 : 2;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: picks.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      mainAxisExtent: 76,
                    ),
                    itemBuilder: (context, index) =>
                        _pickCard(picks[index], index),
                  );
                },
              ),
              const SizedBox(height: 10),
              _tip(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF103A3A), Color(0xFF0A1B2A), Color(0xFF1A1030)],
        ),
        border: Border.all(color: webMint.withAlpha(90)),
        boxShadow: [
          BoxShadow(
            color: webMint.withAlpha(20),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5EEAD4), Color(0xFF2563EB)],
                        ),
                      ),
                      child: const Icon(
                        Icons.public_rounded,
                        size: 17,
                        color: Color(0xFF04121C),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'RETROWEB',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.4,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 7),
                    const WebChip(label: 'v2.6', color: webAmber, filled: true),
                  ],
                ),
                const SizedBox(height: 7),
                const Text(
                  'The small web, hand-indexed.',
                  style: TextStyle(
                    color: Color(0xFFBFE8E2),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'One hundred places worth a look. Drag the cursor, '
                  'tap to click, and follow anything that sounds interesting.',
                  style: TextStyle(
                    color: Colors.white.withAlpha(150),
                    fontSize: 9.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '100',
                style: TextStyle(
                  color: webMint,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  height: 0.95,
                ),
              ),
              const Text(
                'PLACES',
                style: TextStyle(
                  color: webMuted,
                  fontSize: 7.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '$pagesVisited visited',
                style: const TextStyle(color: webAmber, fontSize: 8.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actions() {
    return Row(
      children: [
        Expanded(
          child: BrowserHitBox(
            id: 'portal_search',
            onTap: onSearch,
            radius: 9,
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF07131D),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: webLine),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search_rounded, size: 15, color: webMint),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Search all 100 sites…',
                      style: TextStyle(color: webMuted, fontSize: 10),
                    ),
                  ),
                  Text(
                    'TYPE',
                    style: TextStyle(
                      color: webMuted,
                      fontSize: 7,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        BrowserHitBox(
          id: 'portal_surprise',
          onTap: onSurprise,
          radius: 9,
          glowColor: webAmber,
          child: _actionButton(
            icon: Icons.casino_rounded,
            label: 'Surprise me',
            color: webAmber,
          ),
        ),
        const SizedBox(width: 6),
        BrowserHitBox(
          id: 'portal_bookmarks',
          onTap: onBookmarks,
          radius: 9,
          child: _actionButton(
            icon: Icons.bookmarks_rounded,
            label: '${bookmarks.length}',
            color: webCoral,
          ),
        ),
        const SizedBox(width: 6),
        BrowserHitBox(
          id: 'portal_directory',
          onTap: () => onDirectory(null),
          radius: 9,
          child: _actionButton(
            icon: Icons.grid_view_rounded,
            label: 'All sites',
            color: webMint,
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryRow() {
    return SizedBox(
      height: 26,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final category in WebSiteCatalog.categoryOrder)
            BrowserHitBox(
              id: 'portal_category_$category',
              onTap: () => onDirectory(category),
              radius: 999,
              glowColor: WebSiteCatalog.categoryColor[category] ?? webMint,
              child: Container(
                margin: const EdgeInsets.only(right: 5),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4.5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(5),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: webLine),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      WebSiteCatalog.categoryEmoji[category] ?? '•',
                      style: const TextStyle(fontSize: 10),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$category ${WebSiteCatalog.countIn(category)}',
                      style: const TextStyle(
                        color: webMuted,
                        fontSize: 8.5,
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

  Widget _pickCard(WebSite site, int index) {
    return BrowserHitBox(
      id: 'pick_${site.id}',
      onTap: () => onOpenSite(site.id),
      radius: 10,
      glowColor: site.tint,
      child: Container(
        padding: const EdgeInsets.fromLTRB(9, 7, 9, 7),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [site.tint.withAlpha(24), webPanel.withAlpha(230)],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: site.tint.withAlpha(60)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: site.tint.withAlpha(24),
                border: Border.all(color: site.tint.withAlpha(80)),
              ),
              child: Center(
                child: Text(site.glyph, style: const TextStyle(fontSize: 17)),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    site.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: webText,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    site.tagline,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: webMuted,
                      fontSize: 8,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    site.category.toUpperCase(),
                    style: TextStyle(
                      color: site.tint,
                      fontSize: 6.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 14, color: webMuted),
          ],
        ),
      ),
    );
  }

  Widget _tip() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: webMint.withAlpha(9),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: webMint.withAlpha(45)),
      ),
      child: const Row(
        children: [
          Icon(Icons.mouse_rounded, size: 14, color: webMint),
          SizedBox(width: 7),
          Expanded(
            child: Text(
              'Steer the corner joystick or drag anywhere to move the arrow '
              'cursor. Tap once to click. Hold the cursor near the top or '
              'bottom edge to scroll.',
              style: TextStyle(color: webMuted, fontSize: 8.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// The joystick base: a dark well, a ring, and four small direction ticks.
class _StickFacePainter extends CustomPainter {
  const _StickFacePainter({required this.active});

  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = webMint.withAlpha(active ? 210 : 85);
    canvas.drawCircle(
      center,
      radius - 1,
      Paint()..color = const Color(0xFF04131A).withAlpha(active ? 180 : 80),
    );
    canvas.drawCircle(center, radius - 1, ring);
    canvas.drawCircle(
      center,
      radius * 0.62,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = webMint.withAlpha(active ? 70 : 24),
    );
    final tick = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..color = webMint.withAlpha(active ? 200 : 80);
    for (var i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + direction * (radius - 7),
        center + direction * (radius - 2.5),
        tick,
      );
    }
  }

  @override
  bool shouldRepaint(_StickFacePainter oldDelegate) =>
      oldDelegate.active != active;
}
