import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

/// Мелкие ссылки под paywall: «Политика конфиденциальности · Условия».
class PremiumLinkRow extends StatelessWidget {
  final String privacyLabel;
  final String termsLabel;
  final VoidCallback onPrivacy;
  final VoidCallback onTerms;

  const PremiumLinkRow({
    required this.privacyLabel,
    required this.termsLabel,
    required this.onPrivacy,
    required this.onTerms,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Одна строка: ссылки делят ширину через Flexible и при нехватке
    // места переносятся внутри себя (две строки без разрядки букв), а не
    // разъезжаются на два ряда по 44 px.
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Flexible(child: _Link(label: privacyLabel, onPressed: onPrivacy)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '·',
            style: AppFonts.best.copyWith(color: AppColors.textTertiary),
          ),
        ),
        Flexible(child: _Link(label: termsLabel, onPressed: onTerms)),
      ],
    );
  }
}

class _Link extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _Link({required this.label, required this.onPressed});

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
            alignment: Alignment.center,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppFonts.best.copyWith(
                fontSize: 12,
                letterSpacing: 0,
                color: AppColors.textSecondary,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.textTertiary,
              ),
            ),
          ),
        );
      },
    );
  }
}
