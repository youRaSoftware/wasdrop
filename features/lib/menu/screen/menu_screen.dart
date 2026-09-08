import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../../game/engine/fruit_assets.dart';

/// Меню (мокап, кадр 1): лого, плашка рекорда, ИГРАТЬ, звук / настройки и
/// декоративные шары по краям. Элементы появляются каскадом.
class MenuScreen extends StatefulWidget {
  static const Key settingsButtonKey = Key('menu_settings');
  static const Key soundButtonKey = Key('menu_sound');

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
    final SettingsService settings = appLocator<SettingsService>();
    final GameTheme theme = AppThemeScope.of(context);

    return AppScaffold(
      body: Stack(
        children: <Widget>[
          // Декоративные шары по краям.
          Align(
            alignment: const Alignment(-1.25, -0.55),
            child: _Reveal(
              animation: _step(0.3, 0.9),
              child: BallView(
                tier: BallTier.t6,
                diameter: 88,
                image: FruitAssets.idle(BallTier.t6),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(1.3, -0.1),
            child: _Reveal(
              animation: _step(0.4, 1),
              child: BallView(
                tier: BallTier.t8,
                diameter: 112,
                image: FruitAssets.idle(BallTier.t8),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(-1.05, 0.45),
            child: _Reveal(
              animation: _step(0.5, 1),
              child: BallView(
                tier: BallTier.t3,
                diameter: 56,
                image: FruitAssets.idle(BallTier.t3),
              ),
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
                    style: AppFonts.title.copyWith(color: theme.hudText),
                  ),
                ),
                const SizedBox(height: 16),
                _Reveal(
                  animation: _step(0.2, 0.7),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.stroke, width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const AppIcon(AppIcons.trophy, size: 16),
                        const SizedBox(width: 6),
                        Text('рекорд $_bestScore', style: AppFonts.best),
                      ],
                    ),
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
                        valueListenable: settings.settings,
                        builder: (BuildContext context, SettingsModel value,
                            Widget? _) {
                          return IconCircleButton(
                            key: MenuScreen.soundButtonKey,
                            onPressed: () =>
                                settings.setSoundOn(!value.soundOn),
                            child: AppIcon(
                              value.soundOn
                                  ? AppIcons.soundOn
                                  : AppIcons.soundOff,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      IconCircleButton(
                        key: MenuScreen.settingsButtonKey,
                        onPressed: () async {
                          await context.pushNamed('settings');
                          // Рекорд могли сбросить в настройках.
                          _loadStats();
                        },
                        child: const AppIcon(AppIcons.settings),
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
