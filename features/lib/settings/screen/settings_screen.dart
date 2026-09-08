import 'package:core/core.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../cubit/settings_cubit.dart';
import 'settings_form.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SettingsCubit>(
      create: (BuildContext context) => SettingsCubit(
        statsRepository: appLocator<StatsRepository>(),
      ),
      child: const SettingsForm(),
    );
  }
}
