import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:material_ui/material_ui.dart';
import 'package:planejamento_financeiro/models/balance.dart';
import 'package:planejamento_financeiro/theme/colors.dart';
import 'package:planejamento_financeiro/theme/theme.dart';
import 'package:planejamento_financeiro/widgets/base_modal.dart';
import 'package:planejamento_financeiro/widgets/button.dart';
import 'package:planejamento_financeiro/widgets/formBalance/form_balance.dart';

import '../helpers.dart';

void main() {
  setUpAll(setUpPtBr);

  final tv = BalanceModel(
    id: 'tv',
    name: 'TV',
    value: 800,
    totalValue: 2400,
    type: 'gains',
    installment: 1,
    totalInstallments: 3,
  );
  final aluguel = BalanceModel(
    id: 'al',
    name: 'Aluguel',
    value: 1800,
    type: 'gains',
    realized: true,
  );

  // Abre o formulário num modal, como o app faz.
  Future<void> open(WidgetTester tester, FormBalance form) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.defaultTheme,
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: const [
          ...GlobalMaterialLocalizations.delegates,
          FormBuilderLocalizations.delegate,
        ],
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => baseModal(context, form),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('título de novo gasto', (tester) async {
    await open(tester, const FormBalance(typeBalance: 'expenses'));
    expect(find.text('Novo gasto'), findsOneWidget);
  });

  testWidgets('título de edição de ganho', (tester) async {
    await open(tester, FormBalance(typeBalance: 'gains', balanceEdit: tv));
    expect(find.text('Editar ganho'), findsOneWidget);
  });

  testWidgets('Nome, Valor e Parcelas com o mesmo estilo', (tester) async {
    await open(tester, FormBalance(typeBalance: 'gains', balanceEdit: tv));
    TextStyle editable(String label) => tester
        .widget<EditableText>(
          find.descendant(
            of: find.widgetWithText(FormBuilderTextField, label),
            matching: find.byType(EditableText),
          ),
        )
        .style;
    final parcelas = tester.widget<Text>(find.text('3')).style!;
    for (final s in [editable('Nome'), editable('Valor total'), parcelas]) {
      expect(
        [
          s.fontSize,
          s.fontWeight ?? FontWeight.w400,
          s.color,
          s.fontFamily,
          s.fontFeatures,
        ],
        [18, FontWeight.w400, AppColors.black, 'WorkSans', null],
      );
    }
  });

  testWidgets('rótulo Parcelas', (tester) async {
    await open(tester, const FormBalance());
    expect(find.text('Parcelas'), findsOneWidget);
    expect(find.text('Parcela(s)'), findsNothing);
  });

  testWidgets('contador só perto do limite', (tester) async {
    await open(tester, const FormBalance());
    expect(find.text('0/30'), findsNothing);
    await tester.enterText(
      find.descendant(
        of: find.widgetWithText(FormBuilderTextField, 'Nome'),
        matching: find.byType(EditableText),
      ),
      'a' * 26,
    );
    await tester.pump();
    expect(find.text('26/30'), findsOneWidget);
  });

  testWidgets('erros de validação não mudam a altura do formulário', (
    tester,
  ) async {
    await open(tester, FormBalance(onSubmit: (_) async {}));
    final antes = tester.getSize(find.byType(FormBalance)).height;

    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    // Nome e Valor mostram "Este campo não pode ficar vazio.".
    expect(find.textContaining('vazio'), findsNWidgets(2));
    expect(tester.getSize(find.byType(FormBalance)).height, antes);
  });

  testWidgets('a linha de erro reservada não estoura com fonte em 130%', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(392, 850);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await open(tester, FormBalance(onSubmit: (_) async {}));
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('vazio'), findsNWidgets(2));
  });

  testWidgets('Salvar sem ícone', (tester) async {
    await open(tester, const FormBalance());
    expect(
      find.descendant(of: find.byType(AppButton), matching: find.byType(Icon)),
      findsNothing,
    );
  });

  testWidgets('Excluir pela edição chama onDelete e fecha', (tester) async {
    bool? recebido;
    await open(
      tester,
      FormBalance(
        typeBalance: 'gains',
        balanceEdit: aluguel,
        onDelete: (only) async => recebido = only,
      ),
    );
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir').last);
    await tester.pumpAndSettle();
    expect(recebido, isFalse);
    expect(find.text('Editar ganho'), findsNothing);
  });

  testWidgets('Excluir falhando mantém o modal e avisa', (tester) async {
    await open(
      tester,
      FormBalance(
        typeBalance: 'gains',
        balanceEdit: aluguel,
        onDelete: (_) async => throw Exception('falhou'),
      ),
    );
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir').last);
    await tester.pumpAndSettle();
    expect(find.text('Não foi possível excluir'), findsOneWidget);
    expect(find.text('Editar ganho'), findsOneWidget);
  });

  testWidgets('novo lançamento não tem Excluir', (tester) async {
    await open(tester, FormBalance(onDelete: (_) async {}));
    expect(find.text('Excluir'), findsNothing);
  });

  testWidgets('parcelas com rótulo acessível e área de toque', (tester) async {
    final handle = tester.ensureSemantics();
    await open(tester, const FormBalance());
    expect(find.byTooltip('Menos uma parcela'), findsOneWidget);
    expect(find.byTooltip('Mais uma parcela'), findsOneWidget);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('o foco do campo usa a cor do tipo', (tester) async {
    await open(tester, const FormBalance(typeBalance: 'expenses'));
    final theme = Theme.of(
      tester.element(find.byType(FormBuilderTextField).first),
    );
    final focus =
        theme.inputDecorationTheme.focusedBorder! as UnderlineInputBorder;
    expect(focus.borderSide.color, AppColors.secondary);
  });
}
