import 'package:flutter/material.dart';

import '../models/venue.dart';
import 'venue_art/venue_art_base.dart';
import 'venue_art/venue_art_civic.dart';
import 'venue_art/venue_art_everyday.dart';
import 'venue_art/venue_art_outdoors.dart';
import 'venue_art/venue_art_shops.dart';

/// Paints the animated, hand-drawn backdrop for one [Venue].
///
/// The scene is chosen by [Venue.scene] and each artist composes the same
/// building from its own palette, furniture and focal object. [ambient]
/// loops slowly; [reaction] fades from 1 to 0 after an action so the world
/// visibly answers the tap.
class VenueScenePainter extends CustomPainter {
  const VenueScenePainter({
    required this.venue,
    required this.ambient,
    required this.reaction,
  });

  final Venue venue;
  final double ambient;
  final double reaction;

  @override
  void paint(Canvas canvas, Size size) {
    _artist().paint(canvas, size);
  }

  VenueArtist _artist() {
    switch (venue.scene) {
      case VenueScene.classroom:
        return ClassroomArtist(venue, ambient, reaction);
      case VenueScene.plaza:
        return PlazaArtist(venue, ambient, reaction);
      case VenueScene.church:
        return ChurchArtist(venue, ambient, reaction);
      case VenueScene.park:
        return ParkArtist(venue, ambient, reaction);
      case VenueScene.cafe:
        return CafeArtist(venue, ambient, reaction);
      case VenueScene.bank:
        return BankArtist(venue, ambient, reaction);
      case VenueScene.mall:
        return MallArtist(venue, ambient, reaction);
      case VenueScene.garage:
        return GarageArtist(venue, ambient, reaction);
      case VenueScene.bookstore:
        return BookstoreArtist(venue, ambient, reaction);
      case VenueScene.supermarket:
        return SupermarketArtist(venue, ambient, reaction);
      case VenueScene.pizzeria:
        return PizzeriaArtist(venue, ambient, reaction);
      case VenueScene.hospital:
        return HospitalArtist(venue, ambient, reaction);
      case VenueScene.restaurant:
        return RestaurantArtist(venue, ambient, reaction);
      case VenueScene.laundry:
        return LaundryArtist(venue, ambient, reaction);
      case VenueScene.police:
        return PoliceArtist(venue, ambient, reaction);
      case VenueScene.computer:
        return ComputerArtist(venue, ambient, reaction);
      case VenueScene.amusement:
        return AmusementArtist(venue, ambient, reaction);
      case VenueScene.beach:
        return BeachArtist(venue, ambient, reaction);
      case VenueScene.fishing:
        return FishingArtist(venue, ambient, reaction);
      case VenueScene.hotel:
        return HotelArtist(venue, ambient, reaction);
    }
  }

  @override
  bool shouldRepaint(VenueScenePainter oldDelegate) =>
      oldDelegate.venue.id != venue.id ||
      oldDelegate.ambient != ambient ||
      oldDelegate.reaction != reaction;
}
