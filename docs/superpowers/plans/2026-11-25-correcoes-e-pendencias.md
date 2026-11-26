# Plano: correções e pendências do app e da API (Planejamento Financeiro)

> **Para agentes:** SUB-SKILL OBRIGATÓRIA: use superpowers:executing-plans para implementar este plano tarefa por tarefa, **pausando antes de cada commit para o usuário revisar o código**. A pausa é pedido do usuário e prevalece sobre a regra de execução contínua da skill. Os passos usam checkbox (`- [ ]`) para acompanhamento.

## Contexto

O app Flutter (gastos mês a mês) e a API Node foram analisados em `docs/funcionamento-app-e-api.md`, no repositório do app. O arquivo ainda não está versionado. A análise mostrou:

- bugs no app que corrompem dados: valor ×100 e meses repetidos;
- um app que ainda não fala com a API;
- uma API sem editar e excluir;
- uma lista de pendências de segurança e operação.

Uma varredura nova encontrou mais problemas.

**No app:**
- falta a permissão `INTERNET` no manifesto principal;
- "Salvar" não fecha o modal nem atualiza a lista;
- a sessão não persiste e não existe "Sair";
- 12 arquivos estão fora do `dart format`.

**Na API:**
- JSON malformado no corpo responde 500;
- uma rota inexistente devolve HTML;
- as variáveis de ambiente não são validadas;
- não há README nem `.env.example`;
- o refresh token fica salvo em texto puro;
- o `getById` não é usado.

Este plano corrige tudo isso, liga o app à API e acrescenta o extra escolhido: o setup do Claude Code.

**Objetivo:** deixar os dois projetos corretos, integrados e com testes cobrindo cada correção.

**Arquitetura:**
- **A API vem primeiro:** primeiro as correções, depois o contrato que o app consome (autenticação, editar e excluir).
- **O app em duas frentes:** as correções do app (fase B1) não dependem da API e podem correr em paralelo. Já a integração (fase B2) consome o contrato das tasks A4 e A5.
- **TDD em todas as tasks:**
  - na API, Vitest + supertest + MongoDB em memória, a suíte que já existe;
  - no app, `flutter_test` com dublês escritos à mão (repositório falso, adaptador falso do Dio, armazenamento em memória), sem libs novas de teste.

**Stack:**
- **API:** Node 24, TypeScript 6.0, Express 5.3, Mongoose 9.13, zod 4.6 e Vitest 5.1.
- **App:** Flutter 3.50.1 (Dart 3.14), Dio 5, `flutter_form_builder` 11 e Firebase Auth 7.

**Spec:**
- `docs/funcionamento-app-e-api.md` (repositório do app), principalmente as seções 2.7, 3.8, 4.2 e 5;
- os achados novos listados acima;
- as decisões abaixo.

## Decisões

**Tomadas com o usuário em 25/11/2026:**

1. **Editar um parcelado:** nome, valor (total), tipo, número de parcelas e data valem para o lançamento inteiro. O "realizado" é **por parcela**.
2. **Excluir um parcelado:** o app pergunta "só esta parcela" ou "todas as parcelas". Lançamento à vista só confirma.
3. **Sessão:** a splash vai direto para a home se houver sessão do Firebase **e** tokens da API. Existe um botão **Sair**, que limpa a sessão do Firebase, do Google e os tokens, e revoga o refresh na API.
4. **Extra incluído:** setup do Claude Code. **Ficam de fora:** IA, publicação na Play Store e gráficos/lembretes.
5. **Teto de parcelas:** 30 na API, igual ao que o app já oferece (1 a 30).
6. **Teste no celular:** as telas são validadas no aparelho do usuário (ADB sem fio em `192.168.15.21:45721`), na pausa de revisão de cada task do app.

**Decisões técnicas (minhas; o custo se estiverem erradas está ao lado):**

- **Valores:** continuam em reais com 2 casas, sem mudar para centavos inteiros. O mínimo passa a ser R$ 0,01, e as parcelas são divididas em centavos, com o resto na última. *Custo:* nenhum dado existente muda.
- **Editar a série reconstrói todas as parcelas.** Se a edição mexer em valor, número de parcelas ou data, as parcelas são geradas de novo, mantendo o "realizado" pelo número da parcela. Uma parcela excluída sozinha volta a existir nesse caso. *Custo:* comportamento que pode surpreender, por isso fica registrado no README.
- **Autorização:** a API aceita `Authorization: Bearer <token>` e também o token cru, para ser retrocompatível. O app manda `Bearer`.
- **Status de login e refresh:** passam de 201 para 200 antes da integração, porque o app ainda não consome a API. *Custo:* nenhum cliente quebra.
- **Fuso fixo** `America/Sao_Paulo` para a chave do mês e para as parcelas (`@date-fns/tz`). Os testes rodam com `TZ=UTC`, para o fuso da máquina não esconder bug.

## Restrições globais

**Ciclo de toda task:**
1. escrever os testes listados;
2. rodar e ver o RED pelo motivo indicado;
3. implementar o mínimo;
4. rodar a suíte inteira (GREEN);
5. passar no gate;
6. **pausar para revisão, antes de qualquer commit:**
   - deixar as mudanças sem commit no working tree, visíveis no Source Control do VS Code;
   - mostrar ao usuário os arquivos alterados (`git status` e `git diff --stat`), os testes novos e o resultado do gate;
   - **nas tasks do app (B0 a B13):** instalar a build no celular, abrir a tela afetada, tirar um print, conferir o print e passar o caminho dele ao usuário, que segue o roteiro **No celular** da task;
   - esperar o OK explícito;
7. se o usuário pedir ajustes, aplicar, rodar a suíte e o gate de novo e pausar outra vez;
8. com o OK, fazer o commit (ou os commits) da task e só então seguir para a próxima.

Teste de caracterização ou de guarda (marcado assim) pode passar de primeira.

**Gates:**
- **API:**
  - `npm test`
  - `npm run typecheck`
  - `npm run lint`
  - `npm run build`
  - `npx prettier --check 'src/**/*.ts' 'test/**/*.ts' vitest.config.mts`
  - `npm audit` com 0 vulnerabilidades
- **App:**
  - `flutter analyze` sem erros (zero issues depois da task B6)
  - `flutter test`
  - `dart format --output=none --set-exit-if-changed lib test` (a partir da task B14)

**Branches e PRs:** cada fase sai de um `origin/main` atualizado e termina num PR. O push e o PR só acontecem com o OK do usuário.

| Repositório | Branch | Tasks |
|---|---|---|
| API (`origin/main` = `6b46afe`) | `fix/api-correcoes` | A1–A5 |
| API | `chore/api-qualidade` | A6–A13 |
| App (`origin/main` = `b1f07d6`) | `fix/app-correcoes` | B0–B7 |
| App | `feat/app-integracao` | B8–B13 |
| App | `chore/app-qualidade` | B14–B15 |
| Os dois | `chore/claude-code` | C1 |

**Libs novas, exatamente estas** (versões conferidas em 25/11/2026):
- **API:**
  - `helmet@^8.3.0`
  - `express-rate-limit@^8.7.5`
  - `pino-http@^11.0.0`
  - `@date-fns/tz@^1.5.0`
- **App:** `flutter_secure_storage@^11.2.0`.
- Nenhuma lib existente é atualizada.

**Formato de erro da API:** `{ name, code, message, errors: [{ field, message }] }`. O `NameError` ganha `NotFoundError` e `RateLimitError`. Mensagens novas em pt-BR, com o texto exato deste plano, ficam em `src/utils/errorMessages.ts`.

**Atlas e chaves:**
- O agente nunca conecta no Atlas nem lê o `.env`. A migração no Atlas é passo do usuário (seção O).

**Commits:** em pt-BR, no padrão `fix:`, `feat:`, `test:`, `docs:`, `ci:`, `chore:` e `style:`.

**Testes de widget do app:** o `AppLoad` tem animação infinita. Enquanto ele estiver na tela, use `pump()`, porque o `pumpAndSettle()` estoura o tempo. Inicialize o pt-BR com o `setUpPtBr()` da task B4.

**Teste no celular** (aparelho do usuário: `24117RK2CG`, Android 16, ADB sem fio em `192.168.15.21:45721`):

- **Conexão:** `adb connect 192.168.15.21:45721`. O Android troca a porta quando a depuração sem fio é religada. Se a conexão falhar, pare e peça ao usuário o IP e a porta novos (ou o pareamento com `adb pair`).
- **API local para o celular** (a partir da B9):
  1. MongoDB local descartável: `~/.cache/mongodb-binaries/mongod-x64-zorin-8.2.6 --dbpath <scratchpad>/mongo-dev --port 27017 --bind_ip 127.0.0.1 --fork --logpath <scratchpad>/mongo-dev.log`;
  2. na API, em segundo plano: `MONGO_URI=mongodb://127.0.0.1:27017/planejamento_dev npm run dev`. Os outros valores (`GOOGLE_CLIENT_ID` e os segredos JWT) vêm do `.env` sem que o agente leia o arquivo, porque o dotenv não sobrescreve uma variável já definida;
  3. túnel do celular para a máquina: `adb -s 192.168.15.21:45721 reverse tcp:8080 tcp:8080`. Assim o app usa `API_URL=http://127.0.0.1:8080`, e a API não fica exposta na rede.
- **O celular faz o papel do emulador.** Não há emulador no plano. Para iterar com hot reload no seu terminal: `flutter run -d 192.168.15.21:45721 --dart-define=API_URL=http://127.0.0.1:8080`.
- **Instalar e capturar** (script da task B0):
  - `ADB_DEVICE=192.168.15.21:45721 tool/celular.sh instalar` (debug), ou `… instalar --release`;
  - `ADB_DEVICE=192.168.15.21:45721 tool/celular.sh print <scratchpad>/<task>.png`.
- **Login com Google:** quem toca no seletor de conta é o usuário. Se aparecer um erro de configuração (código 10 ou `DEVELOPER_ERROR`), o usuário confere no Firebase o SHA-1 do keystore de debug: `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`.

## Foco da revisão

1. **Vários 401 ao mesmo tempo.** Com o token vencido, duas requisições simultâneas devem gerar **um** refresh só, e as duas são repetidas. Teste na task B9.
2. **Excluir sem rede.** Se a API falha, o item **continua na lista** e aparece uma mensagem; ele não pode sumir. Teste na task B12.
3. **Home com a API fora do ar.** A home mostra o erro e um botão "Tentar de novo", e não fica girando para sempre. Teste na task B4.
4. **Sessão expirada no meio do uso.** Se o refresh falha, o app volta ao login com aviso, sem loop de refresh. Teste na task B9.
5. **Editar um parcelado depois de marcar parcelas.** Mudar o valor mantém o "realizado" de cada parcela. Teste na task A5.

## Ordem e dependências

```
A1 → A2 → A3 → A4 → A5  (fix/api-correcoes) ──┐
B0 → … → B7  (fix/app-correcoes, em paralelo) │
                                              ▼
                    B8 → B9 → B10 → B11 → B12 → B13 (precisa de A4 e A5)
A6 … A13 (qualidade; A11 depois de A4)    B14 → B15
C1 a qualquer momento (sugestão: primeiro, para os subagentes ajudarem)
```

---

## Parte A: API (`/home/janilso/projetos/backend/planejamento_financeiro_api`)

### Task A1: parcelas com teto, inteiras e divididas em centavos

**Arquivos:** `src/schemas/balance.schema.ts`, `src/services/balance.service.ts` (`generateListInstallments`) e os testes em `test/balances.test.ts`.

- [ ] **Testes:**

  | Nome | Requisição | Esperado |
  |---|---|---|
  | `recusa mais de 30 parcelas` | `balancePayload({ totalInstallments: 31 })` | 400 e `errors[0]` = `{ field: 'totalInstallments', message: 'Máximo de 30 parcelas.' }` (RED: 201) |
  | `recusa número de parcelas fracionado` | `{ totalInstallments: 2.5 }` e `{ installment: 1.5 }` | 400 nos dois (RED: 201) |
  | `divide em centavos e põe o resto na última parcela` | `{ name: 'TV', value: 100, totalInstallments: 3 }` | valores `[33.33, 33.33, 33.34]` (RED: 33.333…) |
  | `recusa valor abaixo de um centavo` | `{ value: 0.001 }` | 400 `Valor deve ser maior que zero` (RED: 201) |

- [ ] **Implementação:**
  - `installment: z.number().int().min(1, …)`.
  - `totalInstallments: z.number().int().min(0).max(30, 'Máximo de 30 parcelas.').optional().nullable().default(0)`.
  - `value: z.number().min(0.01, 'Valor deve ser maior que zero')`.
  - Divisão das parcelas:
    - `cents = Math.round(value * 100)`;
    - `base = Math.floor(cents / n)`;
    - as parcelas 1 a n−1 valem `base / 100`;
    - a última vale `(cents − base·(n−1)) / 100`.
- [ ] **Commit:** `fix: limita as parcelas e divide o valor em centavos`

### Task A2: erros HTTP sempre em JSON

**Arquivos:**
- `src/middlewares/errorHandler.middleware.ts`;
- `src/middlewares/notFound.middleware.ts` (novo, registrado em `src/app.ts` depois das rotas e antes do `errorHandler`);
- `src/middlewares/types.ts` e `src/utils/errorMessages.ts`, com `INVALID_JSON: 'JSON inválido'` e `ROUTE_NOT_FOUND: 'Rota não encontrada'`;
- testes em `test/errors.test.ts`.

- [ ] **Testes:**
  - `JSON malformado responde 400`:
    - requisição: `api.post('/auth/login').set('Content-Type', 'application/json').send('{"googleToken":')`;
    - esperado: `toEqual({ name: 'ValidationError', code: 400, message: 'JSON inválido', errors: [] })`;
    - RED: 500.
  - `rota inexistente responde 404 em JSON`:
    - requisição: `api.get('/nao-existe')`;
    - esperado: `toEqual({ name: 'NotFoundError', code: 404, message: 'Rota não encontrada', errors: [] })`;
    - RED: corpo HTML.
- [ ] **Implementação:** no `errorHandler`, antes do fallback 500, tratar `err.type === 'entity.parse.failed'` (erro do body-parser). O `notFoundHandler` responde com o JSON acima.
- [ ] **Commit:** `fix: responde JSON inválido com 400 e rota inexistente com 404`

### Task A3: validar as variáveis de ambiente na subida

**Arquivos:**
- `src/config/environment.config.ts`;
- `.env.example` (novo);
- `vitest.config.mts`;
- `src/services/auth.service.ts` (renomear `jwtRefrashSecretKey` → `jwtRefreshSecretKey`);
- testes em `test/environment.test.ts`.

**Interfaces:**
- Produz `loadEnvironment(env: NodeJS.ProcessEnv): Environment`, que usa um schema zod e lança `Error` listando as variáveis que faltam.
- Produz `environment = loadEnvironment(process.env)`, depois do `dotenv.config()`.
- As tasks A8 e A9 acrescentam campos a esse schema.

- [ ] **Testes:**
  - `aponta as variáveis obrigatórias que faltam`: `loadEnvironment({})` lança um erro cuja mensagem contém `MONGO_URI`, `GOOGLE_CLIENT_ID`, `JWT_SECRET_KEY` e `JWT_REFRESH_SECRET_KEY`.
  - `aplica os padrões`: o mínimo válido resulta em `port: 8080` e `nodeEnv: 'development'`; com `PORT: '3000'`, resulta em `port: 3000`.
- [ ] **Implementação:**
  - Variáveis obrigatórias: `z.string().min(1)`. Não exigir tamanho mínimo para os segredos, para não derrubar um deploy cujo `.env` tenha segredos curtos.
  - No `vitest.config.mts`, usar `MONGO_URI: 'mongodb://127.0.0.1:1/nunca-usar'` no lugar de `''`. Continua bloqueando o `.env`, e agora passa na validação.
- [ ] **Commit:** `fix: valida as variáveis de ambiente na subida`

### Task A4: contrato de autenticação para o app (e logout)

**Arquivos:**
- `src/middlewares/auth.middleware.ts`;
- `src/services/auth.service.ts`;
- `src/controllers/auth.controller.ts`;
- `src/routes/auth.route.ts`;
- os testes em `test/auth.test.ts` e `test/balances.test.ts`, que passam a esperar as novas mensagens e status.

**Interfaces** (o app consome nas tasks B9 e B10):
- `POST /auth/login` → **200** `{ token, refreshToken }`.
- `POST /auth/refresh` → **200**.
- `POST /auth/logout`, com autenticação → **204**.
- `Authorization: Bearer <token>`.

- [ ] **Testes:**

  | Nome | Esperado | RED |
  |---|---|---|
  | `aceita token com prefixo Bearer` | `GET /balances` com `Bearer <makeToken('user-a')>` → 200 | 403 |
  | `continua aceitando o token cru` | 200 | guarda |
  | `sem Authorization responde 401 AuthError` | `body.name` = `'AuthError'` | `'ValidationError'` |
  | `refresh inválido responde 401 AuthError` | `body.name` = `'AuthError'` | `'InternalServerError'` |
  | Testes atuais de login e refresh | status esperado passa de 201 para **200** | 201 |
  | `login com email_verified false responde 401` | `mockGoogle({ email, name, email_verified: false })` → 401 e `UserModel.countDocuments()` = 0 | 200 |
  | `logout revoga o refresh token` | login → `POST /auth/logout` com `Bearer` → 204 → `POST /auth/refresh` com o refresh antigo → 401 | 404 |
  | `logout sem token responde 401` | 401 | 404 |

- [ ] **Implementação:**
  - Remover `/^Bearer\s+/i` do header.
  - Login e refresh com `res.status(200)`.
  - No login, recusar `payload.email_verified === false`.
  - `AuthService.logout(userId)` faz `updateOne` do `refreshToken` para `''`.
- [ ] **Commits:**
  - `fix: ajusta o contrato de autenticação para o app`
  - `feat: adiciona POST /auth/logout`

### Task A5: editar e excluir lançamentos e parcelas

**Arquivos:**
- `src/schemas/balance.schema.ts`, com `update` (parcial de `create`, sem `installment`, com pelo menos um campo), `installmentRealized` (`{ realized: z.boolean() }`) e os params `id` e `installment` (`z.coerce.number().int().min(1)`);
- `src/middlewares/validateParams.middleware.ts` (novo). Grava o resultado em `res.locals.params`, porque o `req.params` do Express 5 não deve ser reatribuído;
- `src/services/balance.service.ts`, `src/controllers/balance.controller.ts` e `src/routes/balance.route.ts`;
- `src/utils/errorMessages.ts`, com:
  - `BALANCE_NOT_FOUND: 'Lançamento não encontrado'`
  - `INSTALLMENT_NOT_FOUND: 'Parcela não encontrada'`
  - `NOTHING_TO_UPDATE: 'Nenhum campo para atualizar'`
- testes em `test/balances-edit.test.ts`.

**Interfaces** (o app consome nas tasks B11 a B13):

| Rota | Corpo | Resposta |
|---|---|---|
| `PATCH /balances/:id` | ⊆ `{ name, value, type, totalInstallments, date, realized }` | 200, documento atualizado (`updatedAt` em ISO) |
| `PATCH /balances/:id/installments/:installment` | `{ realized }` | 200 |
| `DELETE /balances/:id` | — | 204 |
| `DELETE /balances/:id/installments/:installment` | — | 204. Se não sobrar parcela, o lançamento é removido |

- O `GET /balances` passa a devolver `totalValue` em cada item. É o valor do lançamento, que o app usa para editar parcelados.
- Erros:
  - 404 `NotFoundError` quando o lançamento não existe ou é de outro usuário;
  - 400 para id malformado (o `CastError` já existente);
  - 400 `Nenhum campo para atualizar`;
  - 409 para nome repetido.

- [ ] **Testes** (RED: todas as rotas novas respondem 404 `Rota não encontrada`):
  1. `mudar o valor de um parcelado mantém o realizado de cada parcela`:
     - Notebook 3x de 3000 → `PATCH …/installments/2 { realized: true }` → `PATCH { value: 900 }`;
     - os itens do GET ficam com valores `[300, 300, 300]` e realizado `[false, true, false]`.
  2. `de 3 para 1 parcela vira à vista`: `listInstallments` = `[]` e o GET mostra 1 item.
  3. `PATCH grava updatedAt`: string ISO.
  4. `PATCH sem campos responde 400`, com a mensagem `Nenhum campo para atualizar`.
  5. `PATCH em lançamento de outro usuário responde 404`, e o documento não muda.
  6. `PATCH com id malformado responde 400`, com `ID malformado ou tipo inválido`.
  7. `PATCH com nome já usado pelo mesmo usuário responde 409`.
  8. `marcar parcela` em casos inválidos:
     - em um lançamento à vista → 404 `Parcela não encontrada`;
     - na parcela 9 de 3 → 404;
     - com `/installments/x` → 400, `field: 'installment'`.
  9. `DELETE remove o lançamento inteiro`: 204 e o GET devolve `{}`. Se for de outro usuário → 404, e o documento continua.
  10. `DELETE de uma parcela mantém as outras`:
      - apagar a 2/3 → os itens do GET ficam com as parcelas `[1, 3]`;
      - apagar a 1 e a 3 também → `BalanceModel.countDocuments()` = 0.
  11. `GET inclui totalValue`: parcelado de 3000 → os 3 itens com `totalValue: 3000`; à vista → igual ao `value`.
- [ ] **Implementação:**
  - Todo filtro usa `{ _id: id, userId }`.
  - Reconstruir as parcelas, preservando o `realized` pelo número da parcela, quando:
    - mudar `value`, `totalInstallments` ou `date`;
    - e o novo `totalInstallments` for maior que 1.
  - Se ficar com 1 parcela ou menos, `listInstallments = []`.
  - Excluir uma parcela: `$pull` em `listInstallments`, e depois apagar o documento se a lista esvaziar.
- [ ] **Commits:**
  - `feat: adiciona edição de lançamentos e parcelas`
  - `feat: adiciona exclusão de lançamentos e parcelas`

### Task A6: mensagens de validação em português

**Arquivos:**
- `src/app.ts`: chamar `z.config(z.locales.pt())` no topo;
- `src/config/mapErrorMongo.config.ts`: para `err.kind === 'required'`, a mensagem passa a ser `Campo obrigatório.`;
- testes em `test/auth.test.ts` e `test/mapErrorMongo.test.ts`.

- [ ] **Testes:**
  - `login sem googleToken explica em português`: `errors[0].message` = `Entrada inválida: esperava um texto, recebeu um valor "undefined"`. Valor observado no zod 4.6 com o locale `pt`. RED: a mensagem em inglês.
  - No teste do `getErrorMongo`, a mensagem esperada passa a ser `Campo obrigatório.`. RED: ``Path `name` is required.``.
- [ ] **Commit:** `fix: mensagens de validação em português`

### Task A7: mês e parcelas no fuso de São Paulo

**Arquivos:**
- `package.json`, com `@date-fns/tz`;
- `src/utils/timeZone.ts` (novo): `export const APP_TIME_ZONE = 'America/Sao_Paulo'`;
- `src/utils/dateToMonthYear.ts`, com `format(d, 'MMM/yy', { locale: ptBR, in: tz(APP_TIME_ZONE) })`;
- `src/services/balance.service.ts`, com `addMonths(…, i, { in: tz(APP_TIME_ZONE) })`. Converter de volta com `new Date(x.getTime()).toISOString()`, para manter o formato `…Z`;
- `vitest.config.mts`, com `TZ: 'UTC'` em `env`;
- testes em `test/balances.test.ts`.

- [ ] **Testes:**
  - `agrupa pelo mês de São Paulo`: um lançamento à vista em `2026-03-01T02:00:00.000Z` (28/02, 23h, em São Paulo) → as chaves do GET são `['FEV/26']`. RED com `TZ=UTC`: `'MAR/26'`.
  - O teste atual das parcelas mensais continua com datas `…T12:00:00.000Z`. É guarda.
- [ ] **Commit:** `fix: calcula o mês e as parcelas no fuso de São Paulo`

### Task A8: helmet e limite de requisições

**Arquivos:**
- `package.json`, com `helmet` e `express-rate-limit`;
- `src/middlewares/rateLimit.middleware.ts` (novo): `createLimiter({ windowMs, limit })`, com resposta JSON;
- `src/app.ts`: `helmet()`; `trust proxy` quando `TRUST_PROXY > 0`; o limiter de auth em `/auth`; o limiter geral nas outras rotas;
- `src/config/environment.config.ts`:
  - `RATE_LIMIT_AUTH_MAX` (padrão 20 por 15 min);
  - `RATE_LIMIT_API_MAX` (padrão 300 por 15 min);
  - `TRUST_PROXY` (padrão 0);
- `.env.example`;
- `vitest.config.mts`, com os dois limites em `'10000'`;
- `src/utils/errorMessages.ts`, com `TOO_MANY_REQUESTS: 'Muitas requisições. Tente de novo em alguns minutos.'`;
- testes em `test/security.test.ts` e `test/rate-limit.test.ts`.

- [ ] **Testes:**
  - `envia cabeçalhos de segurança`: a resposta tem `x-content-type-options: nosniff` e não tem `x-powered-by`. RED: tem `x-powered-by`.
  - `limita tentativas de login`:
    - em `rate-limit.test.ts`, chamar `vi.stubEnv('RATE_LIMIT_AUTH_MAX', '3')` e depois `await import('../src/app')`, dentro do teste;
    - o arquivo **não pode** importar nada de `src/` no topo nem chamar `vi.resetModules()`, para não registrar os models duas vezes;
    - a 4ª chamada de `POST /auth/login {}` → 429, `toEqual({ name: 'RateLimitError', code: 429, message: 'Muitas requisições. Tente de novo em alguns minutos.', errors: [] })`.
- [ ] **Commit:** `feat: adiciona helmet e limite de requisições`

### Task A9: logs estruturados

**Arquivos:**
- `package.json`, com `pino-http`;
- `src/config/logger.config.ts` (novo): `createHttpLogger(destination?)`, com `redact: ['req.headers.authorization']` e nível vindo de `LOG_LEVEL` (padrão `info`);
- `src/app.ts`;
- `errorHandler`: troca `console.error` por `req.log.error({ err })`, só para erros 500;
- `vitest.config.mts`, com `LOG_LEVEL: 'silent'`;
- testes em `test/logger.test.ts`.

- [ ] **Teste** `não registra o token nos logs`:
  - preparação: um app Express mínimo com `createHttpLogger(stream em memória)` e uma requisição com `Authorization: segredo-123`;
  - esperado: as linhas registradas não contêm `segredo-123` e contêm `[Redacted]`;
  - RED: o módulo ainda não existe.
- [ ] **Commit:** `feat: adiciona logs estruturados`

### Task A10: migração de índices mais segura

**Arquivos:** `src/migrations/balances.migration.ts` e os testes em `test/migrations.test.ts`.

- [ ] **Testes:**
  - `detecta nomes repetidos mesmo com userId ausente ou null`:
    - preparação: `insertMany([{ name: 'Mercado' }, { userId: null, name: 'Mercado' }])`;
    - esperado: o dry-run traz `duplicates` = `[{ userId: null, name: 'Mercado', count: 2 }]` e o apply é recusado;
    - RED: `duplicates` vazio.
  - `se criar o índice novo falhar, o antigo continua`:
    - preparação: estado legado e `vi.spyOn(BalanceModel, 'createIndexes').mockRejectedValueOnce(new Error('falha simulada'))`;
    - esperado: o apply rejeita com `falha simulada`, e `indexNames()` continua `['_id_', 'name_1']`;
    - RED: o `name_1` some.
  - `CLI em dry-run não cria coleção nem índice` (guarda do Foco 1 do plano anterior):
    - preparação: `execFileSync('node_modules/.bin/tsx', ['src/migrations/run.ts'], { env: { ...process.env, MONGO_URI: inject('mongoUri') + 'cli_' + randomUUID() } })`;
    - esperado: a saída contém `Dry-run: nada foi alterado`, e `listCollections()` desse banco vem vazio.
- [ ] **Implementação:**
  - `$group` por `{ userId: { $ifNull: ['$userId', null] }, name: { $ifNull: ['$name', null] } }`.
  - No apply, `await BalanceModel.createIndexes(); await BalanceModel.cleanIndexes();`, no lugar do `syncIndexes()`.
- [ ] **Commit:** `fix: deixa a migração de índices mais segura`

### Task A11: guardar só o hash do refresh token (depois da A4)

**Arquivos:**
- `src/models/user.model.ts`: o campo passa a se chamar `refreshTokenHash`;
- `src/services/auth.service.ts`: `createHash('sha256')` de `node:crypto` ao salvar e ao buscar;
- os testes em `test/auth.test.ts`.

- [ ] **Testes:**
  - `guarda só o hash do refresh token`: depois do login, o `user.refreshTokenHash` é igual ao sha256 hex de `body.refreshToken`, e `JSON.stringify(user)` não contém o token. RED: o token aparece em texto puro.
  - Os testes de refresh e logout continuam verdes, agora comparando pelo hash.
- [ ] **Commit:** `fix: guarda só o hash do refresh token`

  Depois do deploy, todos precisam entrar de novo. Isso vai para o README (A13) e para a descrição do PR.

### Task A12: CI no GitHub Actions

**Arquivos:** `.github/workflows/ci.yml`.

- [ ] **Workflow:**
  - **Disparo:** `push` na `main` e `pull_request`, em `ubuntu-latest`.
  - **Ambiente:** `actions/checkout@v7`; `actions/setup-node@v7`, com Node 24 e `cache: npm`; `actions/cache@v6` em `~/.cache/mongodb-binaries`, com a chave `mongodb-binaries-8.2.6`.
  - **Passos:**
    1. `npm ci`
    2. `npm run typecheck`
    3. `npm run lint`
    4. prettier `--check`
    5. `npm test`
    6. `npm run build`
    7. `npm audit --audit-level=high`
- [ ] **Verificação:** depois do push autorizado, `gh run watch` deve terminar em sucesso.
- [ ] **Commit:** `ci: roda typecheck, lint, testes e build nos PRs`

### Task A13: README, package.json e código sem uso

**Arquivos:**
- `README.md` (novo);
- `package.json`: remover `"main": "index.js"` e preencher `description`;
- `src/services/balance.service.ts`: remover o `getById`, que não é usado.

- [ ] **README:**
  - o que é;
  - requisitos (Node ≥ 22);
  - configuração (`cp .env.example .env`);
  - comandos;
  - tabela de endpoints, incluindo os da A4 e da A5;
  - fuso de São Paulo;
  - `TRUST_PROXY` e limites;
  - migração (`db:migrate` em dry-run primeiro);
  - a regra de "editar a série reconstrói as parcelas";
  - o aviso de novo login depois da A11.
- [ ] **Verificação:** gate verde.
- [ ] **Commit:** `docs: adiciona README e remove código sem uso`

---

## Parte B: App (`/home/janilso/projetos/mobile/planejamento_financeiro`)

### Task B0: script para instalar e capturar a tela no celular

**Arquivos:** `tool/celular.sh` (novo, executável).

- [ ] **Script** `tool/celular.sh`:
  - exige a variável `ADB_DEVICE`, sem valor padrão (a porta muda), e para com a mensagem de uso se ela faltar;
  - `instalar [--release]`:
    1. `adb connect "$ADB_DEVICE"`;
    2. `adb -s "$ADB_DEVICE" reverse tcp:8080 tcp:8080`;
    3. `flutter build apk --debug` (ou `--release`) com `--dart-define=API_URL=${API_URL:-http://127.0.0.1:8080}`;
    4. `adb -s "$ADB_DEVICE" install -r` com o APK gerado;
    5. `adb -s "$ADB_DEVICE" shell am start -W -n br.com.janilso.planejamentofinanceiro/.MainActivity`;
  - `print <arquivo.png>`: `adb -s "$ADB_DEVICE" exec-out screencap -p > <arquivo.png>`.
- [ ] **Verificação** (é um script, então o teste é rodá-lo):
  - sem `ADB_DEVICE`, sai com código diferente de 0 e mostra o uso;
  - `ADB_DEVICE=192.168.15.21:45721 tool/celular.sh instalar` abre o app no celular;
  - `… print <scratchpad>/b0.png` gera um PNG válido com a splash ou o login (abrir a imagem para conferir).
- [ ] **No celular:** o usuário confirma que o app abriu.
- [ ] **Commit:** `chore: adiciona script para instalar o app e capturar a tela no celular`

### Task B1: valor ×100 na conversão de R$

**Arquivos:** `lib/commons/formats.dart` e os testes em `test/commons/formats_test.dart`.

- [ ] **Teste** `stringMoneyToDouble converte reais`:

  | Entrada | Esperado |
  |---|---|
  | `'R$ 15,00'` | `15.0` |
  | `'R$ 1.234,56'` | `1234.56` |
  | `'R$ 0,50'` | `0.5` |

  RED: `1500.0`.
- [ ] **Implementação:** `double.parse(value.replaceAll(RegExp(r'[^0-9,]'), '').replaceAll(',', '.'))`.
- [ ] **No celular:** sem efeito visível até a B11, quando os valores salvos aparecem na lista. O roteiro da B11 confere o R$ 15,00.
- [ ] **Commit:** `fix: converte o valor em reais sem multiplicar por 100`

### Task B2: meses sem repetição nos dias 29 a 31

**Arquivos:**
- `lib/commons/months.dart` (novo);
- `lib/screens/home.dart`: usa as funções novas, e a comparação de mês considera só ano e mês;
- testes em `test/commons/months_test.dart`.

**Interfaces** (produzidas, usadas pela B4):
- `List<DateTime> monthsAround(DateTime center, {int before = 12, int after = 12})`, sempre no dia 1;
- `List<DateTime> monthsBefore(DateTime month, int count)`;
- `List<DateTime> monthsAfter(DateTime month, int count)`;
- `DateTime dateForNewBalance(DateTime month, DateTime today)`: no mês atual, `today`; nos outros, o dia `min(today.day, último dia do mês)`;
- `String monthKey(DateTime month)`: `MMM/yy` em maiúsculas e sem ponto. Nos testes, `initializeDateFormatting('pt_BR')`.

- [ ] **Testes:**
  - `monthsAfter(DateTime(2026, 1, 31), 3)` → `[2026-02-01, 2026-03-01, 2026-04-01]`. RED: hoje sai `3/3, 31/3, 1/5`.
  - `monthsAround(DateTime(2026, 11, 25))`:
    - tem 25 meses, todos diferentes;
    - o primeiro é `2025-11-01`, o do meio é `2026-11-01` e o último é `2027-11-01`.
  - `dateForNewBalance(DateTime(2026, 2, 1), DateTime(2026, 1, 31))` → `2026-02-28`.
  - `monthKey(DateTime(2026, 5, 1))` → `'MAI/26'`.
- [ ] **No celular:** na home, passar pelos meses até o ano seguinte e voltar: nenhum mês repetido nem faltando. Opcional: mudar a data do celular para 31/01, conferir que fevereiro aparece e depois voltar para a data automática.
- [ ] **Commit:** `fix: gera os meses sem repetir nem pular nos dias 29 a 31`

### Task B3: indicação de parcela na última parcela

**Arquivos:** `lib/models/balance.dart` e os testes em `test/models/balance_test.dart`.

- [ ] **Teste** `isInstallmented depende do total de parcelas`:

  | Parcela | Esperado |
  |---|---|
  | 12 de 12 | `true` (RED: `false`) |
  | 1 de 1 | `false` |
  | 5 de 12 | `true` |

- [ ] **Implementação:** `totalInstallments > 1`.
- [ ] **No celular:** sem efeito visível até a B11. O roteiro da B11 confere a parcela 3/3.
- [ ] **Commit:** `fix: mostra a indicação de parcela também na última`

### Task B4: home com uma busca só e o mês certo em cada aba

**Arquivos:**
- `lib/screens/home.dart`. O construtor passa a ser `HomeScreen({super.key, BalanceRepository? repository, DateTime Function()? clock})`. O estado guarda um `Future<MonthBalanceModel>`, carregado no `initState` e no "Tentar de novo";
- `test/fakes.dart` (novo): `FakeBalanceRepository implements BalanceRepository`, que conta as chamadas;
- `test/helpers.dart` (novo): `setUpPtBr()`;
- testes em `test/screens/home_test.dart`.

**Interfaces** (produzidas): `FakeBalanceRepository` e a injeção de `repository` e `clock` na home.

- [ ] **Testes:**
  - `busca uma vez e cada aba mostra o próprio mês`:
    - preparação: `clock` em 25/11/2026; o falso devolve `NOV/26` com o ganho `Salário` e `DEZ/26` com o gasto `Aluguel`;
    - na abertura, `Salário` aparece;
    - tocar `DEZ/26` e depois `GASTOS` → `Aluguel` aparece;
    - `getCalls == 1`.
    - RED: várias chamadas, e a aba lê o `actualIndex`.
  - `mostra erro com Tentar de novo` (Foco 3 da revisão):
    - preparação: o falso lança um erro;
    - esperado: aparecem o texto `Não foi possível carregar os lançamentos` e o botão `Tentar de novo`; tocar no botão leva a `getCalls == 2`.
- [ ] **No celular:**
  - trocar de mês: cada aba mostra o próprio mês (a de JUL/25 tem os dados de exemplo);
  - em modo avião, abrir a home: aparecem a mensagem de erro e o botão "Tentar de novo". Sair do modo avião e tocar no botão carrega os dados.
- [ ] **Commit:** `fix: busca os lançamentos uma vez e mostra o mês certo em cada aba`

### Task B5: "Salvar" fecha o modal e atualiza a lista

**Arquivos:**
- `lib/widgets/formBalance/form_balance.dart`:
  - o `onSubmit` passa a ser `Future<void> Function(BalanceModel)`;
  - o botão mostra carregando enquanto salva;
  - em caso de sucesso, faz `Navigator.pop`;
  - em caso de erro, mostra a SnackBar `Não foi possível salvar`;
- `lib/screens/home.dart`: depois de criar ou editar, recarrega o `Future`;
- `lib/repository/balance.dart`: assinaturas `Future<void> createBalance(BalanceModel balance)` e `Future<void> updateBalance(String id, Map<String, dynamic> fields)`. O corpo continua mockado até a B11;
- `lib/models/balance.dart`: renomear `uuid` para `id`. O `fromMap` passa a ler `'id'`, e o JSON fixo do repositório troca `"uuid"` por `"id"`;
- os testes em `test/screens/home_test.dart`.

**Interfaces** (produzidas, usadas da B11 à B13): `BalanceModel.id` e as duas assinaturas acima.

- [ ] **Testes:**
  - `salvar fecha o modal e recarrega`:
    - tocar `+`, preencher nome `Mercado` e valor `R$ 50,00`, tocar `Salvar`;
    - esperado: o `FormBalance` não aparece mais, `createCalls == 1` com `value == 50.0`, e `getCalls == 2`;
    - RED: o modal continua aberto.
  - `erro ao salvar mantém o modal`: o falso lança erro → o modal continua aberto e a SnackBar aparece.
- [ ] **No celular:** tocar em +, preencher e salvar: o modal fecha. Os dados continuam de exemplo até a B11.
- [ ] **Commit:** `fix: salvar fecha o modal e atualiza a lista`

### Task B6: feedback de erro no login e fim dos `print`

**Arquivos:**
- `lib/screens/login.dart`:
  - `LoginScreen({super.key, Future<void> Function()? signIn})`, cujo padrão é o fluxo atual;
  - em caso de erro que não seja cancelamento, mostra a SnackBar `Não foi possível entrar. Tente de novo.`;
  - o `finally` passa a ser `if (mounted) setState(…)`;
- os `print` de `repository/balance.dart`, `home.dart` e `login.dart`: remover, ou trocar por `debugPrint`;
- testes em `test/screens/login_test.dart`.

- [ ] **Testes:**
  - `mostra erro quando o login falha`: o `signIn` lança `Exception('x')` → a SnackBar aparece. RED: não aparece.
  - `cancelar não mostra erro`: o `signIn` lança `GoogleSignInException` com `code: GoogleSignInExceptionCode.canceled` → nenhuma SnackBar.
- [ ] **Verificação:** `flutter analyze` → `No issues found!`.
- [ ] **No celular:** cancelar o seletor de conta não mostra mensagem. Em modo avião, tentar entrar mostra "Não foi possível entrar. Tente de novo.".
- [ ] **Commit:** `fix: mostra erro no login e remove os print`

### Task B7: permissão de internet e nome do app

**Arquivos:** `android/app/src/main/AndroidManifest.xml`.
- `<uses-permission android:name="android.permission.INTERNET"/>`;
- `android:label="Planejamento Financeiro"`.

- [ ] **Verificação:**
  1. `flutter build apk --release` termina sem erro;
  2. o manifesto mesclado do release, procurado com `grep -r "android.permission.INTERNET" build/app/intermediates/merged_manifest*/release`, contém a permissão. Hoje ela só aparece nos manifestos de debug e de profile.

  Sem teste automatizado, porque é configuração.
- [ ] **No celular:**
  - instalar o release (`tool/celular.sh instalar --release`): o nome embaixo do ícone é "Planejamento Financeiro";
  - entrar e abrir a home: os dados de exemplo carregam, o que mostra que o release tem acesso à internet.
- [ ] **Commit:** `fix: declara a permissão de internet e o nome do app`

### Task B8: URL da API configurável e cliente HTTP completo

**Arquivos:**
- `lib/network/api_config.dart` (novo): `const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://127.0.0.1:8080')`. Esse endereço funciona no celular e no emulador com `adb reverse tcp:8080 tcp:8080`;
- `lib/network/http_client.dart`:
  - o `DioFactory` usa `apiUrl`;
  - `get`, `post`, `put`, `patch` (novo) e `delete` repassam `headers` (`Options`) e `params` (`queryParameters`);
- `android/app/src/debug/AndroidManifest.xml`: `android:usesCleartextTraffic="true"`, só em debug, para o `http://` local;
- `lib/repository/balance.dart`: o repositório, ainda mockado, para de chamar `/posts` e devolve o JSON fixo direto. Sem isso, a home quebraria entre a B8 e a B11, porque `/posts` não existe na API;
- `test/fakes.dart`: `FakeHttpAdapter implements HttpClientAdapter`, que registra os `RequestOptions` e devolve respostas programadas;
- testes em `test/network/http_client_test.dart`.

- [ ] **Testes:**
  - `get repassa headers e params`: `get(ClientRequest(url: '/x', headers: {'x-test': '1'}, params: {'a': 1}))` → a requisição registrada tem o header `x-test` e `uri.query == 'a=1'`. RED: os dois são ignorados.
  - `patch envia o corpo`.
- [ ] **No celular:** a home continua abrindo com os dados de exemplo, agora sem chamada de rede.
- [ ] **Commit:** `feat: configura a URL da API e completa o cliente HTTP`

### Task B9: login na API, tokens e renovação automática (precisa da A4)

**Arquivos:**
- `pubspec.yaml`, com `flutter_secure_storage`;
- `lib/repository/token_storage.dart` (novo):
  - `class AuthTokens { final String token; final String refreshToken; }`;
  - `abstract class TokenStorage { Future<AuthTokens?> read(); Future<void> save(AuthTokens t); Future<void> clear(); }`;
  - `SecureTokenStorage`;
- `lib/repository/auth.dart` (novo): `AuthRepository(HttpClient, TokenStorage)`, com:
  - `loginWithGoogleIdToken(String idToken)`;
  - `Future<bool> refresh()`;
  - `logout()`: `POST /auth/logout` sem bloquear o fluxo em caso de falha, e depois `clear()`;
- `lib/network/auth_interceptor.dart` (novo): `AuthInterceptor extends QueuedInterceptor`:
  - põe `Bearer` nas requisições, menos em `/auth/login` e `/auth/refresh`;
  - em 401 ou 403, renova **uma vez** com um Dio sem interceptor e repete a requisição;
  - se a renovação falhar, faz `clear()` e chama `onSessionExpired()`;
- `lib/repository/injector.dart` e `lib/screens/login.dart`: depois do Firebase, chamar `loginWithGoogleIdToken(googleAuth.idToken)`. Se falhar, sair do Firebase e mostrar o erro da B6;
- `test/fakes.dart`, com `InMemoryTokenStorage`;
- testes em `test/repository/auth_test.dart`.

- [ ] **Testes:**
  - `login guarda os tokens`: o adaptador devolve 200 `{ token: 't', refreshToken: 'r' }` → `storage.read()` devolve `t` e `r`. RED: o método não existe.
  - `requisições levam o Bearer`: o header é `Authorization: Bearer t`.
  - `401 renova e repete`: a sequência do adaptador é 401 → refresh 200 → 200 → o resultado é 200, e o refresh foi chamado 1 vez.
  - `dois 401 simultâneos renovam uma vez só` (Foco 1 da revisão).
  - `refresh que falha encerra a sessão` (Foco 4): o storage fica vazio, o `onSessionExpired` é chamado 1 vez e não há outra tentativa.
- [ ] **No celular** (com a API local e o túnel da seção Teste no celular): entrar com Google. O log da API mostra `POST /auth/login` com 200, e a home abre. Fechar e abrir o app ainda pede login; a sessão persistente vem na B10.
- [ ] **Commit:** `feat: faz login na API e renova o token automaticamente`

### Task B10: sessão persistente e botão Sair

**Arquivos:**
- `lib/repository/session.dart` (novo): `Future<bool> hasSession({required bool Function() isFirebaseSignedIn, required TokenStorage storage})`;
- `lib/screens/splash.dart`: depois de 2 s, vai para a `HomeScreen` se `hasSession`, ou para o `LoginScreen`;
- `lib/widgets/app_bar.dart` e `lib/screens/home.dart`:
  - ação **Sair**, com confirmação "Sair da conta?";
  - `onLogout`, injetável, que faz `AuthRepository.logout()`, `FirebaseAuth.instance.signOut()` e `GoogleSignIn.instance.signOut()`, e depois `pushAndRemoveUntil` para o login;
- `lib/main.dart`:
  - um `navigatorKey` global;
  - o `onSessionExpired` (B9) navega para o login e mostra a SnackBar `Sua sessão expirou. Entre de novo.`;
- testes em `test/repository/session_test.dart` e `test/screens/home_test.dart`.

- [ ] **Testes:**
  - `hasSession`:

    | Firebase | Tokens | Esperado |
    |---|---|---|
    | logado | presentes | `true` |
    | logado | ausentes | `false` |
    | deslogado | presentes | `false` |

    RED: o módulo não existe.
  - `Sair pede confirmação e chama onLogout`: tocar Sair → Confirmar → `onLogout` chamado 1 vez. Tocar Cancelar → 0 vezes.
- [ ] **No celular:**
  1. fechar o app (tirar dos recentes) e abrir de novo: vai direto para a home;
  2. tocar em Sair e confirmar: volta para o login;
  3. abrir de novo: pede login.
- [ ] **Commit:** `feat: mantém a sessão e adiciona o botão Sair`

### Task B11: repositório real de lançamentos (precisa da A5)

**Arquivos:**
- `lib/models/balance.dart`:
  - campo novo `totalValue` (`double?`);
  - `toApiMap()`, com `{ name, value, type, installment: 1, totalInstallments, date: ISO, realized }`;
- `lib/repository/balance.dart`: remove o JSON fixo e o jsonplaceholder, e implementa, mantendo as assinaturas da B5:
  - `getBalances()`: `GET /balances` → `MonthBalanceModel.fromMap` (o Dio já devolve um `Map`);
  - `createBalance(balance)`: `POST /balances` com `toApiMap()`;
  - `updateBalance(id, fields)`: `PATCH /balances/:id`;
  - `setInstallmentRealized(id, n, realized)`;
  - `deleteBalance(id)`;
  - `deleteInstallment(id, n)`;
  - uma resposta fora de 2xx lança `ApiException(status, message)`; o 409 vira `Você já tem um lançamento com esse nome.`;
- `test/fakes.dart`: atualizar o `FakeBalanceRepository`;
- testes em `test/repository/balance_test.dart`.

- [ ] **Testes:**
  - `getBalances lê o formato da API`: `{'NOV/26': {'gains': [{'id': 'abc', …}], 'expenses': []}}` → `months['NOV/26']!.gains.first.id == 'abc'`. RED: hoje devolve o JSON fixo.
  - `createBalance envia data ISO e parcela 1`.
  - `deleteInstallment chama DELETE /balances/abc/installments/2`.
  - `409 vira ApiException com mensagem amigável`.
- [ ] **No celular:**
  - criar o gasto "Café" de R$ 15,00: aparece como R$ 15,00 no mês aberto (confere a B1);
  - criar "TV" de R$ 100,00 em 3x: as parcelas aparecem nos três meses com R$ 33,33, R$ 33,33 e R$ 33,34, e a última mostra "TV - 3/3" (confere a A1 e a B3);
  - criar outro "Café": aparece "Você já tem um lançamento com esse nome.".
- [ ] **Commit:** `feat: liga o repositório de lançamentos à API`

### Task B12: excluir perguntando "só esta" ou "todas"

**Arquivos:** `lib/widgets/balance_tab_view.dart` e `lib/screens/home.dart`.
- A chave do `Dismissible` deixa de ser `UniqueKey()` e passa a ser `ValueKey('$id-$installment')`.
- O `Dismissible` ganha um `confirmDismiss` com diálogo:
  - **parcelado:** `Só esta parcela`, `Todas as parcelas` e `Cancelar`;
  - **à vista:** `Excluir` e `Cancelar`.
- Chama o repositório, recarrega e devolve `true` em caso de sucesso. Em caso de erro, mostra a SnackBar `Não foi possível excluir` e devolve `false`.

Os testes ficam em `test/screens/home_test.dart`.

- [ ] **Testes:**
  - `só esta parcela`: `deleteInstallment('abc', 2)`. RED: nada é chamado.
  - `todas as parcelas`: `deleteBalance('abc')`.
  - `cancelar mantém o item`.
  - `falha na API mantém o item e avisa` (Foco 2 da revisão).
- [ ] **No celular:**
  - arrastar uma parcela da TV: o diálogo mostra "Só esta parcela", "Todas as parcelas" e "Cancelar". Testar as três;
  - arrastar o Café: o diálogo mostra "Excluir" e "Cancelar";
  - o agente para a API local, e o usuário arrasta um item: ele continua na lista e aparece "Não foi possível excluir". Depois, o agente sobe a API de novo.
- [ ] **Commit:** `feat: exclui lançamento ou parcela pelo arraste`

### Task B13: editar o lançamento e marcar a parcela

**Arquivos:**
- `lib/widgets/formBalance/form_balance.dart`: em parcelado, o campo mostra `totalValue` com o rótulo `Valor total`;
- `lib/screens/home.dart`:
  - o `_onSubmitEdit` **não sobrescreve mais a data** com a do mês da aba;
  - se nome, valor ou parcelas mudaram → `updateBalance`;
  - se só o "realizado" mudou: em parcelado → `setInstallmentRealized(id, installment, realized)`; à vista → vai junto no `updateBalance`;
- testes em `test/screens/home_test.dart`.

- [ ] **Testes:**
  - `marcar realizado em parcelado altera só a parcela`: `setInstallmentRealized('abc', 2, true)`, sem `updateBalance`. RED: o fluxo atual edita e sobrescreve a data.
  - `editar nome de parcelado altera o lançamento`: `updateBalance('abc', {name: …})`.
  - `editar parcelado mostra o valor total`: o campo exibe `R$ 3.000,00` para um item com `value` 1000 e `totalValue` 3000.
- [ ] **No celular:**
  - tocar numa parcela da TV: o campo "Valor total" mostra R$ 100,00;
  - mudar o nome para "Televisão": as três parcelas mudam de nome;
  - marcar só a 2/3 como realizada: só ela perde o ponto.
- [ ] **Commit:** `feat: edita o lançamento e marca a parcela realizada`

### Task B14: formatação e CI do app

**Arquivos:** os 12 arquivos fora do formato (`dart format lib test`) e `.github/workflows/ci.yml`.
- **Disparo:** `push` na `main` e `pull_request`.
- **Ambiente:** `actions/checkout@v7`, `subosito/flutter-action@v2` (`flutter-version: 3.50.1`, `cache: true`).
- **Passos:**
  1. `flutter pub get`
  2. `dart format --output=none --set-exit-if-changed lib test`
  3. `flutter analyze`
  4. `flutter test`

- [ ] **Commits:**
  - `style: formata o código com dart format`
  - `ci: roda format, analyze e testes nos PRs`
- [ ] **Verificação:** depois do push autorizado, `gh run watch` em sucesso.

### Task B15: README do app e documento atualizado

**Arquivos:**
- `README.md`, que troca o padrão do Flutter por:
  - o que é;
  - Flutter 3.50.1;
  - Firebase;
  - como rodar no celular contra a API local (`adb reverse tcp:8080 tcp:8080` e `tool/celular.sh instalar`, ou `flutter run --dart-define=API_URL=http://127.0.0.1:8080`);
  - release com `https`;
  - testes;
  - estrutura;
- `docs/funcionamento-app-e-api.md`, versionado agora: atualizar as tabelas de situação e as seções 2.7, 3.8 e 4.2 com o que foi feito.

- [ ] **Commit:** `docs: atualiza o README e o documento de funcionamento`

---

## Parte C: setup do Claude Code

### Task C1: CLAUDE.md, subagentes, hooks e MCP

**Arquivos:**
- **API:**
  - `CLAUDE.md`: comandos, convenções e armadilhas (Atlas inacessível do sandbox, `db:migrate` sempre em dry-run, fuso de São Paulo);
  - `.claude/settings.json`: `permissions.deny: ["Read(./.env)"]` e um hook `PostToolUse` (`Edit|Write`) que roda `npx prettier --write` em `.ts`;
  - `.claude/agents/revisor-financeiro.md`, com o texto da seção 5.4 do documento.
- **App:**
  - `CLAUDE.md`;
  - `.claude/settings.json`, com o hook de `dart format` da seção 5.5 (o `jq` já está instalado);
  - `.claude/agents/revisor-financeiro.md`;
  - `.mcp.json`, criado com `claude mcp add -s project dart -- dart mcp-server`. Com ele, o agente também abre o app no celular (`launch_app` no dispositivo `192.168.15.21:45721`) e usa hot reload e `get_runtime_errors` durante as tasks do app.
- **Usuário:** `~/.claude/agents/contrato-app-api.md`, com o texto da seção 5.4.

- [ ] **Verificação:**
  - `echo '{"tool_input":{"file_path":"lib/main.dart"}}' | <comando do hook>` sai com 0;
  - `claude mcp list` mostra `dart` no app;
  - os agentes aparecem em `/agents`.
- [ ] **Commit:** `chore: configura o Claude Code no projeto`, em cada repositório.
- [ ] **Passo do usuário** (comando interativo): `/plugin install mongodb@claude-plugins-official`, e o mesmo para `firebase`, `claude-code-setup`, `context7` e `code-review`. Configurar o MongoDB em modo só leitura.

## Operacional (passos do usuário, fora do sandbox)

- **O1. Migração no Atlas,** se ainda não rodou:
  1. Antes, rode uma contagem só de leitura: `db.users.countDocuments({ $or: [{ name: { $in: [null, ''] } }, { email: { $in: [null, ''] } }] })`. O esperado é 0.
  2. Depois do deploy, `npm run db:migrate` (dry-run). Pare se o `toDrop` trouxer qualquer índice além do `name_1`.
  3. `npm run db:migrate -- --apply`.
- **O2. Deploy da API antes do app integrado.** A API das fases A4 e A5 precisa estar no ar antes de publicar o app das tasks B8 a B13. Depois da A11, todos precisam entrar de novo.
- **O3. Variáveis de produção:**
  - `GOOGLE_CLIENT_ID` = o *Web client* do Firebase, que é a audiência do `idToken` do app;
  - `TRUST_PROXY` conforme o provedor;
- **O4. Build do app de produção:** `--dart-define=API_URL=https://…`, com a URL real da API.

## Fora deste plano

- **Escolhas suas:** IA (lançamento por texto e categoria), publicação na Play Store (a assinatura de release ainda usa a chave de debug) e gráficos e lembretes.
- **Mudanças de modelo de dados:** centavos inteiros no banco, iOS, e filtro ou paginação por período no `GET /balances` (hoje ele traz todo o histórico).
- **Arquivo antigo:** o plano anterior, ainda não versionado, em `docs/superpowers/plans/` da API.

## Verificação ponta a ponta

1. **API:** gate verde ao fim de cada task e, depois da A13, `npm test` com toda a suíte nova (por volta de 65 testes).
2. **App:**
   - `flutter analyze` sem issues;
   - `flutter test` verde;
   - `flutter build apk --release` sem erro, com a permissão de internet no manifesto mesclado.
3. **Integração manual no celular** (usuário, com o agente preparando o ambiente da seção Teste no celular):
   - MongoDB local, API local (`npm run dev`) e o túnel `adb reverse`;
   - app instalado com `ADB_DEVICE=192.168.15.21:45721 tool/celular.sh instalar`;
   - roteiro:
     1. entrar com Google;
     2. criar um lançamento à vista e um parcelado em 3x;
     3. trocar de mês;
     4. marcar a parcela 2 como realizada;
     5. editar o valor total;
     6. excluir só uma parcela e depois todas;
     7. Sair;
     8. reabrir o app (deve pedir login);
     9. entrar de novo e reabrir (deve ir direto para a home).
4. **Revisão final:** uma revisão independente da branch de cada fase antes do PR.
