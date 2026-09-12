import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../widgets/menu_fruit_pile.dart';

/// Меню (мокап, кадр 1): лого, плашка рекорда, ИГРАТЬ, звук / настройки над
/// живой кучей фруктов ([MenuFruitPile], выбрано 2026-09-12 вместо
/// статичного коллажа). Контент — колонка не шире
/// [MenuScreen.contentMaxWidth] по центру, на планшете лого крупнее.
/// Элементы появляются каскадом.
class MenuScreen extends StatefulWidget {
  static const double contentMaxWidth = 420;

  /// Ширина экрана, с которой лого растёт (планшеты).
  static const double wideScreen = 600;

  static const Key playButtonKey = Key('menu_play');
  static const Key newGameButtonKey = Key('menu_new_game');
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

  /// Сохранённая партия — если есть, ИГРАТЬ становится «Продолжить».
  GameSnapshot? _savedGame;

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
    final GameSnapshot? saved = await appLocator<GameRepository>().load();
    if (!mounted) return;
    setState(() {
      _bestScore = stats.bestScore;
      _savedGame = saved;
    });
  }

  Future<void> _startNewGame() async {
    await appLocator<GameRepository>().clear();
    if (!mounted) return;
    context.goNamed('game');
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

    final bool wide = MediaQuery.sizeOf(context).width >= MenuScreen.wideScreen;
    final TextStyle titleStyle =
        AppFonts.title.copyWith(fontSize: wide ? 64 : AppFonts.title.fontSize);

    return AppScaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // Живая куча фруктов под интерфейсом.
          FadeTransition(
            opacity: _step(0.2, 0.8),
            child: const MenuFruitPile(),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: MenuScreen.contentMaxWidth,
                ),
                child: Column(
                  children: <Widget>[
                    const Spacer(flex: 2),
                    _Reveal(
                      animation: _step(0, 0.55),
                      scaleFrom: 0.85,
                      // Одной строкой: на планшете лого шире колонки.
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text.rich(
                          TextSpan(
                            children: <InlineSpan>[
                              const TextSpan(text: 'Fruity '),
                              TextSpan(
                                text: 'Drop',
                                style: titleStyle.copyWith(
                                    color: AppColors.accent),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          style: titleStyle.copyWith(color: theme.hudText),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Reveal(
                      animation: _step(0.2, 0.7),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppColors.stroke, width: 2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const AppIcon(AppIcons.trophy, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              context.tr(
                                LocaleKeys.menu_best,
                                namedArgs: <String, String>{
                                  'score': '$_bestScore'
                                },
                              ),
                              style: AppFonts.button.copyWith(
                                fontSize: 17,
                                color: AppColors.secondaryText,
                                fontFeatures: const <FontFeature>[
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    _Reveal(
                      animation: _step(0.35, 0.9),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 60),
                        child: Column(
                          children: <Widget>[
                            SizedBox(
                              width: double.infinity,
                              child: PrimaryButton(
                                key: MenuScreen.playButtonKey,
                                label: context.tr(
                                  _savedGame == null
                                      ? LocaleKeys.menu_play
                                      : LocaleKeys.menu_continue,
                                ),
                                height: 64,
                                onPressed: () => context.goNamed(
                                  'game',
                                  extra: _savedGame,
                                ),
                              ),
                            ),
                            if (_savedGame != null) ...<Widget>[
                              const SizedBox(height: 6),
                              AppTextButton(
                                key: MenuScreen.newGameButtonKey,
                                label: context.tr(LocaleKeys.menu_newGame),
                                onPressed: _startNewGame,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    // Звук и настройки — сразу под кнопкой: низ экрана
                    // отдан фруктам.
                    const SizedBox(height: 20),
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
                    const Spacer(flex: 3),
                  ],
                ),
              ),
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
