import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:planejamento_financeiro/models/balance.dart';
import 'package:planejamento_financeiro/theme/colors.dart';
import 'package:planejamento_financeiro/theme/theme.dart';
import 'package:planejamento_financeiro/widgets/balance_tab_view.dart';

import '../helpers.dart';

void main() {
  setUpAll(setUpPtBr);

  Future<void> pump(
    WidgetTester tester, {
    List<BalanceModel> gains = const [],
  }) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.defaultTheme,
      home: Scaffold(
        backgroundColor: AppColors.primary,
        body: BalanceTabView(gainBalances: gains),
      ),
    ),
  );

  testWidgets('ganhos vazio mostra a mensagem', (tester) async {
    await pump(tester);
    expect(find.text('Nenhum ganho neste mês'), findsOneWidget);
    expect(find.text('Toque em + para lançar'), findsOneWidget);
  });

  testWidgets('espaço no fim para o botão +', (tester) async {
    await pump(
      tester,
      gains: [BalanceModel(id: '1', name: 'Aluguel', value: 10, type: 'gains')],
    );
    expect(
      tester.widget<ListView>(find.byType(ListView)).padding,
      const EdgeInsets.only(bottom: 88),
    );
  });

  testWidgets('fundo do arraste em perigo', (tester) async {
    await pump(
      tester,
      gains: [BalanceModel(id: '1', name: 'Aluguel', value: 10, type: 'gains')],
    );
    await tester.drag(find.text('Aluguel'), const Offset(-200, 0));
    await tester.pump();
    final fundos = tester
        .widgetList<Container>(find.byType(Container))
        .where((c) => c.decoration is BoxDecoration)
        .map((c) => (c.decoration as BoxDecoration).color);
    expect(fundos, contains(AppColors.danger));
  });

  testWidgets('abas com 48 dp', (tester) async {
    await pump(tester);
    expect(
      tester.getSize(find.widgetWithText(Tab, 'GANHOS')).height,
      greaterThanOrEqualTo(48),
    );
  });
}
