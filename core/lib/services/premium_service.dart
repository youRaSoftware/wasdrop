import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../config/app_config.dart';

/// Состояние магазина для paywall: цена известна или магазин недоступен
/// (нет сети, нет продукта, dev-сборка без StoreKit-конфига).
enum PremiumStoreStatus { loading, ready, unavailable }

class PremiumStore {
  final PremiumStoreStatus status;

  /// Локализованная цена из стора («7,99 $»), только при [ready].
  final String? price;

  const PremiumStore._(this.status, this.price);

  const PremiumStore.loading() : this._(PremiumStoreStatus.loading, null);

  const PremiumStore.ready(String price)
      : this._(PremiumStoreStatus.ready, price);

  const PremiumStore.unavailable()
      : this._(PremiumStoreStatus.unavailable, null);

  bool get isReady => status == PremiumStoreStatus.ready;
}

/// Что случилось с покупкой — paywall показывает сообщение и снимает
/// «занято».
enum PremiumEvent {
  purchased,
  restored,
  nothingToRestore,
  pending,
  cancelled,
  failed,
}

/// Покупка «Премиум навсегда» ([PremiumProducts.lifetime]): без рекламы,
/// все обои, продолжение и пополнение зарядов без роликов.
///
/// [isPremium] сразу берётся из кэша ([PremiumRepository]) — премиум
/// работает офлайн; магазин (StoreKit 2 через `in_app_purchase`) обновляет
/// кэш при покупке и восстановлении. Любая ошибка стора не роняет игру.
class PremiumService {
  /// Сколько ждём восстановленных покупок, прежде чем сказать «нечего
  /// восстанавливать».
  static const Duration restoreTimeout = Duration(seconds: 4);

  final PremiumRepository _repository;
  final InAppPurchase _store;

  final ValueNotifier<bool> isPremium = ValueNotifier<bool>(false);
  final ValueNotifier<PremiumStore> store =
      ValueNotifier<PremiumStore>(const PremiumStore.loading());

  final StreamController<PremiumEvent> _events =
      StreamController<PremiumEvent>.broadcast();

  StreamSubscription<List<PurchaseDetails>>? _purchases;
  ProductDetails? _product;
  Timer? _restoreTimer;

  PremiumService(this._repository, {InAppPurchase? store})
      : _store = store ?? InAppPurchase.instance;

  Stream<PremiumEvent> get events => _events.stream;

  /// Тема доступна: бесплатная или куплен премиум.
  bool canUseTheme(bool themeIsLocked) => isPremium.value || !themeIsLocked;

  /// Кэш читается сразу, запрос продукта в стор идёт в фоне — запуск
  /// приложения его не ждёт.
  Future<void> init() async {
    isPremium.value = await _repository.isPremium();
    _purchases ??= _store.purchaseStream.listen(
      _onPurchases,
      onError: (Object error) =>
          debugPrint('PremiumService: purchase stream error: $error'),
    );
    // Без монетизации стор не опрашиваем: paywall скрыт, кэш премиума
    // (если покупка была в другой версии) продолжает действовать.
    if (AppConfig.monetizationEnabled) unawaited(refresh());
  }

  /// Перезапрашивает продукт (paywall открыт заново, появилась сеть).
  Future<void> refresh() async {
    if (store.value.isReady) return;
    store.value = const PremiumStore.loading();
    try {
      if (!await _store.isAvailable()) {
        store.value = const PremiumStore.unavailable();
        return;
      }
      final ProductDetailsResponse response =
          await _store.queryProductDetails(PremiumProducts.all);
      final ProductDetails? product = response.productDetails
          .where((ProductDetails p) => p.id == PremiumProducts.lifetime)
          .firstOrNull;
      if (product == null) {
        debugPrint('PremiumService: product not found '
            '(${response.notFoundIDs}, ${response.error?.message})');
        store.value = const PremiumStore.unavailable();
        return;
      }
      _product = product;
      store.value = PremiumStore.ready(product.price);
    } catch (error) {
      debugPrint('PremiumService: store unavailable: $error');
      store.value = const PremiumStore.unavailable();
    }
  }

  /// Открывает системный лист покупки. Результат придёт в [events].
  Future<void> buy() async {
    final ProductDetails? product = _product;
    if (product == null) {
      await refresh();
      if (_product == null) {
        _events.add(PremiumEvent.failed);
        return;
      }
    }
    try {
      final bool started = await _store.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: _product!),
      );
      if (!started) _events.add(PremiumEvent.failed);
    } catch (error) {
      debugPrint('PremiumService: buy failed: $error');
      _events.add(PremiumEvent.failed);
    }
  }

  /// Восстанавливает покупку на новом устройстве. Если стор ничего не
  /// прислал за [restoreTimeout] — [PremiumEvent.nothingToRestore].
  Future<void> restore() async {
    _restoreTimer?.cancel();
    try {
      await _store.restorePurchases();
      _restoreTimer = Timer(restoreTimeout, () {
        _restoreTimer = null;
        _events.add(PremiumEvent.nothingToRestore);
      });
    } catch (error) {
      debugPrint('PremiumService: restore failed: $error');
      _events.add(PremiumEvent.failed);
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final PurchaseDetails purchase in purchases) {
      final bool ours = purchase.productID == PremiumProducts.lifetime;
      switch (purchase.status) {
        case PurchaseStatus.pending:
          if (ours) _events.add(PremiumEvent.pending);
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (ours) {
            await _grant();
            _restoreTimer?.cancel();
            _restoreTimer = null;
            _events.add(purchase.status == PurchaseStatus.restored
                ? PremiumEvent.restored
                : PremiumEvent.purchased);
          }
        case PurchaseStatus.error:
          debugPrint('PremiumService: purchase error: '
              '${purchase.error?.code} ${purchase.error?.message}');
          if (ours) _events.add(PremiumEvent.failed);
        case PurchaseStatus.canceled:
          if (ours) _events.add(PremiumEvent.cancelled);
      }
      if (purchase.pendingCompletePurchase) {
        try {
          await _store.completePurchase(purchase);
        } catch (error) {
          debugPrint('PremiumService: completePurchase failed: $error');
        }
      }
    }
  }

  Future<void> _grant() async {
    if (isPremium.value) return;
    isPremium.value = true;
    await _repository.setPremium(true);
  }

  /// Тесты и отладка: выставить премиум вручную.
  @visibleForTesting
  Future<void> setPremium(bool value) async {
    isPremium.value = value;
    await _repository.setPremium(value);
  }

  Future<void> dispose() async {
    _restoreTimer?.cancel();
    await _purchases?.cancel();
    await _events.close();
  }
}
