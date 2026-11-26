#!/usr/bin/env bash
# Instala o app no celular, captura a tela e interage com ela, via ADB sem fio.
#
# Uso: ADB_DEVICE=<ip:porta> tool/celular.sh <comando>
#   instalar [--release]       gera o APK, instala e abre o app
#   print <arquivo.png>        captura a tela
#   elementos                  lista textos visíveis e onde estão
#   tocar <texto>              toca no elemento com esse texto (exato ou parcial)
#   tocar-xy <x> <y>           toca numa coordenada
#   arrastar <x1> <y1> <x2> <y2> [ms]   arrasta (swipe)
#   digitar <texto>            digita no campo com foco
#   voltar                     botão voltar do Android
#
# A porta da depuração sem fio muda quando ela é religada, por isso não há valor padrão.
# API_URL (opcional) é passada ao app; o padrão usa o túnel adb reverse para a API local.
set -euo pipefail

APP_ID="br.com.janilso.planejamentofinanceiro"

uso() {
  sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//' >&2
  exit 2
}

[ -n "${ADB_DEVICE:-}" ] || { echo "Erro: defina ADB_DEVICE (ex.: ADB_DEVICE=192.168.15.21:45721)." >&2; uso; }

adb_() { adb -s "$ADB_DEVICE" "$@"; }

# Acorda a tela e avisa se o celular está bloqueado (o print sairia preto).
acordar() {
  adb_ shell input keyevent KEYCODE_WAKEUP
  if adb_ shell dumpsys window | grep -q "isKeyguardShowing=true"; then
    echo "Aviso: o celular está bloqueado. Desbloqueie a tela para ver o app e tirar prints." >&2
  fi
}

# Imprime "texto<TAB>x<TAB>y" de cada elemento com texto (o Flutter expõe o texto em content-desc).
listar_elementos() {
  if ! adb_ shell dumpsys window | grep "mCurrentFocus" | grep -q "$APP_ID"; then
    echo "Aviso: o app não está em primeiro plano; a lista é de outra tela." >&2
  fi
  adb_ shell uiautomator dump /sdcard/ui.xml >/dev/null
  adb_ exec-out cat /sdcard/ui.xml | python3 -I -c '
import re, sys
for node in re.findall(r"<node [^>]*>", sys.stdin.read()):
    attr = dict(re.findall(r"([\w-]+)=\"([^\"]*)\"", node))
    texto = attr.get("text") or attr.get("content-desc")
    if not texto:
        continue
    x1, y1, x2, y2 = map(int, re.findall(r"\d+", attr["bounds"]))
    print(f"{texto}\t{(x1 + x2) // 2}\t{(y1 + y2) // 2}")
'
}

case "${1:-}" in
  instalar)
    modo="debug"
    [ "${2:-}" = "--release" ] && modo="release"

    adb connect "$ADB_DEVICE" >/dev/null
    adb_ reverse tcp:8080 tcp:8080 >/dev/null
    flutter build apk "--$modo" "--dart-define=API_URL=${API_URL:-http://127.0.0.1:8080}"
    adb_ install -r "build/app/outputs/flutter-apk/app-$modo.apk"
    acordar
    adb_ shell am start -W -n "$APP_ID/.MainActivity"
    ;;
  print)
    [ -n "${2:-}" ] || uso
    acordar
    adb_ exec-out screencap -p > "$2"
    echo "Print salvo em $2"
    ;;
  elementos)
    listar_elementos
    ;;
  tocar)
    [ -n "${2:-}" ] || uso
    alvo="$2"
    linha=$(listar_elementos | awk -F'\t' -v t="$alvo" '$1 == t { print; exit }')
    [ -n "$linha" ] || linha=$(listar_elementos | awk -F'\t' -v t="$alvo" 'index($1, t) { print; exit }')
    [ -n "$linha" ] || { echo "Erro: nenhum elemento com o texto \"$alvo\" na tela." >&2; exit 1; }
    IFS=$'\t' read -r texto x y <<< "$linha"
    adb_ shell input tap "$x" "$y"
    echo "Tocou em \"$texto\" ($x, $y)"
    ;;
  tocar-xy)
    [ -n "${3:-}" ] || uso
    adb_ shell input tap "$2" "$3"
    ;;
  arrastar)
    [ -n "${5:-}" ] || uso
    adb_ shell input swipe "$2" "$3" "$4" "$5" "${6:-300}"
    ;;
  digitar)
    [ -n "${2:-}" ] || uso
    # O input text do Android usa %s no lugar de espaço.
    adb_ shell input text "${2// /%s}"
    ;;
  voltar)
    adb_ shell input keyevent KEYCODE_BACK
    ;;
  *)
    uso
    ;;
esac
