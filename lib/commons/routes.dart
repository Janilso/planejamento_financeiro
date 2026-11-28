import 'package:material_ui/material_ui.dart';
import 'package:planejamento_financeiro/theme/motion.dart';

// O logo é compartilhado entre a splash e o login: ele desliza até a nova
// posição enquanto o resto da tela aparece em fade.
const logoHeroTag = 'logo';

// Rota que entra em fade. O app só vai para a frente (as telas se substituem e
// nunca há tela para voltar), então o deslize do iOS não faz sentido aqui.
Route<T> fadeRoute<T>(WidgetBuilder builder) => PageRouteBuilder<T>(
  transitionDuration: AppMotion.page,
  reverseTransitionDuration: AppMotion.page,
  pageBuilder: (context, animation, secondaryAnimation) => builder(context),
  transitionsBuilder: (context, animation, secondaryAnimation, child) =>
      FadeTransition(opacity: animation, child: child),
);

// O botão do login e o cartão branco da home compartilham este Hero: o botão
// voa e cresce até virar o cartão.
const cartaoHeroTag = 'cartao';

// Rota para a home com entrada animada: o fade termina cedo (0,4 da rota) e
// o resto do tempo é a entrada. Depois do login, o botão voa até o cartão;
// depois da splash, as folhas já saíram e o cartão sobe.
Route<T> entradaHomeRoute<T>(WidgetBuilder builder) => PageRouteBuilder<T>(
  transitionDuration: AppMotion.cartao,
  reverseTransitionDuration: AppMotion.cartao,
  pageBuilder: (context, animation, secondaryAnimation) => builder(context),
  transitionsBuilder: (context, animation, secondaryAnimation, child) =>
      FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: const Interval(0, 0.4),
        ),
        child: child,
      ),
);
