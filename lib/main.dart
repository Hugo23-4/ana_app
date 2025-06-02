import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

import 'core/models/services/notification_service.dart';

// Pantallas principales (deshabilitadas temporalmente)
// import 'presentation/screens/auth_screen.dart';
// import 'presentation/screens/home_screen.dart';

// Rutas adicionales (deshabilitadas temporalmente)
// import 'presentation/screens/create_reminder_screen.dart';
// import 'presentation/screens/reminder_list_screen.dart';
// import 'presentation/screens/events_screen.dart';
// import 'presentation/screens/tasks_screen.dart';
// import 'presentation/screens/draw_note_screen.dart';
// import 'presentation/screens/notes_screen.dart';
// import 'presentation/screens/shopping_screen.dart';
// import 'presentation/screens/finances_screen.dart';
// import 'presentation/screens/purchase_history_screen.dart';
// import 'presentation/screens/purchase_stats_screen.dart';
// import 'presentation/screens/finance_stats_screen.dart'; // Archivo no disponible actualmente

// Importaciones para la funcionalidad de Shopping
import 'features/shopping/data/repositories/shopping_repository_impl.dart';
import 'features/shopping/domain/usecases/get_shopping_items_usecase.dart';
import 'features/shopping/domain/usecases/get_purchased_items_usecase.dart';
import 'features/shopping/domain/usecases/add_shopping_item_usecase.dart';
import 'features/shopping/domain/usecases/update_shopping_item_usecase.dart';
import 'features/shopping/domain/usecases/delete_shopping_item_usecase.dart';
import 'features/shopping/domain/usecases/toggle_shopping_item_bought_usecase.dart';
import 'features/shopping/domain/usecases/toggle_shopping_item_recurring_usecase.dart';
import 'features/shopping/presentation/notifiers/shopping_notifier.dart';
import 'features/shopping/presentation/pages/shopping_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Iniciar sesión anónima para no requerir autenticación al usar ShoppingPage
  if (FirebaseAuth.instance.currentUser == null) {
    await FirebaseAuth.instance.signInAnonymously();
  }

  await NotificationService.init(); // Inicializar notificaciones

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final repo = ShoppingRepositoryImpl();
        return ShoppingNotifier(
          getShoppingItemsUseCase: GetShoppingItemsUseCase(repo),
          getPurchasedItemsUseCase: GetPurchasedItemsUseCase(repo),
          addShoppingItemUseCase: AddShoppingItemUseCase(repo),
          updateShoppingItemUseCase: UpdateShoppingItemUseCase(repo),
          deleteShoppingItemUseCase: DeleteShoppingItemUseCase(repo),
          toggleShoppingItemBoughtUseCase: ToggleShoppingItemBoughtUseCase(repo),
          toggleShoppingItemRecurringUseCase: ToggleShoppingItemRecurringUseCase(repo),
        );
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Ana App',
        theme: ThemeData(
          primarySwatch: Colors.indigo,
          scaffoldBackgroundColor: Colors.white,
        ),
        // Rutas de pantallas antiguas inhabilitadas temporalmente
        home: const ShoppingPage(),
      ),
    );
  }
}
