import 'dart:async';
import 'dart:io';

/// Timeout curto pra qualquer chamada online — decide rápido se cai pro
/// caminho offline em vez de travar a tela esperando.
const timeoutRede = Duration(seconds: 6);

/// Não confia num status de conectividade isolado: decide pelo resultado
/// real da chamada. `connectivity_plus` só é usado pra saber quando tentar
/// de novo (ver plano técnico, 9.12), não pra decidir isso aqui.
bool falhaDeRede(Object erro) {
  if (erro is SocketException || erro is TimeoutException) return true;
  final texto = erro.toString().toLowerCase();
  return texto.contains('socket') ||
      texto.contains('network') ||
      texto.contains('failed host lookup') ||
      texto.contains('connection');
}
