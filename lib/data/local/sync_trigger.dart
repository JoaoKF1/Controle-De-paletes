import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sincronizador.dart';

/// Dispara a sincronização da fila de pendentes sempre que a conexão volta.
/// Só precisa ser observado uma vez (ver AuthGate) — o listener fica vivo
/// enquanto alguém observar esse provider.
final syncTriggerProvider = Provider<void>((ref) {
  final sincronizador = ref.watch(sincronizadorProvider);
  // Tenta uma vez já na entrada, caso tenha ficado pendente de uma sessão
  // anterior que fechou ainda offline.
  sincronizador.sincronizarTudo();

  final assinatura = Connectivity().onConnectivityChanged.listen((resultados) {
    final online = resultados.any((r) => r != ConnectivityResult.none);
    if (online) {
      sincronizador.sincronizarTudo();
    }
  });
  ref.onDispose(assinatura.cancel);
});
