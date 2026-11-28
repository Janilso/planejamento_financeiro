# Tema e layout

Tokens e regras visuais do app. As decisões e as medições estão na [revisão de layout](superpowers/specs/2026-11-26-revisao-de-layout-design.md).

## Cores (`lib/theme/colors.dart`)

| Token | Valor | Uso |
|---|---|---|
| `AppColors.primary` | `#44A2A6` | Ganhos: fundo da home, login e splash, botão +, Salvar, valores e ícones da lista |
| `AppColors.secondary` | `#F7646C` | Gastos, nos mesmos lugares |
| `AppColors.primaryLight` / `secondaryLight` | as mesmas a 12% | Fundo do ícone do item |
| `AppColors.danger` | `#D63A42` | Erro, ações destrutivas e fundo do arraste para excluir |
| `AppColors.black` | `#323232` | Texto principal (padrão do tema) |
| `AppColors.textSecondary` | `#5E6B6B` | Texto secundário |
| `AppColors.hint` | `#6B7676` | Texto de exemplo dos campos |
| `AppColors.grayLight` | `#323232` a 10% | Divisórias e sublinhados |

- **Texto sobre a cor da marca:** branco sólido, sem transparência.
- **Exceção de contraste:** ganhos e gastos ficam com **3:1** contra o branco (escolha do usuário). Isso passa no WCAG AA só para texto grande. Por isso o teste `textContrastGuideline` roda só nos diálogos. Perigo, texto secundário e exemplo passam 4,5:1, e `test/theme/tokens_test.dart` confere.

## Texto (`lib/theme/texts_style.dart`)

WorkSans 400/600, com os tamanhos reais em sp. Nada abaixo de 12 sp.

| Estilo | sp | Altura | Uso |
|---|---|---|---|
| `displaySmall` | 36 | 1,2 | balanço |
| `titleLarge` | 26 | 1,2 | totais do resumo |
| `titleSmall` | 20 | 1,3 | título do formulário e do diálogo |
| `bodyLarge` | 18 | 1,3 | item da lista, abas, valores digitados |
| `bodyMedium` | 16 | 1,5 | rótulos de linha, texto do diálogo |
| `bodySmall` | 13 | 1,4 | rótulos do resumo, subtítulos |
| `labelLarge` | 16 (600) | 1,25 | botões |
| `labelMedium` | 14 | 1,4 | rótulo dos campos (600) |
| `labelSmall` | 12 | 1,4 | erro do campo, contador |

Valores em dinheiro fora do formulário usam `FontFeature.tabularFigures()`.

## Espaçamento e raio (`lib/theme/spacing.dart`)

- `AppSpacing`: 4, 8, 12, 16, 24, 32 e 48.
- `AppRadius`: 8, 12 e 16; círculo com `BoxShape.circle`.

## Tema (`lib/theme/theme.dart`)

- `ColorScheme` próprio: `primary`, `secondary`, `error` = perigo, `onSurface` = texto principal.
- Toque: o `splashColor` padrão é a cor de ganhos a 12%. Cada componente usa a cor do seu contexto.
- Diálogos: fundo branco, título em `titleSmall` 600, texto em `bodyMedium` secundário. Botões de texto com 48 dp de altura.
- Campos: rótulo sempre acima, exemplo em `hint`, erro em perigo.
- SnackBar flutuante; modal com fundo branco.

## Movimento (`lib/theme/motion.dart`, `lib/commons/routes.dart`)

- **Cor entre ganhos e gastos:** o fundo da home e o botão + seguem as abas GANHOS/GASTOS. A home guarda um valor de 0 (ganhos) a 1 (gastos) num `ValueNotifier` (`_tipo`) e a cor é `Color.lerp(primary, secondary, valor)`. Cada `BalanceTabView` reporta a posição da sua aba (`onTabProgress`, vinda de `TabController.animation`), então a cor acompanha o dedo no arraste, o assentamento e o toque na aba, sem esperar o fim do gesto. O corpo da home vai como `child` do `ValueListenableBuilder`, para a lista não ser reconstruída a cada quadro.
- **Logo animado na splash** (`lib/widgets/logo_animado.dart`): as três folhas do logo chegam da esquerda, uma depois da outra (a de cima traz o furo do $ e as linhas de velocidade), e "PLANEJAMENTO" e "FINANCEIRO" sobem de baixo da própria faixa. Leva 1,5 s e termina parado antes da troca de tela, então o voo (`Hero`) até o login não muda. **No login** (`LogoAnimado(balancar: true)`), as três folhas ficam balançando sem parar, até 3 dp na horizontal, num ciclo de 2 s, cada uma um pouco atrasada em relação à outra; o texto não se mexe. Vindo da splash (`LoginScreen(vindoDaSplash: true)`), o logo chega voando já montado e só balança; depois de Sair ou da sessão expirar, ele entra em partes e depois balança. Como o balanço não acaba, testes com o login na tela usam `pump(Duration)`, não `pumpAndSettle()`. Com as animações desligadas no sistema, o logo já aparece parado. As partes ficam em `assets/images/logo/` e são recortadas do SVG do Figma, guardado em `docs/assets/logo.svg` (fora do APK): cada `<path>` vira um SVG com o mesmo `viewBox` (`folha-3`, `folha-2`, `folha-1`, `texto-1`, `texto-2`), para as partes se alinharem uma sobre a outra. Se o logo mudar, exporte o SVG de novo e recorte da mesma forma.
- **Troca de tela em fade:** splash, login e home se substituem com `fadeRoute` (`lib/commons/routes.dart`), um fade de `AppMotion.page` (300 ms). O app só vai para a frente (`pushReplacement` e `pushAndRemoveUntil`), então o deslize do iOS não fazia sentido. Vale para splash → login/home, login → home, Sair e sessão expirada.
- **Logo compartilhado:** o logo da splash e o do login são um `Hero` com a mesma tag (`logoHeroTag`); ele desliza até a nova posição enquanto o resto aparece em fade.
- A troca de mês e a de GANHOS/GASTOS usam a mola padrão do `TabBarView`, sem quique.
- Ainda **não** há tratamento de "remover animações" do Android: nem o SDK Material nem o app leem `MediaQuery.disableAnimations`.

## Limites conhecidos

- O layout funciona sem cortes até 130% de fonte do sistema. 200% (WCAG 1.4.4) não tem suporte.
