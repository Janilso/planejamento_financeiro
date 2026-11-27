import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:planejamento_financeiro/theme/colors.dart';

import 'dart:math' as math;

import 'package:planejamento_financeiro/widgets/load/arc.dart';

class AppLoad extends StatefulWidget {
  final double size;
  final Color color;

  const AppLoad({super.key, this.size = 30, this.color = AppColors.white});

  @override
  State<AppLoad> createState() => _AppLoadState();
}

class _AppLoadState extends State<AppLoad> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    final double size = widget.size;
    final Color color = widget.color;
    final Color ringColor = AppColors.black.withAlpha(30);
    final double strokeWidth = size / 7;

    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (_, _) {
          final offsetTween =
              Tween<Offset>(begin: Offset(0, -size), end: Offset.zero).chain(
                CurveTween(
                  curve: const Interval(0.05, 0.4, curve: Curves.easeInCubic),
                ),
              );

          Offset offset = offsetTween.evaluate(_animationController);

          double evalDouble({
            required double from,
            required double to,
            required double begin,
            double end = 1.0,
          }) {
            final t = ((_animationController.value - begin) / (end - begin))
                .clamp(0.0, 1.0);
            return from + (to - from) * t;
          }

          return Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Arc.draw(
                strokeWidth: strokeWidth,
                size: size,
                color: ringColor,
                startAngle: math.pi / 2,
                endAngle: 2 * math.pi,
              ),
              Visibility(
                visible: _animationController.value <= 0.9,
                child: Transform.translate(
                  offset: offset,
                  child: Arc.draw(
                    strokeWidth: strokeWidth,
                    size: size,
                    color: color,
                    startAngle: -3 * math.pi / 2,
                    endAngle: evalDouble(
                      from: math.pi / (size * size),
                      to: math.pi / 1.13,
                      begin: 0.38,
                      end: 0.9,
                    ),
                  ),
                ),
              ),
              Visibility(
                visible: _animationController.value <= 0.9,
                child: Transform.translate(
                  offset: offset,
                  child: Arc.draw(
                    strokeWidth: strokeWidth,
                    size: size,
                    color: color,
                    startAngle: -3 * math.pi / 2,
                    endAngle: evalDouble(
                      from: math.pi / (size * size),
                      to: -math.pi / 1.13,
                      begin: 0.38,
                      end: 0.9,
                    ),
                  ),
                ),
              ),

              /// Right
              Visibility(
                visible: _animationController.value >= 0.9,
                child: Arc.draw(
                  strokeWidth: strokeWidth,
                  size: size,
                  color: color,
                  startAngle: -math.pi / 4,
                  endAngle: evalDouble(
                    from: -math.pi / 7.4,
                    to: -math.pi / 4,
                    begin: 0.9,
                    end: 0.96,
                  ),
                ),
              ),
              // Left
              Visibility(
                visible: _animationController.value >= 0.9,
                child: Arc.draw(
                  strokeWidth: strokeWidth,
                  size: size,
                  color: color,
                  startAngle: -3 * math.pi / 4,
                  endAngle: evalDouble(
                    from: math.pi / 7.4,
                    to: math.pi / 4,
                    begin: 0.9,
                    end: 0.96,
                  ),
                ),
              ),

              /// Right
              Visibility(
                visible: _animationController.value >= 0.9,
                child: Arc.draw(
                  strokeWidth: strokeWidth,
                  size: size,
                  color: color,
                  startAngle: -math.pi / 3.5,
                  endAngle: evalDouble(
                    from: math.pi / 1.273,
                    to: math.pi / 28,
                    begin: 0.9,
                  ),
                ),
              ),

              /// Left
              Visibility(
                visible: _animationController.value >= 0.9,
                child: Arc.draw(
                  strokeWidth: strokeWidth,
                  size: size,
                  color: color,
                  startAngle: math.pi / 0.778,
                  endAngle: evalDouble(
                    from: -math.pi / 1.273,
                    to: -math.pi / 27,
                    begin: 0.9,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
