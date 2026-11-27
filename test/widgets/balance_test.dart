import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:planejamento_financeiro/commons/icons.dart';
import 'package:planejamento_financeiro/models/balance.dart';
import 'package:planejamento_financeiro/theme/colors.dart';
import 'package:planejamento_financeiro/theme/theme.dart';
import 'package:planejamento_financeiro/widgets/balance/balance.dart';

import '../helpers.dart';

BalanceModel model({
  String type = 'gains',
  bool realized = true,
  int installment = 1,
  int total = 1,
}) => BalanceModel(
  name: 'TV',
  value: 100,
  type: type,
  realized: realized,
  installment: installment,
  totalInstallments: total,
);

void main() {
  setUpAll(setUpPtBr);

  Future<void> pump(WidgetTester tester, Widget child, {double width = 392}) =>
      tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.defaultTheme,
          home: MediaQuery(
            data: MediaQueryData(size: Size(width, 800)),
            child: Scaffold(
              body: SizedBox(width: width, child: child),
            ),
          ),
        ),
      );

  test('subtítulo junta parcela e status', () {
    expect(
      balanceSubtitle(model(installment: 2, total: 3)),
      'Parcela 2 de 3 · Recebido',
    );
    expect(balanceSubtitle(model(type: 'expenses')), 'Pago');
    expect(
      balanceSubtitle(model(type: 'expenses', realized: false)),
      'Previsto',
    );
  });

  testWidgets('ícone conforme o status', (tester) async {
    await pump(tester, const Balance(name: 'A', value: 1));
    expect(find.byIcon(AppIcons.check), findsOneWidget);
    await pump(tester, const Balance(name: 'A', value: 1, realized: false));
    expect(find.byIcon(AppIcons.clock), findsOneWidget);
  });

  testWidgets('subtítulo aparece no item', (tester) async {
    await pump(tester, const Balance(name: 'TV', subtitle: 'Previsto'));
    expect(find.text('Previsto'), findsOneWidget);
  });

  testWidgets('valor regular, tabular e na cor do tipo', (tester) async {
    await pump(tester, const Balance(name: 'A', value: 10, isDanger: true));
    final style = tester.widget<Text>(find.textContaining('10,00')).style!;
    expect(style.fontWeight ?? FontWeight.w400, FontWeight.w400);
    expect(style.fontFeatures, contains(const FontFeature.tabularFigures()));
    expect(style.color, AppColors.secondary);
  });

  testWidgets('toque na cor do tipo e retangular', (tester) async {
    await pump(tester, const Balance(name: 'A', value: 1, isDanger: true));
    final ctx = tester.element(find.byType(ListTile));
    expect(Theme.of(ctx).splashColor, AppColors.secondary.withAlpha(31));
    expect(tester.widget<ListTile>(find.byType(ListTile)).shape, isNull);
  });

  testWidgets('nome longo e valor grande não estouram em 360 dp', (
    tester,
  ) async {
    await pump(
      tester,
      const Balance(
        name: 'Assinatura anual do streaming',
        subtitle: 'Parcela 12 de 30 · Recebido',
        value: 1234567.89,
      ),
      width: 360,
    );
    expect(tester.takeException(), isNull);
  });
}
