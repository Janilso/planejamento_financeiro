# Desempenho da lista de meses com histórico grande — Plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (ou superpowers:subagent-driven-development) para implementar tarefa por tarefa. Os passos usam caixas `- [ ]`.

**Goal:** Medir, no celular e na API, como a home se comporta com anos de lançamentos e mudar o código só onde um critério combinado reprovar. A busca por janela de meses, proposta pelo usuário, entra se a linha de base pedir.

**Architecture:** Primeiro, as ferramentas de medição: volumes sintéticos determinísticos (Dart e TS), um teste de profile que passa pelo repositório real e pelo Dio com um adaptador falso, um resumo que aplica os critérios e uma medição da API. Depois, uma linha de base com parada, em que o usuário decide, com os números do `extremo`, se a janela entra. Por fim, só as mudanças cujo gatilho disparou, cada uma com teste e doc próprios.

**Tech Stack:** Flutter 3.50.1 (`material_ui`), Dio 5.11.1, `integration_test` + `flutter drive --profile`; API Express 5 + Mongoose 9 + `@date-fns/tz`, Vitest + `mongodb-memory-server`.

**Spec:** não há documento separado. Os critérios combinados na conversa e os 5 critérios da busca por janela estão nas seções "Critérios" e "Sua proposta", abaixo.

## Context

A ideia é preventiva: garantir que o app continue rápido quando houver muitos ganhos e gastos ao longo de vários anos. Hoje não há nenhum problema sentido. Como funciona:

- **Não existe chamada por mês.** A home faz um único `GET /balances` (`lib/screens/home.dart`, `_loadBalances`), que devolve o histórico inteiro agrupado por `MMM/yy`. Cada aba de mês só procura a sua chave nesse mapa, e criar, editar ou excluir busca tudo de novo.
- **Abas infinitas** (`HomeScreen._handleChangeMonth`): começam com 25 meses e ganham mais 12 sempre que a aba selecionada fica a 4 de uma ponta. A lista nunca encolhe. Só a página visível é montada, porque o `TabBarView` usa um `PageView`. A `TabBar`, porém, tem todas as abas, e cada troca de mês ou de tipo chama `setState` na home inteira, mesmo sem mês novo.
- **Medições rápidas no notebook, só como ordem de grandeza**, com dados sintéticos de 15 a 25 lançamentos por mês:
  - a resposta cresce cerca de 90 KB por ano e vai sem compressão: 614 KB com 5 anos, ou 21 KB com gzip. Esses dados se repetiam muito, então um histórico real comprime menos;
  - o agrupamento na API leva uns 40 ms com 5 anos e 117 ms com 10;
  - no app, `MonthBalanceModel.fromMap` roda na thread principal e leva uns 5 ms com 5 anos. O JSON em si o Dio já decodifica num isolate quando passa de 50 KB.
- **O teste de profile atual não cobre esses riscos.** Ele usa 6 meses pequenos e 3 arremessos a partir do meio da lista, então ela nunca cresce.
- **Bug de correção encontrado:** se duas recargas chegarem fora de ordem, o + pode ficar desativado sem motivo e o `_lastBalances` pode ficar com o resultado antigo.
- **Todos os loaders já são o mesmo componente.** Splash, home e botões usam o `AppLoad`. A única diferença é que, no botão branco do login, ele fica na cor da marca, porque branco sobre branco sumiria.

## Sua proposta: busca por janela de meses

**Faz sentido?** Sim. É a única opção do plano em que o custo de cada chamada não cresce com o histórico: o gzip só divide o tamanho da resposta por uma constante, e o isolate só tira a conversão da thread principal.

**Ganho estimado** (notebook, dados sintéticos; a Task 5 mede de verdade):

| | Hoje | Com gzip e conversão em isolate (Tasks 7 e 9) | Com a janela (7 meses) |
|---|---|---|---|
| `pesado` (5 anos): resposta ao abrir | ~614 KB | ~21 KB (com dados reais, mais) | ~70 KB sem gzip (~400 itens) |
| `pesado`: conversão na thread principal | ~5 ms | ~0 | < 1 ms |
| `pesado`: trabalho da API | agrupa ~3.700 itens (~40 ms) | igual | lê o histórico, mas só agrupa a janela |
| `extremo` (10 anos): resposta ao abrir | ~1,5 MB | ~52 KB (com dados reais, mais) | ~90 KB sem gzip (~500 itens) |
| `extremo`: conversão na thread principal | ~12 ms | ~0 | < 1 ms |
| `extremo`: trabalho da API | agrupa ~8.400 itens (~117 ms) | igual | lê o histórico, mas só agrupa a janela |
| Chamadas para voltar 5 anos, mês a mês | 1 | 1 | ~20 (uma a cada 3 meses) |
| Loader depois de abrir o app | nunca | nunca | quando a navegação passa da busca antecipada |

**Em resumo:** com 5 anos, o gzip e o isolate devem bastar, e a janela economiza só dezenas de KB e de ms. Perto de 10 anos, ela passa a fazer diferença na rede, na API e na memória do celular.

**Custo:** é a maior mudança do plano.
- uma rota nova na API, com validação, Swagger e verificação de contrato;
- um cache de meses no app, com regras de busca, respostas fora de ordem e recarga depois de salvar;
- loaders voltando a aparecer entre meses, quando a navegação for mais rápida que a busca antecipada;
- a ordem de deploy importa: a API nova tem de estar no ar antes do app novo.

**Como cada critério entra:**

| Critério | No plano |
|---|---|
| 1º — abrir no mês atual ±3, com a informação de se há mais dados antes e depois | Ao abrir, `MonthsCache.openAt(mesAtual)` faz uma chamada `GET /balances/months?from=<atual−3>&to=<atual+3>`. A resposta traz `firstMonth` e `lastMonth` do histórico inteiro, e daí saem "tem mais antes" e "tem mais depois" (Task J1) |
| 2º — no penúltimo mês carregado, buscar os próximos 3 se houver dados | `arrivedAt(mes)`, chamado quando uma troca de mês assenta: no penúltimo ou no último mês carregado de um lado, se houver mais dados além, busca os 3 meses seguintes. Sem mais dados, não busca nada (Task J3) |
| 3º — mês escolhido direto (sem rolar) faz o mesmo que abrir a tela | Um toque na aba (`TabBar.onTap`, que só dispara em toque) chama `openAt(mes)`. Se o mês ainda não estiver carregado, busca o ±3 dele, só o que falta. Depois, a regra do 2º continua valendo (Tasks J3 e J4) |
| 4º — loader no mês que ainda está carregando | A página de um mês em `loading` mostra `Center(child: AppLoad())`. Um mês já carregado nunca mostra o loader, nem durante uma recarga (Task J4) |
| 5º — todos os loaders iguais ao do splash | Já vale hoje. O loader de cada mês é o mesmo `AppLoad()` branco, sobre a cor da marca, do splash (Task J4) |

**Decisões minhas** (pode vetar ao aprovar o plano):
- **`firstMonth`/`lastMonth` no lugar de dois indicadores booleanos.** É a mesma informação ("tem mais antes/depois"), mas continua certa depois de um salto (3º critério) e depois de salvar. Indicadores relativos a cada janela se complicam quando um toque cria trechos carregados que não se encostam. Custo aceito: rolar por um buraco nos dados (um ano sem lançamentos no meio do histórico) busca janelas vazias até os dados voltarem.
- **Uma rota separada, `GET /balances/months?from=AAAA-MM&to=AAAA-MM`**, com `from` e `to` inclusivos e no calendário de São Paulo. A `GET /balances` continua igual, para o app antigo durante o deploy. O `docs.test.ts` confere o formato da resposta por caminho, então o formato não pode mudar conforme a query.
- **A API filtra pelos limites dos meses em São Paulo**, comparando instantes, o que é barato. Só os itens da janela passam pelo `dateToMonthYear`. Um teste garante que a classificação é igual à do `dateToMonthYear` nas viradas de mês, inclusive em horário de verão (2018). Filtrar pela chave do mês de cada item seria idêntico por construção, mas manteria o custo da API proporcional ao histórico, que é um dos critérios da decisão.
- **Um toque num mês já carregado não busca nada.** Valem só a regra do 2º e o toque na aba já selecionada, que não faz nada.
- **Depois de criar, editar ou excluir**, o app recarrega numa chamada só o intervalo já carregado inteiro (do primeiro ao último mês buscado). Fica correto para parcelados e nunca mostra o loader em mês já visto. Na pior hipótese, depois de navegar por anos, a recarga fica do tamanho da de hoje.
- **O cache é guardado por mês, nunca pelo índice da aba**, porque acrescentar abas no começo desloca os índices. Uma recarga nunca volta um mês carregado para `loading`, e um contador de geração descarta respostas que chegam fora de ordem.
- **O loader aparece na hora**, como diz o 4º critério. O teste de volume conta quantos meses mostram o loader com a rede lenta (`meses_com_loader`); se forem muitos, dá para buscar antes do penúltimo mês.
- **O botão + só fica desativado quando o mês selecionado falhou ao carregar.**

**Quando entra:** a decisão é sua, na parada da Task 5, com os números do `extremo`. **Padrão:** a janela entra se o `extremo` reprovar na rede, na API ou no `abrir` (critério absoluto, abaixo).

## Critérios

**Volumes.** Os geradores em Dart e em TS seguem as mesmas regras de volume, mas não precisam produzir o mesmo JSON.

| Volume | Meses até o atual (inclusive) | Lançamentos novos por mês | Mês cheio | Itens no `GET` |
|---|---|---|---|---|
| `leve` | 12 | 15 | — | 504 |
| `pesado` | 60 | 20 | o mês atual com 150 | 3.724 |
| `extremo` | 120 | 25 | — | 8.400 |

- Os lançamentos são contados dentro de cada mês a partir de zero (`i`).
  - Com `i % 5 == 0`, o lançamento é parcelado em 10x: as parcelas caem no mês do lançamento e nos 9 seguintes, inclusive meses futuros. O `totalValue` é o valor cheio, dividido em centavos com o resto na última parcela, como faz a API.
  - Com `i % 4 == 0`, é ganho; nos outros casos, é gasto.
- Os valores são pseudoaleatórios, de `Random(42)`, entre R$ 5,00 e R$ 3.000,00, com centavos.
- Os nomes são únicos, têm até 30 caracteres e variam: uns 30 nomes comuns mais um sufixo. Assim a compressão não fica otimista demais.
- As datas caem no dia `1 + i % 28`, às 15:00Z (12:00 em São Paulo). Nenhum fuso joga o lançamento para outro mês.
- Realizado: sempre nos meses passados, quando `i` é par no mês atual e nunca nos futuros.
- O mês atual é o de `hoje`: `DateTime(2026, 11, 25)` no app e `2026-11-25T15:00:00Z` na API.

**Aprovação.** Medida no celular, em profile, usando a mediana de 3 rodadas.

| Fluxo (chave `<volume>_<fluxo>`) | O que mede | Critério |
|---|---|---|
| `abrir` | os dados chegam com o loader na tela | pior quadro de build e de raster < 16 ms |
| `troca_mes_perto` | arremessos 1 a 21 para o passado: a lista vai de 25 a 49 abas | p99 de build e de raster < 8,3 ms e pior quadro < 16 ms |
| `troca_mes_longe` | arremessos 22 a 60: a lista vai até 85 abas | igual ao anterior |
| `troca_tipo` | 6 toques alternados em GASTOS e GANHOS no mês atual | p99 < 8,3 ms |
| `rolar_lista` | 3 arremessos para baixo e 3 para cima na lista de GASTOS do mês atual | p99 < 8,3 ms |
| `salvar` | do toque em Salvar até a recarga chegar e tudo assentar | pior quadro < 16 ms |
| API | local, em processo, 20 requisições | mediana < 200 ms e no máximo 100 KB na rede |

**Veredito:**

| Linhas | Veredito | Quando |
|---|---|---|
| `pesado` | `aprovado` | passa no critério |
| `pesado` | `reprovado` | falha, o `leve` passa, e o `pesado` fica pelo menos 20% pior: dispara a tarefa ligada ao fluxo |
| `pesado` | `limite` | falha, mas fica menos de 20% pior que o `leve`: mostrar ao usuário, sem mudança por padrão |
| `pesado` | `jaExiste` | o `leve` também falha no mesmo critério: mostrar ao usuário como problema que já existe, sem corrigir por conta própria |
| `extremo` | `aprovado` / `reprovado` | só pelo critério absoluto, sem comparar com o `leve`; serve para decidir a janela |
| `leve` | `informativo` | é o controle |

Na troca de mês, quase todos os meses do `leve` ficam vazios, então ele funciona como piso, não como espelho do `pesado`.

**O que não pode piorar:**
- **Mês já carregado nunca mostra o loader.** Sem a janela, nenhum mês mostra o loader depois do primeiro carregamento (testes do grupo `páginas de mês sem piscar o loader`). Com a janela, só um mês ainda não carregado mostra o `AppLoad`, até os dados chegarem.
- A linha de base das animações em `docs/testes.md` (p99 de build de 4,75 / 8,16 / 5,24 ms e de raster de 2,05 / 3,96 / 3,11 ms): nenhum p99 pode ficar mais de 20% acima. Se ficar, rode mais 2 rodadas e use a mediana.

## Ordem de execução

1. **Medição e linha de base:** Tasks 1 a 5. Na parada da Task 5, o usuário decide se a janela entra.
2. **Sem a janela:** 6 → 7 → 8 → 9 → 10 → 11 → 12. Fora a 6, que é uma correção e entra sempre, cada tarefa só roda se o seu gatilho disparou.
3. **Com a janela:** 7 → 8 → J1 → J2 → J3 → J4 → J5 → 10 → 11 → 12.
   - A Task 6 sai: os testes dela passam para o cache, na J3, e o `_loadBalances` deixa de existir.
   - A Task 9 sai: com janelas pequenas, a conversão leva menos de 1 ms.
   - As Tasks 7, 8, 10 e 11 continuam dependendo do próprio gatilho.

## Global Constraints

- **Commits em pt-BR**, com `fix:`, `feat:`, `test:`, `docs:`, `ci:`, `chore:` ou `style:`. **Antes de cada commit, parar e deixar o usuário revisar o código e testar no celular.**
- **TDD** com `flutter_test` ou Vitest e dublês escritos à mão: o teste falha primeiro, pelo motivo certo.
- O `AppLoad` tem animação infinita: use `pump()` enquanto ele estiver na tela. Nos testes de volume, use esperas fixas em vez de `pumpAndSettle()`.
- **Verificação no app:** `dart format lib test integration_test tool`, `flutter analyze` e `flutter test`. Comandos longos ou em segundo plano usam `~/snap/flutter/common/flutter/bin/flutter`.
- **Verificação na API:** `npm run typecheck`, `npm run lint` e `npm test`.
- **Sem `print`:** em `tool/` e `integration_test/`, use `stdout.writeln`, porque o lint `avoid_print` também vale ali.
- **`flutter drive` reinstala o app e apaga a sessão.** Avise o usuário antes de cada rodada e deixe o login, em que ele toca no seletor de conta, para o fim.
  - Rode sempre com `--profile --no-dds`.
  - Para achar a porta do celular, use `adb mdns services` ou `adb devices`; pergunte ao usuário só se não achar.
- A chave do mês tem de continuar igual byte a byte: `MMM/yy`, pt-BR, maiúsculas e sem ponto (`NOV/26`), tanto no `monthKey` (app) quanto no `dateToMonthYear` (API). O mês nos parâmetros e no intervalo (`from`, `to`, `firstMonth`, `lastMonth`) é `AAAA-MM`, no calendário de São Paulo.
- A medição da API usa só o `mongodb-memory-server` da suíte, nunca o `.env` nem o Atlas.
- **Branches:**
  - app: `perf/lista-de-meses`, a partir da `style/animacoes`. Se a `style/animacoes` for mergeada antes, faça rebase na `main`;
  - API: `perf/get-balances`, a partir da `main`.
- Atualize o `docs/` do assunto junto com cada mudança, nos dois repositórios.
- **Agentes de revisão:**
  - mudou o repositório, os models ou uma rota: rode o agente `contrato-app-api`;
  - mexeu em meses ou datas: rode o `revisor-financeiro`.
- Push, PR e deploy só quando o usuário pedir. Com a janela, a API nova precisa estar no ar antes do app novo.

## Review Focus

Cada item tem teste na tarefa dona do código:

1. **Classificação de mês nas viradas, em São Paulo:** o filtro da janela na API classifica igual ao `dateToMonthYear` 1 ms antes, na virada e 1 ms depois, inclusive em horário de verão (dez/2018). Task J1.
2. **Respostas fora de ordem:** uma janela ou recarga antiga que chega depois da nova não sobrescreve os dados nem marca erro. Tasks J3 e 6.
3. **Mês carregado nunca mostra o loader:** nem numa recarga com a página visível, nem depois de a lista de meses crescer com o cache cheio (cache por mês, não por índice). Tasks J4 e 8.
4. **Toque num mês vizinho já carregado não faz chamada,** e o toque na aba já selecionada também não. Task J4.
5. **O + abre "Novo gasto" depois de passar para GASTOS,** quando a troca de tipo deixar de reconstruir a home. O teste vem antes de tirar o `setState`. Task 8.

Também com teste: datas do gerador às 15:00Z e no mês da chave (Task 1); a `message` da API depois de a resposta passar a vir em bytes (Task 9); e o recentrar da janela de abas mantendo o mês e o tipo (Task 11).

---

### Task 1: Volumes sintéticos no app

**Files:**
- Create: `docs/superpowers/plans/2026-11-27-desempenho-da-lista-de-meses.md` (cópia deste plano)
- Create: `test/volumes.dart`, `test/volumes_test.dart`
- Modify: `docs/testes.md` (tabela "O que cada arquivo cobre")

**Interfaces:**
- Consumes: `balanceJson(...)` de `test/fakes.dart`; `monthKey` e `monthsBefore` de `lib/commons/months.dart`.
- Produces: `enum Volume { leve, pesado, extremo }` e `Map<String, dynamic> historicoSintetico(Volume volume, {required DateTime hoje})`, no formato do `GET /balances`: `'NOV/26' → {'gains': [...], 'expenses': [...]}`. A data vai como ISO UTC (`'2026-11-15T15:00:00.000Z'`).

- [ ] **Step 1: Criar a branch e copiar o plano.** Rode `git switch style/animacoes && git switch -c perf/lista-de-meses` e copie este arquivo para `docs/superpowers/plans/2026-11-27-desempenho-da-lista-de-meses.md`.
- [ ] **Step 2: Escrever os testes que falham** em `test/volumes_test.dart`, com `setUpAll(setUpPtBr)` e `hoje = DateTime(2026, 11, 25)`:
  - `'conta de itens de cada volume'`: o total de itens (soma de `gains` e `expenses` em todos os meses) dá 504 no `leve`, 3.724 no `pesado` e 8.400 no `extremo`.
  - `'pesado vai de DEZ/21 a AGO/27 e tem o mês cheio'`: as chaves contêm `'DEZ/21'`, `'NOV/26'` e `'AGO/27'` (a última parcela de NOV/26) e não contêm `'NOV/21'` nem `'SET/27'`. `NOV/26` tem 150 itens ou mais.
  - `'ids únicos por parcela e nomes até 30 caracteres'`: o conjunto de `'${id}-${installment}'` tem o tamanho do total, e todo `name.length` é até 30.
  - `'datas às 15:00Z, até o dia 28 e no mês da chave'`: para cada item, `DateTime.parse(date)` é UTC, tem `hour == 15` e `day <= 28`, e `monthKey(DateTime(d.year, d.month)) == chave`.
  - `'é determinístico'`: duas chamadas iguais produzem o mesmo `jsonEncode`.
- [ ] **Step 3: Rodar e ver falhar.** Rode `flutter test test/volumes_test.dart`. Esperado: falha de compilação, porque `historicoSintetico` ainda não existe.
- [ ] **Step 4: Implementar `historicoSintetico`** em `test/volumes.dart`, seguindo as regras da seção "Critérios". Crie um único `Random(42)` por chamada, percorra os meses do mais antigo para o atual e, no caso de parcelado, distribua as 10 parcelas pelos meses seguintes.
- [ ] **Step 5: Rodar e ver passar.** `flutter test test/volumes_test.dart` e `flutter analyze` passam.
- [ ] **Step 6: Atualizar o doc.** Acrescente a linha de `volumes_test.dart` em "O que cada arquivo cobre".
- [ ] **Step 7: Parar para revisão e fazer dois commits.** `docs: plano de desempenho da lista de meses com histórico grande` (com o plano) e `test: volumes sintéticos de histórico para medir desempenho`.

### Task 2: Resumo das medições com os critérios

**Files:**
- Create: `tool/perf_resumo.dart`, `test/tool/perf_resumo_test.dart`
- Modify: `docs/testes.md` (tabela "O que cada arquivo cobre")

**Interfaces:**
- Produces, em `tool/perf_resumo.dart`, só com Dart puro (`dart:io` e `dart:convert`):
  - `enum Veredito { aprovado, reprovado, limite, jaExiste, informativo }`
  - `class LinhaResumo { final String volume, fluxo; final double p99Build, p99Raster, piorBuild, piorRaster; final Veredito veredito; final bool semControle; }`
  - `List<LinhaResumo> resumir(List<Map<String, dynamic>> rodadas)`:
    - considera só as chaves que começam com o nome de um volume seguido de `_` (`leve_`, `pesado_` ou `extremo_`). Os extras (`conversao`, `abrir_ms`, `meses_com_loader`) não viram linhas;
    - para cada chave `<volume>_<fluxo>`, calcula a mediana entre as rodadas de `99th_percentile_frame_build_time_millis`, `99th_percentile_frame_rasterizer_time_millis`, `worst_frame_build_time_millis` e `worst_frame_rasterizer_time_millis`;
    - aplica a tabela de vereditos da seção "Critérios". Sem a linha do `leve` daquele fluxo (por exemplo, com `VOLUMES=pesado`), uma falha do `pesado` vira `reprovado` com `semControle: true`.
  - `String tabelaMarkdown(List<LinhaResumo> linhas)`: o cabeçalho é `| Volume | Fluxo | p99 build | p99 raster | Pior build | Pior raster | Resultado |`, os valores têm 2 casas e o resultado é `✅`, `❌`, `❌ sem controle`, `⚠️ limite`, `já existe` ou `—`.
  - `main(List<String> args)`: lê os arquivos passados em `args` ou, sem argumentos, os 3 `build/perf/volume_*.json` mais recentes. Imprime a tabela e, embaixo, as medianas dos extras.
- Constantes: `orcamentoQuadroMs = 8.3`, `quadroPontualMs = 16.0` e `margemVolume = 1.2`. O mapa de fluxo para critério copia a tabela "Aprovação": os fluxos pontuais olham só o pior quadro, e `troca_mes_*` olha os dois.

- [ ] **Step 1: Escrever os testes que falham** em `test/tool/perf_resumo_test.dart`, que importa `../../tool/perf_resumo.dart`:
  - `'mediana de três rodadas'`: `pesado_rolar_lista` com p99 de build 7, 9 e 8 (e o `leve` em 6) dá `p99Build == 8` e `aprovado`.
  - `'reprova quando passa do orçamento e fica 20% pior que o leve'`: `pesado_troca_tipo` com p99 de build 10 e o `leve` com 7 dá `reprovado`.
  - `'limite quando passa do orçamento perto do leve'`: o `pesado` com 8,6 e o `leve` com 7,9 dá `limite`.
  - `'já existe quando o leve também reprova'`: o `pesado` com 10 e o `leve` com 9 dá `jaExiste`.
  - `'pontual usa o pior quadro'`: `pesado_salvar` com pior quadro de build 17 (o `leve` com 9) e p99 de 3 dá `reprovado`.
  - `'extremo usa só o critério absoluto'`: `extremo_abrir` com pior quadro de 17 dá `reprovado`, e com 12 dá `aprovado`, mesmo com o `leve` em 18.
  - `'leve é informativo'`.
  - `'ignora os extras'`: uma rodada com `conversao`, `abrir_ms`, `meses_com_loader` e `pesado_rolar_lista` gera só as linhas de `rolar_lista`.
  - `'sem leve, a reprovação fica sem controle'`: só `pesado_troca_tipo`, com p99 de build 10, dá `reprovado` e `semControle == true`.
  - `'tabela em markdown'`: a saída contém o cabeçalho exato e uma linha com `✅`.
- [ ] **Step 2: Rodar e ver falhar.** Rode `flutter test test/tool/perf_resumo_test.dart`. Esperado: falha de compilação.
- [ ] **Step 3: Implementar** `resumir`, `tabelaMarkdown` e `main`.
- [ ] **Step 4: Rodar e ver passar.** Os testes e o `flutter analyze` passam, sem aviso de `avoid_print`.
- [ ] **Step 5: Atualizar o doc** com a linha de `tool/perf_resumo_test.dart`.
- [ ] **Step 6: Parar para revisão e fazer o commit.** `test: resumo das medições de desempenho com os critérios`.

### Task 3: Teste de desempenho com volume no app

**Files:**
- Create: `integration_test/volume_perf_test.dart`, `test_driver/perf_driver.dart`
- Modify: `docs/testes.md` (nova seção "Desempenho com volume (profile)")

**Interfaces:**
- Consumes: `Volume` e `historicoSintetico` (Task 1); `tool/perf_resumo.dart` (Task 2); `BalanceRepository` e `HttpClient` de `lib/`; `setUpPtBr` de `test/helpers.dart`.
- Produces:
  - as chaves `<volume>_<fluxo>` da tabela "Aprovação";
  - `reportData['conversao'][<volume>] = {'decode_ms': x, 'fromMap_ms': y}` e `reportData['abrir_ms'][<volume>] = z`;
  - o arquivo `build/perf/volume_<aaaammdd-hhmmss>.json`;
  - `_AdapterDeVolume`, que a Task J2 estende.

- [ ] **Step 1: Escrever o driver.** Em `test_driver/perf_driver.dart`, chame `integrationDriver(timeout: const Duration(minutes: 40), writeResponseOnFailure: true, responseDataCallback: ...)`. O callback chama `writeResponseData(data, testOutputFilename: 'volume_<carimbo>', destinationDirectory: 'build/perf')`.
- [ ] **Step 2: Escrever o adaptador e a montagem** em `integration_test/volume_perf_test.dart`. Não importe o `dart:io` inteiro, porque o `HttpClient` do app colide com o dele.
  - `_AdapterDeVolume implements HttpClientAdapter`, com `Map<String, dynamic> historico`, `Uint8List corpo`, `Duration atrasoGet`, `Completer<void>? segurarGet` e `int gets`:
    - `GET /balances` espera `segurarGet`, se houver, e o `atrasoGet`. Depois devolve `ResponseBody.fromBytes(corpo, 200, headers: {content-type: [application/json], content-length: ['${corpo.length}']})`, como o Express sem gzip. Assim o Dio decide pelo cabeçalho e decodifica num isolate quando passa de 50 KB;
    - `POST /balances` devolve 201 com `{}`.
  - O `corpo` é codificado uma vez por volume (`utf8.encode(jsonEncode(historico))`), fora de qualquer medição.
  - A home usa `HomeScreen(repository: BalanceRepository(HttpClient(Dio(BaseOptions(baseUrl: 'http://perf.local'))..httpClientAdapter = adaptador)), clock: () => DateTime(2026, 11, 25))`. Não há `AuthInterceptor` nem login: o teste mede só o caminho dos dados.
  - Use `binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive`, como no `animacoes_perf_test.dart`.
  - Use o helper `Future<void> esperar(WidgetTester t) => t.pump(const Duration(milliseconds: 700))` depois de cada arremesso ou toque, no lugar do `pumpAndSettle()`. Com a janela, um mês pode mostrar o `AppLoad`, que nunca assenta, e os fluxos precisam ser comparáveis antes e depois.
- [ ] **Step 3: Escrever os fluxos.**
  - **Ordem:** primeiro um `testWidgets('aquecimento')` sem relatório (`leve`, 3 arremessos de mês e 2 toques de tipo). Depois os volumes de `const String.fromEnvironment('VOLUMES', defaultValue: 'leve,pesado,extremo')`, nessa ordem, com o `extremo` sempre por último.
  - **Montagem:** cada fluxo é um `testWidgets` com `pumpWidget` novo. Fora do `abrir`, espere o `BalanceResume` aparecer, avançando quadros de 16 ms com um limite de 10 s, antes de medir.
  - **`abrir`:** com `segurarGet`, monte a home e deixe o loader girar por 500 ms. Dentro do `watchPerformance`, complete o `segurarGet`, avance quadros de 16 ms até o `BalanceResume` aparecer e espere mais 500 ms. Do momento em que o GET é liberado até o resumo aparecer, meça com um `Stopwatch` e grave em `abrir_ms`.
  - **`troca_mes`:** arremesse a partir do ponto do resumo (`Offset(largura / 2, altura * 0.21)`), com `flingFrom(ponto, Offset(300, 0), 1500)` e `esperar` depois de cada um. Os arremessos 1 a 21 ficam no `watchPerformance` de `troca_mes_perto` e os 22 a 60 no de `troca_mes_longe`. No fim, confira que `find.text('NOV/21')` existe.
  - **`troca_tipo`:** 6 toques alternados em `find.widgetWithText(Tab, 'GASTOS')` e `'GANHOS'`, com `esperar` depois de cada um.
  - **`rolar_lista`:** toque em GASTOS fora da medição. Depois, `flingFrom(Offset(largura / 2, altura * 0.7), Offset(0, -500), 2000)` 3 vezes e `Offset(0, 500)` 3 vezes, com `esperar`.
  - **`salvar`:** use `atrasoGet = 100 ms`, para a recarga chegar enquanto o modal fecha. Abra o modal e preencha `name` com `'Perf <volume>'` e `value` com `'5000'` fora da medição, como no `openFormAndSave` de `home_test.dart`. No `watchPerformance`, toque em Salvar, avance quadros de 16 ms até `adaptador.gets == 2` e o `FormBalance` sumir e, no fim, chame `esperar`.
  - **`conversao`:** para cada volume, meça 5 vezes `jsonDecode(utf8.decode(corpo))` e `MonthBalanceModel.fromMap(...)` separadamente. Grave a mediana em `reportData`, criando o mapa com `binding.reportData ??= {}`.
- [ ] **Step 4: Analisar o código.** `flutter analyze` passa sem avisos.
- [ ] **Step 5: Rodar no celular só com o `leve`**, depois de avisar o usuário: `~/snap/flutter/common/flutter/bin/flutter drive --profile --no-dds -d <celular> --driver=test_driver/perf_driver.dart --target=integration_test/volume_perf_test.dart --dart-define=VOLUMES=leve`. Esperado: todos os testes passam e surge um `build/perf/volume_*.json` com `leve_abrir`, `leve_troca_mes_perto`, `leve_troca_mes_longe`, `leve_troca_tipo`, `leve_rolar_lista`, `leve_salvar`, `conversao` e `abrir_ms`.
- [ ] **Step 6: Conferir o resumo.** `dart run tool/perf_resumo.dart build/perf/<arquivo>.json` imprime a tabela com as linhas do `leve`.
- [ ] **Step 7: Atualizar o doc.** Em `docs/testes.md`, crie a seção "Desempenho com volume (profile)" com o comando, os volumes, a tabela de aprovação, os fluxos e o uso do resumo. Avise que o drive apaga a sessão.
- [ ] **Step 8: Parar para revisão e fazer o commit.** `test: medição de desempenho da home com histórico grande`.

### Task 4: Medição da API

Tudo no repositório `/home/janilso/projetos/backend/planejamento_financeiro_api`.

**Files:**
- Create: `test/perf/volumes.ts`, `test/perf/get-balances.perf.ts`, `vitest.perf.config.mts`
- Modify: `package.json` (script `"perf": "vitest run --config vitest.perf.config.mts"` e o novo config no script `lint`), `test/tsconfig.json` (incluir `../vitest.perf.config.mts`), `docs/testes.md` (seção "Desempenho do GET /balances")

**Interfaces:**
- Consumes: `app` (`src/app.ts`), `BalanceService` + `BalanceModel`, `makeToken` (`test/helpers.ts`).
- Produces:
  - `type Volume = 'leve' | 'pesado' | 'extremo'` e `gerarLancamentos(volume: Volume, hoje: Date): BalanceType[]`. São corpos para o `BalanceService.create`, com as regras da seção "Critérios"; o parcelado usa `totalInstallments: 10` e o `value` cheio;
  - `medirRota(caminho: string, token: string, gzip: boolean): Promise<{ medianaMs: number; p90Ms: number; bytes: number; corpo: Buffer }>`, que a Task J1 reaproveita.

- [ ] **Step 1: Criar a branch.** `git switch main && git switch -c perf/get-balances`.
- [ ] **Step 2: Escrever o `vitest.perf.config.mts`.**
  - Reaproveite o bloco `test` do `vitest.config.mts` espalhando o objeto, que traz o `env` com o `MONGO_URI` que nunca conecta, o `globalSetup` e o `setupFiles`.
  - Troque o `include` por `['test/perf/**/*.perf.ts']` e use `testTimeout` e `hookTimeout` de 300000.
  - Não use `mergeConfig`, porque ele concatena o `include`.
- [ ] **Step 3: Escrever o gerador e a medição.**
  - **Um `it` por volume**, que semeia e mede no próprio teste. O `test/setup.ts` limpa as coleções antes de cada `it`, então semear num `beforeAll` não funciona.
  - **Semear** com `new BalanceService(BalanceModel).create(userId, b)` para cada item de `gerarLancamentos(volume, new Date('2026-11-25T15:00:00Z'))`.
  - **`medirRota`** sobe `app.listen(0)` e usa `node:http`, com `Authorization: Bearer ${token}` e, se pedido, `Accept-Encoding: gzip`.
    - Faz 3 requisições de aquecimento e 20 medidas.
    - O tempo vai até o evento `end`.
    - Conta os bytes crus do corpo: o `node:http` não descomprime.
    - Fecha o servidor no `finally`.
  - **Medir** o `GET /balances`, com e sem gzip. Mostre também `zlib.gzipSync(corpo).length` como estimativa enquanto não houver compressão.
  - **Assertivas** só de sanidade: status 200 e total de itens igual a 504, 3.724 ou 8.400. Os critérios são impressos, não testados, porque a linha de base deve reprovar na rede.
  - **Saída**, uma linha por volume, no formato `pesado | /balances | 3724 itens | mediana 85 ms | p90 110 ms | rede 650 KB | estimativa gzip 60 KB | ✅/❌`.
- [ ] **Step 4: Rodar.** `npm run perf` imprime as 3 linhas. Confira também que `npm test` continua sem rodar o arquivo de perf e que `npm run typecheck` e `npm run lint` passam.
- [ ] **Step 5: Atualizar o doc.** Em `docs/testes.md` da API, explique como rodar, o que é medido e que a medição nunca toca no `.env` nem no Atlas.
- [ ] **Step 6: Parar para revisão e fazer o commit.** `test: medição do GET /balances com histórico grande`.

### Task 5: Linha de base e decisão

Esta tarefa não muda código de produto e termina numa parada com o usuário.

**Files:**
- Modify: `docs/testes.md` do app (tabela "Linha de base" da seção "Desempenho com volume") e `docs/testes.md` da API (números do `npm run perf`)

- [ ] **Step 1: Rodar o drive 3 vezes seguidas** com todos os volumes, como na Task 3 e sem `VOLUMES`, depois de avisar o usuário.
- [ ] **Step 2: Gerar o resumo.** `dart run tool/perf_resumo.dart` produz a tabela com as medianas das 3 rodadas.
- [ ] **Step 3: Medir a API.** Rode `npm run perf` no repositório dela.
- [ ] **Step 4: Gravar nos docs** a tabela do app e a da API, com a data, o aparelho (Android a 120 Hz) e o `fromMap_ms` de cada volume.
- [ ] **Step 5: Ligar cada `reprovado` do `pesado` à sua tarefa:**

  | Reprovado no `pesado` | Tarefa |
  |---|---|
  | API com mais de 100 KB na rede | 7 |
  | `troca_mes_*` ou `troca_tipo` no p99 de build | 8 |
  | `abrir` ou `salvar`, com `fromMap_ms` do `pesado` de 4 ms ou mais (sem a janela) | 9 |
  | `rolar_lista`; ou `troca_tipo`, `abrir` ou `salvar`, se continuarem reprovados depois das Tasks 8 e 9, ou J4 (as que tiverem rodado) | 10 |
  | `troca_mes_longe` pelo menos 20% pior que `troca_mes_perto` no p99 de build, depois da Task 8 | 11 |

- [ ] **Step 6: Montar a decisão da janela.** Para o `extremo`, verifique rede (≤ 100 KB), API (mediana < 200 ms) e `abrir` (pior quadro < 16 ms). Padrão: a janela entra se algum dos três reprovar.
- [ ] **Step 7: Parar e mostrar ao usuário** as tabelas, as linhas `limite` e `jaExiste`, a decisão da janela pelo padrão e a ordem de execução resultante. Ele decide. Nenhum código de produto muda antes disso.
- [ ] **Step 8: Fazer o commit nos dois repositórios**, registrando também a decisão da janela. `docs: linha de base de desempenho com histórico grande`.

### Task 6: Recarga antiga não desfaz a mais nova

Só sem a janela. Com a janela, os testes desta tarefa vão para o cache, na J3.

**Files:**
- Modify: `lib/screens/home.dart` (`_loadBalances`), `test/fakes.dart` (`FakeBalanceRepository`), `test/screens/home_test.dart`, `docs/home-e-lancamentos.md` (seção "Carregamento")

**Interfaces:**
- Produces, em `FakeBalanceRepository`: `bool segurarBuscas = false` e `final List<Completer<MonthBalanceModel>> buscasPendentes = []`. Com `segurarBuscas`, cada `getBalances()` continua contando `getCalls`, guarda um `Completer` e devolve o futuro dele.

- [ ] **Step 1: Escrever os testes que falham** em `home_test.dart`:
  - `'recarga antiga que falha depois da nova não desativa o +'`:
    1. Abra a home com dados e ligue `segurarBuscas`.
    2. Chame `openFormAndSave` duas vezes.
    3. Complete `buscasPendentes[1]` com os dados novos e `buscasPendentes[0]` com erro, com um `pump()` depois de cada um.
    4. Esperado: o `onPressed` do `FloatingActionButton` não é nulo, e o item dos dados novos aparece.
  - `'recarga antiga que chega depois não vira o último resultado'`:
    1. Prepare dados velhos com `DEZ/26 → 'Velho'` e dados novos com `DEZ/26 → 'Novo'`.
    2. Complete o índice 1 com os novos e depois o 0 com os velhos.
    3. Toque em `DEZ/26` e avance 45 quadros de 16 ms.
    4. Esperado: `'Velho'` não aparece em nenhum quadro, e `'Novo'` aparece.
- [ ] **Step 2: Rodar e ver falhar.** `flutter test test/screens/home_test.dart` falha: o + fica nulo no primeiro teste, e `'Velho'` aparece no primeiro quadro do segundo.
- [ ] **Step 3: Implementar.** Em `_loadBalances`, os dois callbacks retornam cedo quando `!mounted || !identical(future, _balances)`. Assim, só a busca mais recente atualiza `_lastBalances` e `_loadFailed`.
- [ ] **Step 4: Rodar e ver passar.** `flutter test` passa inteiro, inclusive os grupos de loader e de erro.
- [ ] **Step 5: Atualizar o doc.** Em "Carregamento", registre que só a busca mais recente atualiza o último resultado e o erro, e que uma recarga antiga que chega depois é ignorada.
- [ ] **Step 6: Parar para revisão e fazer o commit.** `fix: recarga antiga que chega depois não desfaz a mais nova`.

### Task 7: gzip na API

**Gatilho:** a API manda mais de 100 KB na rede no `pesado`.

**Files (API):**
- Modify: `src/app.ts`, `package.json` (`compression` e, nas dependências de desenvolvimento, `@types/compression`), `docs/arquitetura.md`
- Create: `test/compression.test.ts`

- [ ] **Step 1: Escrever os testes que falham.** Os dois criam 10 lançamentos, para passar de 1 KB, que é o mínimo do `compression`:
  - `'GET /balances com Accept-Encoding gzip responde comprimido'`: espera `content-encoding: gzip` e que `res.body` tenha os meses;
  - `'com Accept-Encoding identity responde sem compressão'`: espera `content-encoding` indefinido.
- [ ] **Step 2: Rodar e ver falhar.** `npm test -- compression` falha no primeiro teste.
- [ ] **Step 3: Implementar.** Instale `compression` e `@types/compression` e chame `app.use(compression())` logo depois do `helmet()`, antes das rotas.
- [ ] **Step 4: Rodar e ver passar.** `npm test`, `npm run typecheck` e `npm run lint` passam. No `npm run perf`, o `pesado` fica com até 100 KB na rede e ganha `✅`.
- [ ] **Step 5: Conferir de ponta a ponta na API local.**
  1. Com a API local no ar, rode `curl -s -D - -o /dev/null -H 'Accept-Encoding: gzip' -H "Authorization: Bearer $(npm run -s token:dev -- <userId> | tail -1)" http://127.0.0.1:8080/balances`. Use o `userId` de um usuário com lançamentos no Mongo local; o `tail -1` está ali porque o dotenv imprime uma linha antes. Se já houver uma API rodando na 8080, pare-a e suba de novo com `npm run dev`, para ela carregar o `compression`.
  2. Esperado: `Content-Encoding: gzip` e nenhum `Content-Length`. Sem esse cabeçalho, o Dio do app conta os bytes já descomprimidos e continua decodificando num isolate.
  3. Abra o app contra a API local, com `adb reverse`, e confira que a home carrega. O `dart:io` já pede gzip e descomprime sozinho, então o app não muda.
- [ ] **Step 6: Atualizar o doc.** Em `docs/arquitetura.md` da API, registre a compressão gzip quando o cliente aceita.
- [ ] **Step 7: Avisar o usuário** de que o deploy e a conferência dos cabeçalhos em produção ficam com ele. Se o proxy de produção mandar `Content-Length` com o tamanho comprimido (menos de 50 KB), o Dio passa a decodificar o JSON na thread principal; a Task 9, ou a janela, resolve isso.
- [ ] **Step 8: Parar para revisão e fazer o commit na API.** `feat: respostas comprimidas com gzip`.

### Task 8: Home sem reconstruções à toa

**Gatilho:** `troca_mes_*` ou `troca_tipo` reprovado no p99 de build.

**Files:**
- Modify: `lib/screens/home.dart` (`_handleChangeMonth` e `_handleChangeBalance`), `lib/commons/months.dart` (`monthKey`), `test/screens/home_test.dart`, `docs/home-e-lancamentos.md` (seção "Meses")

- [ ] **Step 1: Fixar o comportamento atual.** Estes testes passam antes da mudança:
  - `'o + abre Novo gasto depois de passar para GASTOS'`: toque na `Tab` GASTOS, chame `pumpAndSettle()`, toque no + e espere `find.text('Novo gasto')`.
  - `'recarga logo depois de a lista crescer mostra o mês certo sem loader'`:
    1. Use um repositório com `'FEV/26' → 'Fevereiro'`.
    2. Toque nos meses até FEV/26, como no teste `'a lista de meses crescendo'`, e logo depois chame `openFormAndSave`.
    3. Esperado: nenhum `AppLoad` quadro a quadro (`semLoaderPor`) e `'Fevereiro'` na tela.
- [ ] **Step 2: Escrever os testes que falham**, com o helper `Future<int> reconstrucoesDaHome(WidgetTester tester, Future<void> Function() acao)`:
  - o helper liga `debugOnRebuildDirtyWidget` (de `package:flutter/widgets.dart`) para contar os elementos cujo `widget is HomeScreen`, roda a ação, volta a variável para `null` (também em `addTearDown`) e devolve a contagem;
  - `'trocar para um mês vizinho não reconstrói a home'`: o toque em `DEZ/26` seguido de `pumpAndSettle()` dá 0;
  - `'trocar GANHOS/GASTOS não reconstrói a home'`: o toque na `Tab` GASTOS seguido de `pumpAndSettle()` dá 0.
- [ ] **Step 3: Rodar e ver falhar.** Os dois testes novos dão uma contagem de 1 ou mais.
- [ ] **Step 4: Implementar.**
  - `_handleChangeMonth` só chama `setState` quando a lista de meses cresce; nos outros casos, só atualiza `actualIndex`.
  - `_handleChangeBalance` só atribui `typeBalancePage`: o + lê o valor no toque, e as páginas novas leem quando são montadas.
  - `monthKey` passa a reaproveitar um único `DateFormat('MMM/yy', 'pt_BR')` de nível superior. A saída continua a mesma, e o teste de `monthKey` cobre isso.
- [ ] **Step 5: Rodar e ver passar.** `flutter test` passa inteiro, inclusive `a aba de tipo se mantém…`, `páginas de mês sem piscar o loader` e `cor do fundo…`.
- [ ] **Step 6: Medir.** Rode o drive uma vez com `VOLUMES=leve,pesado` e o resumo desse arquivo. Esperado: `troca_tipo` e `troca_mes_*` com p99 de build menor que na linha de base.
- [ ] **Step 7: Revisar.** Rode o agente `revisor-financeiro`, porque o `monthKey` mudou.
- [ ] **Step 8: Atualizar o doc.** Em "Meses", registre que trocar de mês ou de tipo não reconstrói mais a home: o `setState` só acontece quando a lista cresce.
- [ ] **Step 9: Parar para revisão e fazer o commit.** `fix: home não se reconstrói ao trocar de mês ou de tipo`.

### Task 9: Conversão fora da thread principal

Só sem a janela. **Gatilho:** `abrir` ou `salvar` reprovado, com `fromMap_ms` do `pesado` de 4 ms ou mais.

**Files:**
- Modify: `lib/network/http_client.dart`, `lib/repository/balance.dart`, `test/network/http_client_test.dart`, `test/repository/balance_test.dart`, `docs/dados-e-api.md`

**Interfaces:**
- `ClientRequest({required String url, Object? body, Map<String, dynamic>? headers, Map<String, dynamic>? params, ResponseType? responseType})`. O `HttpClient.get` repassa o `responseType` às `Options`.
- `HttpClient._buildException`: quando a resposta de erro vier em bytes (`List<int>`), tenta `jsonDecode(utf8.decode(...))` para o `_messageFor` continuar achando a `message`.
- Funções de nível superior em `lib/repository/balance.dart`:
  - `MonthBalanceModel parseBalances(Uint8List bytes)`, que faz UTF-8, `jsonDecode` e `MonthBalanceModel.fromMap`;
  - `Future<MonthBalanceModel> parseBalancesInBackground(Uint8List bytes) => Isolate.run(() => parseBalances(bytes));`.
  - Elas ficam no nível superior porque uma closure criada num método do repositório pode levar o `this` junto (e com ele o Dio), o que quebra em tempo de execução com "unsendable".

- [ ] **Step 1: Escrever os testes que falham.**
  - Em `http_client_test.dart`:
    - `'get repassa o responseType'`: com `responseType: ResponseType.bytes`, o `response.data` é um `List<int>`;
    - `'erro em bytes volta como mapa'`: `FakeResponse(400, {'message': 'Erro X'})` com bytes gera um `ClientResponse` com `data['message'] == 'Erro X'`.
  - Em `balance_test.dart`, que usa `test()` com o Dio real e por isso pega o erro de closure não enviável:
    - `'getBalances lê o formato da API'` continua passando;
    - `'erro no getBalances mantém a mensagem da API'`: `FakeResponse(400, {'message': 'Algo deu errado'})` gera uma `ApiException` com `message == 'Algo deu errado'`.
- [ ] **Step 2: Rodar e ver falhar.** Os testes não compilam, porque `responseType` ainda não existe.
- [ ] **Step 3: Implementar.** O `getBalances` pede `ResponseType.bytes` e devolve `await parseBalancesInBackground(...)`. O retry do 401 no `AuthInterceptor` reaproveita as mesmas opções, então não precisa mudar.
- [ ] **Step 4: Rodar e ver passar.** `flutter test` e `flutter analyze` passam.
- [ ] **Step 5: Medir.** Rode o drive uma vez com `VOLUMES=leve,pesado`. Esperado: `abrir` e `salvar` com pior quadro abaixo de 16 ms.
- [ ] **Step 6: Revisar.** Rode o agente `contrato-app-api`, porque o repositório mudou.
- [ ] **Step 7: Atualizar o doc.** Em `docs/dados-e-api.md`, registre que o `getBalances` pede a resposta em bytes e faz a conversão (UTF-8, JSON e models) num isolate.
- [ ] **Step 8: Parar para revisão e fazer o commit.** `fix: conversão dos lançamentos fora da thread principal`.

### Task 10: Lista do mês mais leve

**Gatilho:** `rolar_lista` reprovado, ou `troca_tipo`, `abrir` ou `salvar` ainda reprovados depois das Tasks 8 e 9, ou J4 (as que tiverem rodado).

**Files:**
- Modify: `lib/widgets/balance_tab_view.dart` (`_buildBalances`), `lib/widgets/balance/balance.dart`, `test/widgets/balance_test.dart`, `test/widgets/balance_tab_view_test.dart`, `docs/home-e-lancamentos.md` (seção "Lista")

- [ ] **Step 1: Tirar o `shrinkWrap: true` do `ListView.builder`.** A página já tem altura fixa, então ele só custa relayout ao rolar.
  - Rode `flutter test`. Esperado: passa, inclusive `'espaço para o +'` e `'mês vazio'`.
  - Rode o drive uma vez. Se os fluxos ligados passarem, pule para o Step 5.
- [ ] **Step 2: Mover o teste do toque.** Leve `'toque na cor do tipo e retangular'` de `balance_test.dart` para `balance_tab_view_test.dart` com o nome `'toque dos itens na cor do tipo'`.
  - Em GANHOS, o `Theme.of` no `ListTile` dá `splashColor == AppColors.primary.withAlpha(31)` e `highlightColor == AppColors.primary.withAlpha(20)`.
  - Em GASTOS, a mesma coisa com `AppColors.secondary`.
  - O teste passa antes e depois do Step 3.
- [ ] **Step 3: Implementar um `Theme` por lista.** O `Balance` deixa de criar o próprio `Theme(copyWith(...))`. No lugar, o `_buildBalances` envolve a lista num único `Theme(data: Theme.of(context).copyWith(splashColor: tone.withAlpha(31), highlightColor: tone.withAlpha(20)))`, já que cada lista tem uma cor só.
- [ ] **Step 4: Rodar e medir.** `flutter test` passa, e o drive roda uma vez para comparar.
- [ ] **Step 5: Atualizar o doc.** Em "Lista", registre que a cor do toque vem de um `Theme` por lista e que a lista não usa `shrinkWrap`.
- [ ] **Step 6: Parar para revisão e fazer o commit.** `fix: lista do mês com menos trabalho por item`.

### Task 11: Janela de abas com tamanho fixo

**Gatilho:** `troca_mes_longe` pelo menos 20% pior que `troca_mes_perto` no p99 de build, depois da Task 8.

**Files:**
- Modify: `lib/screens/home.dart` (`_handleChangeMonth`), `test/screens/home_test.dart`, `docs/home-e-lancamentos.md` (seção "Abas infinitas")

**Abordagem:** ao chegar a 4 abas de uma ponta, a lista não ganha mais 12 meses. Em vez disso, é refeita com `monthsAround(mesSelecionado, before: 24, after: 24)`, ou seja, sempre 49 abas, e mantém o mês selecionado e a aba de tipo. Com a janela de dados, o cache é por mês, então recentrar não perde nada.

- [ ] **Step 1: Escrever os testes que falham.**
  - `'a lista de meses não passa de 49'`: toque nos meses um a um rumo ao passado, a partir de NOV/26, 33 vezes, usando `semLoaderPor` entre os toques. Esperado: `tester.widget<InfiniteTabView>(find.byType(InfiniteTabView)).length` de no máximo 49. Hoje dá 61.
  - `'recentrar mantém o mês e a aba de tipo'`: em GASTOS, cruze a ponta. Esperado: o mês tocado continua selecionado, a página mostra a lista de GASTOS desse mês e nenhum quadro tem `AppLoad`.
- [ ] **Step 2: Rodar e ver falhar.** O primeiro teste dá 61.
- [ ] **Step 3: Implementar** a abordagem em `_handleChangeMonth`. O índice continua vindo de `_indexOfMonth(newMonths, actualMonth)`.
- [ ] **Step 4: Rodar e ver passar.** `flutter test` passa inteiro, inclusive `'a lista de meses crescendo'` e `'quando a lista de meses cresce'`.
- [ ] **Step 5: Medir.** Rode o drive uma vez. Esperado: `troca_mes_longe` perto de `troca_mes_perto`.
- [ ] **Step 6: Revisar.** Rode o agente `revisor-financeiro`, porque a lógica de meses mudou.
- [ ] **Step 7: Atualizar o doc.** Em "Abas infinitas", registre que, a 4 abas de uma ponta, a lista é refeita com 24 meses antes e 24 depois do selecionado. Assim, o custo não cresce com o uso.
- [ ] **Step 8: Parar para revisão e fazer o commit.** `fix: lista de meses com tamanho fixo ao navegar para longe`.

---

## Busca por janela de meses (Tasks J1 a J5)

Estas tarefas só rodam se o usuário escolher a janela na parada da Task 5. As regras e as decisões estão na seção "Sua proposta".

### Task J1: Rota de lançamentos por intervalo de meses na API

**Files (API):**
- Create: `src/middlewares/validateQuery.middleware.ts`, `src/utils/monthRange.ts`, `test/balances-months.test.ts`, `test/monthRange.test.ts`
- Modify:
  - `src/middlewares/index.ts`, `src/schemas/balance.schema.ts` (`monthsQuery`), `src/utils/errorMessages.ts` (mensagens novas);
  - `src/routes/balance.route.ts`, `src/controllers/balance.controller.ts` (`getMonths`), `src/services/balance.service.ts` (`getMonthsByUserId`);
  - `src/docs/openapi.ts`, `test/perf/get-balances.perf.ts`, `docs/lancamentos.md`.

**Interfaces:**
- `GET /balances/months?from=AAAA-MM&to=AAAA-MM` devolve 200 com `{ months: GetBalanceResponse, firstMonth: string | null, lastMonth: string | null }`.
  - `months` traz só os meses do intervalo que têm itens, com as chaves `MMM/YY` de hoje.
  - `firstMonth` e `lastMonth` (`AAAA-MM`) são o primeiro e o último mês com itens no histórico inteiro do usuário, já contando as parcelas.
  - Responde 400, com as mensagens em pt-BR, se `from` ou `to` faltar, estiver mal formado ou se `from > to`.
- `validateQuery(schema)` funciona como o `validateParams` e guarda o resultado em `res.locals.query`.
- Em `src/utils/monthRange.ts`, todas no calendário de `APP_TIME_ZONE`, com `TZDate` de `@date-fns/tz`:
  - `monthStartUtc(yearMonth: string): number`, o instante em que o mês começa em São Paulo;
  - `nextYearMonth(yearMonth: string): string`;
  - `dateToYearMonth(date: string): string`, que devolve `AAAA-MM`.
- `BalanceService.getMonthsByUserId(userId: string, from: string, to: string)`:
  - lê os documentos do usuário como hoje;
  - achata com `factoryGetBalanceResponse`;
  - acha o menor e o maior `Date.parse(date)` para calcular `firstMonth` e `lastMonth`;
  - mantém os itens com `monthStartUtc(from) <= t < monthStartUtc(nextYearMonth(to))` e agrupa só esses com o `generateListInstallmentsByUser` de hoje.
- `GET /balances` não muda.

- [ ] **Step 1: Escrever os testes que falham.**
  - Em `monthRange.test.ts`, `'a janela classifica igual ao dateToMonthYear nas viradas de mês'`:
    - meses `2018-11`, `2018-12` (horário de verão, início às 02:00Z), `2019-02`, `2019-03`, `2026-01` e `2026-11`;
    - instantes `monthStartUtc(M) − 1 ms`, `monthStartUtc(M)` e `+ 1 ms`;
    - para cada instante, estar em `[monthStartUtc(M), monthStartUtc(nextYearMonth(M)))` equivale a `dateToMonthYear(iso) === chave(M)`.
  - Em `balances-months.test.ts`, com `api` e `makeToken`:
    - `'devolve só os meses pedidos'`: lançamentos à vista em 2026-08-15 e 2026-12-15 e um 3x a partir de 2026-10-15; com `from=2026-10&to=2026-11`, as chaves de `months` são exatamente `OUT/26` e `NOV/26`, o `firstMonth` é `'2026-08'` e o `lastMonth` é `'2026-12'`;
    - `'lastMonth conta as parcelas'`: um 10x a partir de 2026-11 dá `lastMonth` `'2027-08'`;
    - `'usuário sem lançamentos'`: `{ months: {}, firstMonth: null, lastMonth: null }`;
    - `'não mistura usuários'`: os dados de outro usuário não aparecem nem contam para o intervalo;
    - `'valida from e to'`: sem `to`, `from=2026-13` ou `from` depois de `to` dão 400 com `ValidationError`;
    - `'resposta segue o spec'`: `expectMatchesSpec(res, 'get', '/balances/months')`.
- [ ] **Step 2: Rodar e ver falhar.** `npm test -- months` falha: a rota responde 404, e o `monthRange` não existe.
- [ ] **Step 3: Implementar** as interfaces acima e documentar a rota no `openapi.ts`. O `docs.test.ts` confere que toda rota está no spec.
- [ ] **Step 4: Rodar e ver passar.** `npm test`, `npm run typecheck` e `npm run lint` passam.
- [ ] **Step 5: Medir a janela.** Em `get-balances.perf.ts`, meça também `GET /balances/months?from=2026-08&to=2027-02` por volume, com `medirRota`. Esperado no `extremo`: mediana < 200 ms e no máximo 100 KB na rede.
- [ ] **Step 6: Revisar.** Rode o agente `revisor-financeiro`, por causa dos meses e do fuso.
- [ ] **Step 7: Atualizar o doc.** Em `docs/lancamentos.md` da API, registre a rota, o formato, `firstMonth`/`lastMonth` e a regra de fuso.
- [ ] **Step 8: Parar para revisão e fazer o commit na API.** `feat: rota de lançamentos por intervalo de meses`.

### Task J2: Repositório do app busca por intervalo

**Files:**
- Create: `lib/models/months_window.dart`
- Modify: `lib/commons/months.dart`, `lib/repository/balance.dart`, `test/fakes.dart`, `test/repository/balance_test.dart`, `test/commons/months_test.dart`, `integration_test/volume_perf_test.dart`, `docs/dados-e-api.md`

**Interfaces:**
- `String yearMonth(DateTime month)` (`'2026-11'`) e `DateTime parseYearMonth(String value)` (dia 1), em `lib/commons/months.dart`.
- `class MonthsWindowModel { final MonthBalanceModel months; final DateTime? firstMonth; final DateTime? lastMonth; factory MonthsWindowModel.fromMap(Map<String, dynamic> map); }`.
- `BalanceRepository.getMonths(DateTime from, DateTime to): Future<MonthsWindowModel>`, que chama `GET /balances/months` com os params `from` e `to` no formato `yearMonth`.
- `FakeBalanceRepository.getMonths`:
  - corta `data` pelos meses do intervalo, comparando as chaves com `monthKey`;
  - calcula `firstMonth` e `lastMonth` pelas chaves que existem em `data`;
  - registra cada chamada em `monthCalls`, no formato `'2026-08..2027-02'`;
  - aceita `error`, `segurarBuscas` e `buscasPendentes` (`List<Completer<MonthsWindowModel>>`).
- `_AdapterDeVolume` (Task 3) passa a servir também `GET /balances/months`: lê `from` e `to` da query, corta o `historico`, calcula `firstMonth`/`lastMonth`, codifica e conta em `gets`.

- [ ] **Step 1: Escrever os testes que falham.**
  - `'yearMonth e parseYearMonth'`: `yearMonth(DateTime(2026, 2, 28)) == '2026-02'` e `parseYearMonth('2026-02') == DateTime(2026, 2, 1)`.
  - `'getMonths chama a rota com from e to'`: com o `FakeHttpAdapter`, o path é `/balances/months` e os params são `from=2026-08` e `to=2027-02`.
  - `'getMonths lê os meses e o intervalo'`: dá `firstMonth == DateTime(2021, 12)` e `lastMonth == DateTime(2027, 8)`, e os dois ficam nulos quando a API manda `null`.
- [ ] **Step 2: Rodar e ver falhar** (falha de compilação).
- [ ] **Step 3: Implementar** as interfaces, inclusive o fake e o adaptador.
- [ ] **Step 4: Rodar e ver passar.** `flutter test` e `flutter analyze` passam.
- [ ] **Step 5: Revisar.** Rode o agente `contrato-app-api`, porque há rota e model novos.
- [ ] **Step 6: Atualizar o doc.** Em `docs/dados-e-api.md`, acrescente a linha de `getMonths` e o model.
- [ ] **Step 7: Parar para revisão e fazer o commit.** `feat: repositório busca lançamentos por intervalo de meses`.

### Task J3: Cache de meses

**Files:**
- Create: `lib/repository/months_cache.dart`, `test/repository/months_cache_test.dart`
- Modify: `docs/arquitetura.md` (camadas)

**Interfaces:**
- `enum MonthState { notLoaded, loading, loaded, error }`
- `class MonthsCache extends ChangeNotifier`, com construtor `MonthsCache(BalanceRepository repository, {int around = 3, int step = 3})` e:
  - `MonthState stateOf(DateTime month)`: devolve `loaded`, com lista vazia, para meses fora de `[firstMonth, lastMonth]` depois da primeira resposta;
  - `GroupBalanceModel? dataOf(DateTime month)`;
  - `bool hasMoreBefore(DateTime month)` e `bool hasMoreAfter(DateTime month)`;
  - `Future<void> openAt(DateTime month)`: critérios 1 e 3. Se o mês não estiver `loaded` nem `loading`, busca numa chamada do primeiro ao último mês que falta em `month ± around`;
  - `Future<void> arrivedAt(DateTime month)`: critério 2. Se o mês não estiver carregado, faz o mesmo que `openAt`. Senão, se o último mês do trecho contínuo `loaded`/`loading` estiver a 1 mês ou menos e houver dados depois dele, busca os `step` meses seguintes; para trás, o mesmo;
  - `Future<void> reload()`: busca numa chamada do primeiro ao último mês já pedido. Os meses continuam `loaded` com os dados antigos até a resposta chegar.
- Regras:
  - o cache é guardado por `yearMonth`;
  - cada chamada recebe uma geração, e o `reload` invalida as anteriores: resposta de geração velha é descartada, com sucesso ou erro;
  - uma janela que falha marca só os meses dela como `error`, e um `openAt` num desses meses tenta de novo;
  - `notifyListeners()` uma vez por resposta.

- [ ] **Step 1: Escrever os testes que falham** em `months_cache_test.dart`, com o `FakeBalanceRepository`:
  - `'abrir busca o mês ±3 numa chamada'`: `openAt(NOV/26)` dá `monthCalls == ['2026-08..2027-02']` e os 7 meses `loaded`.
  - `'meses fora do histórico ficam vazios sem busca'`: com dados só em 2026, depois do `openAt(NOV/26)`, `stateOf(DateTime(2020, 1)) == loaded`, `dataOf` vazio e nenhuma chamada nova.
  - `'chegar ao penúltimo mês busca os 3 seguintes'`: depois do `openAt(NOV/26)`, com `lastMonth` em 2027-08, `arrivedAt(JAN/27)` gera a chamada `'2027-03..2027-05'`.
  - `'sem mais dados depois, não busca'`: com `lastMonth` em 2027-02, `arrivedAt(JAN/27)` não gera chamada.
  - `'para trás funciona igual'`: com `firstMonth` em 2026-01, `arrivedAt(SET/26)` gera `'2026-05..2026-07'`.
  - `'toque busca só o que falta do ±3'`: com `lastMonth` em 2027-12, depois do `openAt(NOV/26)`, `openAt(DEZ/26)` não chama (DEZ/26 já está carregado), e `openAt(JUN/27)` chama `'2027-03..2027-09'`.
  - `'mês carregando não é pedido de novo'`: com `segurarBuscas`, dois `openAt(NOV/26)` dão uma chamada só.
  - `'resposta antiga que chega depois não desfaz a nova'` (vindo da Task 6): `openAt` (0) e depois `reload` (1); completar o 1 com os dados novos e depois o 0 com os velhos deixa `dataOf(NOV/26)` com os novos.
  - `'falha antiga depois da nova não marca erro'` (vindo da Task 6): o 1 dá certo e o 0 falha, e `stateOf(NOV/26)` continua `loaded`.
  - `'recarregar mantém o mês carregado'`: com `segurarBuscas`, `reload()` deixa `stateOf(NOV/26) == loaded` até a resposta; depois, os dados mudam.
  - `'recarregar pede o intervalo já carregado'`: depois de `openAt(NOV/26)` e `arrivedAt(JAN/27)`, `reload()` chama `'2026-08..2027-05'`.
  - `'erro marca só os meses da janela'`: a segunda janela falha, os meses dela ficam `error`, os outros `loaded`, e um `openAt` num deles tenta de novo.
  - `'avisa os ouvintes a cada resposta'`.
- [ ] **Step 2: Rodar e ver falhar** (falha de compilação).
- [ ] **Step 3: Implementar** o `MonthsCache` com essas regras.
- [ ] **Step 4: Rodar e ver passar.** `flutter test` e `flutter analyze` passam.
- [ ] **Step 5: Revisar.** Rode o agente `revisor-financeiro`, por causa da aritmética de meses.
- [ ] **Step 6: Atualizar o doc.** Em `docs/arquitetura.md`, registre o cache na camada de repositórios.
- [ ] **Step 7: Parar para revisão e fazer o commit.** `feat: cache de meses com busca por janela`.

### Task J4: Home com a janela de meses

**Files:**
- Modify:
  - `lib/screens/home.dart`, `lib/widgets/infiniteTabelView/infinite_tabel_view.dart` (`onTapTab`);
  - `lib/repository/balance.dart` (sai o `getBalances`), `test/fakes.dart`, `test/repository/balance_test.dart`;
  - `test/screens/home_test.dart`, `integration_test/volume_perf_test.dart` (o `conversao` passa a medir a janela);
  - `docs/home-e-lancamentos.md` (seções "Meses" e "Carregamento"), `docs/dados-e-api.md`.

**Interfaces:**
- `InfiniteTabView.onTapTab: void Function(int index)?` repassa o `TabBar.onTap`.
- `HomeScreen`:
  - cria um `MonthsCache` com o `widget.repository` e chama `openAt(mês atual)` no `initState`;
  - `onTapTab`: chama `openAt(months[index])`, a não ser que seja a aba já selecionada;
  - `onChangePage`: chama `arrivedAt(months[index])` e mantém o crescimento das abas de hoje;
  - criar, editar e excluir chamam `cache.reload()`.
- Cada página é um `ListenableBuilder(listenable: cache, ...)` que lê `stateOf(months[index])`:
  - `loaded`: o resumo e a lista de hoje;
  - `loading` ou `notLoaded`: `Center(child: AppLoad())`, igual ao do splash;
  - `error`: o cartão de erro de hoje, com o "Tentar de novo" chamando `openAt(mes)`.
- O `+` escuta o cache e fica desativado só quando `stateOf(mesSelecionado) == MonthState.error`.
- A `HomeScreen` não se reconstrói quando o cache muda: só as páginas e o `+` escutam. Os testes da Task 8, se ela tiver rodado, continuam passando.

- [ ] **Step 1: Reescrever ou criar os testes que falham** em `home_test.dart`:
  - `'busca uma vez e cada aba mostra o próprio mês'` vira `'abre com uma chamada do mês ±3 e cada aba mostra o próprio mês'`: `repo.monthCalls == ['2026-08..2027-02']`.
  - `'mostra erro com Tentar de novo'` e `'erro desativa o botão + até carregar de novo'` passam a valer por mês: a falha da primeira janela mostra o cartão e desativa o +, e o toque em "Tentar de novo" carrega e reativa.
  - `'mês carregado nunca mostra o loader'`: tocar e deslizar dentro da janela não mostra o `AppLoad` em nenhum quadro.
  - `'mês fora da janela mostra o loader do splash até chegar'`: com dados até JUN/27 e `segurarBuscas`, arraste a barra de abas até aparecer `ABR/27` e toque nele. Aparece um `AppLoad` de cor `AppColors.white` e tamanho 30; depois de completar, os dados aparecem.
  - `'recarga depois de salvar não mostra o loader'`: com `segurarBuscas`, salvar não mostra o `AppLoad` em nenhum quadro, e os dados novos aparecem ao completar.
  - `'tocar num mês vizinho carregado não busca'`: o toque em `DEZ/26` não aumenta `monthCalls`.
  - `'tocar na aba já selecionada não busca'`.
  - `'a lista de meses crescendo'` continua igual. Com o fake respondendo na hora, cada mês tocado já está carregado (pela janela, pela busca antecipada ou por estar fora do histórico), então nenhum quadro tem `AppLoad`.
- [ ] **Step 2: Rodar e ver falhar.** `flutter test test/screens/home_test.dart` falha nos testes novos e nos reescritos.
- [ ] **Step 3: Implementar.** Tire `_balances`, `_lastBalances`, `_loadFailed`, o `FutureBuilder` e o `getBalances` do repositório e do fake. A `GET /balances` continua na API, para o app antigo.
- [ ] **Step 4: Rodar e ver passar.** `flutter test` passa inteiro, inclusive `a aba de tipo se mantém…`, `cor do fundo…` e os testes da Task 8.
- [ ] **Step 5: Conferir no celular.** Rode contra a API local (`adb reverse`, com a API da J1): abrir, deslizar meses até passar da janela, tocar num mês longe e salvar um parcelado.
- [ ] **Step 6: Revisar.** Rode os agentes `contrato-app-api` e `revisor-financeiro`.
- [ ] **Step 7: Atualizar os docs.** Em "Meses" e "Carregamento", registre os critérios 1 a 5 e as decisões da seção "Sua proposta". Em `docs/dados-e-api.md`, registre que o `getBalances` saiu.
- [ ] **Step 8: Parar para revisão e fazer o commit.** `feat: home busca os lançamentos por janela de meses`.

### Task J5: Medir a janela

**Files:**
- Modify: `integration_test/volume_perf_test.dart`, `docs/testes.md`, `docs/README.md` (seção "Limitações conhecidas")

- [ ] **Step 1: Criar o fluxo `troca_mes_rede`** (informativo), com `atrasoGet = 300 ms`: 20 arremessos para o passado a partir de NOV/26. Em cada espera de 700 ms, avance de 16 em 16 ms e registre se algum quadro teve `AppLoad`. Grave `reportData['meses_com_loader'][<volume>]`, que é quantos dos 20 meses mostraram o loader.
- [ ] **Step 2: Rodar o drive 3 vezes**, depois de avisar o usuário, e gerar o resumo. Esperado:
  - `extremo_abrir` com pior quadro < 16 ms;
  - os outros fluxos do `pesado` sem piorar em relação à linha de base;
  - `meses_com_loader` registrado.
- [ ] **Step 3: Medir a API.** `npm run perf`, com a rota de janela no `extremo` aprovada (mediana < 200 ms e até 100 KB).
- [ ] **Step 4: Registrar os números.** Em `docs/testes.md`, coloque os números com a janela e o `meses_com_loader`. Em `docs/README.md`, registre que, com a rede lenta e a navegação rápida, o loader aparece nos meses que ainda não chegaram.
- [ ] **Step 5: Parar e mostrar ao usuário** os números. Se o `meses_com_loader` o incomodar, a opção é buscar antes do penúltimo mês (`step` ou gatilho a 2 meses), o que pede um ajuste no critério 2.
- [ ] **Step 6: Fazer o commit.** `test: medição da busca por janela de meses`.

---

### Task 12: Medição final e documentação

- [ ] **Step 1: Rodar as verificações.**
  - No app: `flutter test`, `flutter analyze` e `dart format --output=none --set-exit-if-changed lib test integration_test tool`.
  - Na API: `npm test`, `npm run typecheck` e `npm run lint`. Tudo passa.
- [ ] **Step 2: Medir de novo com volume**, depois de avisar o usuário. Rode o drive 3 vezes, gere o resumo e grave uma tabela "Depois" em `docs/testes.md`. Esperado: todas as linhas do `pesado` com `✅`, ou com o motivo das que ficaram.
- [ ] **Step 3: Conferir as animações.** Rode `integration_test/animacoes_perf_test.dart` com o driver antigo (`test_driver/integration_test.dart`) e compare com a tabela de depois das mudanças de animação em `docs/testes.md`. Nenhum p99 pode ficar mais de 20% acima; se ficar, rode mais 2 vezes e use a mediana.
- [ ] **Step 4: Medir a API de novo.** Rode `npm run perf` e grave os números "Depois" no `docs/testes.md` da API.
- [ ] **Step 5: Registrar os limites.** Se o `extremo` revelar algum limite, registre em `docs/README.md`, na seção "Limitações conhecidas".
- [ ] **Step 6: Entregar o celular ao usuário.** Ele faz o login (toca no seletor de conta) e confere no celular, com a API local: abrir, trocar de mês e salvar.
- [ ] **Step 7: Parar para revisão e fazer o commit.** `docs: desempenho depois das mudanças com histórico grande`. Push, PRs e deploy só quando o usuário pedir; com a janela, a API vai antes do app.

## Fora deste plano

- **Filtrar por data no próprio Mongo**, com índices em `date` e em `listInstallments.date`. A rota da janela ainda lê do Mongo todos os documentos do usuário, embora agrupe só a janela. Só vale reabrir se a mediana da rota de janela no `extremo` chegar a 200 ms. Exigiria conferir, no banco real e com dry-run (passo do usuário), se todas as datas estão em ISO UTC.
- **Agrupamento da `GET /balances` antiga** (`reduce` com spread): leva uns 40 ms no `pesado`. Só vale reabrir se a janela não entrar e a mediana do `pesado` chegar a 200 ms. Nesse caso, comece por `node --cpu-prof`: o `format` do date-fns com fuso, chamado em cada item, deve pesar mais que o spread.
- Cache em disco, `TabBarView` virtual (com índice por builder) e paginação dentro do mês.

## Verificação

- **Ferramentas de medição** (Tasks 1 a 4): `flutter test` passa com os testes novos de `volumes` e `perf_resumo`. O drive com `--dart-define=VOLUMES=leve` gera o `build/perf/volume_*.json`, e `dart run tool/perf_resumo.dart` imprime a tabela. Na API, `npm run perf` imprime as linhas por volume e `npm test` continua igual.
- **Decisão** (Task 5): as tabelas da linha de base estão nos dois `docs/testes.md`, e a decisão da janela está registrada. O usuário aprovou a ordem de execução.
- **Cada mudança** (Tasks 6 a 11 e J1 a J4): o teste novo falha antes e passa depois, `flutter test` ou `npm test` passa inteiro, e uma rodada do drive mostra a melhora no fluxo do gatilho.
- **Janela** (J5): o `extremo` aprovado em `abrir`, rede e API; o `meses_com_loader` mostrado ao usuário; e o uso real conferido no celular contra a API local.
- **Final** (Task 12): 3 rodadas com volume e o `pesado` aprovado; `animacoes_perf_test.dart` dentro de 20% da linha de base; os testes de "mês carregado nunca mostra o loader" passando; e o uso no celular conferido pelo usuário.

## Execução

Recomendo que eu execute tudo nesta sessão (superpowers:executing-plans), tarefa por tarefa, parando antes de cada commit. Os drives no celular precisam de mim aqui para avisar você, achar a porta do ADB e esperar o seu toque no seletor de conta. As tarefas dependem umas das outras em sequência, e agentes separados custariam mais sem ganho real. Ao final, um revisor confere a branch inteira.
