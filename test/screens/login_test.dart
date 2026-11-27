import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:material_ui/material_ui.dart';
import 'package:planejamento_financeiro/commons/icons.dart';
import 'package:planejamento_financeiro/screens/login.dart';
import 'package:planejamento_financeiro/theme/overlay.dart';
import 'package:planejamento_financeiro/widgets/button.dart';
import 'package:planejamento_financeiro/theme/theme.dart';

void main() {
  Future<void> tapLogin(
    WidgetTester tester,
    Future<void> Function() signIn,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.defaultTheme,
        home: LoginScreen(signIn: signIn),
      ),
    );
    await tester.tap(find.text('ENTRAR / CADASTRAR'));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('mostra erro quando o login falha', (tester) async {
    await tapLogin(tester, () async => throw Exception('x'));

    expect(
      find.text('Não foi possível entrar. Tente de novo.'),
      findsOneWidget,
    );
  });

  testWidgets('cancelar o login não mostra erro', (tester) async {
    await tapLogin(
      tester,
      () async => throw const GoogleSignInException(
        code: GoogleSignInExceptionCode.canceled,
      ),
    );

    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('ENTRAR / CADASTRAR'), findsOneWidget);
  });

  testWidgets('o aviso de erro aparece acima do botão', (tester) async {
    await tapLogin(tester, () async => throw Exception('x'));
    await tester.pumpAndSettle();

    final aviso = tester.getRect(find.byType(SnackBar));
    final botao = tester.getRect(find.byType(AppButton));
    expect(aviso.bottom, lessThanOrEqualTo(botao.top));
  });

  testWidgets('o botão não estoura em 320 dp', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.defaultTheme, home: const LoginScreen()),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('o ícone do Google fica à esquerda do texto', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.defaultTheme, home: const LoginScreen()),
    );
    expect(
      tester.getCenter(find.byIcon(AppIcons.google)).dx,
      lessThan(tester.getCenter(find.text('ENTRAR / CADASTRAR')).dx),
    );
  });

  testWidgets('a barra de status usa ícones claros sobre a cor da marca', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.defaultTheme, home: const LoginScreen()),
    );
    final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
      find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first,
    );
    expect(region.value, onBrandOverlay);
  });
}
