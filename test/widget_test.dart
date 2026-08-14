// Teste básico de fumaça: confirma que o app sobe sem travar na inicialização
// da UI (não testa a integração real com Supabase — usa credenciais falsas
// só pra satisfazer o Supabase.initialize() que o AuthGate depende dele).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:controle_paletes/main.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://smoke-test.supabase.co',
      publishableKey: 'smoke-test-key',
    );
  });

  testWidgets('App inicia e mostra algum conteúdo', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ControlePaletesApp()),
    );
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
