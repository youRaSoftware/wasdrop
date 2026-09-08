import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

/// Строка «подпись — значение» (статистика, версия). [leading] — мини-шар
/// перед значением («Самый большой фрукт»).
class SettingsValueRow extends StatelessWidget {
  final String label;
  final String value;
  final Widget? leading;

  const SettingsValueRow({
    required this.label,
    required this.value,
    this.leading,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final Widget? leading = this.leading;

    return Container(
      constraints: const BoxConstraints(minHeight: AppDimens.minTapTarget),
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
          if (leading != null) ...<Widget>[
            leading,
            const SizedBox(width: 8),
          ],
          Text(
            value,
            style: AppFonts.score.copyWith(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
