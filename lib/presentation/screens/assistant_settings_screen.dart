import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AssistantSettingsScreen extends StatefulWidget {
  const AssistantSettingsScreen({super.key});

  @override
  State<AssistantSettingsScreen> createState() => _AssistantSettingsScreenState();
}

class _AssistantSettingsScreenState extends State<AssistantSettingsScreen> {
  bool _isPushToTalk = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isPushToTalk = prefs.getBool('assistant_mode_push') ?? true;
    });
  }

  Future<void> _saveSettings(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('assistant_mode_push', value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes del Asistente de Voz'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Modo push-to-talk'),
            subtitle: const Text('Si está desactivado, se usa modo toggle'),
            value: _isPushToTalk,
            onChanged: (val) {
              setState(() => _isPushToTalk = val);
              _saveSettings(val);
            },
          ),
          // Aquí se pueden añadir más ajustes en el futuro
        ],
      ),
    );
  }
}
