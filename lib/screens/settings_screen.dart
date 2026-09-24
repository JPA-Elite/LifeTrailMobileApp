import 'package:flutter/material.dart';
import '../services/audio_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsState();
}

class _SettingsState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SwitchListTile(
                title: const Text('Sound'),
                value: AudioService().enabled,
                onChanged: (v) => setState(() => AudioService().enabled = v),
              ),
              const ListTile(
                title: Text('Orientation'),
                subtitle: Text('Landscape only (locked at startup).'),
              ),
              const ListTile(
                title: Text('Credits'),
                subtitle: Text(
                  'Life Trail — an original game. No third-party characters, art, or stories are used.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
