# Revisão de layout: diagnóstico e proposta

Data: 2026-11-26. Situação: **aprovado pelo usuário** em 2026-11-26. As decisões visuais da seção 4 foram tomadas nos protótipos e nas perguntas da revisão.

## 1. Por quê

O visual do app tem pouco acabamento. O usuário pediu uma revisão geral, com acabamento visual como prioridade, seguindo princípios de design, UI e UX de apps de finanças.

Critérios usados:
- Material 3;
- WCAG 2.2 AA;
- área de toque mínima de 48 dp;
- as skills `ui-ux-pro-max` (checklist `pro-rules.md`), `mobile-app-design-mastery` e `flutter-design`.

Quando as fontes discordam, a ordem é WCAG/Material 3, depois o tema do projeto, depois as skills.

- **Objetivo:** cada texto legível, um sistema de cores, tipografia e espaçamento aplicado pelo tema, e telas que mostram o número principal com clareza e dão retorno a cada ação.
- **Não é objetivo:** tema escuro, gráficos, categorias, mudanças na API e troca do logo.
- **O que não pode acontecer:** perder a identidade (verde-água para ganhos, coral para gastos, WorkSans e logo), ou o app ficar mais lento ou mais difícil de usar do que hoje.

## 2. Como foi feito

- **Capturas no celular do usuário** (1080×2400, fonte do sistema em 0,9), com dados fictícios na API e no Mongo locais. Estados capturados:
  - login;
  - home sem lançamentos, com ganhos e com gastos;
  - formulário novo, de edição de parcelado e com erro;
  - diálogos de excluir e sair;
  - carregando e erro de carregamento;
  - fonte em 130%.
- **Medições:**
  - contraste calculado pela fórmula do WCAG;
  - tamanhos efetivos de fonte;
  - levantamento no código de cores, estilos e números soltos.

## 3. Achados, do mais grave ao mais leve

### Crítico

**C1. O texto não alcança o contraste mínimo com as cores da marca.**

| Onde | Par | Contraste | Mínimo |
|---|---|---|---|
| Resumo, abas e balanço | branco sobre #65BCBF | 2,21:1 | 3:1 (grande) / 4,5:1 |
| Mesmo lugar, em gastos | branco sobre #F8777D | 2,65:1 | idem |
| Rótulos "GANHOS/GASTOS/BALANÇO" e abas inativas | branco 70% sobre verde-água / coral | 1,77:1 / 1,99:1 | 4,5:1 |
| Título da barra, valores da lista e botão do login | #65BCBF sobre branco | 2,21:1 | 4,5:1 |
| Valores de gasto na lista | #F8777D sobre branco | 2,65:1 | 4,5:1 |
| Ícone "$" dos itens | cor sobre a mesma cor a 10% | 2,05:1 / 2,41:1 | 3:1 (ícone) |
| Nome do item | #323232 sobre branco | 12,8:1 | ok |

Código: `lib/theme/colors.dart`, `AppColors.whiteDesable` usado em `resume_money.dart:28`, `balance_tab_view.dart:131`, `infinite_tabel_view.dart:74` e `balance_resume.dart:61`.

### Alto

**A1. O tema de texto atrapalha mais do que ajuda** (`lib/theme/texts_style.dart`, `theme.dart`):
- **Escala:** todo tamanho é dividido por `_sizeScale = 0.9`. O `labelMedium` fica com 8,9 sp e o `labelSmall` com 6,7 sp, abaixo do mínimo legível de 11 sp.
- **Botões dos diálogos:** os `TextButton` usam o `labelLarge`, que fica com 11,1 sp. O "Cancelar/Excluir" sai miúdo.
- **Altura de linha:** é `height: 1` em todos os estilos. O recomendado é 1,4–1,5 no corpo e 1,1–1,2 nos títulos.
- **Cor padrão:** todo o `textTheme` é branco por padrão. Por isso há 13 `copyWith(color: ...)` espalhados, um em cada lugar que precisa de texto escuro.

**A2. O `ColorScheme` não tem relação com a marca.** O `ColorScheme.fromSeed(seedColor: AppColors.white)` gera tons cinza e verde-petróleo, que aparecem no fundo dos diálogos, nos botões de texto e no switch desligado. No diálogo de excluir, "Excluir" tem a mesma cor de "Cancelar" e não sinaliza perigo (`balance_tab_view.dart:55-80`).

**A3. A cor é o único sinal de "não realizado".** É um ponto de 6 px no canto do ícone, sem legenda (`balance/balance.dart:46-60`). O resumo soma realizados e previstos sem separar os dois, então não mostra quanto ainda falta entrar ou sair no mês, que é a pergunta mais comum num app de finanças.

**A4. Excluir só funciona arrastando o item.** Não há alternativa visível. O arraste horizontal também é o gesto que troca a aba Ganhos/Gastos, então dois gestos disputam a mesma área (`balance_tab_view.dart:181-215`, limitação já registrada no `docs/README.md`).

**A5. Os estados vazio e de erro estão incompletos.**
- **Mês sem lançamentos:** mostra um cartão branco vazio, sem texto e sem chamada para o "+" (captura 02).
- **Erro de carregamento:** a tela é só texto sobre a cor, e o "+" continua ativo (captura 14).

### Médio

**M1. A mesma informação aparece repetida.**
- O título da barra ("GANHOS - Novembro 2026") repete o mês das abas e o tipo da aba de baixo, e o texto muda quando se troca a aba.
- "GANHOS/GASTOS" aparece no resumo e nas abas.
- A tela gasta 3 níveis de cabeçalho antes da lista.

**M2. O formulário é inconsistente** (capturas 03, 06 e 07):
- "Nome" tem o rótulo pequeno acima do campo, enquanto "Valor" tem o rótulo grande dentro dele.
- O texto digitado fica alinhado à direita.
- O contador "0/30" aparece sempre.
- O rótulo diz "Parcela(s)".
- O "+/-" das parcelas tem área de toque pequena.
- O ícone do botão é de "enviar", que não combina com "Salvar".

**M3. Os itens da lista não trazem informação além do nome e do valor.**
- Todos têm o mesmo ícone "$".
- A parcela aparece como "TV - 1/3" grudada no nome.
- Não há data nem sinal de realizado em texto.
- O valor não usa algarismos de largura fixa, então os números não se alinham.

**M4. Espaçamentos e raios não seguem uma escala.**
- Há 12 valores de espaçamento diferentes: 4, 5, 8, 10, 12, 16, 18, 24, 32, 44, 48 e 50. Vários (5, 10, 18, 44, 50) ficam fora da grade de 4/8.
- Há quatro raios diferentes: 10, 16, 20 e 35.

**M5. O balanço negativo não tem destaque.** O `ResumeMoney` usa a mesma cor para qualquer sinal.

**M6. O último item da lista fica escondido atrás do botão +.** A lista não tem espaço no fim para o FAB, e com 3 ou mais itens o valor do último fica coberto (visto no protótipo com os lançamentos de teste). Proposta: um espaço no fim da lista com a altura do FAB mais 16 dp.

### Baixo

**B1. Login:**
- a SnackBar "Sua sessão expirou" fica colada no botão (captura 01);
- o botão estoura em telas de 720 px (`docs/README.md`);
- o "G" à direita do texto foge do padrão do Google.

**B2. A aba do mês sai da tela quando a fonte do sistema muda com o app aberto.** Abrindo já com fonte grande, o mês fica centralizado (capturas 11 e 15).

**B3. O `splash.dart:66` usa `Colors.white` direto, e o `load.dart:34` usa `CupertinoColors.black`.**

**B4. O ícone de Sair fica em destaque no topo da tela principal.** É uma ação rara e destrutiva no lugar mais visível.

## 4. Proposta

### 4.1 Tokens (tema)

- **Cores:** um `ColorScheme` próprio, montado a partir da marca, sem `fromSeed(white)`.
  - Tons de texto e fundo da marca medidos:

    | Papel | Ganhos | Gastos | Contraste com branco |
    |---|---|---|---|
    | **Cor da marca em tudo**: fundo da home, login e splash, botão +, botão Salvar, valores e ícones da lista, título | **#44A2A6** | **#F7646C** | 3,0:1 |
    | Tinta clara (fundo do ícone do item) | #44A2A6 a 12% | #F7646C a 12% | n/a |
    | Fundo do arraste para excluir | n/a | **#D63A42** | 4,62:1 |

    **Escolha do usuário (2026-11-26), depois de comparar no celular** os tons originais, a variante A escura, três famílias claras com texto escuro e três pares com texto branco que passavam em 4,5:1. O pedido foi: texto branco sobre a cor, num tom próximo do original, aplicado em tudo, até no botão +.
    - **Exceção de contraste consciente:** 3:1 atende o WCAG AA só para texto grande (totais, balanço e o + do botão). Ficam abaixo de 4,5:1 os rótulos ("GANHOS", "BALANÇO"), as abas de mês e de tipo, o "Falta pagar/receber", os valores da lista e o título da barra. A melhora sobre o original é de 2,2–2,6:1 para 3,0:1. Os testes de `textContrastGuideline` não entram para essas telas, e a exceção fica registrada no `docs/README.md`.
    - **Arraste para excluir:** o fundo usa #D63A42, um vermelho perto do coral, mas mais fundo (1,5:1 em relação ao fundo de gastos). Assim ele se destaca quando aparece, também na aba de gastos. O "Excluir" em branco passa com 4,62:1.
    - **O que foi descartado:** a variante A (#368083/#D0444B), por parecer acinzentada; as opções com texto escuro, porque o usuário quer texto branco; W1 (#188387/#D0454C), W2 (#1D7FA3/#D0445B) e W3 (#1A8196/#BF555B), que passavam em 4,5:1, mas ficavam mais escuras que o desejado.

  - Neutros para texto: #323232 (12,8:1 sobre branco) e um cinza secundário com pelo menos 4,5:1.
  - **Erro e perigo** (texto de erro, sublinhado de erro, ações destrutivas nos diálogos, fundo do arraste): #D63A42, que passa com 4,62:1 sobre branco. Não entra na exceção.
- **Tipografia:** WorkSans (400/600), com tamanhos reais, sem o `_sizeScale`. Os tamanhos reproduzem, arredondados, os que o usuário aprovou nos protótipos (que ainda rodavam com o fator 0,9), e corrigem os estilos que ficavam ilegíveis:

  | Estilo | sp | Altura | Uso |
  |---|---|---|---|
  | `displaySmall` | 36 | 1,2 | balanço |
  | `titleLarge` | 26 | 1,2 | totais do resumo |
  | `titleSmall` | 20 | 1,3 | título do formulário e do diálogo |
  | `bodyLarge` | 18 | 1,3 | nome e valor do item, abas, valores digitados |
  | `bodyMedium` | 16 | 1,5 | rótulos "Realizado"/"Parcelas", texto do diálogo, "Toque em + para lançar" |
  | `bodySmall` | 13 | 1,4 | rótulos do resumo, "Falta…", subtítulo do item |
  | `labelLarge` | 16 (600) | 1,25 | botões |
  | `labelMedium` | 14 | 1,4 | rótulo dos campos de texto (600) |
  | `labelSmall` | 12 | 1,4 | erro do campo, contador |

  - nada abaixo de 12 sp;
  - cor padrão vinda do `ColorScheme` (`onSurface`), não branca;
  - valores em dinheiro com `FontFeature.tabularFigures()`.
- **Espaçamento:** 4, 8, 12, 16, 24, 32 e 48 (`AppSpacing`).
- **Raios:** 8, 12, 16 e circular (`AppRadius`).
- **Componentes no `ThemeData`:** `dialogTheme`, `textButtonTheme`, `switchTheme`, `inputDecorationTheme` (rótulo sempre acima do campo, texto à esquerda), `snackBarTheme` (flutuante) e `floatingActionButtonTheme`.

### 4.2 Decisões visuais

As decisões abaixo são escolhidas por protótipos no app.

1. **Cabeçalho e resumo: decidido, variante A** (escolha do usuário, 2026-11-26).
   - **Como fica:** mantém o layout com fundo colorido que muda com a aba, nos tons da seção 4.1 (#44A2A6 e #F7646C). O texto sobre a cor fica em branco sólido, sem transparência, porque qualquer transparência baixaria ainda mais o contraste. A hierarquia entre rótulo e valor, e entre aba ativa e inativa, vem do peso e do tamanho da letra, não da transparência.
   - **C (considerada):** fundo claro, resumo num cartão verde-água fixo e cor só nos destaques. Tinha hierarquia mais calma, mas mudava mais a identidade.
   - **B (descartada):** manter as cores atuais com texto escuro sobre elas (5,8:1 e 4,8:1). Os valores da lista, sobre branco, continuariam reprovados, então ela resolvia só metade do problema.
   - **Tons:** foram trocados depois da escolha da A. Veja a seção 4.1.
2. **Item da lista: decidido** (aprovado no protótipo, com o valor em peso regular a pedido do usuário).
   - **Ícone:** um círculo de 40 dp com a tinta clara da cor do tipo. Dentro, ✓ (`AppIcons.check`) quando realizado e um relógio (`AppIcons.clock`) quando previsto. O protótipo usou os ícones do Material, mas a implementação usa a família `AppIcons` do app, para manter um só traço. O ponto de 6 px deixa de existir.
   - **Toque e toque longo:** o realce segue a cor do tipo (a cor da marca a cerca de 12% no splash e 8% no highlight) e é retangular, do tamanho da linha. O `ListTile` perde o `RoundedRectangleBorder(20)`, que deixava o realce desalinhado. **Regra geral:** o `splashColor` deixa de ser coral no tema inteiro, e cada componente usa a cor do seu contexto (pedido do usuário, 2026-11-26).
   - **Título:** o nome, em `bodyLarge` e cor de texto principal. O nome não leva mais "- 1/3".
   - **Subtítulo:** em cinza secundário, juntando com " · " a parcela ("Parcela 1 de 3", só em parcelado) e o status ("Pago" ou "Recebido" quando realizado, conforme o tipo; "Previsto" quando não).
   - **Valor:** à direita, em `bodyLarge` com **peso regular (400)**, na cor do tipo (#44A2A6 ou #F7646C, dentro da exceção de 3:1) e com `FontFeature.tabularFigures()`.
3. **Resumo com previsto × realizado: decidido.**
   - Embaixo de cada total aparece uma linha pequena: "Falta receber R$ X" (ganhos não realizados) e "Falta pagar R$ X" (gastos não realizados).
   - Ganhos e gastos ficam lado a lado em `Row` com `Expanded`, e não mais em `Wrap`. Assim não quebram em duas linhas quando o valor cresce.
   - Os totais e o balanço continuam em negrito (600), porque são o número principal da tela.
   - **Escolha minha:** a linha "Falta…" some quando o valor é R$ 0,00.
4. **Mês vazio: decidido.** No lugar da lista vazia aparecem:
   - um ícone em cinza secundário: `Icons.savings_outlined` para ganhos ou `Icons.receipt_long_outlined` para gastos;
   - "Nenhum ganho neste mês" ou "Nenhum gasto neste mês", em `bodyLarge` 600;
   - "Toque em + para lançar".
5. **Escolhas minhas, sem protótipo** (seguem das regras e dos tokens):
   - **Excluir sem arrastar:** o formulário de edição ganha um botão "Excluir" em estilo de texto, com o tom de perigo, que abre o mesmo diálogo do arraste. O arraste continua como atalho (A4).
   - **Diálogos e formulário:** foram prototipados e aprovados; veja o item 8.
   - **Login e SnackBar:** a SnackBar fica flutuante, com margem acima do botão. O botão de login não estoura a largura (B1).
   - **Estado de erro:** ícone e mensagem com o mesmo desenho do estado vazio, mais o botão "Tentar de novo". O + fica desativado enquanto houver erro.
   - **Cinza secundário:** #5E6B6B, que dá 5,5:1 sobre branco.
   - **Balanço negativo (M5):** o número continua em branco sólido, porque nenhuma outra cor passa no contraste sobre o fundo. Ele mostra o sinal "−" e, embaixo, a linha "Gastos acima dos ganhos". O aviso fica em texto, não só em cor.
   - **Retorno de sucesso:** uma SnackBar flutuante e curta: "Lançamento salvo" ao criar ou editar, "Lançamento excluído" ao excluir. Sem "Desfazer", porque exigiria adiar a exclusão na API, e mudar a API está fora do escopo.
   - **Tamanho de fonte do sistema:** o critério é funcionar sem texto cortado nem estouro até 130%. Os 200% do WCAG 1.4.4 exigiriam o cabeçalho rolar junto com a lista (slivers). Para um app pessoal isso fica como limitação conhecida, registrada no `docs/README.md`.
6. **Barra do topo e Sair: decidido** (escolha do usuário, 2026-11-26; resolve M1 e B4).
   - A barra branca e o título "GANHOS - Novembro 2026" saem. O topo fica no fundo colorido, que vai até a barra de status, com os ícones do sistema em claro.
   - À direita fica um menu ⋮ com "Sair", que abre o diálogo de confirmação que já existe. O menu precisa de rótulo acessível ("Mais opções").
   - O mês fica só nas abas de mês. O nome completo ("Novembro de 2026") pode ir no rótulo de acessibilidade da aba selecionada.
7. **Login e splash: decidido** (escolha do usuário, 2026-11-26). O fundo usa a cor de ganhos (#44A2A6, "em tudo"), com textos brancos e o logo branco. O botão de login fica branco, com texto e ícone em #44A2A6. Valem os 3:1 da exceção da seção 4.1.
8. **Modais: decidido** (prototipado e ajustado com o usuário, 2026-11-26). A escala de fontes dos modais fica assim:

   | Papel | Estilo |
   |---|---|
   | Título do formulário ("Novo gasto", "Editar ganho") | 20 sp, 600, texto principal |
   | Rótulo de campo de texto (Nome, Valor) | 14 sp, 600, **sempre acima** do campo (`FloatingLabelBehavior.always`); em #D63A42 quando há erro |
   | **Valores digitados: Nome, Valor e o número de Parcelas** | **um estilo só, de uma única função: 18 sp, regular (400), texto principal, sem algarismos tabulares**, alinhado à esquerda nos campos de texto. Pedido do usuário: os três devem ser iguais, sem nenhuma diferença de tamanho, peso ou forma |
   | Texto de exemplo | 18 sp, regular, #6B7676 (4,7:1) |
   | Rótulo das linhas "Realizado" e "Parcelas" | 16 sp, regular, texto principal |
   | Erro do campo | 12 sp, #D63A42 (4,62:1) |
   | Botão Salvar | 16 sp, 600, **sem ícone** e com o texto centralizado |
   | Título do diálogo | 20 sp, 600 |
   | Texto do diálogo | 16 sp, cinza secundário, explicando a consequência ("Este lançamento tem 3 parcelas…", "Esta ação não pode ser desfeita.", "Seus lançamentos continuam salvos.") |
   | Botões do diálogo | 16 sp, 600, altura mínima de 48 dp; "Cancelar" no texto principal; ação destrutiva ("Excluir", "Todas", "Só esta", "Sair") em #D63A42 |

   - **Parcelas mantém o layout de antes:** o rótulo à esquerda e o "− número +" à direita, na mesma linha. Só o número muda, para o estilo dos valores digitados. O "−" e o "+" ganham rótulo acessível ("Menos uma parcela", "Mais uma parcela").
   - **"Realizado"** continua como está: o rótulo ao lado do switch.
   - **O contador "0/30"** some. Na implementação, ele aparece só perto do limite.
   - **O fundo do modal** é branco, não o cinza-azulado do tema atual.
   - **O que o protótipo não mostra e a implementação corrige pelo `ColorScheme` próprio:** o switch desligado, o sublinhado de erro (hoje vermelho padrão do Material) e o puxador do cursor (hoje verde-petróleo) passam para as cores do tipo.

## 5. O que fica para quem implementar

- A ordem dos PRs (tema, componentes, telas), com TDD e os testes `meetsGuideline(textContrastGuideline / androidTapTargetGuideline / labeledTapTargetGuideline)`.
- Os nomes exatos dos tokens e onde ficam, desde que sigam as escalas acima.
- B2 (aba do mês fora da tela ao trocar a fonte), B3 (cores soltas na splash e no load), o "G" do Google à esquerda do texto, o limite em que o contador aparece e a posição do botão Excluir no formulário.
- Os testes que acham o Sair por `find.byTooltip('Sair')` passam a abrir o menu ⋮ antes.
- Os protótipos foram descartados (o branch `spike/layout-variantes` foi apagado). A referência visual é este documento; a implementação é refeita com TDD a partir do `main`.
