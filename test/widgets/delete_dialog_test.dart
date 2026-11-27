import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:planejamento_financeiro/models/balance.dart';
import 'package:planejamento_financeiro/theme/colors.dart';
import 'package:planejamento_financeiro/theme/theme.dart';
import 'package:planejamento_financeiro/widgets/delete_dialog.dart';

void main() {
  final parcelado = BalanceModel(
    name: 'TV',
    value: 100,
    type: 'expenses',
    installment: 2,
    totalInstallments: 3,
  );
  final aVista = BalanceModel(name: 'Aluguel', value: 100, type: 'expenses');

  // Abre o diálogo e devolve uma função que lê o resultado depois.
  Future<bool? Function()> open(WidgetTester tester, BalanceModel b) async {
    bool? result;
    var done = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.defaultTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await confirmDeleteBalance(context, b);
                done = true;
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return () {
      expect(done, isTrue);
      return result;
    };
  }

  testWidgets('parcelado devolve true em Só esta', (tester) async {
    final res = await open(tester, parcelado);
    expect(find.text('Excluir "TV"?'), findsOneWidget);
    expect(
      find.text(
        'Este lançamento tem 3 parcelas. Você pode excluir só a parcela 2 ou todas.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Só esta'));
    await tester.pumpAndSettle();
    expect(res(), isTrue);
  });

  testWidgets('parcelado devolve false em Todas', (tester) async {
    final res = await open(tester, parcelado);
    await tester.tap(find.text('Todas'));
    await tester.pumpAndSettle();
    expect(res(), isFalse);
  });

  testWidgets('à vista explica e devolve false em Excluir', (tester) async {
    final res = await open(tester, aVista);
    expect(find.text('Esta ação não pode ser desfeita.'), findsOneWidget);
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    expect(res(), isFalse);
  });

  testWidgets('Cancelar devolve null', (tester) async {
    final res = await open(tester, aVista);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(res(), isNull);
  });

  testWidgets('ações destrutivas em perigo', (tester) async {
    await open(tester, parcelado);
    for (final label in ['Todas', 'Só esta']) {
      final button = tester.widget<TextButton>(
        find.widgetWithText(TextButton, label),
      );
      expect(button.style!.foregroundColor!.resolve({}), AppColors.danger);
    }
  });

  testWidgets('contraste e área de toque', (tester) async {
    final handle = tester.ensureSemantics();
    await open(tester, parcelado);
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    handle.dispose();
  });
}
