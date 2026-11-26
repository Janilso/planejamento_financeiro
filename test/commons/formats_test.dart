import 'package:flutter_test/flutter_test.dart';
import 'package:planejamento_financeiro/commons/formats.dart';

void main() {
  test('stringMoneyToDouble converte reais', () {
    expect(AppFormats.stringMoneyToDouble('R\$ 15,00'), 15.0);
    expect(AppFormats.stringMoneyToDouble('R\$ 1.234,56'), 1234.56);
    expect(AppFormats.stringMoneyToDouble('R\$ 0,50'), 0.5);
  });
}
