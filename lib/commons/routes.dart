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
