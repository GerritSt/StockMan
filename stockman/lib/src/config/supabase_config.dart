/// Supabase configuration
/// IMPORTANT: API keys have been moved to .env file for security
/// Never commit API keys to version control!
class SupabaseConfig {
  // TODO: Load these from .env file using flutter_dotenv or --dart-define
  // For now, these are placeholder values - actual keys are in .env
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project.supabase.co',
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-anon-key-here',
  );

  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: 'your-web-client-id.apps.googleusercontent.com',
  );

  static const String googleAndroidClientId = String.fromEnvironment(
    'GOOGLE_ANDROID_CLIENT_ID',
    defaultValue: 'your-android-client-id.apps.googleusercontent.com',
  );
}
