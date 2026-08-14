import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Expõe a instância única do cliente Supabase (já inicializada no main.dart)
/// para qualquer repositório que precisar dela.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
