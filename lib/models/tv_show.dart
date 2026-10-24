import 'package:flutter/material.dart';

/// The art style used by the in-scene TV for a channel.
enum TvVisual { movie, internet, news, cartoon }

/// One channel on the living-room television.
///
/// The activity id points at an [ActivityConfig] in core_systems.dart, which
/// is what actually spends energy and advances the clock. Keeping that data
/// out of the scene means a TV visit behaves exactly like every other
/// activity in the game (and is blocked when the player is too tired).
class TvChannel {
  const TvChannel({
    required this.id,
    required this.title,
    required this.program,
    required this.description,
    required this.activityId,
    required this.visual,
    required this.emoji,
    required this.accent,
    required this.secondary,
  });

  final String id;
  final String title;
  final String program;
  final String description;
  final String activityId;
  final TvVisual visual;
  final String emoji;
  final Color accent;
  final Color secondary;
}

class TvCatalog {
  const TvCatalog._();

  static const List<TvChannel> channels = [
    TvChannel(
      id: 'movie',
      title: 'Movie Night',
      program: 'Neon Harbor',
      description:
          'A rainy-night thriller with a glowing city and a saxophone.',
      activityId: 'tv_movie',
      visual: TvVisual.movie,
      emoji: '🎬',
      accent: Color(0xFFFF6B9A),
      secondary: Color(0xFF6C5CE7),
    ),
    TvChannel(
      id: 'internet',
      title: 'Browse the Internet',
      program: 'RetroWeb',
      description: 'Forums, recipes, a quiz, and one very important cat video.',
      activityId: 'tv_internet',
      visual: TvVisual.internet,
      emoji: '🌐',
      accent: Color(0xFF5EEAD4),
      secondary: Color(0xFF2563EB),
    ),
    TvChannel(
      id: 'news',
      title: 'Watch the News',
      program: 'Channel 7 Live',
      description:
          'Local headlines, weather, and the bakery’s prize-winning pie.',
      activityId: 'tv_news',
      visual: TvVisual.news,
      emoji: '📰',
      accent: Color(0xFFFFC857),
      secondary: Color(0xFFB3261E),
    ),
    TvChannel(
      id: 'cartoons',
      title: 'Saturday Cartoons',
      program: 'Pancake Pals',
      description: 'A sunny, silly cartoon about breakfast that fights back.',
      activityId: 'tv_cartoon',
      visual: TvVisual.cartoon,
      emoji: '🥞',
      accent: Color(0xFFFFD166),
      secondary: Color(0xFF2A9D8F),
    ),
  ];

  static TvChannel? byId(String id) {
    for (final channel in channels) {
      if (channel.id == id) return channel;
    }
    return null;
  }
}
