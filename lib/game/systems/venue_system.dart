import '../../models/cooking.dart';
import '../../models/quest_model.dart';
import '../../models/venue.dart';
import '../state/game_state.dart';
import 'core_systems.dart';

/// Result of trying an action inside a venue scene.
class VenueActionOutcome {
  const VenueActionOutcome({
    required this.ok,
    required this.message,
    this.moneySpent = 0,
    this.minutes = 0,
  });

  final bool ok;
  final String message;
  final int moneySpent;
  final int minutes;
}

/// True when the venue's doors are shut right now.
bool venueIsClosed(GameState gs, Venue venue) =>
    !gs.isLocationOpen(venue.id);

/// Why [action] cannot be taken right now, or null when it can.
///
/// When [venue] is supplied, its real opening hours and the action's own
/// one-per-day / quest rules are checked before anything is spent.
String? venueUnavailableReason(
  GameState gs,
  VenueAction action, {
  Venue? venue,
}) {
  if (venue != null && venueIsClosed(gs, venue)) {
    return '${venue.title} is closed. '
        'Hours: ${_hoursFor(venue.id)}.';
  }

  switch (action.special) {
    case VenueSpecial.allowance:
      if ((gs.flags['allowance_day'] ?? -1) == gs.time.day) {
        return 'You already collected today\'s allowance. '
            'Come back tomorrow.';
      }
      break;
    case VenueSpecial.debt:
      if (gs.rentPaid) return 'Your rent is already settled.';
      break;
    case VenueSpecial.attendance:
      if (gs.player.energy < 8) {
        return 'You are too tired to sit through a class.';
      }
      break;
    case VenueSpecial.workShift:
    case VenueSpecial.gymSession:
    case VenueSpecial.pantryRestock:
    case VenueSpecial.walletSearch:
    case VenueSpecial.report:
    case VenueSpecial.bookRoom:
    case VenueSpecial.none:
      break;
  }

  if (action.moneyCost > gs.player.money) {
    return 'You need ₱${action.moneyCost} for that.';
  }
  if (action.energyDelta < 0 &&
      gs.player.energy + action.energyDelta < 0) {
    return 'You are too tired for that. Rest first.';
  }
  return null;
}

String _hoursFor(String venueId) => LocationHours.label(venueId);

/// Applies a venue action to the live game state.
///
/// All checks happen before anything is spent, so a failed attempt is a
/// no-op: no money vanishes, no clock moves, no stats change.
VenueActionOutcome applyVenueAction(
  GameState gs,
  VenueAction action, {
  Venue? venue,
}) {
  final reason = venueUnavailableReason(gs, action, venue: venue);
  if (reason != null) {
    return VenueActionOutcome(ok: false, message: reason);
  }

  if (action.special == VenueSpecial.debt) {
    final result = gs.payRent();
    if (!result.ok) {
      return VenueActionOutcome(
        ok: false,
        message: result.reason ?? 'You cannot pay the rent right now.',
      );
    }
    if (action.minutes > 0) gs.advanceMinutes(action.minutes);
    return VenueActionOutcome(
      ok: true,
      message: action.blurb,
      minutes: action.minutes,
    );
  }

  if (action.special == VenueSpecial.allowance) {
    final result = gs.withdrawAllowance();
    if (!result.ok) {
      return VenueActionOutcome(
        ok: false,
        message: result.reason ?? 'The teller shakes her head.',
      );
    }
    return VenueActionOutcome(
      ok: true,
      message: '${action.blurb} ${result.reason ?? ''}'.trim(),
      minutes: action.minutes,
    );
  }

  if (action.moneyCost > 0) {
    final spent = gs.removeMoney(action.moneyCost);
    if (!spent.ok) {
      return VenueActionOutcome(
        ok: false,
        message: 'Not enough money for that.',
      );
    }
  }

  final minutesBefore = gs.time.day * 1440 + gs.time.minutes;

  switch (action.special) {
    case VenueSpecial.attendance:
      gs.attendClass(present: true);
      break;
    case VenueSpecial.gymSession:
      gs.applyActivity('gym');
      final quest = gs.quests['gym_initiation'];
      if (quest != null && gs.player.strength >= 14) {
        gs.completeObjective('gym_initiation', 'train_strength');
      }
      break;
    case VenueSpecial.workShift:
      gs.applyActivity('work');
      if (action.moneyGain > 0) gs.addMoney(action.moneyGain);
      // The café quest starts the moment you meet Lena behind the counter,
      // and the shift itself is the lunch rush.
      if (gs.quests['cafe_part_time']?.status == QuestStatus.available) {
        gs.startQuest('cafe_part_time');
      }
      gs.completeObjective('cafe_part_time', 'meet_lena');
      gs.completeObjective('cafe_part_time', 'lunch_rush');
      break;
    case VenueSpecial.allowance:
      break;
    case VenueSpecial.pantryRestock:
      PantryCatalog.groceryBundle.forEach(gs.addItem);
      if (action.minutes > 0) gs.advanceMinutes(action.minutes);
      if (action.questId != null && action.objectiveId != null) {
        gs.completeObjective(action.questId!, action.objectiveId!);
      }
      break;
    case VenueSpecial.walletSearch:
      if (action.minutes > 0) gs.advanceMinutes(action.minutes);
      final quest = gs.quests['missing_wallet'];
      if (quest?.status == QuestStatus.active) {
        gs.completeObjective('missing_wallet', 'search_plaza');
        gs.addItem('wallet_maria', 1);
        return VenueActionOutcome(
          ok: true,
          message:
              'A brown wallet is wedged under the bench. Maria\'s name is '
              'inside. You pocket it carefully.',
          moneySpent: action.moneyCost,
          minutes: action.minutes,
        );
      }
      return VenueActionOutcome(
        ok: true,
        message:
            'You search the benches. Crumbs, a bus ticket, and one warm coin '
            '— no wallet today.',
        minutes: action.minutes,
      );
    case VenueSpecial.report:
      if (action.minutes > 0) gs.advanceMinutes(action.minutes);
      if (action.charm != 0) gs.addCharm(action.charm);
      gs.setFlag('filed_police_report');
      break;
    case VenueSpecial.bookRoom:
      gs.sleep();
      gs.changeHealth(action.health);
      return VenueActionOutcome(
        ok: true,
        message:
            'You sleep until 07:00 in a bed that is too big for one. Energy '
            'fully restored.',
        minutes: 0,
      );
    case VenueSpecial.debt:
      break;
    case VenueSpecial.none:
      if (action.minutes > 0) gs.advanceMinutes(action.minutes);
      if (action.energyDelta != 0) gs.changeEnergy(action.energyDelta);
      if (action.happiness != 0) gs.addHappiness(action.happiness);
      if (action.charm != 0) gs.addCharm(action.charm);
      if (action.intelligence != 0) {
        gs.addIntelligence(action.intelligence);
      }
      if (action.strength != 0) gs.addStrength(action.strength);
      if (action.education != 0) gs.addEducation(action.education);
      if (action.health != 0) gs.changeHealth(action.health);
      if (action.moneyGain > 0) gs.addMoney(action.moneyGain);
      if (action.itemId != null && action.itemCount > 0) {
        gs.addItem(action.itemId!, action.itemCount);
      }
      if (action.questId != null && action.objectiveId != null) {
        gs.completeObjective(action.questId!, action.objectiveId!);
      }
      if (action.relationshipNpc != null &&
          action.relationshipDelta != 0) {
        gs.adjustRelationship(
          action.relationshipNpc!,
          action.relationshipDelta,
        );
      }
      if (action.setFlag != null) gs.setFlag(action.setFlag!);
      break;
  }

  final elapsed =
      (gs.time.day * 1440 + gs.time.minutes) - minutesBefore;
  return VenueActionOutcome(
    ok: true,
    message: action.blurb,
    moneySpent: action.moneyCost,
    minutes: elapsed > 0 ? elapsed : action.minutes,
  );
}
