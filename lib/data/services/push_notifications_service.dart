import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../local/rede.dart';
import '../remote/supabase_provider.dart';

/// Push notification (Firebase Cloud Messaging) só existe pro Android hoje
/// — o Firebase só foi configurado pra essa plataforma (ver plano técnico,
/// seção 12); no Windows (dev/admin, alvo principal de teste) isso é
/// pulado de propósito, sem inicializar nada. Nunca lança erro: falha de
/// permissão/token não pode derrubar o login.
class PushNotificationsService {
  final SupabaseClient _client;
  PushNotificationsService(this._client);

  StreamSubscription<String>? _assinaturaRefresh;

  Future<void> registrar(String usuarioId) async {
    if (!Platform.isAndroid) return;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      if (token != null) {
        await _salvarToken(token);
      }
      // Um listener só por aparelho — sem cancelar, cada login novo
      // empilhava outro listener, inclusive de usuários anteriores.
      await _assinaturaRefresh?.cancel();
      _assinaturaRefresh = messaging.onTokenRefresh.listen((novoToken) {
        _salvarToken(novoToken).catchError((_) {});
      });
    } catch (_) {
      // Sem internet, permissão negada, Google Play Services ausente etc.
      // — o app continua funcionando normalmente sem push.
    }
  }

  /// Chamado no logout: o aparelho para de receber push desse usuário.
  /// Mesmo esquema do registrar — nunca lança erro.
  Future<void> remover(String usuarioId) async {
    if (!Platform.isAndroid) return;
    try {
      await _assinaturaRefresh?.cancel();
      _assinaturaRefresh = null;
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await _client
          .from('device_tokens')
          .delete()
          .eq('token', token)
          .eq('usuario_id', usuarioId)
          .timeout(timeoutRede);
    } catch (_) {
      // Offline no logout: o token fica lá, mas é reatribuído no próximo
      // login nesse aparelho (ver registrar_device_token).
    }
  }

  /// Via função `security definer` em vez de upsert direto: se o mesmo
  /// aparelho já estava registrado pra outro usuário, o upsert esbarrava no
  /// RLS de `device_tokens` (só o dono da linha pode alterá-la) e o token
  /// continuava apontando pro usuário antigo.
  Future<void> _salvarToken(String token) {
    return _client
        .rpc('registrar_device_token', params: {'p_token': token})
        .timeout(timeoutRede);
  }
}

final pushNotificationsServiceProvider = Provider<PushNotificationsService>((
  ref,
) {
  return PushNotificationsService(ref.watch(supabaseClientProvider));
});
