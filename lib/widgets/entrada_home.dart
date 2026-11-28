import 'package:material_ui/material_ui.dart';

// A animação da rota que abriu a home com entrada animada (nula nas outras
// entradas e com as animações desligadas): as abas e o resumo descem. Vindo do
// login, o botão vira o cartão; vindo da splash, o cartão sobe (`cartaoSobe`).
class EntradaHome extends InheritedWidget {
  const EntradaHome({
    super.key,
    this.animacao,
    this.cartaoSobe = false,
    required super.child,
  });

  final Animation<double>? animacao;
  final bool cartaoSobe;

  static EntradaHome? _de(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<EntradaHome>();

  static Animation<double>? of(BuildContext context) => _de(context)?.animacao;

  @override
  bool updateShouldNotify(EntradaHome old) =>
      animacao != old.animacao || cartaoSobe != old.cartaoSobe;
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

// O cartão sobe 40 dp e aparece entre 0,2 e 1,0 da rota (entrada vinda da
// splash); nas outras entradas, não faz nada.
class EntradaSubindo extends StatelessWidget {
  const EntradaSubindo({super.key, required this.child});

  final Widget child;

  static const _intervalo = Interval(0.2, 1.0, curve: Curves.easeOutCubic);

  @override
  Widget build(BuildContext context) {
    final entrada = EntradaHome._de(context);
    final animacao = entrada?.animacao;
    if (animacao == null || !entrada!.cartaoSobe) return child;
    return AnimatedBuilder(
      animation: animacao,
      builder: (context, filho) {
        final t = _intervalo.transform(animacao.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 40),
            child: filho,
          ),
        );
      },
      child: child,
    );
  }
}
