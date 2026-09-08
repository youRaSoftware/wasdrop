import 'package:flutter/material.dart';

/// Содержимое кнопки: необязательная иконка слева и подпись.
class ButtonLabel extends StatelessWidget {
  static const double gap = 8;

  final String label;
  final TextStyle style;
  final Widget? icon;

  const ButtonLabel({
    required this.label,
    required this.style,
    this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final Widget? icon = this.icon;
    if (icon == null) return Text(label, style: style);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        icon,
        const SizedBox(width: gap),
        Text(label, style: style),
      ],
    );
  }
}
