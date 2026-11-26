# Dados e API

## Models (`lib/models/`)

**`BalanceModel`:** um lançamento à vista ou uma parcela, como vem do `GET /balances`.

| Campo | Observação |
|---|---|
| `id` | Id do lançamento na API (o mesmo em todas as parcelas) |
| `name`, `type` | `type` é `gains` ou `expenses` |
| `value` | Valor da parcela (ou do lançamento à vista) |
| `totalValue` | Valor do lançamento inteiro; usado no formulário de edição |
| `installment`, `totalInstallments` | Parcela atual e total |
| `realized` | Se já aconteceu |
| `date`, `createdAt`, `updatedAt` | Datas |
| `isInstallmented` | `totalInstallments > 1` |

- `fromMap` lê o JSON da API.
- `toApiMap()` gera o corpo do `POST /balances`: `installment: 1` e a data em ISO UTC.

**`GroupBalanceModel`:** `gains` e `expenses` de um mês. **`MonthBalanceModel`:** o mapa `"NOV/26"` → `GroupBalanceModel`, no mesmo formato da resposta do `GET /balances`.

## Repositório (`lib/repository/balance.dart`)

| Método | Rota da API |
|---|---|
| `getBalances()` | `GET /balances` |
| `createBalance(balance)` | `POST /balances` |
| `updateBalance(id, fields)` | `PATCH /balances/:id` |
| `setInstallmentRealized(id, n, realized)` | `PATCH /balances/:id/installments/:n` |
| `deleteBalance(id)` | `DELETE /balances/:id` |
| `deleteInstallment(id, n)` | `DELETE /balances/:id/installments/:n` |

O contrato completo de cada rota (campos, regras e erros) está no Swagger da API, em `/docs`.

## Erros

Uma resposta fora de 2xx vira `ApiException(status, message)`:

- **409** → "Você já tem um lançamento com esse nome.";
- se a API mandou `message`, ela é usada (as mensagens da API são em pt-BR);
- sem resposta → "Não foi possível falar com o servidor.".

O formulário mostra essa mensagem dentro do modal. A exclusão pela lista mostra sempre "Não foi possível excluir", numa SnackBar.

## Cliente HTTP (`lib/network/`)

- **`api_config.dart`:** `apiUrl` vem de `--dart-define=API_URL=...`. O padrão é `http://127.0.0.1:8080`, que funciona no celular e no emulador com `adb reverse tcp:8080 tcp:8080`.
- **`http_client.dart`:** `DioFactory` cria o Dio com a URL e timeouts de 20 s. O `HttpClient` expõe `get`, `post`, `put`, `patch` e `delete` com `ClientRequest(url, body, headers, params)` e devolve `ClientResponse`; um erro HTTP é **lançado** como `ClientResponse`, que o repositório converte em `ApiException`.
- **`auth_interceptor.dart`:** o token e a renovação; veja [Autenticação e sessão](autenticacao-e-sessao.md).
