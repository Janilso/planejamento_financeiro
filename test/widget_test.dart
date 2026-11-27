import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:planejamento_financeiro/theme/theme.dart';
import 'package:planejamento_financeiro/widgets/button.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    theme: AppTheme.defaultTheme,
    home: Scaffold(body: child),
  );

  testWidgets('AppButton mostra o texto e chama onPressed', (tester) async {
    var pressed = 0;
    await tester.pumpWidget(
      wrap(AppButton(text: 'ENTRAR', onPressed: () => pressed++)),
    );

    expect(find.text('ENTRAR'), findsOneWidget);
    await tester.tap(find.byType(ElevatedButton));
    expect(pressed, 1);
  });

  testWidgets('AppButton em loading não chama onPressed', (tester) async {
    var pressed = 0;
    await tester.pumpWidget(
      wrap(
        AppButton(text: 'ENTRAR', loading: true, onPressed: () => pressed++),
      ),
    );

    expect(find.text('ENTRAR'), findsNothing);
    await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
    expect(pressed, 0);
  });

  testWidgets('AppButton com ícone não estoura em 320 dp', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      wrap(
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 44),
          child: AppButton(text: 'ENTRAR / CADASTRAR', icon: Icons.login),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.getCenter(find.byIcon(Icons.login)).dx,
      lessThan(tester.getCenter(find.text('ENTRAR / CADASTRAR')).dx),
    );
  });
}
