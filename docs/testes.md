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
| `network/http_client_test.dart` | Headers, params e `patch` |
| `repository/auth_test.dart` | Login, `Bearer`, renovação, dois 401 simultâneos com um refresh só, sessão expirada |
| `repository/session_test.dart` | `hasSession` |
| `repository/balance_test.dart` | Formato da API, corpo do `POST`, rota da parcela, 409 |
| `screens/login_test.dart` | Erro no login (acima do botão), cancelamento e botão em 320 dp |
| `screens/home_test.dart` | Busca única, erro com "Tentar de novo", salvar, Sair, exclusão (só a parcela, todas, cancelar, falha) e edição (valor total, realizado por parcela, nome) |
| `widget_test.dart` | `AppButton`, inclusive com ícone em 320 dp |
| `theme/tokens_test.dart` | Contrastes, a exceção de 3:1 da marca e as escalas de espaçamento e raio |
| `theme/theme_test.dart` | Escala de texto, `ColorScheme` e temas de diálogo, campos, SnackBar e modal |
| `widgets/balance_test.dart` | Subtítulo, ícone de status, valor e toque do item |
| `widgets/balance_resume_test.dart` | "Falta receber/pagar", balanço negativo e valores enormes |
| `widgets/balance_tab_view_test.dart` | Mês vazio, espaço para o +, arraste e abas de 48 dp |
| `widgets/delete_dialog_test.dart` | Opções, textos, cor de perigo e acessibilidade do diálogo de excluir |
| `widgets/form_balance_test.dart` | Título, estilo único dos valores, contador, Excluir pela edição e acessibilidade |

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

## CI

`.github/workflows/ci.yml` roda em cada pull request e em push na `main`, com Flutter 3.50.1: `flutter pub get`, checagem do `dart format`, `flutter analyze` e `flutter test`.
