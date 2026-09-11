part of 'premium_cubit.dart';

class PremiumState extends Equatable {
  final bool isPremium;
  final PremiumStore store;

  /// Идёт покупка или восстановление — кнопки заблокированы.
  final bool busy;

  /// Ключ локализации сообщения под кнопками (ошибка, «восстановлено»…).
  final String? message;

  const PremiumState({
    required this.isPremium,
    required this.store,
    this.busy = false,
    this.message,
  });

  PremiumState copyWith({
    bool? isPremium,
    PremiumStore? store,
    bool? busy,
    String? message,
    bool clearMessage = false,
  }) {
    return PremiumState(
      isPremium: isPremium ?? this.isPremium,
      store: store ?? this.store,
      busy: busy ?? this.busy,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[isPremium, store.status, store.price, busy, message];
}
