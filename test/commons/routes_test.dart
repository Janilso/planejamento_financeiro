import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:planejamento_financeiro/commons/routes.dart';
import 'package:planejamento_financeiro/theme/motion.dart';

void main() {
  Future<void> abrirNovaTela(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.push(
              context,
              fadeRoute((_) => const Scaffold(body: Text('nova'))),
            ),
            child: const Text('ir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ir'));
    await tester.pump();
  }

  testWidgets('a tela nova entra em fade, sem deslizar', (tester) async {
    await abrirNovaTela(tester);
    await tester.pump(const Duration(milliseconds: 100));

    final fade = tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.text('nova'),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(fade.opacity.value, inExclusiveRange(0.0, 1.0));
    // O deslize do iOS usa SlideTransition; o fade não pode ter nenhum.
    expect(
      find.ancestor(
        of: find.text('nova'),
        matching: find.byType(SlideTransition),
      ),
      findsNothing,
    );
  });

  testWidgets('o fade dura AppMotion.page', (tester) async {
    expect(AppMotion.page, const Duration(milliseconds: 300));
    await abrirNovaTela(tester);

    await tester.pump(AppMotion.page ~/ 2);
    final meio = tester
        .widget<FadeTransition>(
          find
              .ancestor(
                of: find.text('nova'),
                matching: find.byType(FadeTransition),
              )
              .first,
        )
        .opacity
        .value;
    expect(meio, closeTo(0.5, 0.05));

    await tester.pump(AppMotion.page);
    await tester.pumpAndSettle();
    expect(find.text('ir'), findsNothing, reason: 'a rota antiga saiu da tela');
  });
}
