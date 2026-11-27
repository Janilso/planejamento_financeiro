import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:planejamento_financeiro/theme/theme.dart';
import 'package:planejamento_financeiro/widgets/infiniteTabelView/infinite_tabel_view.dart';

import '../helpers.dart';

void main() {
  testWidgets('a página assenta sem passar do ponto', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.defaultTheme,
        home: Scaffold(
          body: InfiniteTabView(
            length: 3,
            buildTabBar: (_, i) => 'M$i',
            buildTabView: (_, i) => Center(child: Text('p$i')),
          ),
        ),
      ),
    );
    final pos = tabViewPosition(tester, find.byType(TabBarView));
    final largura = pos.viewportDimension;

    // Um arremesso para a esquerda leva à página 1: o alvo é uma largura.
    await tester.fling(find.byType(TabBarView), const Offset(-300, 0), 1000);
    final maximo = await maxPixelsWhileSettling(tester, pos);

    expect(maximo, lessThanOrEqualTo(largura + 0.5));
    expect(pos.pixels, closeTo(largura, 0.5));
  });
}
