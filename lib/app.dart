import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final AppConfig config = appLocator<AppConfig>();
    final AppRouter appRouter = appLocator<AppRouter>();
    final SettingsService settings = appLocator<SettingsService>();

    return MaterialApp.router(
      title: config.appName,
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      themeMode: ThemeMode.light,
      routeInformationParser: appRouter.router.routeInformationParser,
      routeInformationProvider: appRouter.router.routeInformationProvider,
      routerDelegate: appRouter.router.routerDelegate,
      builder: (BuildContext context, Widget? child) {
        final Widget content = child ?? const SizedBox.shrink();
        // Тема-обои для всех экранов — из настроек, без DI в core_ui.
        return ValueListenableBuilder<SettingsModel>(
          valueListenable: settings.settings,
          builder: (BuildContext context, SettingsModel value, Widget? _) {
            return AppThemeScope(
              theme: GameThemes.byId(value.themeId),
              child: config.showFlavorBanner
                  ? Banner(
                      message: config.flavor.name.toUpperCase(),
                      location: BannerLocation.topEnd,
                      color: AppColors.alert,
                      child: content,
                    )
                  : content,
            );
          },
        );
      },
    );
  }
}
