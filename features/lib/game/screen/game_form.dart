import 'dart:async';
import 'dart:math' as math;

import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../cubit/game_cubit.dart';
import '../engine/wasdrop_game.dart';
import '../widgets/bonus_bar.dart';
import '../widgets/game_hud.dart';
import '../widgets/game_over_overlay.dart';
import '../widgets/garden_intro_overlay.dart';
import '../widgets/jar_painter.dart';
import '../widgets/mission_toast.dart';
import '../widgets/missions_overlay.dart';
import '../widgets/missions_panel.dart';
import '../widgets/onboarding_overlay.dart';
import '../widgets/pause_overlay.dart';

/// Игровая форма: HUD, стакан с движком, полоса бонусов, оверлеи паузы и
/// проигрыша. Сохраняет партию (`GameCubit.saveSnapshot`) при уходе
/// приложения в фон, раз в [autosaveInterval] и перед выходом в меню.
///
/// Бонусы: кнопка взводит бонус и над стаканом появляется подсказка;
/// встряску срабатывает [ShakeDetector] (акселерометр), бомбочка и
/// увеличение ждут тапа по фрукту в движке.
class GameForm extends StatefulWidget {
  static const Duration autosaveInterval = Duration(seconds: 2);

  /// Игровая колонка (HUD, стакан, бонусы) не шире телефона и стакан не
  /// выше [jarMaxAspect] ширин: на планшете партия идёт как на iPhone, а не
  /// в широком низком стакане с фруктами в 2.5 раза крупнее (2026-09-13).
  static const double contentMaxWidth = 760;
  static const double jarMaxAspect = 1.7;

  /// Ниже этой высоты экрана панель заказов — компактная (кольца).
  static const double compactMissionsHeight = 700;

  static const Key bonusHintKey = Key('bonus_hint');

  final GameSnapshot? resumeFrom;

  const GameForm({this.resumeFrom, super.key});

  @override
  State<GameForm> createState() => _GameFormState();
}

class _GameFormState extends State<GameForm> with WidgetsBindingObserver {
  late final GameCubit _cubit = context.read<GameCubit>();
  // Восстановленная партия играется в своём стакане, новая — в выбранном
  // в настройках (меню / пауза → «Стаканы»).
  late final WasDropGame _game = WasDropGame(
    cubit: _cubit,
    settings: appLocator<SettingsService>().settings,
    resumeFrom: widget.resumeFrom,
    jarShape: JarShapes.byId(
      widget.resumeFrom?.jarId ?? appLocator<SettingsService>().value.jarId,
    ),
  );
  late final ShakeDetector _shakeDetector =
      ShakeDetector(onShake: _onDeviceShake);
  final PremiumService _premium = appLocator<PremiumService>();
  Timer? _autosave;

  /// Всплывашка «заказ выполнен» (одна за раз, в Overlay над стаканом).
  OverlayEntry? _toast;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _autosave = Timer.periodic(GameForm.autosaveInterval, (_) => _save());
    _shakeDetector.start();
    _premium.isPremium.addListener(_onPremiumChanged);
  }

  @override
  void dispose() {
    _toast?.remove();
    _premium.isPremium.removeListener(_onPremiumChanged);
    _autosave?.cancel();
    unawaited(_shakeDetector.stop());
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Купили премиум из paywall поверх игры — кнопки рекламы меняются.
  void _onPremiumChanged() => setState(() {});

  /// Всплывашка над стаканом (BlocListener на номер выполнения заказа).
  void _showToast(Mission mission) {
    _toast?.remove();
    final Rect jar = _jarRect();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (BuildContext context) => Positioned(
        left: jar.left,
        width: jar.width,
        top: jar.top + jar.height * 0.22,
        child: Center(
          child: MissionToast(
            mission: mission,
            onDone: () {
              if (_toast == entry) _toast = null;
              entry.remove();
            },
          ),
        ),
      ),
    );
    _toast = entry;
    Overlay.of(context).insert(entry);
  }

  Rect _jarRect() {
    final RenderObject? box = _jarKey.currentContext?.findRenderObject();
    if (box is RenderBox && box.hasSize) {
      return box.localToGlobal(Offset.zero) & box.size;
    }
    final Size size = MediaQuery.sizeOf(context);
    return Offset.zero & size;
  }

  final GlobalKey _jarKey = GlobalKey();

  /// Сколько звёзд до ближайшего закрытого стакана (null — все открыты).
  int? _starsToNextJar() {
    final int stars = _cubit.totalStars;
    final Iterable<int> locked = JarShapes.all
        .where((JarShape j) => !j.comingSoon && j.starsToUnlock > stars)
        .map((JarShape j) => j.starsToUnlock - stars);
    return locked.isEmpty ? null : locked.reduce(math.min);
  }

  /// Раскладка кнопок под монетизацию (`AppConfig.monetizationEnabled`).
  static const bool _monetization = AppConfig.monetizationEnabled;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _save();
    }
  }

  void _save() {
    if (!_game.isLoaded || _cubit.isClosed) return;
    unawaited(
      _cubit.saveSnapshot(_game.captureBalls(), jarId: _game.jarShape.id),
    );
  }

  /// «Продолжить» после проигрыша: кубит показывает ролик (или пропускает
  /// его премиуму); если продолжение выдано — движок снимает верхний слой,
  /// и только потом партия возвращается в игру.
  Future<void> _continue() async {
    if (!await _cubit.requestContinue()) return;
    if (!mounted || !_game.isLoaded) return;
    _game.clearTopLayer();
    _cubit.resumeAfterContinue();
  }

  /// Телефон встряхнули: срабатывает только при взведённой встряске
  /// (кубит проверяет заряды и статус), движок — кулдаун.
  void _onDeviceShake() {
    if (!_game.isLoaded || !_game.canShake) return;
    if (!_cubit.useShake()) return;
    _game.shake();
  }

  @override
  Widget build(BuildContext context) {
    final GameState state = context.watch<GameCubit>().state;
    final GameTheme theme = AppThemeScope.of(context);
    final Bonus? armed = state.armed;

    // Без рекламы: премиум или монетизация выключена (релиз 1.0).
    final bool isPremium = _cubit.adFree;
    _game.paused = state.status != GameStatus.playing ||
        state.adBusy ||
        state.onboardingOpen ||
        state.gardenIntroOpen;
    // Низкий экран (iPhone SE): панель заказов кольцами в одну строку.
    final bool compactMissions =
        MediaQuery.sizeOf(context).height < GameForm.compactMissionsHeight;

    return BlocListener<GameCubit, GameState>(
      listenWhen: (GameState a, GameState b) =>
          a.completedCount != b.completedCount && b.completedMission != null,
      listener: (BuildContext context, GameState s) =>
          _showToast(s.completedMission!),
      child: AppScaffold(
        body: SafeArea(
          child: Stack(
            children: <Widget>[
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: GameForm.contentMaxWidth,
                  ),
                  child: Column(
                    children: <Widget>[
                      const GameHud(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                        child: MissionsPanel(
                          compact: compactMissions,
                          onTap: _cubit.showMissions,
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxHeight: GameForm.contentMaxWidth *
                                  GameForm.jarMaxAspect,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(25, 8, 25, 4),
                              child: Stack(
                                fit: StackFit.expand,
                                children: <Widget>[
                                  KeyedSubtree(
                                    key: _jarKey,
                                    child: _Jar(game: _game, theme: theme),
                                  ),
                                  if (armed != null)
                                    Positioned(
                                      top: 12,
                                      left: 8,
                                      right: 8,
                                      child: IgnorePointer(
                                        child: Center(
                                          child: _BonusHint(
                                            key: GameForm.bonusHintKey,
                                            bonus: armed,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                        child: BonusBar(
                          onArm: _cubit.armBonus,
                          onRefill: _cubit.requestRefill,
                          isPremium: isPremium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (state.status == GameStatus.paused && state.missionsOpen)
                MissionsOverlay(
                  missions: state.missions,
                  stars: _cubit.totalStars,
                  done: _cubit.totalMissionsDone,
                  onClose: _cubit.hideMissions,
                )
              else if (state.status == GameStatus.paused)
                PauseOverlay(
                  onResume: _cubit.resume,
                  onMissions: _cubit.showMissions,
                  onRestart: () {
                    _cubit.restart();
                    _game.reset();
                  },
                  onMenu: () {
                    _save();
                    context.goNamed('menu');
                  },
                ),
              if (state.status == GameStatus.gameOver)
                GameOverOverlay(
                  score: state.score,
                  bestScore: state.bestScore,
                  isNewRecord: state.isNewRecord,
                  starsEarned: state.starsEarned,
                  starsToNextJar: _starsToNextJar(),
                  onRestart: () {
                    _cubit.restart();
                    _game.reset();
                  },
                  onMenu: () => context.goNamed('menu'),
                  onContinueAd: _continue,
                  onRemoveAds: () => context.pushNamed('premium'),
                  canContinue: state.canContinue,
                  canRestart: state.mode != GameMode.daily,
                  mode: state.mode,
                  timeUp: state.secondsLeft == 0,
                  isPremium: isPremium,
                  showRemoveAds: _monetization && !isPremium,
                  adBusy: state.adBusy,
                  adUnavailable: state.adUnavailable,
                ),
              if (state.onboardingOpen)
                OnboardingOverlay(onDone: _cubit.finishOnboarding)
              else if (state.gardenIntroOpen)
                GardenIntroOverlay(onDone: _cubit.finishGardenIntro),
            ],
          ),
        ),
      ),
    );
  }
}

/// Стакан по контуру `JarShape`: заливка и стенка — из темы (движок фон не
/// рисует, так что полупрозрачный стакан просвечивает), рисует `JarPainter`.
/// Холст лежит внутри стенки (физическое дно = верх стенки, иначе нижние
/// 5 px фруктов прячутся под ней) и обрезан по контуру `JarClipper`.
class _Jar extends StatelessWidget {
  final WasDropGame game;
  final GameTheme theme;

  const _Jar({required this.game, required this.theme});

  @override
  Widget build(BuildContext context) {
    // Заливка под холстом, стенка поверх него: обрезать холст по контуру
    // (ClipPath) нельзя — клип режет и хит-тест, и тап рядом с узким горлом
    // вазы не доходил бы до игры. Фрукты за контур не выходят (физика), а
    // край стакана перекрывает стенка.
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        CustomPaint(
          painter: JarPainter(
            shape: game.jarShape,
            fill: theme.jarFill,
            wall: theme.jarWall,
            layer: JarLayer.fill,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
            left: AppDimens.jarWallWidth,
            right: AppDimens.jarWallWidth,
            bottom: AppDimens.jarWallWidth,
          ),
          child: GameWidget<WasDropGame>(game: game),
        ),
        IgnorePointer(
          child: CustomPaint(
            painter: JarPainter(
              shape: game.jarShape,
              fill: theme.jarFill,
              wall: theme.jarWall,
              layer: JarLayer.wall,
            ),
          ),
        ),
      ],
    );
  }
}

/// Подсказка взведённого бонуса — пилюля на светлой подложке у верха
/// стакана: у встряски с картинкой телефона, у остальных только текст.
class _BonusHint extends StatelessWidget {
  final Bonus bonus;

  const _BonusHint({required this.bonus, super.key});

  @override
  Widget build(BuildContext context) {
    final String text = switch (bonus) {
      Bonus.shake => context.tr(LocaleKeys.bonus_shakeHint),
      Bonus.bomb => context.tr(LocaleKeys.bonus_pickFruit),
      Bonus.upgrade => context.tr(LocaleKeys.bonus_pickUpgrade),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.stroke, width: 2),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.panelShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (bonus == Bonus.shake) ...<Widget>[
            const Image(
              image: AssetImage(
                'assets/images/fx/shake_hint.png',
                package: 'features',
              ),
              width: 44,
              height: 44,
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: AppFonts.button.copyWith(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
