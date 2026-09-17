import 'package:core/core.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../cubit/jars_cubit.dart';
import 'jars_form.dart';

/// Экран выбора стакана `/jars` (из меню и из паузы).
class JarsScreen extends StatelessWidget {
  const JarsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<JarsCubit>(
      create: (BuildContext context) => JarsCubit(
        progressRepository: appLocator<ProgressRepository>(),
        settings: appLocator<SettingsService>(),
      ),
      child: const JarsForm(),
    );
  }
}
