import 'package:flutter/material.dart';
import 'package:stockman/src/Pages/main_page.dart';
import 'package:stockman/src/config/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stockman/src/config/supabase_config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'src/Pages/Login/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
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
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final session = snapshot.hasData ? snapshot.data!.session : null;

          if (session != null) {
            // Verify the session is still valid by checking if user exists
            return FutureBuilder(
              future: _verifySession(session),
              builder: (context, verifySnapshot) {
                if (verifySnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (verifySnapshot.data == true) {
                  // Valid session - user exists
                  return MainPage(farmerUID: session.user.id);
                } else {
                  // Invalid session - user was deleted or session expired
                  return const LoginPage();
                }
              },
            );
          } else {
            return const LoginPage();
          }
        },
      ),
    );
  }

  // Verify if the session is still valid
  Future<bool> _verifySession(Session session) async {
    try {
      // Try to get the current user - this will fail if user was deleted
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        await Supabase.instance.client.auth.signOut();
        return false;
      }
      // You could also make an API call here to verify the user exists in your database
      return true;
    } catch (e) {
      // If there's an error, sign out and return false
      await Supabase.instance.client.auth.signOut();
      return false;
    }
  }
}
