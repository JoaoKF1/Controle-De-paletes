import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_config.dart';
import 'core/router/auth_gate.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
    if (AppConfig.supabaseUrl.isEmpty || AppConfig.supabaseAnonKey.isEmpty) {
      throw StateError(
        'SUPABASE_URL ou SUPABASE_ANON_KEY ausente no .env (ver .env.example).',
      );
    }
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
    );
  } catch (e) {
    // Sem isso, qualquer falha aqui deixava o app preso numa tela branca,
    // sem mensagem nenhuma — o operador não tinha nem o que reportar.
    runApp(ErroInicializacaoApp(detalhe: e.toString()));
    return;
  }

  // Firebase (push notification, ver plano técnico seção 12) só está
  // configurado pra Android — no Windows (alvo principal de dev/admin)
  // não tem app registrado no Firebase, então nem tenta inicializar.
  // Push é opcional: se falhar, o app abre normalmente sem notificação.
  if (Platform.isAndroid) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint('Firebase não inicializou, seguindo sem push: $e');
    }
  }

  runApp(
    ProviderScope(
      // O Riverpod 3 refaz sozinho até 10x (com espera crescente) qualquer
      // provider que falhe — a tela ficava ~40s em "carregando" antes de
      // mostrar o erro. Falha de rede já cai pro cache offline dentro dos
      // repositórios (ver plano técnico, 9.12), então aqui o erro aparece
      // na hora.
      retry: (_, _) => null,
      child: const ControlePaletesApp(),
    ),
  );
}

/// Tela mostrada no lugar do app quando a configuração básica falha antes
/// de qualquer coisa funcionar (ex.: APK gerado sem o .env).
class ErroInicializacaoApp extends StatelessWidget {
  final String detalhe;
  const ErroInicializacaoApp({super.key, required this.detalhe});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: construirTema(Brightness.light),
      darkTheme: construirTema(Brightness.dark),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'O app não conseguiu iniciar.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Avise o Admin e informe o detalhe abaixo.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  SelectableText(detalhe, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ControlePaletesApp extends StatelessWidget {
  const ControlePaletesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle de Paletes',
      debugShowCheckedModeBanner: false,
      theme: construirTema(Brightness.light),
      darkTheme: construirTema(Brightness.dark),
      themeMode: ThemeMode.system,
      home: const AuthGate(),
    );
  }
}
