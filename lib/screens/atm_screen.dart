import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/state/game_state.dart';
import '../services/audio_service.dart';

/// Fullscreen 24-hour ATM: PIN gate (default 000000) -> menu -> balance /
/// withdraw / deposit / change PIN -> receipt. All money moves through
/// GameState, so cash, bank balance and time stay consistent.
class AtmScreen extends ConsumerStatefulWidget {
  const AtmScreen({super.key});

  @override
  ConsumerState<AtmScreen> createState() => _AtmScreenState();
}

enum _AtmStep { pin, menu, withdraw, deposit, changePin, receipt }

class _AtmScreenState extends ConsumerState<AtmScreen> {
  _AtmStep _step = _AtmStep.pin;
  String _entry = '';
  String _error = '';
  String _receipt = '';
  String _receiptTitle = '';
  bool _receiptOk = true;

  // Change-PIN flow state: current -> new -> confirm.
  String _pendingCurrentPin = '';
  String _pendingNewPin = '';
  bool _confirmingPin = false;

  static const _gold = Color(0xFFFFD966);
  static const _teal = Color(0xFF1B3A2D);
  static const _ink = Color(0xFF111417);

  int get _pinLen => GameState.atmPinLength;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _clearError() {
    if (_error.isNotEmpty) setState(() => _error = '');
  }

  void _press(String digit) {
    _clearError();
    final cap = _step == _AtmStep.withdraw || _step == _AtmStep.deposit
        ? 6
        : _pinLen;
    if (_entry.length >= cap) return;
    setState(() => _entry += digit);
    if ((_step == _AtmStep.pin || _step == _AtmStep.changePin) &&
        _entry.length == _pinLen) {
      _submitPin();
    }
  }

  void _backspace() {
    _clearError();
    if (_entry.isNotEmpty) setState(() => _entry = _entry.substring(0, _entry.length - 1));
  }

  void _clear() => setState(() {
    _entry = '';
    _error = '';
  });

  void _submitPin() {
    final gs = ref.read(gameStateProvider);
    if (_step == _AtmStep.pin) {
      if (gs.verifyAtmPin(_entry)) {
        AudioService().coins();
        setState(() {
          _step = _AtmStep.menu;
          _entry = '';
        });
      } else {
        setState(() {
          _error = 'Wrong PIN. Try again.';
          _entry = '';
        });
      }
      return;
    }
    // Change-PIN: current -> new -> confirm, each 6 digits.
    if (_pendingCurrentPin.isEmpty) {
      if (!gs.verifyAtmPin(_entry)) {
        setState(() {
          _error = 'Current PIN is wrong.';
          _entry = '';
        });
        return;
      }
      setState(() {
        _pendingCurrentPin = _entry;
        _entry = '';
      });
      return;
    }
    if (!_confirmingPin) {
      setState(() {
        _pendingNewPin = _entry;
        _confirmingPin = true;
        _entry = '';
      });
      return;
    }
    if (_entry != _pendingNewPin) {
      setState(() {
        _error = 'PINs do not match. Start over.';
        _entry = '';
        _pendingCurrentPin = '';
        _pendingNewPin = '';
        _confirmingPin = false;
      });
      return;
    }
    final res = gs.atmChangePin(_pendingCurrentPin, _entry);
    setState(() {
      _pendingCurrentPin = '';
      _pendingNewPin = '';
      _confirmingPin = false;
      _entry = '';
    });
    _showReceipt(
      'PIN Changed',
      res.ok ? 'Your new PIN is active.' : res.reason ?? 'Failed.',
      res.ok,
    );
  }

  void _doWithdraw(int amount) {
    final gs = ref.read(gameStateProvider);
    final res = gs.atmWithdraw(amount);
    if (res.ok) AudioService().coins();
    _showReceipt(
      'Withdrawal',
      res.ok
          ? 'Dispensed ₱$amount.\nCash: ${gs.pesoBalance}\nBank: ${gs.bankPesoBalance}'
          : res.reason ?? 'Failed.',
      res.ok,
    );
  }

  void _doDeposit(int amount) {
    final gs = ref.read(gameStateProvider);
    final res = gs.atmDeposit(amount);
    if (res.ok) AudioService().coins();
    _showReceipt(
      'Deposit',
      res.ok
          ? 'Accepted ₱$amount.\nCash: ${gs.pesoBalance}\nBank: ${gs.bankPesoBalance}'
          : res.reason ?? 'Failed.',
      res.ok,
    );
  }

  void _showReceipt(String title, String body, bool ok) {
    setState(() {
      _receiptTitle = title;
      _receipt = body;
      _receiptOk = ok;
      _step = _AtmStep.receipt;
      _entry = '';
      _error = '';
    });
  }

  void _goMenu() => setState(() {
    _step = _AtmStep.menu;
    _entry = '';
    _error = '';
    _pendingCurrentPin = '';
    _pendingNewPin = '';
    _confirmingPin = false;
  });

  @override
  Widget build(BuildContext context) {
    final gs = ref.watch(gameStateProvider);
    // Keypad lives only on entry steps; menu/receipt use big buttons.
    final showKeys = _step != _AtmStep.menu && _step != _AtmStep.receipt;
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFF0D1B16),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D1B16), Color(0xFF1B3A2D), Color(0xFF0D1B16)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _header(context),
              Expanded(
                child: showKeys
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Content left, keypad right: everything fits
                          // without vertical overflow on short screens.
                          Expanded(flex: 5, child: _screenPanel(gs)),
                          SizedBox(width: 196, child: _keypad()),
                        ],
                      )
                    : _screenPanel(gs),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _gold,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.account_balance, color: _ink, size: 22),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LIFETRAIL BANK',
                  style: TextStyle(
                    color: _gold,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  '24-HOUR ATM • FIRST BANK',
                  style: TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _screenPanel(GameState gs) {
    return Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F4EC), Color(0xFFCFE3D4)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _gold, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _stepTitle(gs),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _teal,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _stepSubtitle(gs),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: SingleChildScrollView(
              child: Center(child: _stepBody(gs)),
            ),
          ),
          // Fixed-height error slot: showing an error never shifts
          // the layout, so no bottom overflow on small screens.
          SizedBox(
            height: 22,
            child: _error.isEmpty
                ? null
                : Text(
                    _error,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFB3261E),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _stepTitle(GameState gs) {
    return switch (_step) {
      _AtmStep.pin => 'WELCOME',
      _AtmStep.menu => 'MAIN MENU',
      _AtmStep.withdraw => 'WITHDRAW',
      _AtmStep.deposit => 'DEPOSIT',
      _AtmStep.changePin => 'CHANGE PIN',
      _AtmStep.receipt => _receiptTitle.toUpperCase(),
    };
  }

  String _stepSubtitle(GameState gs) {
    return switch (_step) {
      _AtmStep.pin => 'Enter your 6-digit PIN (default 000000)',
      _AtmStep.menu => 'Cash ${gs.pesoBalance} • Bank ${gs.bankPesoBalance}',
      _AtmStep.withdraw => 'Cash ${gs.pesoBalance} • Bank ${gs.bankPesoBalance}',
      _AtmStep.deposit => 'Cash ${gs.pesoBalance} • Bank ${gs.bankPesoBalance}',
      _AtmStep.changePin => _confirmingPin
          ? 'Confirm your new PIN'
          : _pendingCurrentPin.isEmpty
              ? 'Enter current PIN, then a new one'
              : 'Enter a new 6-digit PIN',
      _AtmStep.receipt => _receiptOk ? 'Transaction complete' : 'Heads up',
    };
  }

  Widget _stepBody(GameState gs) {
    return switch (_step) {
      _AtmStep.pin || _AtmStep.changePin => _pinDots(),
      _AtmStep.menu => _menuGrid(),
      _AtmStep.withdraw => _amountEntry(
          quick: const [100, 200, 500, 1000],
          onQuick: _doWithdraw,
          onCustom: () {
            final amount = int.tryParse(_entry) ?? 0;
            _doWithdraw(amount);
          },
        ),
      _AtmStep.deposit => _amountEntry(
          quick: const [100, 200, 500, 1000],
          onQuick: _doDeposit,
          onCustom: () {
            final amount = int.tryParse(_entry) ?? 0;
            _doDeposit(amount);
          },
        ),
      _AtmStep.receipt => _receiptSlip(),
    };
  }

  Widget _pinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pinLen, (i) {
        final filled = i < _entry.length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? _teal : Colors.transparent,
            border: Border.all(color: _teal, width: 2),
          ),
        );
      }),
    );
  }

  Widget _menuGrid() {
    final items = [
      (_Icons.cash, 'Balance', () {
        final gs = ref.read(gameStateProvider);
        _showReceipt(
          'Balance',
          'Cash: ${gs.pesoBalance}\nBank: ${gs.bankPesoBalance}',
          true,
        );
      }),
      (_Icons.withdraw, 'Withdraw', () => setState(() => _step = _AtmStep.withdraw)),
      (_Icons.deposit, 'Deposit', () => setState(() => _step = _AtmStep.deposit)),
      (_Icons.pin, 'Change PIN', () => setState(() => _step = _AtmStep.changePin)),
    ];
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.4,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final (icon, label, tap) in items)
          InkWell(
            onTap: () {
              _clear();
              tap();
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: _teal,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: _gold, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _amountEntry({
    required List<int> quick,
    required void Function(int) onQuick,
    required VoidCallback onCustom,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _teal),
          ),
          child: Text(
            _entry.isEmpty ? '₱0' : '₱$_entry',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: _teal,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final q in quick)
              InkWell(
                onTap: () => onQuick(q),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _gold,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '₱$q',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _ink,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(onPressed: _goMenu, child: const Text('Back')),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: onCustom,
              style: FilledButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Confirm amount',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _receiptSlip() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '*** LIFETRAIL BANK ***',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const Divider(),
          Text(_receipt, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Done')),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _goMenu,
                style: FilledButton.styleFrom(
                  backgroundColor: _teal,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'More',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _keypad() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 14, 14, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final row in [
              ['1', '2', '3'],
              ['4', '5', '6'],
              ['7', '8', '9'],
              ['C', '0', '⌫'],
            ])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final key in row)
                      InkWell(
                        onTap: () {
                          if (key == 'C') {
                            _clear();
                          } else if (key == '⌫') {
                            _backspace();
                          } else {
                            _press(key);
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        hoverColor: _gold.withAlpha(70),
                        splashColor: _gold.withAlpha(90),
                        highlightColor: _gold.withAlpha(50),
                        child: Container(
                          width: 56,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Text(
                            key,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Icon aliases keep the menu table compact.
class _Icons {
  static const cash = Icons.account_balance_wallet_rounded;
  static const withdraw = Icons.money_rounded;
  static const deposit = Icons.savings_rounded;
  static const pin = Icons.pin_rounded;
}
