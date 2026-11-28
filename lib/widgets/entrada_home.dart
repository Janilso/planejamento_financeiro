import 'package:material_ui/material_ui.dart';

// A animação da rota que abriu a home depois do login (nula nas outras
// entradas): as abas e o resumo descem enquanto o botão vira o cartão.
class EntradaHome extends InheritedWidget {
  const EntradaHome({super.key, this.animacao, required super.child});

  final Animation<double>? animacao;

  static Animation<double>? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<EntradaHome>()?.animacao;

  @override
  bool updateShouldNotify(EntradaHome old) => animacao != old.animacao;
}

// Desce 24 dp e aparece entre 0,3 e 1,0 da rota; sem animação, não faz nada.
class EntradaDescendo extends StatelessWidget {
  const EntradaDescendo({super.key, required this.child});

  final Widget child;

  static const _intervalo = Interval(0.3, 1.0, curve: Curves.easeOutCubic);

  @override
  Widget build(BuildContext context) {
    final animacao = EntradaHome.of(context);
    if (animacao == null) return child;
    return AnimatedBuilder(
      animation: animacao,
      builder: (context, filho) {
        final t = _intervalo.transform(animacao.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (t - 1) * 24),
            child: filho,
          ),
        );
      },
      child: child,
    );
  }
}
