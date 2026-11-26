# Contribuindo

## Mudança numa tela

1. **Teste de widget primeiro** em `test/screens/`, usando o `FakeBalanceRepository` e um `clock` fixo. Rode e veja falhar.
2. Implemente na tela ou no widget. Dependências novas entram como parâmetro opcional, com o padrão vindo do `appInjector`.
3. Rode o app no celular contra a API local ([Ambiente](ambiente.md)) e confira na tela.

## Chamada nova à API

1. Confira a rota no Swagger da API (`/docs`).
2. Teste em `test/repository/` com o `FakeHttpAdapter`: rota, corpo e tratamento de erro.
3. Método no repositório (`lib/repository/`), passando por `_call` para os erros virarem `ApiException`.
4. Acrescente o método ao `FakeBalanceRepository` (`test/fakes.dart`).
5. Se for uma dependência nova, registre no `lib/repository/injector.dart`.

## Gate antes de abrir PR

```sh
dart format lib test
flutter analyze
flutter test
```

## Convenções

- Commits em pt-BR: `feat:`, `fix:`, `test:`, `docs:`, `ci:`, `chore:`, `style:`.
- Meses sempre no dia 1; a chave do mês tem de bater com a da API (`monthKey`).
- Valores em R$ passam por `AppFormats`; nunca multiplique por 100.
- Atualize o arquivo de `docs/` do assunto junto com a mudança.
