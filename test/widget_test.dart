// Teste básico de fumaça: confirma que o app sobe sem travar na inicialização
// da UI (não testa a integração real com Supabase).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:controle_paletes/main.dart';

void main() {
  testWidgets('App inicia e mostra algum conteúdo', (WidgetTester tester) async {
    await tester.pumpWidget(const ControlePaletesApp());
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
