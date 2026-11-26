import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:material_ui/material_ui.dart';
import 'package:planejamento_financeiro/screens/login.dart';
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
}
