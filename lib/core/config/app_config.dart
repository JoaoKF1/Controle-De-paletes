import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centraliza a leitura de variáveis de ambiente (arquivo .env, que fica
/// fora do controle de versão — veja .env.example para o modelo).
class AppConfig {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
}
