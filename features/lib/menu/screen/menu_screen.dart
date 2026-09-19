import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../../jars/widgets/jar_label.dart';

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
  static const Key jarButtonKey = Key('menu_jar');
  static const Key timedButtonKey = Key('menu_timed');
  static const Key dailyButtonKey = Key('menu_daily');
  static const Key gardenButtonKey = Key('menu_garden');
  static const Key settingsButtonKey = Key('menu_settings');
  static const Key soundButtonKey = Key('menu_sound');
  static const Key leaderboardButtonKey = Key('menu_leaderboard');

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
  int _bestTimed = 0;
  int _bestDaily = 0;
  int _bestGarden = 0;

  /// Сохранённая партия «Сада чудес» (карточка режима продолжает её).
  GameSnapshot? _savedGarden;
  bool _gardenIsNew = true;

  /// Сегодняшний вызов уже сыгран — кнопка показывает счёт и не активна.
  int? _dailyToday;

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
    final GameSnapshot? savedGarden =
        await appLocator<GameRepository>().load(mode: GameMode.garden);
    final ProgressModel progress =
        await appLocator<ProgressRepository>().getProgress();
    if (!mounted) return;
    setState(() {
      _bestScore = stats.bestScore;
      _bestTimed = stats.bestTimed;
      _bestDaily = stats.bestDaily;
      _bestGarden = stats.bestGarden;
      _savedGame = saved;
      _savedGarden = savedGarden;
      _gardenIsNew = !progress.gardenIntroDone;
      _dailyToday =
          progress.dailyPlayed(dailySeed()) ? progress.dailyScore : null;
    });
  }

  Future<void> _startNewGame() async {
    await appLocator<GameRepository>().clear();
    if (!mounted) return;
    context.goNamed('game');
  }

  // Как и классика — через `go`: игра возвращается в меню `goNamed('menu')`,
  // и свежий экран заново читает рекорды и зачёт дня.
  void _startMode(GameMode mode) => context.goNamed(
        'game',
        extra: GameLaunch(
          mode: mode,
          // «Сад чудес» продолжает свою сохранённую партию.
          resumeFrom: mode == GameMode.garden ? _savedGarden : null,
        ),
      );

  Animation<double> _step(double from, double to) {
    return CurvedAnimation(
      parent: _intro,
      curve: Interval(from, to, curve: Curves.easeOutCubic),
    );
  }

  @override
  Widget build(BuildContext context) {
    final SettingsService settings = appLocator<SettingsService>();
    final GameCenterService gameCenter = appLocator<GameCenterService>();
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
                                  extra: _savedGame == null
                                      ? const GameLaunch()
                                      : GameLaunch.resume(_savedGame!),
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
                            const SizedBox(height: 10),
                            // Режимы сеткой 2×2: «На время», «Вызов дня»
                            // (один зачёт в день — после него кнопка
                            // показывает счёт), «Сад чудес» (акцент и NEW до
                            // первого входа) и выбор стакана.
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: _ModeButton(
                                    key: MenuScreen.timedButtonKey,
                                    label: context.tr(LocaleKeys.menu_timed),
                                    sub: _bestTimed > 0
                                        ? context.tr(
                                            LocaleKeys.menu_best,
                                            namedArgs: <String, String>{
                                              'score': '$_bestTimed',
                                            },
                                          )
                                        : null,
                                    onPressed: () => _startMode(GameMode.timed),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _ModeButton(
                                    key: MenuScreen.dailyButtonKey,
                                    label: context.tr(LocaleKeys.menu_daily),
                                    sub: _dailyToday != null
                                        ? context.tr(
                                            LocaleKeys.menu_dailyDone,
                                            namedArgs: <String, String>{
                                              'score': '$_dailyToday',
                                            },
                                          )
                                        : _bestDaily > 0
                                            ? context.tr(
                                                LocaleKeys.menu_best,
                                                namedArgs: <String, String>{
                                                  'score': '$_bestDaily',
                                                },
                                              )
                                            : null,
                                    onPressed: _dailyToday != null
                                        ? null
                                        : () => _startMode(GameMode.daily),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ValueListenableBuilder<SettingsModel>(
                              valueListenable: settings.settings,
                              builder: (BuildContext context,
                                  SettingsModel value, Widget? _) {
                                final JarShape jar =
                                    JarShapes.byId(value.jarId);
                                return Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: _ModeButton(
                                        key: MenuScreen.gardenButtonKey,
                                        label:
                                            context.tr(LocaleKeys.menu_garden),
                                        sub: _savedGarden != null
                                            ? context
                                                .tr(LocaleKeys.menu_continue)
                                            : _bestGarden > 0
                                                ? context.tr(
                                                    LocaleKeys.menu_best,
                                                    namedArgs: <String, String>{
                                                      'score': '$_bestGarden',
                                                    },
                                                  )
                                                : null,
                                        accent: AppColors.garden,
                                        badge: _gardenIsNew
                                            ? context.tr(LocaleKeys.menu_new)
                                            : null,
                                        onPressed: () =>
                                            _startMode(GameMode.garden),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _ModeButton(
                                        key: MenuScreen.jarButtonKey,
                                        label: context.tr(LocaleKeys.menu_jars),
                                        sub: jarLabel(context, jar),
                                        onPressed: () =>
                                            context.pushNamed('jars'),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
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
                          // Game Center — только после входа.
                          ValueListenableBuilder<bool>(
                            valueListenable: gameCenter.isSignedIn,
                            builder: (BuildContext context, bool signedIn,
                                Widget? _) {
                              if (!signedIn) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(left: 16),
                                child: IconCircleButton(
                                  key: MenuScreen.leaderboardButtonKey,
                                  onPressed: gameCenter.showLeaderboards,
                                  child: const AppIcon(AppIcons.trophy),
                                ),
                              );
                            },
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

/// Кнопка режима в меню: название и подпись (рекорд или сегодняшний счёт);
/// без [onPressed] — приглушена (вызов дня уже сыгран).
class _ModeButton extends StatelessWidget {
  final String label;
  final String? sub;
  final VoidCallback? onPressed;

  /// Цвет рамки (акцент режима) и бейдж в углу («NEW»).
  final Color? accent;
  final String? badge;

  const _ModeButton({
    required this.label,
    required this.onPressed,
    this.sub,
    this.accent,
    this.badge,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;
    return AppPressable(
      onPressed: onPressed,
      builder: (BuildContext context, double pressed, Widget? _) {
        final Widget card = Container(
          height: 56,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
            border: Border.all(color: accent ?? AppColors.stroke, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Длинные названия (немецкий, японский) ужимаются, не режутся.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: AppFonts.button.copyWith(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (sub != null) ...<Widget>[
                const SizedBox(height: 2),
                Text(
                  sub!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.best.copyWith(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ],
          ),
        );
        return Opacity(
          opacity: enabled ? 1 - 0.3 * pressed : 0.55,
          child: badge == null
              ? card
              : Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    card,
                    Positioned(
                      top: -8,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: accent ?? AppColors.accent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge!,
                          style: AppFonts.best.copyWith(
                            fontSize: 9,
                            color: AppColors.surface,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
