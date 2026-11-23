import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locadora_app/app_store.dart';
import 'package:locadora_app/main.dart';

void main() {
  testWidgets('login leva à lista de veículos e logout volta ao login', (tester) async {
    // Tela de celular (412 x 915).
    tester.view.physicalSize = const Size(1236, 2745);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(LocadoraApp(store: AppStore()));
    expect(find.text('Bem-vindo de volta'), findsOneWidget);

    await tester.ensureVisible(find.text('Cliente'));
    await tester.tap(find.text('Cliente'));
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Fiat Mobi'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    expect(find.text('Maria Silva'), findsOneWidget);

    await tester.ensureVisible(find.text('Sair'));
    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();
    expect(find.text('Bem-vindo de volta'), findsOneWidget);
  });
}
