import 'package:envied/envied.dart';

part 'app_env.g.dart';

@Envied(path: '.env', obfuscate: true)
abstract final class AppEnv {
  @EnviedField(
    varName: 'SUPABASE_URL',
    defaultValue: 'YOUR_SUPABASE_URL',
  )
  static final String supabaseUrl = _AppEnv.supabaseUrl;

  @EnviedField(
    varName: 'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_SUPABASE_ANON_KEY',
  )
  static final String supabaseAnonKey = _AppEnv.supabaseAnonKey;

  @EnviedField(
    varName: 'TWELVE_DATA_API_KEY',
    defaultValue: 'YOUR_TWELVE_DATA_API_KEY',
  )
  static final String twelveDataApiKey = _AppEnv.twelveDataApiKey;
}
