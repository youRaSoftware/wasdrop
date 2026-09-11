import 'package:core/core.dart';
import 'package:flutter/material.dart';

import '../cubit/premium_cubit.dart';
import 'premium_form.dart';

/// Paywall «Премиум навсегда» (`/premium`, открывается `pushNamed`).
class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PremiumCubit>(
      create: (BuildContext context) =>
          PremiumCubit(premium: appLocator<PremiumService>()),
      child: const PremiumForm(),
    );
  }
}
