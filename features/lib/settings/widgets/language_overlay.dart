import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

/// Выбор языка интерфейса поверх экрана настроек: «Системный» и все языки
/// из [AppLocalizationEnum] (имя языка — на нём самом). Ключ строки —
/// `Key('language_<code>')`, у системного — `language_system`.
class LanguageOverlay extends StatelessWidget {
  final String? selectedCode;
  final ValueChanged<String?> onSelect;
  final VoidCallback onCancel;

  const LanguageOverlay({
    required this.selectedCode,
    required this.onSelect,
    required this.onCancel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppOverlay(
      width: 300,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: Text(
              context.tr(LocaleKeys.settings_languageTitle),
              style: AppFonts.overlayTitle,
            ),
          ),
          const SizedBox(height: 10),
          _LanguageRow(
            key: const Key('language_system'),
            label: context.tr(LocaleKeys.settings_languageSystem),
            selected: selectedCode == null,
            onPressed: () => onSelect(null),
          ),
          for (final AppLocalizationEnum lang in AppLocalizationEnum.values)
            _LanguageRow(
              key: Key('language_${lang.code}'),
              label: lang.languageDisplayName,
              selected: lang.code == selectedCode,
              onPressed: () => onSelect(lang.code),
            ),
          const SizedBox(height: 6),
          AppTextButton(
            label: context.tr(LocaleKeys.settings_cancel),
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  const _LanguageRow({
    required this.label,
    required this.selected,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onPressed: onPressed,
      builder: (BuildContext context, double pressed, Widget? _) {
        return Opacity(
          opacity: 1 - 0.4 * pressed,
          child: Container(
            constraints:
                const BoxConstraints(minHeight: AppDimens.minTapTarget),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    label,
                    style: AppFonts.button.copyWith(
                      fontSize: 15,
                      color: selected
                          ? AppColors.textPrimary
                          : AppColors.secondaryText,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_rounded,
                    size: 22,
                    color: AppColors.accent,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
