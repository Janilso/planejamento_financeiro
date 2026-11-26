# Planejamento Financeiro

App Android pessoal para controlar ganhos e gastos mês a mês. Você entra com a conta Google e lança valores à vista ou parcelados (até 30x). Cada mês mostra o resumo de ganhos, gastos e balanço. Os dados ficam na API [planejamento_financeiro_api](https://github.com/Janilso/planejamento_financeiro_api).

Como o app e a API funcionam por dentro: [docs/funcionamento-app-e-api.md](docs/funcionamento-app-e-api.md).

## Requisitos

- Flutter 3.50.1 (Dart 3.14).
- Android. O app ainda não tem versão para iOS.
- A API rodando, local ou publicada.
- O Firebase já vem configurado: `android/app/google-services.json` e `lib/firebase_options.dart`, projeto `planejamento-financeiro-e0a27`. Para o login com Google funcionar num computador novo, cadastre no Firebase o SHA-1 do keystore de debug:

  ```sh
  keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
  ```

## Rodar no celular contra a API local

A URL da API vem de `--dart-define=API_URL=...`. O padrão é `http://127.0.0.1:8080`, que funciona no celular ou no emulador por um túnel do `adb`. Assim a API não fica exposta na rede.

1. Suba a API local (veja o README dela). Ela escuta na porta 8080.
2. Conecte o celular por USB ou pela depuração sem fio (`adb connect <ip>:<porta>`).
3. Abra o túnel e rode o app:

   ```sh
   adb reverse tcp:8080 tcp:8080
   flutter run --dart-define=API_URL=http://127.0.0.1:8080
   ```

O script `tool/celular.sh` faz tudo isso e ainda captura a tela e interage com ela. Ele serve para testes guiados:

```sh
ADB_DEVICE=<ip>:<porta> tool/celular.sh instalar           # gera o APK de debug, instala e abre
ADB_DEVICE=<ip>:<porta> tool/celular.sh print tela.png     # captura a tela
ADB_DEVICE=<ip>:<porta> tool/celular.sh elementos          # lista os textos visíveis e onde estão
```

Rode o script sem argumentos para ver todos os comandos.

O build de debug libera `http://` (`usesCleartextTraffic`, só em `android/app/src/debug`). O release só aceita `https://`.

## Build de release

```sh
flutter build apk --release --dart-define=API_URL=https://<endereço-da-api>
```

A assinatura de release ainda usa a chave de debug. Antes de publicar na Play Store, é preciso criar uma chave própria.

## Testes e checagens

```sh
flutter test
flutter analyze
dart format --output=none --set-exit-if-changed lib test
```

O CI (`.github/workflows/ci.yml`) roda os três em cada pull request e em cada push na `main`. Os testes usam dublês escritos à mão (`test/fakes.dart`): repositório falso, adaptador falso do Dio e armazenamento de tokens em memória.

## Estrutura

```
lib/
├── main.dart        inicializa pt-BR, Firebase e Google Sign-In; trata a sessão expirada
├── screens/         splash (decide entre login e home), login e home
├── models/          BalanceModel (lançamento ou parcela) e os agrupamentos por mês
├── repository/      lançamentos, login na API, tokens (armazenamento seguro), sessão e injetor
├── network/         URL da API, cliente HTTP (Dio) e interceptor que põe o token e o renova
├── widgets/         abas de meses, lista com arrastar para excluir, resumo e formulário
├── commons/         meses, datas, formatação de R$, textos e ícones
└── theme/           cores e estilos
tool/celular.sh      instala e opera o app no celular por adb
```

## Como funciona, em resumo

- **Login:** Google Sign-In → Firebase Auth → `POST /auth/login` na API. O token e o refresh token ficam no armazenamento seguro do Android. Com sessão válida, a splash vai direto para a home.
- **Token vencido:** o interceptor renova uma vez só, mesmo que várias requisições falhem juntas, e repete as requisições. Se a renovação falhar, o app volta ao login com o aviso "Sua sessão expirou. Entre de novo.".
- **Lançamentos:** criar, editar e marcar como realizado pelo formulário, e excluir arrastando o item para a esquerda. Num parcelado, editar muda o lançamento inteiro (o campo mostra o **valor total**). O "realizado" e a exclusão de "só esta parcela" valem para uma parcela.
