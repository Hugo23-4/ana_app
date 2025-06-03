import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

import 'core/models/services/notification_service.dart';
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Login anónimo
  if (FirebaseAuth.instance.currentUser == null) {
    await FirebaseAuth.instance.signInAnonymously();
  }

  // Inicializar notificaciones (manejar posibles errores)
  try {
    await NotificationService.init();
  } catch (e) {
    debugPrint('Error al iniciar notificaciones: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
          toggleShoppingItemRecurringUseCase:
              ToggleShoppingItemRecurringUseCase(repo),
        );
      },
      child: MaterialApp(
        title: 'Ana App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.indigo,
          scaffoldBackgroundColor: Colors.white,
        ),
        home: const ShoppingPage(),
      ),
    );
  }
}
