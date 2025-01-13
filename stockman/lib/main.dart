import 'package:flutter/material.dart';
import 'package:stockman/src/Pages/main_page.dart';
import 'package:stockman/src/config/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const StockMan());
}

// put the cronological of the execution of the project here
class StockMan extends StatelessWidget {
  const StockMan({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StockMan',
      theme: AppTheme.lightTheme,
      home: const MainPage(),
    );
  }
}