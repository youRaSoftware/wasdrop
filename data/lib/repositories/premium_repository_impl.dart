import 'package:domain/domain.dart';

import '../providers/local/premium_hive_provider.dart';

class PremiumRepositoryImpl implements PremiumRepository {
  final PremiumHiveProvider _provider;

  PremiumRepositoryImpl(this._provider);

  @override
  Future<bool> isPremium() async => _provider.isPremium;

  @override
  Future<void> setPremium(bool value) => _provider.save(isPremium: value);
}
