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
| `screens/login_test.dart` | Erro no login e cancelamento |
| `screens/home_test.dart` | Busca única, erro com "Tentar de novo", salvar, Sair, exclusão (só a parcela, todas, cancelar, falha) e edição (valor total, realizado por parcela, nome) |
| `widget_test.dart` | `AppButton` |

## Padrões

- **TDD:** o teste vem antes e precisa falhar pelo motivo certo.
- **Dependências injetadas:** a `HomeScreen` recebe `repository`, `clock` (data fixa) e `onLogout`; a `LoginScreen` recebe `signIn`. Os testes usam esses parâmetros em vez de Firebase e rede.
- **`AppLoad` tem animação infinita:** enquanto ele estiver na tela, use `pump()`. O `pumpAndSettle()` estoura o tempo esperando a animação acabar.
- **Localizações:** os testes de widget montam o `MaterialApp` com `GlobalMaterialLocalizations` e `FormBuilderLocalizations`, como o app.

## CI

`.github/workflows/ci.yml` roda em cada pull request e em push na `main`, com Flutter 3.50.1: `flutter pub get`, checagem do `dart format`, `flutter analyze` e `flutter test`.
