import 'dart:async';

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

  static const Key bonusHintKey = Key('bonus_hint');

  final GameSnapshot? resumeFrom;

  const GameForm({this.resumeFrom, super.key});

  @override
  State<GameForm> createState() => _GameFormState();
}

class _GameFormState extends State<GameForm> with WidgetsBindingObserver {
  late final GameCubit _cubit = context.read<GameCubit>();
  late final WasDropGame _game = WasDropGame(
    cubit: _cubit,
    settings: appLocator<SettingsService>().settings,
    resumeFrom: widget.resumeFrom,
  );
  late final ShakeDetector _shakeDetector =
      ShakeDetector(onShake: _onDeviceShake);
  final PremiumService _premium = appLocator<PremiumService>();
  Timer? _autosave;

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
    _premium.isPremium.removeListener(_onPremiumChanged);
    _autosave?.cancel();
    unawaited(_shakeDetector.stop());
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Купили премиум из paywall поверх игры — кнопки рекламы меняются.
  void _onPremiumChanged() => setState(() {});

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
    unawaited(_cubit.saveSnapshot(_game.captureBalls()));
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

    final bool isPremium = _premium.isPremium.value;
    _game.paused = state.status != GameStatus.playing || state.adBusy;

    return AppScaffold(
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
                const GameHud(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(25, 8, 25, 4),
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        _Jar(game: _game, theme: theme),
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
            if (state.status == GameStatus.paused)
              PauseOverlay(
                onResume: _cubit.resume,
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
                onRestart: () {
                  _cubit.restart();
                  _game.reset();
                },
                onMenu: () => context.goNamed('menu'),
                onContinueAd: _continue,
                onRemoveAds: () => context.pushNamed('premium'),
                canContinue: state.continues > 0,
                isPremium: isPremium,
                adBusy: state.adBusy,
                adUnavailable: state.adUnavailable,
              ),
          ],
        ),
      ),
    );
  }
}

/// Стакан: заливка и стенки — из темы (движок фон не рисует, так что
/// полупрозрачный стакан просвечивает). Холст лежит внутри обводки:
/// физическое дно = верх стенки, иначе нижние 5 px фруктов прячутся под ней.
class _Jar extends StatelessWidget {
  final WasDropGame game;
  final GameTheme theme;

  const _Jar({required this.game, required this.theme});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.jarFill,
        border: Border(
          left: BorderSide(color: theme.jarWall, width: AppDimens.jarWallWidth),
          right:
              BorderSide(color: theme.jarWall, width: AppDimens.jarWallWidth),
          bottom:
              BorderSide(color: theme.jarWall, width: AppDimens.jarWallWidth),
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppDimens.jarCornerRadius),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          left: AppDimens.jarWallWidth,
          right: AppDimens.jarWallWidth,
          bottom: AppDimens.jarWallWidth,
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(AppDimens.jarInnerCornerRadius),
          ),
          child: GameWidget<WasDropGame>(game: game),
        ),
      ),
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
