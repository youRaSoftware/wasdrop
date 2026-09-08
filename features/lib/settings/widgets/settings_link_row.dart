import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

/// Строка-ссылка с шевроном («Лицензии»): вся строка — тап-цель,
/// при нажатии слегка гаснет.
class SettingsLinkRow extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const SettingsLinkRow({
    required this.label,
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
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 24,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
