# Revisão de layout: plano de implementação

> **Para agentes:** SUB-SKILL OBRIGATÓRIA: use `superpowers:subagent-driven-development` (recomendado) ou `superpowers:executing-plans` para implementar este plano tarefa por tarefa. Os passos usam checkbox (`- [ ]`).

**Objetivo:** aplicar no app a revisão de layout aprovada: tema com tokens, escala de texto legível, item da lista, resumo, estados vazio e de erro, modais, barra do topo com menu, login e splash.

**Arquitetura:** três PRs em sequência. **Tema** troca os tokens e o `ThemeData`. **Componentes** refaz os widgets da lista, do resumo, do formulário e o diálogo de excluir. **Telas** refaz a home (topo, erro, retornos), o login e a splash. Cada PR deixa o app funcionando. Cada novo PR nasce do `main` depois que o anterior é mesclado, ou do branch anterior se o usuário pedir.

**Stack:** Flutter 3.50.1 / Dart 3.14, `material_ui`, `flutter_form_builder`, `flutter_test` com dublês escritos à mão (`test/fakes.dart`). Sem dependências novas.

**Spec:** [`docs/superpowers/specs/2026-11-26-revisao-de-layout-design.md`](../specs/2026-11-26-revisao-de-layout-design.md). Leia junto com o plano: a seção 4 tem os valores.

## Restrições globais

- **Cores** (`AppColors`):
  - ganhos `#44A2A6` e gastos `#F7646C`, em tudo: fundo da home, login, splash, botão +, Salvar, valores e ícones da lista;
  - tinta `#1F44A2A6` / `#1FF7646C`;
  - perigo `#D63A42`;
  - texto principal `#323232`, secundário `#5E6B6B` e de exemplo `#6B7676`;
  - divisória `#1A323232`.
- **Texto sobre a cor:** branco sólido, sem transparência. O `AppColors.whiteDesable` deixa de existir.
- **Exceção de contraste consciente:** a cor da marca sobre branco, e o branco sobre ela, ficam com 3:1. Por isso, **nenhum** teste `textContrastGuideline` roda nas telas com a cor da marca. Ele roda só nos diálogos.
- **Tipografia:** WorkSans 400/600, com os tamanhos e alturas da tabela da spec 4.1. Nada abaixo de 12 sp. Valores em dinheiro fora do formulário usam `FontFeature.tabularFigures()`.
- **Espaçamento e raio:** cada arquivo tocado passa a usar `AppSpacing` (4/8/12/16/24/32/48) e `AppRadius` (8/12/16), arredondando para o vizinho da grade: 5→4, 10→8, 18→16, 44→48, 50→48. Os raios ficam assim: 10→8, 20→16, 35→circular.
- **Áreas de toque:** mínimo de 48 dp. Todo botão só com ícone tem `tooltip`.
- **Texto da interface** (exato, pt-BR):
  - "Nenhum ganho neste mês" / "Nenhum gasto neste mês" / "Toque em + para lançar";
  - "Falta receber {valor}" / "Falta pagar {valor}" / "Gastos acima dos ganhos";
  - "Lançamento salvo" / "Lançamento excluído" / "Não foi possível excluir";
  - "Mais opções" / "Sair" / "Seus lançamentos continuam salvos.";
  - "Esta ação não pode ser desfeita." / "Este lançamento tem {N} parcelas. Você pode excluir só a parcela {n} ou todas." / "Todas" / "Só esta";
  - "Novo ganho" / "Novo gasto" / "Editar ganho" / "Editar gasto" / "Parcelas" / "Menos uma parcela" / "Mais uma parcela" / "Novo lançamento".
- **Valores em texto nos testes:** sempre por `AppFormats.valueToMoney(x)`, porque o `R$` vem com espaço não separável.
- **Convenções** (`CLAUDE.md`):
  - TDD, com o teste falhando pelo motivo certo antes do código;
  - `pump()` enquanto o `AppLoad` estiver na tela;
  - `dart format lib test`;
  - commits em pt-BR (`style:`, `feat:`, `fix:`, `test:`, `docs:`);
  - **antes de cada commit, pare e deixe o usuário revisar o código e testar no celular**;
  - atualize o arquivo de `docs/` do assunto junto com a mudança.
- **Verificação no celular a cada tarefa visível:** `flutter run -d <ip>:<porta>` com a API local. Passe pelos estados da tarefa e confira `get_runtime_errors` no MCP do Dart antes de pedir a revisão.

## Foco de revisão

1. **Valores muito grandes no resumo** (R$ 1.234.567,89 em ganhos e gastos, tela de 360 dp): nada estoura; o número encolhe (`FittedBox(scaleDown)`). Teste na Tarefa 7.
2. **Nome com 30 caracteres, parcela "Parcela 12 de 30 · Recebido" e valor grande no mesmo item:** nada estoura; o nome corta com reticências. Teste na Tarefa 4.
3. **Balanço negativo:** aparece o sinal e a linha "Gastos acima dos ganhos". Teste na Tarefa 7.
4. **Fonte do sistema em 130% na home:** sem estouro, e a aba do mês selecionado continua visível depois de trocar a escala com a tela aberta (B2). Teste na Tarefa 9.
5. **Excluir pelo formulário com a API falhando:** o modal fica aberto e mostra "Não foi possível excluir". Teste na Tarefa 8.

---

## PR 1: Tema (branch `style/tema`)

### Task 1: Tokens de cor, espaçamento e raio

**Arquivos:**
- Modificar: `lib/theme/colors.dart`. Trocar também os usos de `AppColors.whiteDesable` por `AppColors.white` em `lib/widgets/resume_money.dart`, `balance_resume.dart`, `balance_tab_view.dart` e `infiniteTabelView/infinite_tabel_view.dart`.
- Criar: `lib/theme/spacing.dart`
- Modificar: `test/helpers.dart`
- Criar: `test/theme/tokens_test.dart`

**Interfaces:**
- Produz:
  - `AppColors.primary` / `secondary` / `primaryLight` / `secondaryLight` / `danger` / `black` / `textSecondary` / `hint` / `grayLight` / `white` (`static const Color`, com os valores das restrições);
  - `AppSpacing.xs` 4, `sm` 8, `md` 12, `base` 16, `lg` 24, `xl` 32, `xxl` 48 (`static const double`);
  - `AppRadius.sm` 8, `md` 12, `lg` 16 (`static const double`);
  - nos testes, `double contrastRatio(Color a, Color b)` (com `computeLuminance`).

- [ ] **Passo 1: Escrever o teste que falha**

```dart
test('perigo, texto secundário e exemplo passam 4,5:1 sobre branco', () {
  for (final c in [AppColors.danger, AppColors.textSecondary, AppColors.hint, AppColors.black]) {
    expect(contrastRatio(c, AppColors.white), greaterThanOrEqualTo(4.5));
  }
});
test('cor da marca fica na exceção de 3:1', () {
  expect(AppColors.primary, const Color(0xFF44A2A6));
  expect(AppColors.secondary, const Color(0xFFF7646C));
  for (final c in [AppColors.primary, AppColors.secondary]) {
    expect(contrastRatio(c, AppColors.white), inInclusiveRange(2.95, 4.49));
  }
});
test('fundo do arraste se distingue do coral', () {
  expect(contrastRatio(AppColors.danger, AppColors.secondary), greaterThanOrEqualTo(1.5));
});
test('escalas', () {
  expect([AppSpacing.xs, AppSpacing.sm, AppSpacing.md, AppSpacing.base, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxl], [4, 8, 12, 16, 24, 32, 48]);
  expect([AppRadius.sm, AppRadius.md, AppRadius.lg], [8, 12, 16]);
});
```

- [ ] **Passo 2:** `flutter test test/theme/tokens_test.dart`. Esperado: FALHA, porque `danger`, `AppSpacing` e `contrastRatio` não existem.
- [ ] **Passo 3:** criar os tokens, remover o `whiteDesable` e trocar os quatro usos por `AppColors.white`.
- [ ] **Passo 4:** `flutter test && flutter analyze`. Esperado: tudo passa.
- [ ] **Passo 5:** parar para a revisão do usuário. Depois: `git commit -m "style: troca as cores da marca e cria os tokens de espaçamento e raio"`

### Task 2: Escala de texto

**Arquivos:**
- Modificar: `lib/theme/texts_style.dart`. Remover o `_sizeScale` e o `customSize`, e acrescentar o `displaySmall`.
- Modificar: `lib/widgets/resume_money.dart`. O único uso de `customSize(32)` passa a ser `textTheme.displaySmall` com `w600`.
- Modificar: `lib/theme/theme.dart`. Incluir o `displaySmall` no `textTheme`.
- Criar: `test/theme/theme_test.dart`

**Interfaces:**
- Produz: `AppTextsStyle.displaySmall/titleLarge/titleMedium/titleSmall/bodyLarge/bodyMedium/bodySmall/labelLarge/labelMedium/labelSmall({Color? color = AppColors.black, FontWeight fontWeight = FontWeight.w400, ...})`, com o tamanho real e a altura da tabela da spec. O `titleMedium` fica com 22 e altura 1,25. O `labelLarge` tem `w600` como padrão. O `AppTheme.defaultTheme.textTheme` usa todos eles.

- [ ] **Passo 1: Escrever o teste que falha**

```dart
final t = AppTheme.defaultTheme.textTheme;
test('tamanhos e alturas da spec', () {
  expect(t.displaySmall!.fontSize, 36);
  expect(t.titleLarge!.fontSize, 26);
  expect(t.titleSmall!.fontSize, 20);
  expect([t.bodyLarge!.fontSize, t.bodyLarge!.height], [18, 1.3]);
  expect([t.bodyMedium!.fontSize, t.bodyMedium!.height], [16, 1.5]);
  expect(t.bodySmall!.fontSize, 13);
  expect([t.labelLarge!.fontSize, t.labelLarge!.fontWeight], [16, FontWeight.w600]);
  expect(t.labelMedium!.fontSize, 14);
  expect(t.labelSmall!.fontSize, 12);
});
test('nada abaixo de 12 sp, WorkSans e texto escuro por padrão', () {
  for (final s in [t.displaySmall, t.titleLarge, t.titleMedium, t.titleSmall, t.bodyLarge, t.bodyMedium, t.bodySmall, t.labelLarge, t.labelMedium, t.labelSmall]) {
    expect(s!.fontSize, greaterThanOrEqualTo(12));
    expect(s.fontFamily, 'WorkSans');
    expect(s.color, AppColors.black);
  }
});
```

- [ ] **Passo 2:** `flutter test test/theme/theme_test.dart`. Esperado: FALHA nos tamanhos (bodyLarge = 17,8) e na cor (branca).
- [ ] **Passo 3:** implementar.
- [ ] **Passo 4:** rodar `flutter test`.
  - Os testes antigos continuam passando, porque buscam textos e não estilos.
  - No celular, o texto da splash e do erro da home fica escuro sobre a cor até a Tarefa 9/10. Isso é esperado neste PR, e o usuário vai ver.
- [ ] **Passo 5:** parar para a revisão. Depois: `git commit -m "style: escala de texto com tamanhos reais e texto escuro por padrão"`

### Task 3: `ColorScheme` e temas dos componentes

**Arquivos:**
- Modificar: `lib/theme/theme.dart`
- Modificar: `test/theme/theme_test.dart`
- Criar: `docs/tema-e-layout.md`, com os tokens, a escala, a exceção de 3:1 e o critério de fonte de 130%. Ligar no índice do `docs/README.md`.

**Interfaces:**
- Produz: o `AppTheme.defaultTheme` com:
  - `colorScheme: ColorScheme.light(primary, onPrimary: white, secondary, onSecondary: white, error: danger, onError: white, surface: white, onSurface: black, onSurfaceVariant: textSecondary, outline: grayLight)`;
  - `splashColor: primary.withAlpha(31)` e `highlightColor: primary.withAlpha(20)`;
  - `dialogTheme`: fundo branco, título `titleSmall` `w600`, conteúdo `bodyMedium` em `textSecondary`;
  - `textButtonTheme`: frente `black`, `labelLarge`, `minimumSize: Size(64, 48)`;
  - `inputDecorationTheme`: `floatingLabelBehavior: always`, rótulo `labelMedium` `w600` `black`, exemplo `bodyLarge` `hint`, erro `labelSmall` `danger`, sublinhado `grayLight` (1, ou 2 com foco) e `danger` no erro;
  - `snackBarTheme(behavior: SnackBarBehavior.floating)`;
  - `bottomSheetTheme`: fundo branco, também no modal;
  - `floatingActionButtonTheme(foregroundColor: white)`.

- [ ] **Passo 1: Escrever o teste que falha** (no mesmo arquivo)

```dart
final th = AppTheme.defaultTheme;
test('esquema de cores da marca', () {
  expect(th.colorScheme.primary, AppColors.primary);
  expect(th.colorScheme.error, AppColors.danger);
  expect(th.colorScheme.onSurface, AppColors.black);
});
test('toque não é mais coral', () {
  expect(th.splashColor, AppColors.primary.withAlpha(31));
});
test('diálogos, botões de texto, campos, SnackBar e modal', () {
  expect(th.dialogTheme.titleTextStyle!.fontSize, 20);
  expect(th.dialogTheme.backgroundColor, AppColors.white);
  expect(th.textButtonTheme.style!.minimumSize!.resolve({}), const Size(64, 48));
  expect(th.inputDecorationTheme.floatingLabelBehavior, FloatingLabelBehavior.always);
  expect(th.inputDecorationTheme.errorStyle!.color, AppColors.danger);
  expect(th.snackBarTheme.behavior, SnackBarBehavior.floating);
  expect(th.bottomSheetTheme.backgroundColor, AppColors.white);
});
```

- [ ] **Passo 2:** `flutter test test/theme/theme_test.dart`. Esperado: FALHA (`primary` cinza, sem `dialogTheme`).
- [ ] **Passo 3:** implementar e escrever o `docs/tema-e-layout.md`.
- [ ] **Passo 4:** rodar `flutter test && flutter analyze`. Depois, conferir no celular: diálogos, SnackBar flutuante e modal branco.
- [ ] **Passo 5:** parar para a revisão. Depois: `git commit -m "style: esquema de cores da marca e temas de diálogo, campos e SnackBar"` e abrir o PR 1.

---

## PR 2: Componentes (branch `style/componentes`)

### Task 4: Item da lista

**Arquivos:**
- Modificar: `lib/widgets/balance/balance.dart`
- Criar: `test/widgets/balance_test.dart`

**Interfaces:**
- Produz:
  - `String balanceSubtitle(BalanceModel balance)`. Junta com " · " a parte "Parcela {installment} de {totalInstallments}" (só quando `isInstallmented`) e o status: "Recebido" (ganho realizado), "Pago" (gasto realizado) ou "Previsto".
  - `Balance({required String name, String? subtitle, double? value, bool isDanger = false, bool realized = true, GestureTapCallback? onTap})`. O `isDot` sai.
  - O widget envolve o `ListTile` num `Theme` com `splashColor: cor.withAlpha(31)` e `highlightColor: cor.withAlpha(20)`, e o `ListTile` fica sem `shape`.
  - Ícone: `AppIcons.check` ou `AppIcons.clock` num círculo de 40 dp com a tinta.
  - Nome em `bodyLarge`, com `maxLines: 1` e reticências.
  - Valor em `bodyLarge` `w400`, na cor do tipo, com algarismos tabulares.

- [ ] **Passo 1: Escrever o teste que falha**

```dart
test('subtítulo', () {
  expect(balanceSubtitle(model(type: 'gains', realized: true, installment: 2, total: 3)), 'Parcela 2 de 3 · Recebido');
  expect(balanceSubtitle(model(type: 'expenses', realized: true)), 'Pago');
  expect(balanceSubtitle(model(type: 'expenses', realized: false)), 'Previsto');
});
testWidgets('ícone conforme o status', ...);      // realized → AppIcons.check; false → AppIcons.clock
testWidgets('valor regular, tabular e na cor do tipo', ...); // fontWeight w400, fontFeatures contém tabularFigures, cor secondary com isDanger
testWidgets('toque na cor do tipo e retangular', (tester) async {
  // pump Balance(isDanger: true)
  final ctx = tester.element(find.byType(ListTile));
  expect(Theme.of(ctx).splashColor, AppColors.secondary.withAlpha(31));
  expect(tester.widget<ListTile>(find.byType(ListTile)).shape, isNull);
});
testWidgets('nome longo e valor grande não estouram em 360 dp', ...); // nome de 30 caracteres, "Parcela 12 de 30 · Recebido", 1234567.89; tester.takeException() é null
```

(`model(...)` é um auxiliar local que monta um `BalanceModel.fromMap(balanceJson(...))`.)

- [ ] **Passo 2:** `flutter test test/widgets/balance_test.dart`. Esperado: FALHA (`balanceSubtitle` não existe).
- [ ] **Passo 3:** implementar. Na mesma tarefa, ajustar a chamada em `balance_tab_view.dart` para `name: balance.name, subtitle: balanceSubtitle(balance), realized: balance.realized`. Atualizar o `test/screens/home_test.dart`: `find.text('TV - 2/3')` passa a ser `find.text('TV')`.
- [ ] **Passo 4:** rodar `flutter test`. Esperado: tudo passa.
- [ ] **Passo 5:** parar para a revisão (celular: lista em ganhos e gastos, toque longo). Depois: `git commit -m "feat: item da lista com status em texto, parcela em linha própria e toque na cor do tipo"`

### Task 5: Diálogo de excluir

**Arquivos:**
- Criar: `lib/widgets/delete_dialog.dart`
- Criar: `test/widgets/delete_dialog_test.dart`

**Interfaces:**
- Produz: `Future<bool?> confirmDeleteBalance(BuildContext context, BalanceModel balance)`. Devolve `null` (Cancelar), `false` (excluir o lançamento: "Todas" ou "Excluir") ou `true` ("Só esta").
- Conteúdo: título `'Excluir "{name}"?'`, mais o texto e os botões das restrições globais.
- A ação destrutiva usa `TextButton.styleFrom(foregroundColor: AppColors.danger)`.

- [ ] **Passo 1: Escrever o teste que falha**: abre o diálogo num `Scaffold` branco a partir de um botão de teste e guarda o retorno.
  - `'parcelado devolve true em Só esta e false em Todas'`, com o texto `'Este lançamento tem 3 parcelas. Você pode excluir só a parcela 2 ou todas.'`;
  - `'à vista mostra Esta ação não pode ser desfeita. e devolve false em Excluir'`;
  - `'Cancelar devolve null'`;
  - `'ações destrutivas em perigo'`: `tester.widget<TextButton>(find.widgetWithText(TextButton, 'Excluir')).style!.foregroundColor!.resolve({})` é `AppColors.danger`;
  - `'contraste e toque'`: `await expectLater(tester, meetsGuideline(textContrastGuideline))` e `meetsGuideline(androidTapTargetGuideline)` com o diálogo aberto.
- [ ] **Passo 2:** `flutter test test/widgets/delete_dialog_test.dart`. Esperado: FALHA (a função não existe).
- [ ] **Passo 3:** implementar. O `_confirmDelete` de `balance_tab_view.dart` passa a chamar `confirmDeleteBalance` e mantém o `try/catch` e a SnackBar de falha. Atualizar o `home_test.dart`: `'Só esta parcela'` vira `'Só esta'` e `'Todas as parcelas'` vira `'Todas'`. Atualizar a tabela de exclusão do `docs/home-e-lancamentos.md`.
- [ ] **Passo 4:** rodar `flutter test`.
- [ ] **Passo 5:** parar para a revisão (celular: arrastar um parcelado e um à vista). Depois: `git commit -m "feat: diálogo de excluir explica a consequência e destaca a ação destrutiva"`

### Task 6: Lista, mês vazio e arraste

**Arquivos:**
- Criar: `lib/widgets/state_message.dart`
- Modificar: `lib/widgets/balance_tab_view.dart` e `lib/widgets/infiniteTabelView/infinite_tabel_view.dart`
- Criar: `test/widgets/balance_tab_view_test.dart`
- Modificar: `docs/home-e-lancamentos.md`

**Interfaces:**
- Produz: `StateMessage({required IconData icon, required String title, String? subtitle, Widget? action})`.
  - Ícone de 40 dp em `textSecondary`.
  - Título em `bodyLarge` `w600` `black`.
  - Subtítulo em `bodyMedium` `textSecondary`.
  - Conteúdo centralizado e com `padding` de `AppSpacing.lg`.
  - A Tarefa 9 reusa esse widget no erro.
- Na lista vazia: `StateMessage(icon: Icons.savings_outlined | Icons.receipt_long_outlined, title: 'Nenhum ganho neste mês' | 'Nenhum gasto neste mês', subtitle: 'Toque em + para lançar')`.
- Na lista:
  - `ListView` com `padding: EdgeInsets.only(bottom: 88)` (FAB de 56 + margem de 16 + 16);
  - fundo do `Dismissible` em `AppColors.danger`;
  - abas Ganhos/Gastos e abas de mês com rótulo branco (`w400`, e `w600` na selecionada), indicador branco e `Tab(height: 48)`.

- [ ] **Passo 1: Escrever o teste que falha**, com `BalanceTabView` num `Scaffold`:
  - `'ganhos vazio mostra a mensagem'`: `find.text('Nenhum ganho neste mês')` e `find.text('Toque em + para lançar')`;
  - `'espaço no fim para o botão +'`: `tester.widget<ListView>(find.byType(ListView)).padding` é `EdgeInsets.only(bottom: 88)`;
  - `'fundo do arraste em perigo'`: depois de `tester.drag(find.text('Aluguel'), Offset(-200, 0))` e `pump()`, existe um `Container` com `BoxDecoration.color` igual a `AppColors.danger`;
  - `'abas com 48 dp'`: `tester.getSize(find.widgetWithText(Tab, 'GANHOS')).height` é maior ou igual a 48.
- [ ] **Passo 2:** `flutter test test/widgets/balance_tab_view_test.dart`. Esperado: FALHA.
- [ ] **Passo 3:** implementar e atualizar a seção "Lista" do `docs/home-e-lancamentos.md`, com o estado vazio, o subtítulo e o arraste.
- [ ] **Passo 4:** rodar `flutter test`.
- [ ] **Passo 5:** parar para a revisão (celular: mês vazio, lista com 4 ou mais itens rolando até o fim, arraste em gastos). Depois: `git commit -m "feat: mensagem de mês vazio, espaço para o botão + e arraste em vermelho de perigo"`

### Task 7: Resumo

**Arquivos:**
- Modificar: `lib/widgets/resume_money.dart` e `lib/widgets/balance_resume.dart`
- Criar: `test/widgets/balance_resume_test.dart`

**Interfaces:**
- Produz: `ResumeMoney({required String label, required double value, bool center = false, String? hint})`.
  - Rótulo em `bodySmall` branco.
  - Valor em `titleLarge`, ou em `displaySmall` quando `center`, sempre `w600`, branco, com algarismos tabulares, dentro de `FittedBox(fit: BoxFit.scaleDown)`.
  - O `hint` fica numa linha em `bodySmall` branco.
- `BalanceResume`:
  - `Row` com dois `Expanded`, separados por `AppSpacing.base`;
  - `hint` "Falta receber/pagar {valor}" só quando a soma dos itens com `realized == false` é maior que 0;
  - "Gastos acima dos ganhos" embaixo do balanço quando ele é menor que 0;
  - divisória branca de espessura 2.

- [ ] **Passo 1: Escrever o teste que falha**, com o `BalanceResume` num `Scaffold` de fundo `AppColors.primary` e `MediaQuery` de 360 dp:
  - `'mostra quanto falta'`: ganhos 5000 (realizado) e 1200 (previsto) dão `find.text('Falta receber ${AppFormats.valueToMoney(1200)}')`;
  - `'esconde quando não falta nada'`: tudo realizado dá `find.textContaining('Falta')` igual a `findsNothing`;
  - `'balanço negativo avisa em texto'`: gastos 300 e ganhos 100 dão `find.text('Gastos acima dos ganhos')`;
  - `'valores enormes não estouram'`: 1234567.89 nos dois, com `tester.takeException()` nulo.
- [ ] **Passo 2:** `flutter test test/widgets/balance_resume_test.dart`. Esperado: FALHA.
- [ ] **Passo 3:** implementar e atualizar a seção "Carregamento/Resumo" do `docs/home-e-lancamentos.md`.
- [ ] **Passo 4:** rodar `flutter test`.
- [ ] **Passo 5:** parar para a revisão (celular: mês com previstos e mês com balanço negativo). Depois: `git commit -m "feat: resumo mostra quanto falta receber e pagar e avisa o balanço negativo"`

### Task 8: Formulário e botão

**Arquivos:**
- Modificar: `lib/widgets/formField/form_field.dart`, `lib/widgets/formBalance/form_balance.dart`, `lib/widgets/button.dart` e `lib/widgets/balance_tab_view.dart` (repassa o `onDelete` ao formulário de edição)
- Criar: `test/widgets/form_balance_test.dart`
- Modificar: `test/widget_test.dart` e `docs/home-e-lancamentos.md` (seção "Formulário")

**Interfaces:**
- Consome: `confirmDeleteBalance` (Tarefa 5).
- Produz:
  - `TextStyle formValueStyle(BuildContext context)`, em `form_field.dart`. Devolve `bodyLarge` com `w400` e `black`, sem `fontFeatures`. É **o único** estilo do texto digitado (Nome, Valor) e do número de Parcelas.
  - **Campo de texto:** rótulo vindo do tema, sempre acima; texto à esquerda; contador visível só quando `currentLength >= maxLength - 5`, como `'{n}/{max}'` em `labelSmall` `textSecondary`.
  - **Linha de Parcelas:** mantém o layout (rótulo em `bodyMedium` à esquerda, depois "−", o número em `Text` com `formValueStyle` e "+"). Os `IconButton` têm `tooltip` "Menos uma parcela" e "Mais uma parcela".
  - **`FormBalance({String typeBalance, BalanceModel? balanceEdit, Future<void> Function(BalanceModel)? onSubmit, Future<void> Function(bool onlyInstallment)? onDelete})`:**
    - título "Novo/Editar ganho/gasto" em `titleSmall` `w600`;
    - rótulo "Parcelas" e exemplo "R$ 0,00" no Valor;
    - Salvar sem ícone;
    - na edição, um `TextButton` "Excluir" em `danger`, abaixo do Salvar. Ele chama `confirmDeleteBalance` e, com uma escolha, `onDelete(escolha)` e fecha o modal. Se der erro, mostra `'Não foi possível excluir'` no modal;
    - um `Theme` envolvendo o formulário, com `textSelectionTheme` na cor do tipo (cursor, puxador e seleção).
  - **`AppButton`:**
    - texto em `labelLarge`;
    - ícone, quando houver, **antes** do texto (`IconAlignment.start`);
    - texto em `Flexible`, com reticências;
    - sem o `SizedBox(width: 48)`.

- [ ] **Passo 1: Escrever o teste que falha**
  - `'título conforme o tipo e o modo'`: "Novo gasto" e "Editar ganho";
  - `'Nome, Valor e Parcelas com o mesmo estilo'` (pedido explícito do usuário):

```dart
TextStyle editable(String label) => tester.widget<EditableText>(find.descendant(of: find.widgetWithText(FormBuilderTextField, label), matching: find.byType(EditableText))).style;
final parcelas = tester.widget<Text>(find.text('3')).style!;
for (final s in [editable('Nome'), editable('Valor total'), parcelas]) {
  expect([s.fontSize, s.fontWeight ?? FontWeight.w400, s.color, s.fontFamily, s.fontFeatures], [18, FontWeight.w400, AppColors.black, 'WorkSans', null]);
}
```

  - `'rótulo Parcelas e sem Parcela(s)'`;
  - `'contador só perto do limite'`: com 0 caracteres, `find.text('0/30')` dá nada; depois de `enterText` com 26 caracteres, aparece `find.text('26/30')`;
  - `'Salvar sem ícone'`: `find.descendant(of: find.byType(AppButton), matching: find.byType(Icon))` dá nada;
  - `'Excluir pela edição chama onDelete'`: à vista → "Excluir" → "Excluir" no diálogo → `onDelete(false)` chamado e o modal fecha;
  - `'Excluir falhando mantém o modal'`: `onDelete` lança erro, e aparece `'Não foi possível excluir'` com o título "Editar ganho" ainda na tela;
  - `'toque e rótulos'`: `meetsGuideline(androidTapTargetGuideline)` e `meetsGuideline(labeledTapTargetGuideline)`;
  - em `widget_test.dart`, `'AppButton com ícone não estoura em 320 dp'`, com `takeException()` nulo e o ícone à esquerda do texto (`getCenter(icon).dx < getCenter(text).dx`).
- [ ] **Passo 2:** `flutter test test/widgets/form_balance_test.dart test/widget_test.dart`. Esperado: FALHA.
- [ ] **Passo 3:** implementar.
  - O `balance_tab_view` repassa ao `FormBalance` de edição o `onDelete` que já recebe da home: `onDelete: (only) => widget.onDelete!(balance, onlyInstallment: only)`. Com isso, excluir pela edição já funciona nesta tarefa, e a Tarefa 9 só acrescenta o aviso de sucesso.
  - Na linha "Realizado", o switch mantém as cores ativas do tipo. As inativas vêm do novo `ColorScheme`.
  - Atualizar a tabela do formulário no `docs/home-e-lancamentos.md`.
- [ ] **Passo 4:** rodar `flutter test && flutter analyze`.
- [ ] **Passo 5:** parar para a revisão (celular: novo, edição de parcelado, erro, excluir pela edição, cursor na cor do tipo). Depois: `git commit -m "feat: formulário com título, estilo único nos valores e excluir pela edição"` e abrir o PR 2.

---

## PR 3: Telas (branch `style/telas`)

### Task 9: Home

**Arquivos:**
- Modificar: `lib/screens/home.dart` e `lib/widgets/infiniteTabelView/infinite_tabel_view.dart`
- Remover: `lib/widgets/app_bar.dart`
- Modificar: `test/screens/home_test.dart` e `docs/home-e-lancamentos.md` (diagrama do layout, Sair, erro, retornos)

**Interfaces:**
- Consome: `StateMessage` (Tarefa 6), `FormBalance.onDelete` (Tarefa 8) e `confirmDeleteBalance` (Tarefa 5).
- Produz:
  - `InfiniteTabView({..., Widget? trailing})`. O `trailing` fica à direita do `TabBar`, na mesma linha. O `TabBar` ganha `key: ValueKey(MediaQuery.textScalerOf(context))`, para voltar a mostrar a aba selecionada quando a escala muda (B2).
  - **Home sem `appBar`:**
    - `AnnotatedRegion<SystemUiOverlayStyle>(value: SystemUiOverlayStyle.light)` + `SafeArea`;
    - fundo na cor do tipo;
    - `trailing`: `PopupMenuButton` com `tooltip: 'Mais opções'`, ícone `Icons.more_vert` branco e um item "Sair", que chama o `_confirmLogout`;
    - diálogo de sair com o texto "Seus lançamentos continuam salvos." e "Sair" em `danger`.
  - **Erro de carregamento:** um cartão branco com `StateMessage(icon: AppIcons.erro, title: 'Não foi possível carregar os lançamentos', action: TextButton('Tentar de novo'))`. O FAB fica com `onPressed: null` enquanto o carregamento estiver com erro.
  - **FAB:** `tooltip: 'Novo lançamento'`, fundo na cor do tipo e ícone branco.
  - **Retornos:** SnackBar "Lançamento salvo" depois de criar ou editar com sucesso, e "Lançamento excluído" depois de excluir com sucesso, pela lista ou pelo formulário.

- [ ] **Passo 1: Escrever o teste que falha** (`home_test.dart`):
  - trocar o `find.byTooltip('Sair')` por `tap(find.byTooltip('Mais opções'))`, `pumpAndSettle` e `tap(find.text('Sair'))`;
  - `'sem barra de título'`: `find.text('GANHOS - Novembro 2026')` dá nada;
  - `'diálogo de sair explica'`: `find.text('Seus lançamentos continuam salvos.')`;
  - `'erro desativa o botão +'`: `tester.widget<FloatingActionButton>(find.byType(FloatingActionButton)).onPressed` é nulo, e depois de "Tentar de novo" com sucesso deixa de ser;
  - `'salvar avisa'`: `find.text('Lançamento salvo')` depois de salvar;
  - `'excluir avisa'`: `find.text('Lançamento excluído')` depois de "Só esta";
  - `'excluir pela edição'`: tocar "TV" → "Excluir" → "Só esta"; esperado `repo.calls` com a exclusão da parcela 2;
  - `'fonte em 130% não estoura e mantém NOV/26 visível'`: montar com `MediaQuery(textScaler: TextScaler.linear(1.0))`, trocar para `1.3` e dar `pumpAndSettle`. Esperado: `takeException()` nulo e `tester.getRect(find.text('NOV/26'))` dentro de `tester.getRect(find.byType(Scaffold))`;
  - `'toque e rótulos na home'`: `meetsGuideline(androidTapTargetGuideline)` e `meetsGuideline(labeledTapTargetGuideline)`.
- [ ] **Passo 2:** `flutter test test/screens/home_test.dart`. Esperado: FALHA.
- [ ] **Passo 3:** implementar, remover o `app_bar.dart` e redesenhar o diagrama da seção "Layout" do `docs/home-e-lancamentos.md`.
- [ ] **Passo 4:** rodar `flutter test && flutter analyze`.
- [ ] **Passo 5:** parar para a revisão. No celular:
  - ganhos e gastos, menu ⋮ → Sair → Cancelar;
  - erro com a API parada (`adb reverse --remove`);
  - salvar, excluir pela lista e pela edição;
  - fonte do sistema em 1,3, trocada com o app aberto e restaurada para o valor original.

  Depois: `git commit -m "feat: home sem barra de título, menu com Sair, estado de erro e avisos de sucesso"`

### Task 10: Login e splash

**Arquivos:**
- Modificar: `lib/screens/login.dart`, `lib/screens/splash.dart` e `lib/widgets/load/load.dart` (anel em `AppColors.black.withAlpha(30)`, B3)
- Modificar: `test/screens/login_test.dart`
- Modificar: `docs/README.md` e `docs/testes.md`

**Interfaces:**
- Login:
  - fundo `AppColors.primary`;
  - `AppButton` branco, com texto e ícone do Google em `primary` e o ícone à esquerda;
  - margens em `AppSpacing`;
  - a SnackBar de erro, flutuante pelo tema, aparece acima do botão.
- Splash:
  - fundo `AppColors.primary`;
  - textos em branco explícito (`bodyLarge`/`bodySmall` com `color: AppColors.white`);
  - divisória em `AppColors.white`;
  - espaçamentos em `AppSpacing`.

- [ ] **Passo 1: Escrever o teste que falha** (`login_test.dart`):
  - `'erro aparece acima do botão'`: depois do `signIn` lançar erro e de um `pump`, `tester.getRect(find.byType(SnackBar)).bottom` é menor ou igual a `tester.getRect(find.byType(AppButton)).top`;
  - `'botão não estoura em 320 dp'`: `MediaQuery` de 320 de largura, com `takeException()` nulo;
  - `'ícone do Google à esquerda do texto'`.
- [ ] **Passo 2:** `flutter test test/screens/login_test.dart`. Esperado: FALHA (a SnackBar fixa cobre o botão).
- [ ] **Passo 3:** implementar.
  - No `docs/README.md`:
    - tirar a limitação "O botão Entrar / Cadastrar estoura a largura";
    - acrescentar a exceção de contraste de 3:1;
    - acrescentar o critério de fonte de 130% (200% sem suporte);
    - manter a de "Deslizar na lista troca Ganhos/Gastos".
  - No `docs/testes.md`, acrescentar os arquivos novos de `test/theme/` e `test/widgets/` à tabela.
- [ ] **Passo 4:** rodar `flutter test && flutter analyze && dart format --output=none --set-exit-if-changed lib test`.
- [ ] **Passo 5:** parar para a revisão. No celular: sair, ver o login, provocar um erro de login (API parada) e reabrir o app para ver a splash. Depois: `git commit -m "style: login e splash na cor da marca, com botão e aviso de erro que não se sobrepõem"` e abrir o PR 3.

---

## Verificação final (depois do PR 3)

- `flutter test`, `flutter analyze` e o `dart format` verificado passam.
- **No celular, com a API e o Mongo locais e dados fictícios**, capturar os mesmos 14 estados da revisão:
  - login, splash;
  - home vazia, com ganhos e com gastos;
  - formulário novo, de edição e com erro;
  - excluir à vista e parcelado, sair;
  - carregando, erro;
  - fonte em 130%.

  Montar a página "antes × depois" e abrir com `google-chrome file://…`.
- **O `get_runtime_errors` do MCP do Dart fica vazio** depois de navegar por tudo.
- **Revisão do branch inteiro por um revisor novo** (`superpowers:requesting-code-review`) antes do último PR.
