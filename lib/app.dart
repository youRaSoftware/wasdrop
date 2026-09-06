import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final AppConfig config = appLocator<AppConfig>();
    final AppRouter appRouter = appLocator<AppRouter>();

    return MaterialApp.router(
      title: config.appName,
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      themeMode: ThemeMode.light,
      routeInformationParser: appRouter.router.routeInformationParser,
      routeInformationProvider: appRouter.router.routeInformationProvider,
      routerDelegate: appRouter.router.routerDelegate,
      builder: (BuildContext context, Widget? child) {
        if (!config.showFlavorBanner || child == null) {
          return child ?? const SizedBox.shrink();
        }
        return Banner(
          message: config.flavor.name.toUpperCase(),
          location: BannerLocation.topEnd,
          color: AppColors.alert,
          child: child,
        );
      },
    );
  }
}
