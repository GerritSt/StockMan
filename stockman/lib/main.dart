import 'package:flutter/material.dart';
import 'package:stockman/src/Pages/main_page.dart';
import 'package:stockman/src/config/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'src/Pages/Login/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAuth.instance.signOut(); // Always sign out on app start
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
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            final user = snapshot.data!;
            // The user is now signed in through the firebase authentication
            // Send the UID through to MainPage
            return MainPage(farmerUID: user.uid);
          } else {
            return const LoginPage();
          }
        },
      ),
    );
  }
}
