import 'package:integration_test/integration_test_driver.dart';

// Grava cada rodada do teste de volume em build/perf/volume_<carimbo>.json, para
// o tool/perf_resumo.dart tirar a mediana de várias rodadas.
Future<void> main() => integrationDriver(
  timeout: const Duration(minutes: 40),
  writeResponseOnFailure: true,
  responseDataCallback: (data) async {
    final agora = DateTime.now();
    String d(int n) => n.toString().padLeft(2, '0');
    final carimbo =
        '${agora.year}${d(agora.month)}${d(agora.day)}-'
        '${d(agora.hour)}${d(agora.minute)}${d(agora.second)}';
    await writeResponseData(
      data,
      testOutputFilename: 'volume_$carimbo',
      destinationDirectory: 'build/perf',
    );
  },
);
