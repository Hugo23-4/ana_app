import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

import 'core/models/services/notification_service.dart';

// Pantallas principales
import 'presentation/screens/auth_screen.dart';
import 'presentation/screens/home_screen.dart';

// Rutas adicionales
import 'presentation/screens/create_reminder_screen.dart';
import 'presentation/screens/reminder_list_screen.dart';
import 'presentation/screens/events_screen.dart';
import 'presentation/screens/tasks_screen.dart';
import 'presentation/screens/draw_note_screen.dart';
import 'presentation/screens/notes_screen.dart';
import 'presentation/screens/shopping_screen.dart';
import 'presentation/screens/finances_screen.dart';
import 'presentation/screens/purchase_history_screen.dart';
import 'presentation/screens/purchase_stats_screen.dart';
import 'presentation/screens/finance_stats_screen.dart'; // ✅ Asegúrate que este archivo exista

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService.init(); // Inicializar notificaciones

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ana App',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.white,
      ),
      routes: {
        '/crear-recordatorio': (_) => const CreateReminderScreen(),
        '/ver-recordatorios': (_) => const ReminderListScreen(),
        '/eventos': (_) => const EventsScreen(),
        '/tareas': (_) => const TasksScreen(),
        '/nota-dibujada': (_) => const DrawNoteScreen(),
        '/notas': (_) => const NotesScreen(),
        '/compras': (_) => const ShoppingScreen(),
        '/finanzas': (_) => const FinancesScreen(),
        '/historial-compras': (_) => const PurchaseHistoryScreen(),
        '/estadisticas-compras': (_) => const PurchaseStatsScreen(),
        '/estadisticas-financieras': (_) => const FinanceStatsScreen(),
        '/asistente-voz': (_) => const AssistantScreen(),
        '/asistente-voz': (_) => const AssistantScreen(),
        '/ajustes-asistente': (_) => const AssistantSettingsScreen(),
      },
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData) {
            return const HomeScreen(); // Usuario autenticado
          }

          return const AuthScreen(); // Usuario no autenticado
        },
      ),
    );
  }
}