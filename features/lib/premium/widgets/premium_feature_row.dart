import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

/// Пункт списка «что даёт премиум»: иконка в кружке и подпись
/// (или произвольный [trailing] вместо подписи — ряд обоев).
class PremiumFeatureRow extends StatelessWidget {
  final Widget icon;
  final String label;
  final Widget? trailing;

  const PremiumFeatureRow({
    required this.icon,
    required this.label,
    this.trailing,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final Widget? trailing = this.trailing;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondarySurface,
              border: Border.all(color: AppColors.stroke, width: 1.5),
            ),
            child: icon,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: AppFonts.button.copyWith(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (trailing != null) ...<Widget>[
                  const SizedBox(height: 8),
                  trailing,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
