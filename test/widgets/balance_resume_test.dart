import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:planejamento_financeiro/commons/formats.dart';
import 'package:planejamento_financeiro/models/balance.dart';
import 'package:planejamento_financeiro/theme/colors.dart';
import 'package:planejamento_financeiro/theme/theme.dart';
import 'package:planejamento_financeiro/widgets/balance_resume.dart';

import '../helpers.dart';

BalanceModel item(double value, {bool realized = true}) =>
    BalanceModel(name: 'x', value: value, realized: realized);

void main() {
  setUpAll(setUpPtBr);

  Future<void> pump(
    WidgetTester tester, {
    List<BalanceModel> gains = const [],
    List<BalanceModel> expenses = const [],
  }) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.defaultTheme,
        home: Scaffold(
          backgroundColor: AppColors.primary,
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BalanceResume(gains: gains, expenses: expenses),
          ),
        ),
      ),
    );
  }

  testWidgets('mostra quanto falta receber', (tester) async {
    await pump(tester, gains: [item(5000), item(1200, realized: false)]);
    expect(
      find.text('Falta receber ${AppFormats.valueToMoney(1200)}'),
      findsOneWidget,
    );
  });

  testWidgets('mostra quanto falta pagar', (tester) async {
    await pump(tester, expenses: [item(120, realized: false), item(650)]);
    expect(
      find.text('Falta pagar ${AppFormats.valueToMoney(120)}'),
      findsOneWidget,
    );
  });

  testWidgets('esconde quando não falta nada', (tester) async {
    await pump(tester, gains: [item(5000)], expenses: [item(650)]);
    expect(find.textContaining('Falta'), findsNothing);
  });

  testWidgets('balanço negativo avisa em texto', (tester) async {
    await pump(tester, gains: [item(100)], expenses: [item(300)]);
    expect(find.text('Gastos acima dos ganhos'), findsOneWidget);
    expect(find.text(AppFormats.valueToMoney(-200)), findsOneWidget);
  });

  testWidgets('balanço positivo não avisa', (tester) async {
    await pump(tester, gains: [item(300)], expenses: [item(100)]);
    expect(find.text('Gastos acima dos ganhos'), findsNothing);
  });

  testWidgets('valores enormes não estouram em 360 dp', (tester) async {
    await pump(
      tester,
      gains: [item(1234567.89, realized: false)],
      expenses: [item(1234567.89, realized: false)],
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('valores com algarismos tabulares', (tester) async {
    await pump(tester, gains: [item(5000)]);
    final style = tester
        .widget<Text>(find.text(AppFormats.valueToMoney(5000)).first)
        .style!;
    expect(style.fontFeatures, contains(const FontFeature.tabularFigures()));
  });
}
