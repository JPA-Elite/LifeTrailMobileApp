import 'package:flutter/material.dart';
import 'routes.dart';
import 'theme.dart';

class LifeTrailApp extends StatelessWidget {
  const LifeTrailApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Life Trail',
      debugShowCheckedModeBanner: false,
      theme: LifeTrailTheme.light,
      darkTheme: LifeTrailTheme.dark,
      themeMode: ThemeMode.system,
      initialRoute: Routes.mainMenu,
      routes: Routes.table,
    );
  }
}
