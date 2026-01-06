/// Supabase configuration
/// Replace these with your actual Supabase project URL and anon key
/// You can find these in your Supabase project dashboard under Settings > API
class SupabaseConfig {
  static const String supabaseUrl = 'https://obqkmorzxfmecarodsnx.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9icWttb3J6eGZtZWNhcm9kc254Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA1MjQ3OTgsImV4cCI6MjA3NjEwMDc5OH0.V1dATtgSEEV64rYn2GI94AvKIbdAEIbouRUGV2YYFWA';

  // Google Sign-In Web Client ID (from Google Cloud Console - Web Client)
  // Get this from: https://console.cloud.google.com/apis/credentials
  // Paste the Web Client ID you created (ending in .apps.googleusercontent.com)
  static const String googleWebClientId =
      '862912032200-p5g5ars7rorutkf403ol4871b4sqm2lh.apps.googleusercontent.com';

  static const String googleAndroidClientId =
      '862912032200-5fa9okvvr9qre8ucr3trs2v32jk6npia.apps.googleusercontent.com';
}
