import 'package:get_it/get_it.dart';

import '../app_router/app_router.dart';

void setupNavigationDependencies() {
  GetIt.instance.registerLazySingleton<AppRouter>(AppRouter.new);
}
