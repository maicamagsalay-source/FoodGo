class AppConfig {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://hgcecniddjrmcgxqrpnz.supabase.co',
  );
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhnY2VjbmlkZGpybWNneHFycG56Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA0NjkwMTksImV4cCI6MjEwNjA0NTAxOX0.T9LHGsJj02QKvaaybPJHjSCbKYrVy5UIXWdtGfJy-PY',
  );

  static bool get isSupabaseConfigured =>
      supabaseUrl.startsWith('https://') && supabasePublishableKey.isNotEmpty;
}
