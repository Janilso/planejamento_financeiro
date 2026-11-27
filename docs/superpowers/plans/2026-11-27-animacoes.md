# Animações: mola, loader, cor e formulário — Plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (ou superpowers:subagent-driven-development) para implementar tarefa por tarefa. Os passos usam caixas `- [ ]`.

**Goal:** Tirar o quique da troca de mês/tipo, as piscadas do loader, o degrau de cor do fundo e o pulo do layout nos erros do formulário.

**Architecture:** Mudanças pequenas e independentes em widgets existentes. Um arquivo novo, `lib/theme/motion.dart`, guarda a duração e a curva da cor. Cada tarefa tem o teste que falha primeiro, vira um commit e atualiza o doc do assunto.

**Tech Stack:** Flutter 3.50.1 (`material_ui`), `flutter_test` com dublês escritos à mão, `integration_test` para a linha de base de desempenho.

**Spec:** `docs/superpowers/specs/2026-11-27-animacoes-design.md`

## Global Constraints

- Commits em pt-BR no padrão `fix:`, `feat:`, `test:`, `docs:`, `style:`. **Antes de cada commit, parar e deixar o usuário revisar o código e testar no celular.**
- TDD: o teste falha primeiro, pelo motivo certo. Sem libs de mock.
- O `AppLoad` tem animação infinita: nos testes, use `pump(Duration)` enquanto ele estiver na tela; nunca `pumpAndSettle()`.
- Rodar `dart format lib test` (o hook já formata cada `.dart` editado), `flutter analyze` e `flutter test`. Usar `~/snap/flutter/common/flutter/bin/flutter` em comandos de segundo plano.
- Atualizar o arquivo de `docs/` do assunto junto com a mudança.
- Não mexer em: transição de telas, altura do cabeçalho, movimento reduzido, arraste sobre itens (ficam para outra rodada).
- A chave do mês continua `MMM/yy` em pt-BR, maiúsculas e sem ponto (`NOV/26`).

## Review Focus

Entradas e condições que a spec implica e nenhuma tarefa exercitaria sozinha (cada uma tem teste na tarefa dona do código):

1. **Primeiro carregamento sem dados anteriores:** o `AppLoad` ainda aparece (o `initialData` é nulo). Tarefa 2.
2. **Recarga que falha depois de um carregamento bom** (por exemplo, salvar e a rede cair): o erro "Não foi possível carregar os lançamentos" ainda aparece, mesmo com dado antigo em memória. Tarefa 2.
3. **Botão + desativado por erro** continua translúcido e a cor ainda anima sem quebrar o `onPressed: null`. Tarefa 3 (o teste existente `erro desativa o botão + até carregar de novo` precisa continuar passando).
4. **Fonte do sistema em 130% no modal:** a linha de erro reservada não gera overflow. Tarefa 4.
5. **Abas GANHOS/GASTOS:** não precisam de teste de quique. Com só duas páginas, o destino de qualquer arremesso é uma ponta, onde o `ClampingScrollPhysics` do pai corta a posição: a mola não consegue passar do ponto, com ou sem a física customizada (verificado: o teste passava antes da mudança). Só a troca de mês, com páginas no meio, quica. Tarefa 1.

---

### Task 1: Mola padrão nas abas de mês e de tipo

**Files:**
- Delete: `lib/widgets/infiniteTabelView/custom_tab_bar_view_scroll_physics.dart`
- Modify: `lib/widgets/infiniteTabelView/infinite_tabel_view.dart` (remover o import da linha 5 e `physics:` do `TabBarView`, linha ~107)
- Modify: `lib/widgets/balance_tab_view.dart` (remover o import da linha 12 e `physics:` do `TabBarView`, linha ~123)
- Modify: `test/helpers.dart`
- Create: `test/widgets/infinite_tab_view_test.dart`
- Modify: `docs/home-e-lancamentos.md` (seção "Meses" e "Lista")

**Interfaces:**
- Produces em `test/helpers.dart`:
  - `ScrollPosition tabViewPosition(WidgetTester tester, Finder tabBarView)`: a `ScrollPosition` do `Scrollable` mais externo dentro do `TabBarView`.
  - `Future<double> maxPixelsWhileSettling(WidgetTester tester, ScrollPosition position, {int frames = 200})`: avança `frames` quadros de 8 ms e devolve o maior `position.pixels` visto.

- [ ] **Step 1: Escrever os testes que falham**

`infinite_tab_view_test.dart`, teste `'a página assenta sem passar do ponto'`: monta `InfiniteTabView(length: 3, buildTabBar: (_, i) => 'M$i', buildTabView: (_, i) => Center(child: Text('p$i')))` num `MaterialApp`/`Scaffold`; guarda `largura = pos.viewportDimension`; `tester.fling(find.byType(TabBarView), const Offset(-300, 0), 1000)`; então `expect(await maxPixelsWhileSettling(tester, pos), lessThanOrEqualTo(largura + 0.5))` e `expect(pos.pixels, closeTo(largura, 0.5))`.


- [ ] **Step 2: Rodar e ver falhar**

Run: `flutter test test/widgets/infinite_tab_view_test.dart`
Expected: o teste novo FALHA com o máximo ≈ `largura + 22` (a mola customizada passa ~22 px do alvo).

- [ ] **Step 3: Implementar**

Apagar o arquivo da physics e remover os dois imports e os dois `physics:`. O `TabBarView` sem `physics` usa `PageScrollPhysics` sobre `ClampingScrollPhysics` (razão 1,1). Adicionar os dois helpers a `test/helpers.dart` (precisa de `package:flutter_test/flutter_test.dart`).

- [ ] **Step 4: Rodar e ver passar**

Run: `flutter test` e `flutter analyze`
Expected: tudo passa, sem avisos.

- [ ] **Step 5: Doc**

Em `docs/home-e-lancamentos.md`, uma linha em "Meses" e uma em "Lista": a troca de mês e a de GANHOS/GASTOS usam a física padrão do `TabBarView`, sem quique.

- [ ] **Step 6: Commit (depois da revisão do usuário)**

`fix: troca de mês e de tipo sem quique, com a mola padrão do Flutter`

---

### Task 2: Páginas sem piscar o loader

**Files:**
- Modify: `lib/screens/home.dart` (`_loadBalances`, `FutureBuilder` da `buildTabView`)
- Modify: `test/screens/home_test.dart`
- Modify: `docs/home-e-lancamentos.md` (seção "Carregamento")

**Interfaces:**
- Produces em `_HomeScreenState`: `MonthBalanceModel? _lastBalances;` preenchido no sucesso de `_loadBalances()`.
- O `FutureBuilder` passa a ser `FutureBuilder<MonthBalanceModel>(future: _balances, initialData: _lastBalances, …)`.

- [ ] **Step 1: Escrever os testes**

Em `home_test.dart` (importar `package:planejamento_financeiro/widgets/load/load.dart` e `theme/colors.dart` se faltar), com um repositório de 3 meses (`NOV/26`, `DEZ/26`, `JAN/27`, cada um com ao menos um ganho via `balanceJson`):

- `'trocar de mês não mostra o loader em nenhum quadro'`: `pumpHome`; `tester.tap(find.text('DEZ/26'))`; por 45 vezes `await tester.pump(const Duration(milliseconds: 16))` e `expect(find.byType(AppLoad), findsNothing, reason: 'quadro $i')`. Repetir deslizando de volta com `tester.flingFrom(tester.getCenter(find.byType(BalanceResume).last), const Offset(300, 0), 1500)`.
- `'a lista que cresce não pisca o loader'`: `pumpHome`; tocar, em ordem, `OUT/26, SET/26, AGO/26, JUL/26, JUN/26, MAI/26, ABR/26, MAR/26, FEV/26` (a nona faz a lista passar de 25 para 37 meses), com o mesmo laço de 45 quadros sem `AppLoad` após cada toque.
- `'o primeiro carregamento ainda mostra o loader'` (Review Focus 1): `tester.pumpWidget` da home sem o segundo `pump` do `pumpHome` e `expect(find.byType(AppLoad), findsOneWidget)`; depois `pump` até os dados aparecerem e `findsNothing`.
- `'recarga que falha depois de carregar mostra o erro'` (Review Focus 2): `pumpHome` com dados; `repo.error = Exception('x')`; `openFormAndSave(tester)` (o helper existente); `expect(find.text('Não foi possível carregar os lançamentos'), findsOneWidget)`.

- [ ] **Step 2: Rodar e ver falhar**

Run: `flutter test test/screens/home_test.dart --plain-name "loader"`
Expected: os dois primeiros FALHAM (`AppLoad` no quadro 1; na lista que cresce, no 1 e no 19); os outros dois PASSAM (são guardas).

- [ ] **Step 3: Implementar**

Em `_loadBalances`, no `then` de sucesso, `_lastBalances = data` antes do `setState` de `_loadFailed`. No `FutureBuilder`, passar `initialData: _lastBalances` e tipar com `<MonthBalanceModel>`. `snapshot.hasError` continua sendo checado antes de `hasData`.

- [ ] **Step 4: Rodar e ver passar**

Run: `flutter test` e `flutter analyze`
Expected: tudo passa.

- [ ] **Step 5: Doc**

Em "Carregamento": a home guarda o último resultado e o usa como `initialData`, então páginas novas (troca de mês, ou lista que cresce) já nascem com a lista, sem piscar o `AppLoad`; só o primeiro carregamento mostra o loader.

- [ ] **Step 6: Commit (depois da revisão do usuário)**

`fix: páginas de mês nascem com o último resultado e não piscam o loader`

---

### Task 3: Cor do fundo e do + animada

**Files:**
- Create: `lib/theme/motion.dart`
- Modify: `lib/screens/home.dart` (`build`)
- Modify: `test/screens/home_test.dart`
- Modify: `docs/tema-e-layout.md` (nova seção "Movimento")

**Interfaces:**
- Produces em `lib/theme/motion.dart`: `class AppMotion { AppMotion._(); static const Duration color = Duration(milliseconds: 250); static const Curve colorCurve = Curves.easeOut; }`.
- Consome em `home.dart`: `colorState` (já existe: `AppColors.primary` em ganhos, `AppColors.secondary` em gastos).

- [ ] **Step 1: Escrever os testes**

`home_test.dart`, com os helpers locais `Color? fundo(WidgetTester t) => t.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor` e `fab()` (já existe no arquivo):

- `'a cor do fundo e do + anda de ganhos para gastos'`: `fundo == AppColors.primary` no início; tocar `find.widgetWithText(Tab, 'GASTOS')`; `pump()` e `pump(const Duration(milliseconds: 100))`; o fundo não é `primary` nem `secondary`, e `fab().backgroundColor == fundo(tester)`; depois `pump(const Duration(milliseconds: 400))` e `fundo == AppColors.secondary`.
- `'trocar de mês estando em gastos volta a verde com transição'`: ir a GASTOS e esperar; tocar `DEZ/26`; registrar o fundo a cada `pump(16 ms)` por 60 quadros; esperar uma cor intermediária (nem `primary`, nem `secondary`) e o último valor `AppColors.primary`.
- O teste existente `'erro desativa o botão + até carregar de novo'` deve continuar passando (Review Focus 3).

Sem teste só para a constante: a duração de 250 ms fica fixada no primeiro teste (aos 100 ms a cor ainda está no meio; aos 250 ms já chegou). Um `pump()` antes do `pump(Duration)` é necessário: o primeiro quadro é o instante zero da animação.

- [ ] **Step 2: Rodar e ver falhar**

Run: `flutter test test/screens/home_test.dart --plain-name "cor do fundo"`
Expected: os testes de cor FALHAM (a cor pula direto para `secondary`; a cor pula direto para `secondary`).

- [ ] **Step 3: Implementar**

Criar `AppMotion`. Em `HomeScreen.build`, embrulhar o `Scaffold` num `TweenAnimationBuilder<Color?>(tween: ColorTween(end: colorState), duration: AppMotion.color, curve: AppMotion.colorCurve, child: <o SafeArea atual>, builder: (context, color, body) => Scaffold(backgroundColor: color, body: body, floatingActionButton: …))`. O `child` evita reconstruir a lista a cada quadro da cor. O botão + usa a mesma `color` (e `color.withAlpha(110)` quando `_loadFailed`).

- [ ] **Step 4: Rodar e ver passar**

Run: `flutter test` e `flutter analyze`
Expected: tudo passa.

- [ ] **Ajuste depois do teste do usuário (2026-11-27):** a cor implícita de 250 ms só começava quando o índice da aba mudava, no fim do arraste, então "demorava e mudava bruscamente". Trocado por cor ligada ao progresso das abas: `BalanceTabView.onTabProgress: ValueChanged<double>?` (valor de `TabController.animation`, 0 a 1) e, na home, um `AnimationController _tipo` (0 = ganhos, 1 = gastos) que recebe o valor direto e anima para 0 só na troca de mês (`animateTo(0, duration: AppMotion.color, curve: AppMotion.colorCurve)`). Teste novo `'segue o dedo ao arrastar de ganhos para gastos'`: com o dedo na tela a cor está entre as duas e fica mais perto do coral a cada movimento. Verificado: falha sem o `onTabProgress` na home e passa com ele.

- [ ] **Step 5: Doc**

`docs/tema-e-layout.md`: seção "Movimento (`lib/theme/motion.dart`)": a cor do fundo e do botão + anima por 250 ms com `easeOut` ao trocar entre ganhos e gastos (toque, fim do deslize ou troca de mês). Citar também na seção do botão + de `docs/home-e-lancamentos.md`, se houver.

- [ ] **Step 6: Commit (depois da revisão do usuário)**

`feat: cor do fundo e do botão + com transição entre ganhos e gastos`

---

### Task 4: Formulário que não pula com os erros

**Files:**
- Modify: `lib/widgets/formField/form_field.dart` (caso `TypeInput.text`)
- Modify: `lib/theme/theme.dart` (`inputDecorationTheme`)
- Modify: `test/widgets/form_balance_test.dart`
- Modify: `test/theme/theme_test.dart` (um `expect` do `helperStyle`)
- Modify: `docs/home-e-lancamentos.md` (seção "Formulário")

**Interfaces:**
- `InputDecoration(hintText: hintText, labelText: label, helperText: ' ')` nos campos de texto (Nome e Valor).
- `InputDecorationTheme.helperStyle` = `textTheme.labelSmall` (o mesmo estilo de `errorStyle`, para a linha reservada ter a altura da linha de erro).

- [ ] **Step 1: Escrever os testes**

`form_balance_test.dart`, usando o helper `open`:

- `'erros de validação não mudam a altura do formulário'`: `open(tester, FormBalance(onSubmit: (_) async {}))`; `antes = tester.getSize(find.byType(FormBalance)).height`; tocar `Salvar`; `pumpAndSettle`; `expect(find.textContaining('vazio'), findsNWidgets(2))` (Nome e Valor); `expect(tester.getSize(find.byType(FormBalance)).height, antes)`.
- `'a linha de erro reservada não estoura com fonte em 130%'` (Review Focus 4): `tester.view.physicalSize = const Size(392, 850)`, `tester.platformDispatcher.textScaleFactorTestValue = 1.3`, abrir, tocar `Salvar`, `pumpAndSettle` e `expect(tester.takeException(), isNull)`; restaurar os valores no `addTearDown`.

`theme_test.dart`: `helperStyle` e `errorStyle` do `inputDecorationTheme` têm o mesmo `fontSize` e a mesma `height` (a linha reservada tem a altura da linha de erro).

- [ ] **Step 2: Rodar e ver falhar**

Run: `flutter test test/widgets/form_balance_test.dart test/theme/theme_test.dart`
Expected: o teste de altura FALHA (o formulário cresce com os erros); o do `helperStyle` FALHA.

- [ ] **Step 3: Implementar**

Adicionar `helperText: ' '` ao `InputDecoration` do caso `TypeInput.text` e `helperStyle` ao `inputDecorationTheme`.

- [ ] **Step 4: Rodar e ver passar**

Run: `flutter test` e `flutter analyze`
Expected: tudo passa (inclusive os testes de contador e de estilo dos valores, que não podem mudar).

- [ ] **Step 5: Doc**

Em "Formulário": a linha de erro de Nome e Valor é reservada (`helperText: ' '`), então os erros de validação aparecem sem mudar a altura do modal; o formulário fica duas linhas mais alto que antes.

- [ ] **Step 6: Commit (depois da revisão do usuário)**

`fix: formulário não pula quando aparecem os erros de validação`

---

### Task 5: Verificação final (sem commit próprio)

- [ ] **Step 1:** `dart format --output=none --set-exit-if-changed lib test`, `flutter analyze` e `flutter test` limpos.
- [ ] **Step 2:** Refazer a linha de base em profile e comparar com a de `docs/testes.md`: `flutter drive --profile --no-dds -d <celular> --driver=test_driver/integration_test.dart --target=integration_test/animacoes_perf_test.dart`. Esperado: p90 e p99 de build e raster iguais ou melhores. **O `flutter drive` apaga a sessão do app:** reinstalar com `tool/celular.sh instalar` e pedir ao usuário o toque no seletor do Google.
- [ ] **Step 3:** No celular, gravar de novo a troca de mês, o deslize GANHOS↔GASTOS e a validação do modal, e conferir quadro a quadro: sem faixa do mês seguinte, sem loader, cor com transição, formulário sem pulo.
- [ ] **Step 4:** Parar e deixar o usuário revisar o código e testar antes de cada commit.

---

## Segunda rodada (pedidos do usuário depois de testar no celular)

Mesmo método: teste que falha primeiro, sem commit antes da revisão do usuário.

### Task 5: Manter a aba de tipo ao trocar de mês

**Files:** `lib/widgets/balance_tab_view.dart` (novo `final String initialType` = `TypeBalance.gains`, usado como `initialIndex` do `TabController`), `lib/screens/home.dart` (passa `initialType: typeBalancePage`; `_handleChangeMonth` deixa de zerar `typeBalancePage`; `_tipo` vira `ValueNotifier<double>`), `lib/theme/motion.dart` removido nesta tarefa e recriado na 7. Testes em `home_test.dart`: `'a aba de tipo se mantém ao trocar de mês'` (toque, deslize, lista que cresce, e o guarda de ganhos) e `'trocar de mês estando em gastos mantém o coral'` (substitui o teste que esperava voltar a verde).

### Task 6: Altura reservada no resumo

**Files:** `lib/widgets/resume_money.dart` (a linha de apoio vira `Visibility(maintainSize: true, ...)` com `Text(hint ?? ' ')`). Testes: `balance_resume_test.dart` (`'o resumo termina no mesmo ponto com ou sem avisos'`, medindo o fim do último `ResumeMoney`, porque o `Column` do resumo ocupa a altura que recebe) e `home_test.dart` (`'o cartão da lista fica na mesma altura em todos os meses'`). Nos testes a fonte é a Ahem, mais larga que a WorkSans: usar a largura padrão de 800 dp, onde nenhum aviso quebra.

### Task 7: Fade com logo compartilhado

**Files:** `lib/commons/routes.dart` (`const logoHeroTag = 'logo'`, `Route<T> fadeRoute<T>(WidgetBuilder builder)`), `lib/theme/motion.dart` (`AppMotion.page` = 300 ms), `splash.dart`, `login.dart`, `home.dart` (`_logout`) e `main.dart` (sessão expirada) trocam `CupertinoPageRoute` por `fadeRoute`; `Hero(tag: logoHeroTag)` em volta do logo da splash e do login. Testes: `test/commons/routes_test.dart` (fade de 300 ms, sem `SlideTransition`) e `login_test.dart` (o logo é um `Hero` com a tag). A splash não tem teste de widget (Timer e plataforma): vale a gravação no celular.
