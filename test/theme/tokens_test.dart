import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planejamento_financeiro/theme/colors.dart';
import 'package:planejamento_financeiro/theme/spacing.dart';

import '../helpers.dart';

void main() {
  test('perigo, texto secundário e exemplo passam 4,5:1 sobre branco', () {
    for (final c in [
      AppColors.danger,
      AppColors.textSecondary,
      AppColors.hint,
      AppColors.black,
    ]) {
      expect(contrastRatio(c, AppColors.white), greaterThanOrEqualTo(4.5));
    }
  });

  test('cor da marca fica na exceção de 3:1', () {
    expect(AppColors.primary, const Color(0xFF44A2A6));
    expect(AppColors.secondary, const Color(0xFFF7646C));
    for (final c in [AppColors.primary, AppColors.secondary]) {
      expect(contrastRatio(c, AppColors.white), inInclusiveRange(2.95, 4.49));
    }
  });

  test('fundo do arraste se distingue do coral', () {
    expect(
      contrastRatio(AppColors.danger, AppColors.secondary),
      greaterThanOrEqualTo(1.5),
    );
  });

  test('escalas de espaçamento e raio', () {
    expect(
      [
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.base,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xxl,
      ],
      [4, 8, 12, 16, 24, 32, 48],
    );
    expect([AppRadius.sm, AppRadius.md, AppRadius.lg], [8, 12, 16]);
  });
}
