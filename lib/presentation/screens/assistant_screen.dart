import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  late stt.SpeechToText _speech;
  late FlutterTts _tts;
  bool _isListening = false;
  String _recognizedText = '';

  bool _isPushToTalk = true; // Se cargará de shared_preferences

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _tts = FlutterTts();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isPushToTalk = prefs.getBool('assistant_mode_push') ?? true;
    });
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) => print('onStatus: $status'),
      onError: (error) => print('onError: $error'),
    );
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() {
            _recognizedText = result.recognizedWords;
          });
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Micrófono no disponible')),
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
    _interpretCommand(_recognizedText);
  }

  // Lógica de TTS: "Ana" hablando
  Future<void> _speak(String text) async {
    await _tts.setLanguage("es-ES");
    await _tts.setSpeechRate(0.9);
    await _tts.speak(text);
  }

  void _interpretCommand(String command) {
    final cmdLower = command.toLowerCase();

    if (cmdLower.contains('crear nota')) {
      _speak("Creando una nota, abriendo la pantalla de notas");
      Navigator.pushNamed(context, '/notas');
    } else if (cmdLower.contains('crear recordatorio')) {
      _speak("Abriendo el creador de recordatorios");
      Navigator.pushNamed(context, '/crear-recordatorio');
    } else if (cmdLower.contains('mostrar tareas')) {
      _speak("Abriendo tu lista de tareas");
      Navigator.pushNamed(context, '/tareas');
    } else if (cmdLower.contains('calendario')) {
      _speak("Abriendo el calendario");
      Navigator.pushNamed(context, '/calendario');
    } else {
      _speak("Lo siento, no entiendo el comando: $command");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se reconoce el comando: $command')),
      );
    }
  }

  // Manejo del toggle/push en la UI
  void _onMicButtonPressed() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistente de voz “Ana”'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _recognizedText,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildMicButton(isDark),
              const SizedBox(height: 16),
              Text(
                _isPushToTalk
                    ? 'Mantén pulsado para hablar'
                    : (_isListening ? 'Hablando...' : 'Pulsa el micrófono para hablar'),
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Si push-to-talk está activo, es un GestureDetector
  // si no, es un onTap normal
  Widget _buildMicButton(bool isDark) {
    final micColor = _isListening
        ? Colors.redAccent
        : (isDark ? Colors.indigo : Colors.indigo.shade200);

    if (_isPushToTalk) {
      // Modo push-to-talk: Mantener pulsado
      return GestureDetector(
        onTapDown: (_) => _startListening(),
        onTapUp: (_) => _stopListening(),
        child: CircleAvatar(
          radius: 40,
          backgroundColor: micColor,
          child: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.white, size: 40),
        ),
      );
    } else {
      // Modo toggle: un toque para start, otro para stop
      return GestureDetector(
        onTap: _onMicButtonPressed,
        child: CircleAvatar(
          radius: 40,
          backgroundColor: micColor,
          child: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.white, size: 40),
        ),
      );
    }
  }
}
