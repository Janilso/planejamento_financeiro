import 'package:flutter_test/flutter_test.dart';
import 'package:planejamento_financeiro/models/balance.dart';

void main() {
  test('isInstallmented depende do total de parcelas', () {
    expect(
      BalanceModel(installment: 12, totalInstallments: 12).isInstallmented,
      isTrue,
    );
    expect(
      BalanceModel(installment: 1, totalInstallments: 1).isInstallmented,
      isFalse,
    );
    expect(
      BalanceModel(installment: 5, totalInstallments: 12).isInstallmented,
      isTrue,
    );
  });
}
