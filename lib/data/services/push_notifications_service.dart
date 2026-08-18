import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../remote/supabase_provider.dart';

/// Push notification (Firebase Cloud Messaging) só existe pro Android hoje
/// — o Firebase só foi configurado pra essa plataforma (ver plano técnico,
/// seção 12); no Windows (dev/admin, alvo principal de teste) isso é
/// pulado de propósito, sem inicializar nada. Nunca lança erro: falha de
/// permissão/token não pode derrubar o login.
class PushNotificationsService {
  final SupabaseClient _client;
  PushNotificationsService(this._client);

  Future<void> registrar(String usuarioId) async {
    if (!Platform.isAndroid) return;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      if (token != null) {
        await _salvarToken(usuarioId, token);
      }
      messaging.onTokenRefresh.listen((novoToken) {
        _salvarToken(usuarioId, novoToken);
      });
    } catch (_) {
      // Sem internet, permissão negada, Google Play Services ausente etc.
      // — o app continua funcionando normalmente sem push.
    }
  }

  Future<void> _salvarToken(String usuarioId, String token) {
    return _client.from('device_tokens').upsert(
      {'usuario_id': usuarioId, 'token': token},
      onConflict: 'token',
    );
  }
}

final pushNotificationsServiceProvider = Provider<PushNotificationsService>((
  ref,
) {
  return PushNotificationsService(ref.watch(supabaseClientProvider));
});
