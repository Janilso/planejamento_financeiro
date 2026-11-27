# Testes

```sh
flutter test
flutter analyze
dart format --output=none --set-exit-if-changed lib test
```

`flutter_test` com **dublês escritos à mão**, sem libs de mock.

## Dublês (`test/fakes.dart`)

| Dublê | Substitui | Para quê |
|---|---|---|
| `FakeBalanceRepository` | `BalanceRepository` | Devolve dados programados (`data`), falha quando pedido (`error`, `saveError`) e registra as chamadas (`getCalls`, `createCalls`, `calls`) |
| `balanceJson(...)` | — | Monta um item no formato do `GET /balances` (com `id`, parcela, `totalValue` etc.) |
| `FakeHttpAdapter` + `FakeResponse` | O adaptador HTTP do Dio | Registra as requisições e devolve respostas programadas, sem rede |
| `InMemoryTokenStorage` | `SecureTokenStorage` | Tokens em memória |

`test/helpers.dart` tem o `setUpPtBr()`, que inicializa datas e moeda em pt-BR (`setUpAll(setUpPtBr)`).

## O que cada arquivo cobre

| Arquivo | Cobre |
|---|---|
| `commons/formats_test.dart` | Conversão de "R$ 1.234,56" para número |
| `commons/months_test.dart` | Meses sem repetir nem pular, `dateForNewBalance`, `monthKey` |
| `models/balance_test.dart` | `isInstallmented` |
| `network/http_client_test.dart` | Headers, params, `patch`, `responseType` e erro em bytes de volta como JSON |
| `repository/auth_test.dart` | Login, `Bearer`, renovação, dois 401 simultâneos com um refresh só, sessão expirada |
| `repository/session_test.dart` | `hasSession` |
| `repository/balance_test.dart` | Formato da API, `parseBalances`, mensagem de erro do `getBalances`, corpo do `POST`, rota da parcela, 409 |
| `screens/login_test.dart` | Erro no login (acima do botão), cancelamento e botão em 320 dp |
| `screens/home_test.dart` | Busca única, erro com "Tentar de novo", salvar, Sair, exclusão (só a parcela, todas, cancelar, falha), edição (valor total, realizado por parcela, nome), reconstruções da home e recargas fora de ordem |
| `widget_test.dart` | `AppButton`, inclusive com ícone em 320 dp |
| `theme/tokens_test.dart` | Contrastes, a exceção de 3:1 da marca e as escalas de espaçamento e raio |
| `theme/theme_test.dart` | Escala de texto, `ColorScheme` e temas de diálogo, campos, SnackBar e modal |
| `widgets/balance_test.dart` | Subtítulo, ícone de status, valor e toque do item |
| `widgets/balance_resume_test.dart` | "Falta receber/pagar", balanço negativo e valores enormes |
| `widgets/balance_tab_view_test.dart` | Mês vazio, espaço para o +, arraste e abas de 48 dp |
| `widgets/delete_dialog_test.dart` | Opções, textos, cor de perigo e acessibilidade do diálogo de excluir |
| `widgets/form_balance_test.dart` | Título, estilo único dos valores, contador, Excluir pela edição e acessibilidade |
| `volumes_test.dart` | Os históricos sintéticos (`test/volumes.dart`): contagem de itens, meses, ids, datas às 15:00Z e determinismo |
| `tool/perf_resumo_test.dart` | O resumo das medições de desempenho (`tool/perf_resumo.dart`): mediana das rodadas e os vereditos aprovado, reprovado, limite e já existe |

## Padrões

- **TDD:** o teste vem antes e precisa falhar pelo motivo certo.
- **Dependências injetadas:** a `HomeScreen` recebe `repository`, `clock` (data fixa) e `onLogout`; a `LoginScreen` recebe `signIn`. Os testes usam esses parâmetros em vez de Firebase e rede.
- **`AppLoad` tem animação infinita:** enquanto ele estiver na tela, use `pump()`. O `pumpAndSettle()` estoura o tempo esperando a animação acabar.
- **Localizações:** os testes de widget montam o `MaterialApp` com `GlobalMaterialLocalizations` e `FormBuilderLocalizations`, como o app.

## Desempenho das animações (profile)

`integration_test/animacoes_perf_test.dart` mede os quadros da home no **celular**, em modo profile, com o dublê do repositório (sem login nem rede). Cada fluxo usa `binding.watchPerformance`: troca de mês (deslizar sobre o resumo), troca GANHOS/GASTOS (deslizar no espaço vazio da lista) e abrir/fechar o modal. Não roda no `flutter test` nem no CI.

```sh
flutter drive --profile --no-dds -d <celular> \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/animacoes_perf_test.dart
```

- O resultado fica em `build/integration_response_data.json`: média, p90, p99 e pior quadro de build e raster, e a contagem de quadros perdidos de cada fluxo.
- **`--no-dds` é obrigatório.** Sem ele o teste falha com "Failed to connect to VM Service".
- **O `flutter drive` reinstala o app e apaga a sessão guardada:** depois dele o app abre no login e é preciso tocar no seletor de conta do Google.
- O contador de "quadros perdidos" usa 16 ms fixos. No celular de 120 Hz o orçamento é 8,3 ms, então compare o p90 e o p99.
- O teclado do sistema não entra na medição do modal.

Linha de base de 2026-11-27 (Android a 120 Hz, valores em ms; antes das mudanças de animação):

| Fluxo | Quadros | Build média / p90 / p99 / pior | Raster média / p90 / p99 / pior |
|---|---|---|---|
| Troca de mês | 642 | 0,76 / 1,32 / 4,68 / 6,35 | 1,06 / 1,42 / 1,92 / 4,13 |
| GANHOS/GASTOS | 480 | 1,11 / 2,03 / 9,93 / 18,21 | 2,48 / 3,12 / 4,01 / 8,10 |
| Modal abrir/fechar | 535 | 1,34 / 2,12 / 5,48 / 11,92 | 2,21 / 2,60 / 2,86 / 17,29 |

Depois das mudanças de animação (mola padrão, páginas sem loader, cor animada e linha de erro reservada), a mesma bateria deu números equivalentes: p99 de build de 4,75 / 8,16 / 5,24 ms e p99 de raster de 2,05 / 3,96 / 3,11 ms nos três fluxos. Uma rodada por fluxo: diferenças de média dessa ordem são ruído.

## Desempenho com volume (profile)

`integration_test/volume_perf_test.dart` mede a home com histórico grande, no **celular**, em profile. Diferente do teste das animações, os dados passam pelo `BalanceRepository` e pelo `HttpClient` de verdade, sobre um adaptador do Dio que serve o JSON sintético com `content-length` (como a API sem gzip): é o único jeito de incluir a decisão do Dio de decodificar fora da thread principal (acima de 50 KB) e o `fromMap` na thread principal. Não roda no `flutter test` nem no CI.

```sh
flutter drive --profile --no-dds -d <celular> \
  --driver=test_driver/perf_driver.dart \
  --target=integration_test/volume_perf_test.dart \
  [--dart-define=VOLUMES=leve,pesado,extremo]
dart run tool/perf_resumo.dart   # tabela com as 3 rodadas mais recentes
```

Cada rodada grava `build/perf/volume_<carimbo>.json`. Rode 3 vezes e deixe o `tool/perf_resumo.dart` tirar a mediana e aplicar os critérios. O `drive` apaga a sessão do app (como no teste das animações): depois dele, é preciso entrar de novo com a conta Google.

**Volumes** (`test/volumes.dart`, determinísticos; datas às 15:00Z, até o dia 28):

| Volume | Meses | Lançamentos por mês | Itens no `GET` |
|---|---|---|---|
| `leve` | 12 | 15 | 504 |
| `pesado` | 60 (o mês atual com 150) | 20 | 3.724 |
| `extremo` | 120 | 25 | 8.400 |

Um em cada cinco lançamentos é parcelado em 10x, com as parcelas nos meses seguintes. O teste roda primeiro um aquecimento sem relatório e deixa o `extremo` por último.

**Fluxos e critérios** (mediana de 3 rodadas, no `pesado`):

| Fluxo | O que mede | Critério |
|---|---|---|
| `abrir` | os dados chegam com o loader na tela | pior quadro de build e raster < 16 ms |
| `troca_mes_perto` | 21 arremessos para o passado (25 a 49 abas) | p99 < 8,3 ms e pior quadro < 16 ms |
| `troca_mes_longe` | mais 39 arremessos (até 85 abas) | igual |
| `troca_tipo` | 6 toques alternados em GASTOS e GANHOS | p99 < 8,3 ms |
| `rolar_lista` | 3 arremessos para baixo e 3 para cima na lista de GASTOS | p99 < 8,3 ms |
| `salvar` | do toque em Salvar até a recarga assentar | pior quadro < 16 ms |

O `tool/perf_resumo.dart` classifica cada fluxo do `pesado`: `reprovado` (falha e fica pelo menos 20% pior que o `leve`), `limite` (falha, mas perto do `leve`), `já existe` (o `leve` também falha) ou `✅`. O `extremo` só usa o critério absoluto. Além dos quadros, o relatório traz `abrir_ms` (do GET liberado até o resumo aparecer) e `conversao` (`decode_ms` e `fromMap_ms`, na thread principal, de cada volume).

### Linha de base com volume (2026-11-27)

Android a 120 Hz, profile, mediana de 3 rodadas, valores em ms (`tool/perf_resumo.dart`):

| Volume | Fluxo | p99 build | p99 raster | Pior build | Pior raster | Resultado |
|---|---|---|---|---|---|---|
| leve | abrir | 13,02 | 1,20 | 13,02 | 1,20 | — |
| leve | troca_mes_perto | 14,18 | 4,45 | 33,95 | 6,34 | — |
| leve | troca_mes_longe | 9,39 | 3,68 | 27,63 | 12,83 | — |
| leve | troca_tipo | 10,13 | 3,55 | 12,19 | 4,85 | — |
| leve | rolar_lista | 3,31 | 4,41 | 3,77 | 8,37 | — |
| leve | salvar | 6,65 | 4,12 | 7,76 | 4,25 | — |
| pesado | abrir | 4,78 | 3,23 | 6,70 | 3,24 | ✅ |
| pesado | troca_mes_perto | 11,83 | 3,84 | 30,40 | 4,88 | já existe |
| pesado | troca_mes_longe | 12,61 | 4,02 | 34,88 | 5,03 | já existe |
| pesado | troca_tipo | 10,07 | 3,98 | 15,14 | 4,63 | já existe |
| pesado | rolar_lista | 3,57 | 3,77 | 12,31 | 12,00 | ✅ |
| pesado | salvar | 5,16 | 3,88 | 8,20 | 3,92 | ✅ |
| extremo | abrir | 1,16 | 2,86 | 7,72 | 3,04 | ✅ |
| extremo | troca_mes_perto | 14,60 | 4,00 | 33,30 | 4,90 | ❌ |
| extremo | troca_mes_longe | 12,97 | 3,97 | 35,61 | 5,08 | ❌ |
| extremo | troca_tipo | 10,14 | 3,86 | 12,14 | 4,13 | ❌ |
| extremo | rolar_lista | 3,58 | 4,13 | 8,43 | 11,28 | ✅ |
| extremo | salvar | 6,45 | 3,38 | 11,36 | 3,66 | ✅ |

| Volume | `abrir_ms` (GET liberado até o resumo) | Decodificar o JSON | `fromMap` (thread principal) |
|---|---|---|---|
| leve | 23 | 1,39 | 1,82 |
| pesado | 49 | 9,39 | 10,05 |
| extremo | 95 | 21,27 | 22,32 |

- **Os problemas de troca de mês e de tipo não dependem do volume:** o `leve` (poucos itens) tem os mesmos números do `pesado` e do `extremo`. Os piores quadros de 30 a 35 ms na troca de mês coincidem com a lista de abas crescendo (a cada 12 meses, a home inteira é reconstruída e o `TabController` é recriado).
- **O `fromMap` bloqueia a thread principal por 10 ms no `pesado` e 22 ms no `extremo`.** Os quadros de `abrir` e `salvar` não mostram isso, porque o `FrameTiming` mede o `build` de cada quadro, não o intervalo perdido enquanto a thread está ocupada. Use a tabela de conversão.
- O `troca_tipo` no `leve` (p99 10,13) está acima da linha de base antiga das animações (8,16): o `leve` já tem 504 itens e as 25 abas de mês, e a home inteira é reconstruída a cada troca de tipo.

## CI

`.github/workflows/ci.yml` roda em cada pull request e em push na `main`, com Flutter 3.50.1: `flutter pub get`, checagem do `dart format`, `flutter analyze` e `flutter test`.
