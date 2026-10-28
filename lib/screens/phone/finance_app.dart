import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../game/state/game_state.dart';
import '../../game/state/phone_state.dart';
import 'phone_ui.dart';

/// The bank app. It can sign in, verify identity, reset the PIN and show the
/// balance — by design there is no deposit or withdrawal path anywhere in
/// this file.
class FinanceApp extends ConsumerStatefulWidget {
  const FinanceApp({super.key});

  @override
  ConsumerState<FinanceApp> createState() => _FinanceAppState();
}

class _FinanceAppState extends ConsumerState<FinanceApp> {
  final _mobile = TextEditingController();
  final _pin = TextEditingController();
  bool _resetFlow = false;
  bool _obscure = true;

  @override
  void dispose() {
    _mobile.dispose();
    _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final finance = ref.watch(financeStateProvider);
    final gs = ref.watch(gameStateProvider);

    if (finance.loggedIn) {
      return _Dashboard(gs: gs, finance: finance);
    }

    return PhoneAppScaffold(
      title: _resetFlow ? 'Reset your PIN' : 'LifeTrail Bank',
      subtitle: _resetFlow
          ? 'Identity check and a new 6-digit PIN'
          : 'Student savings · secure sign in',
      icon: _resetFlow ? Icons.lock_reset_rounded : Icons.account_balance,
      accent: kPhoneAmber,
      actions: [
        if (_resetFlow)
          IconButton(
            tooltip: 'Cancel reset',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.06),
            ),
            onPressed: () {
              ref.read(financeStateProvider).cancelReset();
              setState(() => _resetFlow = false);
            },
            icon: const Icon(Icons.close_rounded, color: kPhoneInk),
          ),
      ],
      body: _resetFlow
          ? _ResetFlow(
              onDone: () {
                _pin.clear();
                setState(() => _resetFlow = false);
              },
            )
          : _LoginForm(
              mobile: _mobile,
              pin: _pin,
              obscure: _obscure,
              onToggleObscure: () => setState(() => _obscure = !_obscure),
              onLogin: () {
                FocusScope.of(context).unfocus();
                ref
                    .read(financeStateProvider)
                    .login(_mobile.text, _pin.text);
              },
              onForgot: () {
                ref.read(financeStateProvider).cancelReset();
                setState(() => _resetFlow = true);
              },
              error: finance.error,
              demoPinVisible: finance.usesDemoPin,
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sign in
// ---------------------------------------------------------------------------

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.mobile,
    required this.pin,
    required this.obscure,
    required this.onToggleObscure,
    required this.onLogin,
    required this.onForgot,
    required this.error,
    required this.demoPinVisible,
  });

  final TextEditingController mobile;
  final TextEditingController pin;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final VoidCallback onLogin;
  final VoidCallback onForgot;
  final String? error;
  final bool demoPinVisible;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 12),
      children: [
        PhoneCard(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          color: kPhonePanelSoft,
          child: Column(
            children: [
              const _BrandMark(),
              const SizedBox(height: 12),
              const Text(
                'Welcome back',
                style: TextStyle(
                  color: kPhoneInk,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Sign in to view your student savings.',
                textAlign: TextAlign.center,
                style: TextStyle(color: kPhoneMuted, fontSize: 12),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: mobile,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
                  LengthLimitingTextInputFormatter(13),
                ],
                style: const TextStyle(color: kPhoneInk, fontSize: 14),
                decoration: phoneFieldDecoration(
                  hint: 'Registered mobile number',
                  icon: Icons.phone_android_rounded,
                  accent: kPhoneAmber,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: pin,
                obscureText: obscure,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                onSubmitted: (_) => onLogin(),
                style: const TextStyle(
                  color: kPhoneInk,
                  fontSize: 16,
                  letterSpacing: 5,
                ),
                decoration: phoneFieldDecoration(
                  hint: '6-digit PIN',
                  icon: Icons.dialpad_rounded,
                  accent: kPhoneAmber,
                  suffix: IconButton(
                    onPressed: onToggleObscure,
                    tooltip: obscure ? 'Show PIN' : 'Hide PIN',
                    icon: Icon(
                      obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: kPhoneMuted,
                      size: 19,
                    ),
                  ),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 10),
                _ErrorBanner(message: error!),
              ],
              const SizedBox(height: 16),
              PhoneButton(
                label: 'Log in',
                icon: Icons.lock_open_rounded,
                color: kPhoneAmber,
                onPressed: onLogin,
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: onForgot,
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(
                    color: kPhoneAmber,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        PhoneCard(
          color: const Color(0xFF1E1A10),
          borderColor: kPhoneAmber.withValues(alpha: 0.22),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.key_rounded,
                color: kPhoneAmber,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DEMO ACCESS',
                      style: TextStyle(
                        color: kPhoneAmber,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mobile ${FinanceState.demoMobile} · Birthday ${FinanceState.demoBirthday}',
                      style: const TextStyle(
                        color: kPhoneInk,
                        fontSize: 11.5,
                        height: 1.4,
                      ),
                    ),
                    Text(
                      demoPinVisible
                          ? 'PIN ${FinanceState.demoPin} · change it anytime'
                          : 'PIN changed this session',
                      style: const TextStyle(
                        color: kPhoneMuted,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined, color: kPhoneMuted, size: 13),
            SizedBox(width: 5),
            Text(
              'View-only account · deposits and withdrawals are locked',
              style: TextStyle(color: kPhoneMuted, fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPhoneAmber, Color(0xFFB97B22)],
        ),
        boxShadow: [
          BoxShadow(
            color: kPhoneAmber.withValues(alpha: 0.22),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(
        Icons.account_balance_rounded,
        color: Color(0xFF231708),
        size: 30,
      ),
    );
  }
}

void _showLockedSnack(BuildContext context, String action) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2A2213),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        content: Row(
          children: [
            const Icon(Icons.lock_outline_rounded, color: kPhoneAmber),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                '$action is disabled on this view-only student account.',
                style: const TextStyle(color: kPhoneInk, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
}

// ---------------------------------------------------------------------------
// Forgot password
// ---------------------------------------------------------------------------

class _ResetFlow extends ConsumerStatefulWidget {
  const _ResetFlow({required this.onDone});

  final VoidCallback onDone;

  @override
  ConsumerState<_ResetFlow> createState() => _ResetFlowState();
}

class _ResetFlowState extends ConsumerState<_ResetFlow> {
  final _mobile = TextEditingController();
  final _birthday = TextEditingController();
  final _pin = TextEditingController();
  final _confirm = TextEditingController();
  bool _done = false;

  @override
  void dispose() {
    _mobile.dispose();
    _birthday.dispose();
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final finance = ref.watch(financeStateProvider);
    if (_done) return _Success(onDone: widget.onDone);

    return ListView(
      padding: const EdgeInsets.only(bottom: 12),
      children: [
        PhoneCard(
          color: kPhonePanelSoft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _StepDot(index: 1, active: !finance.verified),
                  const SizedBox(width: 8),
                  const Text(
                    'Verify it’s you',
                    style: TextStyle(
                      color: kPhoneInk,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _StepDot(index: 2, active: finance.verified),
                  const SizedBox(width: 8),
                  Text(
                    'New PIN',
                    style: TextStyle(
                      color: finance.verified ? kPhoneInk : kPhoneMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (!finance.verified) ...[
                const Text(
                  'Enter the mobile number on file and the birthday linked to the account.',
                  style: TextStyle(
                    color: kPhoneMuted,
                    fontSize: 11.5,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _mobile,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
                    LengthLimitingTextInputFormatter(13),
                  ],
                  style: const TextStyle(color: kPhoneInk, fontSize: 14),
                  decoration: phoneFieldDecoration(
                    hint: FinanceState.demoMobile,
                    icon: Icons.phone_android_rounded,
                    accent: kPhoneAmber,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _birthday,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
                    LengthLimitingTextInputFormatter(10),
                  ],
                  style: const TextStyle(color: kPhoneInk, fontSize: 14),
                  decoration: phoneFieldDecoration(
                    hint: 'Birthday (MM/DD/YYYY)',
                    icon: Icons.cake_outlined,
                    accent: kPhoneAmber,
                  ),
                ),
                if (finance.error != null) ...[
                  const SizedBox(height: 10),
                  _ErrorBanner(message: finance.error!),
                ],
                const SizedBox(height: 14),
                PhoneButton(
                  label: 'Verify identity',
                  icon: Icons.verified_user_outlined,
                  color: kPhoneAmber,
                  onPressed: () => ref
                      .read(financeStateProvider)
                      .verifyIdentity(
                        mobile: _mobile.text,
                        birthday: _birthday.text,
                      ),
                ),
              ] else ...[
                const Text(
                  'Choose a new 6-digit PIN. It replaces the old one immediately.',
                  style: TextStyle(
                    color: kPhoneMuted,
                    fontSize: 11.5,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pin,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  style: const TextStyle(
                    color: kPhoneInk,
                    fontSize: 16,
                    letterSpacing: 5,
                  ),
                  decoration: phoneFieldDecoration(
                    hint: 'New 6-digit PIN',
                    icon: Icons.dialpad_rounded,
                    accent: kPhoneAmber,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _confirm,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  style: const TextStyle(
                    color: kPhoneInk,
                    fontSize: 16,
                    letterSpacing: 5,
                  ),
                  decoration: phoneFieldDecoration(
                    hint: 'Confirm new PIN',
                    icon: Icons.lock_outline_rounded,
                    accent: kPhoneAmber,
                  ),
                ),
                if (finance.error != null) ...[
                  const SizedBox(height: 10),
                  _ErrorBanner(message: finance.error!),
                ],
                const SizedBox(height: 14),
                PhoneButton(
                  label: 'Save new PIN',
                  icon: Icons.check_rounded,
                  color: kPhoneGreen,
                  onPressed: () {
                    final ok = ref
                        .read(financeStateProvider)
                        .resetPin(pin: _pin.text, confirm: _confirm.text);
                    if (ok) {
                      HapticFeedback.lightImpact();
                      setState(() => _done = true);
                    }
                  },
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => ref.read(financeStateProvider).cancelReset(),
                  child: const Text(
                    'Use a different account',
                    style: TextStyle(color: kPhoneMuted, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.index, required this.active});

  final int index;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active
            ? kPhoneAmber.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.05),
        border: Border.all(
          color: active ? kPhoneAmber : Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Text(
        '$index',
        style: TextStyle(
          color: active ? kPhoneAmber : kPhoneMuted,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Success extends StatelessWidget {
  const _Success({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: PhoneCard(
        padding: const EdgeInsets.all(24),
        color: kPhonePanelSoft,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kPhoneGreen.withValues(alpha: 0.14),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: kPhoneGreen,
                size: 34,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'PIN updated',
              style: TextStyle(
                color: kPhoneInk,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Use your new PIN the next time you sign in.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kPhoneMuted,
                fontSize: 12,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            PhoneButton(
              label: 'Back to sign in',
              icon: Icons.login_rounded,
              color: kPhoneAmber,
              onPressed: onDone,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Signed-in dashboard
// ---------------------------------------------------------------------------

class _Dashboard extends StatefulWidget {
  const _Dashboard({required this.gs, required this.finance});

  final GameState gs;
  final FinanceState finance;

  @override
  State<_Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<_Dashboard> {
  bool _hidden = false;
  bool _accountVisible = false;

  @override
  Widget build(BuildContext context) {
    final gs = widget.gs;
    final money = NumberFormat.decimalPattern().format(gs.player.money);
    return PhoneAppScaffold(
      title: 'Finance',
      subtitle: 'Signed in · ${FinanceState.accountHolder}',
      icon: Icons.account_balance_wallet_rounded,
      accent: kPhoneAmber,
      actions: [
        IconButton(
          tooltip: 'Sign out',
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.06),
          ),
          onPressed: () => widget.finance.logout(),
          icon: const Icon(Icons.logout_rounded, color: kPhoneInk, size: 20),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.only(bottom: 12),
        children: [
          // Balance card.
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3A2B14), Color(0xFF16120B)],
              ),
              border: Border.all(
                color: kPhoneAmber.withValues(alpha: 0.26),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'AVAILABLE BALANCE',
                      style: TextStyle(
                        color: kPhoneAmber,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Spacer(),
                    const PhonePill(
                      label: 'View only',
                      color: kPhoneAmber,
                      icon: Icons.visibility_rounded,
                      dense: true,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _hidden ? '₱ ••••••' : '₱$money',
                      style: const TextStyle(
                        color: kPhoneCream,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      tooltip: _hidden ? 'Show balance' : 'Hide balance',
                      onPressed: () => setState(() => _hidden = !_hidden),
                      icon: Icon(
                        _hidden
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: kPhoneMuted,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Student Savings · ${FinanceState.branch}',
                  style: const TextStyle(
                    color: kPhoneMuted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () =>
                      setState(() => _accountVisible = !_accountVisible),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Text(
                          _accountVisible
                              ? FinanceState.accountNumber
                              : '•••• ${FinanceState.accountNumber.substring(FinanceState.accountNumber.length - 4)}',
                          style: const TextStyle(
                            color: kPhoneCream,
                            fontSize: 12.5,
                            letterSpacing: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          _accountVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: kPhoneMuted,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Quick actions, visibly locked.
          PhoneCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      color: kPhoneMuted,
                      size: 15,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'GUARDIAN-LOCKED ACTIONS',
                      style: TextStyle(
                        color: kPhoneMuted,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final action in const [
                      (Icons.south_west_rounded, 'Deposit'),
                      (Icons.north_east_rounded, 'Withdraw'),
                      (Icons.swap_horiz_rounded, 'Transfer'),
                    ])
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () =>
                                _showLockedSnack(context, action.$2),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.05),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    action.$1,
                                    color: kPhoneMuted,
                                    size: 19,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    action.$2,
                                    style: const TextStyle(
                                      color: kPhoneMuted,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Icon(
                                    Icons.lock_rounded,
                                    color: kPhoneAmber,
                                    size: 10,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 9),
                const Text(
                  'Balances are visible for school budgeting. Deposits and '
                  'withdrawals are disabled on minor accounts.',
                  style: TextStyle(
                    color: kPhoneMuted,
                    fontSize: 10.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          PhoneCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RECENT ACTIVITY',
                  style: TextStyle(
                    color: kPhoneMuted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                for (final tx in _activity())
                  _TransactionRow(entry: tx),
              ],
            ),
          ),
          const SizedBox(height: 10),
          PhoneCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ACCOUNT DETAILS',
                  style: TextStyle(
                    color: kPhoneMuted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                _DetailRow(label: 'Holder', value: FinanceState.accountHolder),
                _DetailRow(label: 'Branch', value: FinanceState.branch),
                _DetailRow(
                  label: 'Mobile',
                  value: _maskMobile(FinanceState.demoMobile),
                ),
                const _DetailRow(label: 'Type', value: 'Student savings'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<({String title, String when, int amount, IconData icon})> _activity() {
    return const [
      (
        title: 'School allowance',
        when: 'Today · 07:10',
        amount: 500,
        icon: Icons.savings_outlined,
      ),
      (
        title: 'Canteen',
        when: 'Yesterday · 12:20',
        amount: -85,
        icon: Icons.lunch_dining_outlined,
      ),
      (
        title: 'Bookstore',
        when: '2 days ago · 15:45',
        amount: -120,
        icon: Icons.menu_book_outlined,
      ),
      (
        title: 'Junk shop errand',
        when: '3 days ago · 16:05',
        amount: 60,
        icon: Icons.recycling_outlined,
      ),
      (
        title: 'Savings interest',
        when: '5 days ago',
        amount: 12,
        icon: Icons.trending_up_rounded,
      ),
    ];
  }

  String _maskMobile(String mobile) {
    final digits = mobile.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return mobile;
    return '•••• ${digits.substring(digits.length - 4)}';
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.entry});

  final ({String title, String when, int amount, IconData icon}) entry;

  @override
  Widget build(BuildContext context) {
    final positive = entry.amount >= 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: (positive ? kPhoneGreen : kPhoneMuted).withValues(
                alpha: 0.12,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              entry.icon,
              size: 16,
              color: positive ? kPhoneGreen : kPhoneMuted,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: const TextStyle(
                    color: kPhoneInk,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  entry.when,
                  style: const TextStyle(
                    color: kPhoneMuted,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${positive ? '+' : '−'}₱${NumberFormat.decimalPattern().format(entry.amount.abs())}',
            style: TextStyle(
              color: positive ? kPhoneGreen : kPhoneInk,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(color: kPhoneMuted, fontSize: 11.5),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: kPhoneInk,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: kPhoneRose.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPhoneRose.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: kPhoneRose,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: kPhoneRose,
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
