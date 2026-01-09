import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Supabase configuration
/// IMPORTANT: API keys are loaded from .env file for security
/// Never commit API keys to version control!
class SupabaseConfig {
  // Load values from .env file at runtime
  static String get supabaseUrl =>
      dotenv.get('SUPABASE_URL', fallback: 'https://your-project.supabase.co');

  static String get supabaseAnonKey =>
      dotenv.get('SUPABASE_ANON_KEY', fallback: 'your-anon-key-here');

  static String get googleWebClientId => dotenv.get('GOOGLE_WEB_CLIENT_ID',
      fallback: 'your-web-client-id.apps.googleusercontent.com');

  static String get googleAndroidClientId =>
      dotenv.get('GOOGLE_ANDROID_CLIENT_ID',
          fallback: 'your-android-client-id.apps.googleusercontent.com');
}
