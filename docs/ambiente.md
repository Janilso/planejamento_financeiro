# Ambiente

## Requisitos

- Flutter 3.50.1 (Dart 3.14). Só Android por enquanto (`br.com.janilso.planejamentofinanceiro`).
- A API rodando (veja o README da API).
- Um celular com depuração USB ou sem fio, ou um emulador.

## Firebase

- Projeto `planejamento-financeiro-e0a27`. Os arquivos já estão no repositório: `android/app/google-services.json` e `lib/firebase_options.dart` (gerado pelo FlutterFire; não edite à mão).
- **Computador novo:** cadastre no Firebase o SHA-1 do keystore de debug, senão o login com Google falha (código 10 / `DEVELOPER_ERROR`):

  ```sh
  keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
  ```

- O `GOOGLE_CLIENT_ID` da API precisa ser o *Web client* deste projeto Firebase, que é a audiência do `idToken` do app.

## Rodar contra a API local

```sh
adb reverse tcp:8080 tcp:8080
flutter run --dart-define=API_URL=http://127.0.0.1:8080
```

O `adb reverse` faz o `127.0.0.1:8080` do celular apontar para a porta 8080 do computador. Assim a API não fica exposta na rede. Sem `--dart-define`, o padrão já é esse endereço.

O build de debug libera `http://` (`usesCleartextTraffic` só em `android/app/src/debug/AndroidManifest.xml`). O release só aceita `https://`.

## `tool/celular.sh`

Instala e opera o app no celular por ADB. Exige `ADB_DEVICE=<ip>:<porta>` (a porta da depuração sem fio muda quando ela é religada).

| Comando | O que faz |
|---|---|
| `instalar [--release]` | Abre o túnel, gera o APK, instala e abre o app |
| `print <arquivo.png>` | Captura a tela |
| `elementos` | Lista os textos visíveis e onde estão |
| `tocar <texto>` / `tocar-xy <x> <y>` | Toca num elemento / numa coordenada |
| `arrastar <x1> <y1> <x2> <y2> [ms]` | Arrasta |
| `digitar <texto>` / `voltar` | Digita no campo com foco / botão voltar |

## Release

```sh
flutter build apk --release --dart-define=API_URL=https://<endereço-da-api>
```

- O manifesto principal declara a permissão de internet e o nome "Planejamento Financeiro".
- A assinatura de release ainda usa a chave de debug (`android/app/build.gradle.kts`). Antes de publicar na Play Store, crie uma chave própria.
- O lint do release está desligado (`checkReleaseBuilds = false`).
