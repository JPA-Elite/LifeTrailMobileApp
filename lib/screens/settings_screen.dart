import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/state/game_state.dart';
import '../services/audio_service.dart';
import '../services/save_service.dart';

/// Settings, About, and Terms of Service in one tabbed screen.
///
/// Everything here is local to the device: the sound switch is persisted by
/// [AudioService], the slot list and destructive actions go through
/// [PrefsSaveService], and About reads the live [GameState] when a session is
/// loaded.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);
  final PrefsSaveService _save = PrefsSaveService();

  List<Map<String, dynamic>> _slots = const [];
  bool _loadingSaves = true;
  bool _sound = true;

  static const String _version = '0.1.0';
  static const String _updated = 'October 26, 2026';

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _sound = AudioService().enabled;
    // main() initialises this, but the screen still works when opened
    // directly (tests, hot restart) before the singleton has read prefs.
    AudioService().init().then((_) {
      if (mounted) setState(() => _sound = AudioService().enabled);
    });
    _refreshSaves();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _refreshSaves() async {
    final slots = await _save.slotSummaries();
    if (!mounted) return;
    setState(() {
      _slots = slots;
      _loadingSaves = false;
    });
  }

  Future<void> _setSound(bool value) async {
    setState(() => _sound = value);
    HapticFeedback.selectionClick();
    if (value) AudioService().uiTap();
    await AudioService().setEnabled(value);
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
    required Key actionKey,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: actionKey,
              style: FilledButton.styleFrom(
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(action),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<void> _deleteSlot(String slot) async {
    final ok = await _confirm(
      title: 'Delete ${_slotLabel(slot)}?',
      message:
          'This removes the saved life in ${_slotLabel(slot)}. It cannot be '
          'undone, but your current session keeps running until you save again.',
      action: 'Delete',
      actionKey: const ValueKey('settings_confirm_delete'),
    );
    if (!ok) return;
    await _save.deleteSave(slot);
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    await _refreshSaves();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${_slotLabel(slot)} deleted.')));
  }

  Future<void> _resetAll() async {
    final ok = await _confirm(
      title: 'Reset all progress?',
      message:
          'Every save slot will be deleted and the current session will be '
          'cleared. The game returns to the main menu. This cannot be undone.',
      action: 'Reset everything',
      actionKey: const ValueKey('settings_confirm_reset'),
    );
    if (!ok) return;
    for (final slot in PrefsSaveService.slots) {
      await _save.deleteSave(slot);
    }
    ref.read(gameStateProvider).reset();
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  String _slotLabel(String slot) {
    final digit = slot.replaceAll(RegExp(r'[^0-9]'), '');
    return digit.isEmpty ? slot : 'Slot $digit';
  }

  String _slotSummary(Map<String, dynamic> summary) {
    if (summary['empty'] == true) {
      return summary['corrupt'] == true ? 'Unreadable save data' : 'Empty slot';
    }
    final day = summary['day'] ?? 1;
    final chapter = summary['chapter'] ?? 1;
    final money = (summary['money'] as num?)?.toInt() ?? 0;
    return 'Day $day · \$${_money(money)} · Chapter $chapter';
  }

  String _money(int value) => value.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (match) => '${match[1]},',
  );

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value
        .split(RegExp(r'[_\s]+'))
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final game = ref.watch(gameStateProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        bottom: TabBar(
          controller: _tabs,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          tabs: const [
            Tab(key: ValueKey('settings_tab_game'), text: 'Game'),
            Tab(key: ValueKey('settings_tab_about'), text: 'About'),
            Tab(key: ValueKey('settings_tab_terms'), text: 'Terms of Service'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _gameTab(scheme),
          _aboutTab(scheme, game),
          _termsTab(scheme),
        ],
      ),
    );
  }

  Widget _page(List<Widget> children) {
    return SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6, left: 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _panel({required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _gameTab(ColorScheme scheme) {
    return _page([
      _sectionTitle('Audio'),
      _panel(
        children: [
          SwitchListTile(
            key: const ValueKey('settings_sound'),
            secondary: Icon(
              _sound ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: scheme.primary,
            ),
            title: const Text('Sound'),
            subtitle: Text(
              _sound ? 'Sound and music are on.' : 'Sound and music are muted.',
            ),
            value: _sound,
            onChanged: _setSound,
          ),
          const Divider(height: 1),
          const ListTile(
            leading: Icon(Icons.screen_rotation_rounded),
            title: Text('Orientation'),
            subtitle: Text('Landscape only; it auto-rotates left or right.'),
          ),
        ],
      ),
      _sectionTitle('Saved progress'),
      if (_loadingSaves)
        const Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        )
      else
        _panel(
          children: [
            for (var i = 0; i < _slots.length; i++) ...[
              if (i > 0) const Divider(height: 1),
              Builder(
                builder: (context) {
                  final summary = _slots[i];
                  final slot =
                      summary['slot'] as String? ?? PrefsSaveService.slots[i];
                  final empty = summary['empty'] == true;
                  return ListTile(
                    key: ValueKey('settings_slot_$slot'),
                    leading: CircleAvatar(
                      backgroundColor: empty
                          ? scheme.surfaceContainerHighest
                          : scheme.primaryContainer,
                      foregroundColor: empty
                          ? scheme.onSurfaceVariant
                          : scheme.onPrimaryContainer,
                      child: Text('${i + 1}'),
                    ),
                    title: Text(
                      _slotLabel(slot),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(_slotSummary(summary)),
                    trailing: IconButton(
                      key: ValueKey('settings_delete_$slot'),
                      tooltip: 'Delete ${_slotLabel(slot)}',
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: empty ? null : () => _deleteSlot(slot),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      const SizedBox(height: 2),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          key: const ValueKey('settings_reset'),
          style: OutlinedButton.styleFrom(
            foregroundColor: scheme.error,
            side: BorderSide(color: scheme.error.withAlpha(150)),
            padding: const EdgeInsets.symmetric(vertical: 13),
          ),
          onPressed: _resetAll,
          icon: const Icon(Icons.restart_alt_rounded),
          label: const Text('Reset all progress'),
        ),
      ),
      const SizedBox(height: 16),
      Text(
        'Saving is also handled in the Slots screen from the main menu. '
        'Deleting a slot here is permanent.',
        style: TextStyle(
          fontSize: 12,
          color: scheme.onSurfaceVariant,
          height: 1.35,
        ),
      ),
    ]);
  }

  Widget _aboutTab(ColorScheme scheme, GameState game) {
    return _page([
      const SizedBox(height: 6),
      Center(
        child: Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.primaryContainer,
          ),
          child: Icon(
            Icons.hiking_rounded,
            size: 42,
            color: scheme.onPrimaryContainer,
          ),
        ),
      ),
      const SizedBox(height: 10),
      const Center(
        child: Text(
          'Life Trail',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
      ),
      Center(
        child: Text(
          'Version $_version · Original offline life simulation',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
      ),
      const SizedBox(height: 16),
      Text(
        'Life Trail is a small, hand-built life simulation. Walk around town, '
        'meet neighbours, work, study, cook, decorate, browse the RetroWeb on '
        'the living-room television, and take each day at your own pace.',
        style: TextStyle(fontSize: 14, height: 1.45, color: scheme.onSurface),
      ),
      const SizedBox(height: 18),
      _sectionTitle('Your life so far'),
      if (!game.isLoaded)
        Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            key: const ValueKey('settings_about_no_game'),
            leading: Icon(Icons.nights_stay_outlined, color: scheme.primary),
            title: const Text('No game in progress'),
            subtitle: const Text(
              'Start or continue a life from the main menu to see live '
              'health, energy, money, and time here.',
            ),
          ),
        )
      else
        _panel(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _stat(
                    scheme,
                    Icons.calendar_today_rounded,
                    'Day',
                    '${game.time.day}',
                  ),
                  _stat(
                    scheme,
                    Icons.schedule_rounded,
                    'Time',
                    '${game.time.weekdayLabel} ${game.time.clockLabel}',
                  ),
                  _stat(
                    scheme,
                    Icons.auto_stories_rounded,
                    'Chapter',
                    '${game.chapter}',
                  ),
                  _stat(
                    scheme,
                    Icons.favorite_rounded,
                    'Health',
                    '${game.player.health}/100',
                  ),
                  _stat(
                    scheme,
                    Icons.bolt_rounded,
                    'Energy',
                    '${game.player.energy}/100',
                  ),
                  _stat(
                    scheme,
                    Icons.sentiment_satisfied_alt_rounded,
                    'Happiness',
                    '${game.player.happiness}/100',
                  ),
                  _stat(
                    scheme,
                    Icons.payments_rounded,
                    'Money',
                    '\$${_money(game.player.money)}',
                  ),
                  _stat(
                    scheme,
                    Icons.school_rounded,
                    'Education',
                    '${game.player.education}',
                  ),
                  _stat(
                    scheme,
                    Icons.place_rounded,
                    'Location',
                    _titleCase(game.player.locationId),
                  ),
                ],
              ),
            ),
          ],
        ),
      const SizedBox(height: 10),
      _sectionTitle('Credits'),
      _panel(
        children: const [
          ListTile(
            leading: Icon(Icons.brush_rounded),
            title: Text('An original game'),
            subtitle: Text(
              'All characters, art, writing, and stories in Life Trail are '
              'original. No third-party characters or assets are used.',
            ),
          ),
          Divider(height: 1),
          ListTile(
            leading: Icon(Icons.code_rounded),
            title: Text('Built with Flutter and Flame'),
            subtitle: Text(
              'A single-player project made for quiet afternoons and small '
              'screens.',
            ),
          ),
        ],
      ),
    ]);
  }

  Widget _stat(ColorScheme scheme, IconData icon, String label, String value) {
    return Container(
      width: 152,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(140),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: scheme.primary),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _termsTab(ColorScheme scheme) {
    return _page([
      const SizedBox(height: 4),
      const Text(
        'Terms of Service',
        key: ValueKey('settings_terms_title'),
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 4),
      Text(
        'Last updated: $_updated',
        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
      ),
      const SizedBox(height: 16),
      _legal(
        scheme,
        '1. Acceptance',
        'By installing or playing Life Trail you agree to these terms. If you '
            'do not agree, please stop using the app and remove it from your '
            'device.',
      ),
      _legal(
        scheme,
        '2. The game',
        'Life Trail is a single-player, offline life-simulation game provided '
            'for personal entertainment. It is not a substitute for medical, '
            'financial, legal, or other professional advice. Events, people, '
            'businesses, and places in the game are fictional.',
      ),
      _legal(
        scheme,
        '3. Your save data',
        'Progress is stored only on this device. There is no account, cloud '
            'sync, or online backup. Deleting a save slot, clearing the app\'s '
            'storage, uninstalling the app, or resetting all progress removes '
            'that data permanently. You are responsible for keeping your '
            'device safe.',
      ),
      _legal(
        scheme,
        '4. Privacy',
        'Life Trail does not collect personal information. It has no account '
            'system, advertising, analytics, tracking SDKs, or social features, '
            'and it does not send your save data anywhere. The app works '
            'entirely offline; any network access your device performs for '
            'installing or updating the app is handled by your app store, not '
            'by Life Trail.',
      ),
      _legal(
        scheme,
        '5. Purchases',
        'This build is free to play. It contains no in-app purchases, '
            'loot boxes, subscriptions, or advertisements.',
      ),
      _legal(
        scheme,
        '6. Fair use',
        'You may play Life Trail for personal enjoyment. Please do not sell, '
            'redistribute, or claim the game or its original content as your '
            'own. Do not use the app in a way that breaks the law or harms '
            'others.',
      ),
      _legal(
        scheme,
        '7. Availability and changes',
        'The game is provided "as is" and may change, be updated, or be '
            'discontinued at any time. These terms may be revised; the date at '
            'the top of this page shows the latest revision.',
      ),
      _legal(
        scheme,
        '8. Limitation of liability',
        'To the fullest extent allowed by law, the developer is not liable for '
            'any loss of save data, device storage, or other damages arising '
            'from your use of the app. Nothing here limits rights that cannot '
            'be limited by law.',
      ),
      _legal(
        scheme,
        '9. Contact',
        'Life Trail has no online account or support portal. If you need help, '
            'use the documentation or store listing provided with the app.',
      ),
      const SizedBox(height: 6),
      Text(
        'Thank you for taking a quiet walk on the Life Trail.',
        style: TextStyle(
          fontSize: 13,
          fontStyle: FontStyle.italic,
          color: scheme.onSurfaceVariant,
        ),
      ),
    ]);
  }

  Widget _legal(ColorScheme scheme, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
