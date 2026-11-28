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
class LogoAnimado extends StatefulWidget {
  const LogoAnimado({super.key});

  static const duracao = Duration(milliseconds: 1500);

  @override
  State<LogoAnimado> createState() => _LogoAnimadoState();
}

class _LogoAnimadoState extends State<LogoAnimado>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: LogoAnimado.duracao,
  );
  bool _iniciado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciado) return;
    _iniciado = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Folha entrando de fora da tela, pela esquerda.
  Widget _folha(String nome, double inicio, double fim) => SlideTransition(
    position: Tween(begin: const Offset(-2.2, 0), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(inicio, fim, curve: Curves.easeOutCubic),
      ),
    ),
    child: _parte(nome),
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

  @override
  Widget build(BuildContext context) {
    // Center: na splash o logo fica numa ListView, que força a largura da tela;
    // sem ele o SizedBox esticaria e as partes ficariam encostadas à esquerda.
    return Center(
      child: SizedBox(
        width: _largura,
        height: _altura,
        child: Stack(
          children: [
            _folha('folha-3', 0.0, 0.35),
            _folha('folha-2', 0.1, 0.45),
            _folha('folha-1', 0.2, 0.55),
            _texto('texto-1', 84, 101, 0.5),
            _texto('texto-2', 104, 118, 0.62),
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
