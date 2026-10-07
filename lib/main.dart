import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants.dart';
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
        colorSchemeSeed: kAccent,
        scaffoldBackgroundColor: kBg,
        appBarTheme: const AppBarTheme(
          backgroundColor: kBg,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: kCard,
          surfaceTintColor: Colors.transparent,
          indicatorColor: kAccent.withOpacity(0.28),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: kCard,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      home: const HomeShell(),
    );
  }
}
