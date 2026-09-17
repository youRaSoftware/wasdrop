import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../engine/fruit_assets.dart';

/// «Как играть»: три шага (бросай → сливай → бонусы и заказы) с картинками
/// из спрайтов, точки, «Дальше» / «Играть!» и «Пропустить». Показывается
/// при первом запуске поверх игры и из настроек.
class OnboardingOverlay extends StatefulWidget {
  static const Key nextKey = Key('onboarding_next');
  static const Key skipKey = Key('onboarding_skip');

  final VoidCallback onDone;

  const OnboardingOverlay({required this.onDone, super.key});

  @override
  State<OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends State<OnboardingOverlay> {
  static const int steps = 3;
  final PageController _pages = PageController();
  int _step = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next() {
    if (_step >= steps - 1) {
      widget.onDone();
      return;
    }
    _pages.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool last = _step == steps - 1;
    return AppOverlay(
      width: 300,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            height: 250,
            child: PageView(
              controller: _pages,
              onPageChanged: (int i) => setState(() => _step = i),
              children: const <Widget>[
                _Step(
                  titleKey: LocaleKeys.onboarding_step1Title,
                  textKey: LocaleKeys.onboarding_step1,
                  art: _DropArt(),
                ),
                _Step(
                  titleKey: LocaleKeys.onboarding_step2Title,
                  textKey: LocaleKeys.onboarding_step2,
                  art: _MergeArt(),
                ),
                _Step(
                  titleKey: LocaleKeys.onboarding_step3Title,
                  textKey: LocaleKeys.onboarding_step3,
                  art: _BonusArt(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              for (int i = 0; i < steps; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _step ? 18 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: i == _step ? AppColors.accent : AppColors.stroke,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            key: OnboardingOverlay.nextKey,
            label: context.tr(
              last ? LocaleKeys.onboarding_start : LocaleKeys.onboarding_next,
            ),
            onPressed: _next,
          ),
          if (!last) ...<Widget>[
            const SizedBox(height: 2),
            AppTextButton(
              key: OnboardingOverlay.skipKey,
              label: context.tr(LocaleKeys.onboarding_skip),
              onPressed: widget.onDone,
            ),
          ],
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String titleKey;
  final String textKey;
  final Widget art;

  const _Step({
    required this.titleKey,
    required this.textKey,
    required this.art,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SizedBox(height: 110, child: Center(child: art)),
        const SizedBox(height: 12),
        Text(
          context.tr(titleKey),
          textAlign: TextAlign.center,
          style: AppFonts.overlayTitle.copyWith(fontSize: 17),
        ),
        const SizedBox(height: 8),
        Text(
          context.tr(textKey),
          textAlign: TextAlign.center,
          style: AppFonts.best.copyWith(
            fontSize: 13,
            height: 1.35,
            color: AppColors.textSecondary,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

Widget _fruit(BallTier tier, double d) =>
    BallView(tier: tier, diameter: d, image: FruitAssets.idle(tier));

/// Шаг 1: фрукт над пунктиром прицела и «стаканом».
class _DropArt extends StatelessWidget {
  const _DropArt();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _fruit(BallTier.t3, 44),
        const SizedBox(height: 4),
        Container(width: 2, height: 30, color: AppColors.textTertiary),
        Container(
          width: 120,
          height: 8,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.jarWall, width: 4),
              left: BorderSide(color: AppColors.jarWall, width: 4),
              right: BorderSide(color: AppColors.jarWall, width: 4),
            ),
          ),
        ),
      ],
    );
  }
}

/// Шаг 2: вишня + вишня → клубника.
class _MergeArt extends StatelessWidget {
  const _MergeArt();

  @override
  Widget build(BuildContext context) {
    final TextStyle sign = AppFonts.score.copyWith(
      fontSize: 26,
      color: AppColors.textSecondary,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _fruit(BallTier.t1, 40),
        const SizedBox(width: 6),
        Text('+', style: sign),
        const SizedBox(width: 6),
        _fruit(BallTier.t1, 40),
        const SizedBox(width: 10),
        Text('=', style: sign),
        const SizedBox(width: 10),
        _fruit(BallTier.t2, 56),
      ],
    );
  }
}

/// Шаг 3: иконки бонусов и звезда заказов.
class _BonusArt extends StatelessWidget {
  const _BonusArt();

  @override
  Widget build(BuildContext context) {
    Widget circle(AppIcons icon) => Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            border: Border.all(color: AppColors.stroke, width: 2),
          ),
          child: AppIcon(icon, size: 26),
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        circle(AppIcons.shake),
        const SizedBox(width: 10),
        circle(AppIcons.bomb),
        const SizedBox(width: 10),
        circle(AppIcons.upgrade),
        const SizedBox(width: 18),
        circle(AppIcons.star),
      ],
    );
  }
}
