# App do Planejamento Financeiro

App Flutter (Android) pessoal e simples para controlar ganhos e gastos mês a mês. A API fica em `/home/janilso/projetos/backend/planejamento_financeiro_api`. O funcionamento dos dois está em `docs/funcionamento-app-e-api.md`, e o plano de correções em `docs/superpowers/plans/`.

## Comandos

- `flutter test` e `flutter analyze`.
- `dart format lib test` (o hook do projeto formata cada `.dart` editado).
- Celular do usuário por ADB sem fio: `adb connect 192.168.15.21:45721` (a porta muda quando a depuração sem fio é religada; peça a nova ao usuário).
- Rodar no celular: `flutter run -d 192.168.15.21:45721`. Com a API local: `adb -s 192.168.15.21:45721 reverse tcp:8080 tcp:8080` e `--dart-define=API_URL=http://127.0.0.1:8080`.

## Convenções

- Commits em pt-BR, no padrão `fix:`, `feat:`, `test:`, `docs:`, `ci:`, `chore:`, `style:`.
- TDD com `flutter_test` e dublês escritos à mão (sem libs de mock).
- O `AppLoad` tem animação infinita: nos testes de widget, use `pump()` enquanto ele estiver na tela.
- Antes de cada commit, pare e deixe o usuário revisar o código e testar no celular.

## Armadilhas

- `AppFormats.stringMoneyToDouble` multiplicava valores por 100 ("R$ 15,00" virava 1500).
- Gerar meses mantendo o dia de hoje repete e pula meses nos dias 29 a 31: use o dia 1.
- A chave do mês ("MMM/YY", pt-BR, sem ponto, maiúsculas) precisa bater com a da API.
- O login usa Google + Firebase Auth; o seletor de conta no celular é sempre tocado pelo usuário.
