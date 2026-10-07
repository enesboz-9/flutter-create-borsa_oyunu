import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_shell.dart';
import 'services/game_repository.dart';
import 'services/price_service.dart';
import 'state/game_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Gerçek veriye geçerken: MockPriceService -> kendi PriceService'in,
  // LocalGameRepository -> Supabase repository'n.
  final controller = GameController(MockPriceService(), LocalGameRepository());
  await controller.init();

  runApp(
    ChangeNotifierProvider<GameController>.value(
      value: controller,
      child: const BorsaOyunuApp(),
    ),
  );
}

class BorsaOyunuApp extends StatelessWidget {
  const BorsaOyunuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Borsa Oyunu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.teal,
      ),
      home: const HomeShell(),
    );
  }
}
