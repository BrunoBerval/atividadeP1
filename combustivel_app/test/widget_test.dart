import 'package:combustivel_app/main.dart';
import 'package:combustivel_app/providers/app_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Exibe o indicador durante o carregamento inicial', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppProvider(),
        child: const MyApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      Localizations.localeOf(tester.element(find.byType(Scaffold))),
      const Locale('pt', 'BR'),
    );
  });
}
