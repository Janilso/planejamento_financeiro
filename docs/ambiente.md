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

## Taxa de atualização (120 Hz)

O app não pede uma taxa de atualização: o Flutter segue a que o Android liberar para ele. No celular de teste (Xiaomi com HyperOS, tela de 120 Hz, "taxa inteligente" ligada e o teto do usuário em 120) ele **já anima a ~120 fps**, medido em 2026-11-27. Não há nada a configurar.

| Build | Situação | Intervalo mediano entre quadros | Quadros a ~120 fps |
|---|---|---|---|
| Profile | Assentamento depois de um arremesso rápido | 8,28 ms (~121 fps), p90 9,3 ms | 97% |
| Profile | Arraste contínuo | 8,38 ms | 88% |
| Debug | Arraste contínuo | 8,79 ms | 63% |

- **Julgue a fluidez em profile ou release, nunca em debug.** No debug quase 4 em cada 10 quadros atrasam e a animação parece rodar a 60 fps. Para instalar em profile: `flutter build apk --profile --dart-define=API_URL=http://127.0.0.1:8080` e `adb install -r build/app/outputs/flutter-apk/app-profile.apk` (o `tool/celular.sh instalar` só faz debug e release; o profile não tem hot reload).
- **Parado, a tela baixa a taxa de propósito** (a "taxa inteligente" do HyperOS). Um indicador de taxa mostrando 60 com o app em repouso é normal.
- Perto de 3% dos quadros em profile caem para 16,7 ms; é o pior caso dos testes de desempenho (veja [Testes](testes.md)).

**Como conferir no aparelho**

- Taxa que o Android aplicou, com o app animando (por exemplo, enquanto você arrasta): `adb shell dumpsys SurfaceFlinger | grep -E "renderRate|vsyncRate"`. Deve mostrar `120.00 Hz`.
- Cadência dos quadros: grave a tela (`adb shell screenrecord --size 540x1200 /sdcard/c.mp4`) fazendo arremessos rápidos (`adb shell input swipe 900 500 200 500 120`, esperando ~1,4 s entre eles), baixe o vídeo e meça o intervalo entre quadros com `ffprobe -select_streams v -show_entries frame=pts_time -of csv=p=0`. Considere só a animação de assentamento, depois que o dedo sai: intervalos de ~8,3 ms são 120 fps e de ~16,7 ms são 60 fps. Um arraste lento com `input swipe` mistura a taxa de toque do ADB com a de renderização.
- A camada do app é uma `SurfaceView`, então `dumpsys SurfaceFlinger --latency` devolve só o período do display, sem os quadros. E `dumpsys gfxinfo` não enxerga os quadros do Flutter.

**Se algum outro celular ficar preso em 60 Hz.** Algumas fabricantes limitam apps fora da lista a 60 Hz. O ajuste seria pedir a taxa alta no `MainActivity` (cerca de 10 linhas de Kotlin, com `preferredRefreshRate` ou `preferredDisplayModeId`). **Não foi feito:** neste celular não há ganho, não dá para testar em outro aparelho e fixar 120 Hz custa um pouco de bateria. Só vale a pena se alguém notar o problema.

## Release

```sh
flutter build apk --release --dart-define=API_URL=https://<endereço-da-api>
```

- O manifesto principal declara a permissão de internet e o nome "Planejamento Financeiro".
- A assinatura de release ainda usa a chave de debug (`android/app/build.gradle.kts`). Antes de publicar na Play Store, crie uma chave própria.
- O lint do release está desligado (`checkReleaseBuilds = false`).
