import 'dart:math' as math;

import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

const _largura = 168.0;
const _altura = 117.0;
// Altura do viewBox do SVG (docs/assets/logo.svg); as faixas do texto usam essa
// unidade.
const _alturaSvg = 118.0;

// Logo da splash em partes (assets/images/logo/, recortadas de
// docs/assets/logo.svg): as três folhas chegam da esquerda, uma depois da
// outra (a de cima traz o furo do $ e as linhas de velocidade), e as duas
// linhas do texto sobem de baixo da própria faixa. Termina parado em 1,5 s,
// antes da troca de tela; com as animações desligadas no sistema, já começa
// parado.
//
// No login, `balancar` deixa as três folhas indo e voltando até 3 dp na
// horizontal, sem parar, cada uma um pouco atrasada em relação à outra. Sem
// `entrada`, o logo já começa montado (quando chega voando da splash).
class LogoAnimado extends StatefulWidget {
  const LogoAnimado({
    super.key,
    this.entrada = true,
    this.balancar = false,
    this.saida,
  });

  final bool entrada;
  final bool balancar;

  // Saída para a home (splash, usuário logado): de 0 a 1, as folhas saem
  // voando pela borda direita da tela, uma depois da outra, e o texto desce
  // 16 dp e some.
  final Animation<double>? saida;

  static const duracao = Duration(milliseconds: 1500);
  static const cicloDoBalanco = Duration(milliseconds: 2000);
  static const amplitude = 3.0;

  @override
  State<LogoAnimado> createState() => _LogoAnimadoState();
}

class _LogoAnimadoState extends State<LogoAnimado>
    with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: LogoAnimado.duracao,
  );
  late final AnimationController _balanco = AnimationController(
    vsync: this,
    duration: LogoAnimado.cicloDoBalanco,
  );
  // Rampa do balanço: a amplitude cresce de 0 a 1 ao começar, para as folhas
  // não pularem; parada, deixa as folhas no lugar.
  late final AnimationController _rampa = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  bool _iniciado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciado) return;
    _iniciado = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      return;
    }
    if (!widget.entrada) {
      _controller.value = 1;
      _balancar();
      return;
    }
    _controller.forward().then((_) => _balancar());
  }

  void _balancar() {
    if (!widget.balancar || !mounted) return;
    _balanco.repeat();
    _rampa.forward();
  }

  @override
  void dispose() {
    _rampa.dispose();
    _balanco.dispose();
    _controller.dispose();
    super.dispose();
  }

  // Folha entrando de fora da tela, pela esquerda; depois, no login, balança
  // com o atraso `fase` (fração do ciclo).
  Widget _folha(String nome, double inicio, double fim, double fase) =>
      SlideTransition(
        position: Tween(begin: const Offset(-2.2, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(inicio, fim, curve: Curves.easeOutCubic),
          ),
        ),
        child: AnimatedBuilder(
          animation: Listenable.merge([_balanco, _rampa]),
          builder: (context, child) => Transform.translate(
            offset: Offset(
              LogoAnimado.amplitude *
                  Curves.easeInOut.transform(_rampa.value) *
                  math.sin(2 * math.pi * (_balanco.value - fase)),
              0,
            ),
            child: child,
          ),
          child: _parte(nome),
        ),
      );

  // Linha do texto subindo de baixo da própria faixa (topo e base em unidades
  // do viewBox): começa escondida, sem aparecer cortada.
  Widget _texto(String nome, double topo, double base, double inicio) {
    final subida = CurvedAnimation(
      parent: _controller,
      curve: Interval(inicio, inicio + 0.25, curve: Curves.easeOutCubic),
    );
    return ClipRect(
      clipper: _Faixa(topo / _alturaSvg, base / _alturaSvg),
      child: AnimatedBuilder(
        animation: subida,
        builder: (context, child) => Transform.translate(
          offset: Offset(
            0,
            (1 - subida.value) * (base - topo) * _altura / _alturaSvg,
          ),
          child: child,
        ),
        child: _parte(nome),
      ),
    );
  }

  Widget _parte(String nome) => SvgPicture.asset(
    'assets/images/logo/$nome.svg',
    width: _largura,
    height: _altura,
  );

  // Folhas: andam para a direita até sair da tela (a partir da borda esquerda
  // do logo, a largura da tela basta). Texto: desce 16 dp e some.
  Widget _sai(Widget filho, double inicio, double fim, {required bool folha}) {
    final saida = widget.saida;
    if (saida == null) return filho;
    final intervalo = Interval(inicio, fim, curve: Curves.easeInCubic);
    final largura = MediaQuery.sizeOf(context).width;
    return AnimatedBuilder(
      animation: saida,
      builder: (context, c) {
        final t = intervalo.transform(saida.value);
        return folha
            ? Transform.translate(offset: Offset(t * largura, 0), child: c)
            : Opacity(
                opacity: 1 - t,
                child: Transform.translate(offset: Offset(0, t * 16), child: c),
              );
      },
      child: filho,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Center: na splash o logo fica numa ListView, que força a largura da tela;
    // sem ele o SizedBox esticaria e as partes ficariam encostadas à esquerda.
    return Center(
      child: SizedBox(
        width: _largura,
        height: _altura,
        // As folhas saem da caixa do logo ao voar: sem recorte.
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _sai(_folha('folha-3', 0.0, 0.35, 0.24), 0.3, 0.9, folha: true),
            _sai(_folha('folha-2', 0.1, 0.45, 0.12), 0.15, 0.75, folha: true),
            _sai(_folha('folha-1', 0.2, 0.55, 0.0), 0.0, 0.6, folha: true),
            _sai(_texto('texto-1', 84, 101, 0.5), 0.0, 0.5, folha: false),
            _sai(_texto('texto-2', 104, 118, 0.62), 0.0, 0.5, folha: false),
          ],
        ),
      ),
    );
  }
}

class _Faixa extends CustomClipper<Rect> {
  const _Faixa(this.topo, this.base);

  final double topo;
  final double base;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, size.height * topo, size.width, size.height * base);

  @override
  bool shouldReclip(_Faixa oldClipper) =>
      oldClipper.topo != topo || oldClipper.base != base;
}
