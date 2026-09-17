import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../cubit/jars_cubit.dart';
import '../widgets/jar_card.dart';

/// Экран выбора стакана: сетка карточек, звёзды в заголовке. Тап по
/// открытому — выбор (действует на следующую партию).
class JarsForm extends StatelessWidget {
  static const double contentMaxWidth = 520;

  const JarsForm({super.key});

  static Key cardKey(String id) => Key('jar_$id');

  @override
  Widget build(BuildContext context) {
    final JarsCubit cubit = context.read<JarsCubit>();
    final JarsState state = context.watch<JarsCubit>().state;
    final GameTheme theme = AppThemeScope.of(context);

    return AppScaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: contentMaxWidth),
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Row(
                    children: <Widget>[
                      IconCircleButton(
                        size: AppDimens.minTapTarget,
                        onPressed: context.pop,
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          size: 22,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          context.tr(LocaleKeys.jars_title),
                          style: AppFonts.overlayTitle
                              .copyWith(color: theme.hudText),
                        ),
                      ),
                      _StarsChip(stars: state.stars),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Text(
                    context.tr(LocaleKeys.jars_nextGame),
                    style: AppFonts.best.copyWith(
                      color: theme.hudTextTertiary,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.78,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    children: <Widget>[
                      for (final JarShape jar in JarShapes.all)
                        JarCard(
                          key: cardKey(jar.id),
                          jar: jar,
                          selected: jar.id == state.selectedId,
                          unlocked: state.isUnlocked(jar),
                          onTap: () => cubit.select(jar),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StarsChip extends StatelessWidget {
  final int stars;

  const _StarsChip({required this.stars});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.stroke, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const AppIcon(AppIcons.star, size: 18),
          const SizedBox(width: 6),
          Text(
            '$stars',
            style: AppFonts.button.copyWith(
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
