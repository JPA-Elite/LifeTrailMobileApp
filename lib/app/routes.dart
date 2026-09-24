import 'package:flutter/material.dart';
import '../screens/main_menu_screen.dart';
import '../screens/game_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/save_load_screen.dart';

class Routes {
  static const mainMenu = '/';
  static const game = '/game';
  static const settings = '/settings';
  static const saveLoad = '/save-load';

  static Map<String, WidgetBuilder> get table => {
    mainMenu: (_) => const MainMenuScreen(),
    game: (_) => const GameScreen(),
    settings: (_) => const SettingsScreen(),
    saveLoad: (_) => const SaveLoadScreen(),
  };
}
