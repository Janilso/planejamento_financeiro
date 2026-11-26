import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:planejamento_financeiro/theme/colors.dart';
import 'package:planejamento_financeiro/theme/theme.dart';

void main() {
  final t = AppTheme.defaultTheme.textTheme;

  test('tamanhos e alturas da spec', () {
    expect(t.displaySmall!.fontSize, 36);
    expect(t.titleLarge!.fontSize, 26);
    expect(t.titleSmall!.fontSize, 20);
    expect([t.bodyLarge!.fontSize, t.bodyLarge!.height], [18, 1.3]);
    expect([t.bodyMedium!.fontSize, t.bodyMedium!.height], [16, 1.5]);
    expect(t.bodySmall!.fontSize, 13);
    expect(
      [t.labelLarge!.fontSize, t.labelLarge!.fontWeight],
      [16, FontWeight.w600],
    );
    expect(t.labelMedium!.fontSize, 14);
    expect(t.labelSmall!.fontSize, 12);
  });

  test('nada abaixo de 12 sp, WorkSans e texto escuro por padrão', () {
    for (final s in [
      t.displaySmall,
      t.titleLarge,
      t.titleMedium,
      t.titleSmall,
      t.bodyLarge,
      t.bodyMedium,
      t.bodySmall,
      t.labelLarge,
      t.labelMedium,
      t.labelSmall,
    ]) {
      expect(s!.fontSize, greaterThanOrEqualTo(12));
      expect(s.fontFamily, 'WorkSans');
      expect(s.color, AppColors.black);
    }
  });
}
