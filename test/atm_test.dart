import 'package:flutter_test/flutter_test.dart';
import 'package:lifetrail/game/state/game_state.dart';

GameState _fresh() {
  final gs = GameState();
  gs.loadSnapshot(
    player: gs.player,
    time: gs.time,
    npcs: {},
    quests: {},
    flags: {},
    inventory: [],
  );
  return gs;
}

void main() {
  test('default PIN is 000000 and verifies', () {
    final gs = _fresh();
    expect(gs.atmPin, '000000');
    expect(gs.verifyAtmPin('000000'), isTrue);
    expect(gs.verifyAtmPin('123456'), isFalse);
  });

  test('withdraw moves bank -> cash and costs time', () {
    final gs = _fresh();
    final bankBefore = gs.bankBalance; // 2000
    final cashBefore = gs.player.money; // 500
    final minutesBefore = gs.time.minutes;
    final res = gs.atmWithdraw(300);
    expect(res.ok, isTrue);
    expect(gs.bankBalance, bankBefore - 300);
    expect(gs.player.money, cashBefore + 300);
    expect(gs.time.minutes, greaterThan(minutesBefore));
  });

  test('withdraw fails on insufficient bank balance', () {
    final gs = _fresh();
    final res = gs.atmWithdraw(gs.bankBalance + 1);
    expect(res.ok, isFalse);
    expect(gs.player.money, 500);
  });

  test('deposit moves cash -> bank and rejects broke users', () {
    final gs = _fresh();
    expect(gs.atmDeposit(200).ok, isTrue);
    expect(gs.player.money, 300);
    expect(gs.bankBalance, 2200);
    expect(gs.atmDeposit(999999).ok, isFalse);
  });

  test('change PIN round-trips and rejects wrong current', () {
    final gs = _fresh();
    expect(gs.atmChangePin('111111', '123456').ok, isFalse);
    expect(gs.atmChangePin('000000', '123456').ok, isTrue);
    expect(gs.verifyAtmPin('123456'), isTrue);
    expect(gs.verifyAtmPin('000000'), isFalse);
    expect(gs.atmChangePin('123456', '12345').ok, isFalse);
    expect(gs.atmChangePin('123456', '123456').ok, isFalse);
  });
}
