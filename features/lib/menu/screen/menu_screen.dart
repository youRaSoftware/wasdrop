import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

/// Меню (мокап, кадр 1): лого, плашка рекорда, ИГРАТЬ, 🔊 / ⚙️ и
/// декоративные шары по краям. Элементы появляются каскадом.
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..forward();

  int _bestScore = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final GameStatsModel stats = await appLocator<StatsRepository>().getStats();
    if (mounted) setState(() => _bestScore = stats.bestScore);
  }

  Animation<double> _step(double from, double to) {
    return CurvedAnimation(
      parent: _intro,
      curve: Interval(from, to, curve: Curves.easeOutCubic),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AudioService audio = appLocator<AudioService>();

    return AppScaffold(
      body: Stack(
        children: <Widget>[
          // Декоративные шары по краям.
          Align(
            alignment: const Alignment(-1.25, -0.55),
            child: _Reveal(
              animation: _step(0.3, 0.9),
              child: const BallView(tier: BallTier.t6, diameter: 88),
            ),
          ),
          Align(
            alignment: const Alignment(1.3, -0.1),
            child: _Reveal(
              animation: _step(0.4, 1),
              child: const BallView(tier: BallTier.t8, diameter: 112),
            ),
          ),
          Align(
            alignment: const Alignment(-1.05, 0.45),
            child: _Reveal(
              animation: _step(0.5, 1),
              child: const BallView(tier: BallTier.t3, diameter: 56),
            ),
          ),
          SafeArea(
            child: Column(
              children: <Widget>[
                const Spacer(flex: 2),
                _Reveal(
                  animation: _step(0, 0.55),
                  scaleFrom: 0.85,
                  child: Text.rich(
                    TextSpan(
                      children: <InlineSpan>[
                        const TextSpan(text: 'Was'),
                        TextSpan(
                          text: 'Drop',
                          style:
                              AppFonts.title.copyWith(color: AppColors.accent),
                        ),
                      ],
                    ),
                    style: AppFonts.title,
                  ),
                ),
                const SizedBox(height: 16),
                _Reveal(
                  animation: _step(0.2, 0.7),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.stroke, width: 2),
                    ),
                    child: Text('🏆 рекорд $_bestScore', style: AppFonts.best),
                  ),
                ),
                const Spacer(),
                _Reveal(
                  animation: _step(0.35, 0.9),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 60),
                    child: SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        label: 'ИГРАТЬ',
                        height: 64,
                        onPressed: () => context.goNamed('game'),
                      ),
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                _Reveal(
                  animation: _step(0.55, 1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ValueListenableBuilder<SettingsModel>(
                        valueListenable: audio.settings,
                        builder: (BuildContext context, SettingsModel settings,
                            Widget? _) {
                          return IconCircleButton(
                            onPressed: () =>
                                audio.setSoundOn(!settings.soundOn),
                            child: Text(
                              settings.soundOn ? '🔊' : '🔇',
                              style: const TextStyle(fontSize: 20),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      IconCircleButton(
                        onPressed: () {
                          // TODO: экран настроек (Фаза 3).
                        },
                        child: const Text('⚙️', style: TextStyle(fontSize: 20)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Появление элемента меню: проявляется, всплывает снизу и (опционально)
/// вырастает из [scaleFrom].
class _Reveal extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  final double scaleFrom;

  const _Reveal({
    required this.animation,
    required this.child,
    this.scaleFrom = 1,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.18),
          end: Offset.zero,
        ).animate(animation),
        child: ScaleTransition(
          scale: Tween<double>(begin: scaleFrom, end: 1).animate(animation),
          child: child,
        ),
      ),
    );
  }
}
