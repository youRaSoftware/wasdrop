import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;

  const AppScaffold({required this.body, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgScreen,
      body: body,
    );
  }
}
