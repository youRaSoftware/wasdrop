import 'dart:async';

import 'package:core/core.dart';

part 'premium_state.dart';

/// Paywall «Премиум навсегда»: цена и доступность стора — из
/// [PremiumService.store], факт покупки — из [PremiumService.isPremium],
/// результат покупки/восстановления — из [PremiumService.events].
class PremiumCubit extends Cubit<PremiumState> {
  final PremiumService premium;

  StreamSubscription<PremiumEvent>? _events;

  PremiumCubit({required this.premium})
      : super(PremiumState(
          isPremium: premium.isPremium.value,
          store: premium.store.value,
        )) {
    premium.isPremium.addListener(_onPremiumChanged);
    premium.store.addListener(_onStoreChanged);
    _events = premium.events.listen(_onEvent);
    // Магазин мог быть недоступен при старте (нет сети) — пробуем снова.
    unawaited(premium.refresh());
  }

  void _safeEmit(PremiumState next) {
    if (isClosed) return;
    emit(next);
  }

  void _onPremiumChanged() =>
      _safeEmit(state.copyWith(isPremium: premium.isPremium.value));

  void _onStoreChanged() =>
      _safeEmit(state.copyWith(store: premium.store.value));

  void _onEvent(PremiumEvent event) {
    final String? message = switch (event) {
      PremiumEvent.purchased => null,
      PremiumEvent.restored => LocaleKeys.premium_restored,
      PremiumEvent.nothingToRestore => LocaleKeys.premium_nothingToRestore,
      PremiumEvent.pending => LocaleKeys.premium_pending,
      PremiumEvent.cancelled => null,
      PremiumEvent.failed => LocaleKeys.premium_purchaseFailed,
    };
    _safeEmit(state.copyWith(
        busy: false, message: message, clearMessage: message == null));
  }

  Future<void> buy() async {
    if (state.busy) return;
    _safeEmit(state.copyWith(busy: true, clearMessage: true));
    await premium.buy();
  }

  Future<void> restore() async {
    if (state.busy) return;
    _safeEmit(state.copyWith(busy: true, clearMessage: true));
    await premium.restore();
  }

  void dismissMessage() => _safeEmit(state.copyWith(clearMessage: true));

  @override
  Future<void> close() async {
    premium.isPremium.removeListener(_onPremiumChanged);
    premium.store.removeListener(_onStoreChanged);
    await _events?.cancel();
    return super.close();
  }
}
