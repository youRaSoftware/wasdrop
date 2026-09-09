import 'dart:async';

import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../engine/splash_game.dart';

/// Сплеш — первый экран приложения: фрукты сыплются с неба и складываются
/// в кучу ([SplashGame]), поверх проявляется лого; через [duration] или по
/// тапу — меню. Без кубита: у экрана нет состояния, только таймер.
class SplashScreen extends StatefulWidget {
  static const Duration duration = Duration(milliseconds: 3600);
  static const Key skipKey = Key('splash_skip');

  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final SplashGame _game = SplashGame();
  Timer? _timer;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(SplashScreen.duration, _finish);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _finish() {
    if (_done || !mounted) return;
    _done = true;
    context.goNamed('menu');
  }

  @override
  Widget build(BuildContext context) {
    final GameTheme theme = AppThemeScope.of(context);

    return AppScaffold(
      body: GestureDetector(
        key: SplashScreen.skipKey,
        behavior: HitTestBehavior.opaque,
        onTap: _finish,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            GameWidget<SplashGame>(game: _game),
            SafeArea(
              child: Align(
                alignment: const Alignment(0, -0.55),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (BuildContext context, double t, Widget? child) {
                    return Opacity(
                      opacity: t,
                      child: Transform.translate(
                        offset: Offset(0, 18 * (1 - t)),
                        child: child,
                      ),
                    );
                  },
                  child: Text.rich(
                    TextSpan(
                      children: <InlineSpan>[
                        const TextSpan(text: 'Fruity '),
                        TextSpan(
                          text: 'Drop',
                          style:
                              AppFonts.title.copyWith(color: AppColors.accent),
                        ),
                      ],
                    ),
                    style: AppFonts.title.copyWith(color: theme.hudText),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
