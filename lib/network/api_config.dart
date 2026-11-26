// URL da API, definida no build: --dart-define=API_URL=https://...
// O padrão usa o túnel `adb reverse tcp:8080 tcp:8080`, que funciona no
// celular e no emulador.
const apiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://127.0.0.1:8080',
);
