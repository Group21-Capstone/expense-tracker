/// Central configuration for external services.
///
/// Values can be overridden at build time with --dart-define, e.g.
///   flutter run --dart-define=GROQ_API_KEY=...
/// Otherwise the defaultValue below is used.
///
/// SECURITY NOTES:
/// - The Supabase anon key is safe to ship in the client because access is
///   gated by Row-Level Security.
/// - The Groq key is NOT safe to ship — it is embedded in the app bundle
///   and can be extracted from a release build. Acceptable for a demo /
///   prototype only; for production, proxy Groq calls through a Supabase
///   Edge Function so the key stays server-side.
class AppConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static const String groqApiKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: '',
  );

  static bool get isGroqConfigured =>
      groqApiKey.isNotEmpty && groqApiKey != 'YOUR_GROQ_API_KEY';

  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseUrl != 'YOUR_SUPABASE_URL' &&
      supabaseAnonKey.isNotEmpty &&
      supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY';
}
