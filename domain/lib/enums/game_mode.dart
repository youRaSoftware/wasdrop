/// Режим партии.
enum GameMode {
  /// Бесконечная партия на счёт; единственный режим с сохранением.
  classic,

  /// Две минуты на счёт (`GameRules.timedSeconds`), без продолжений.
  timed,

  /// Ежедневный вызов: очередь фруктов и заказы из seed по дате (UTC),
  /// одинаковые у всех; один зачёт в день, без продолжений.
  daily,

  /// «Сад чудес»: в очередь подмешиваются особые фрукты (`SpecialKind`);
  /// свой снимок партии и рекорд, сохраняется как классика.
  garden;

  bool get isClassic => this == GameMode.classic;

  /// Партия сохраняется и продолжается из меню (классика и сад).
  bool get isResumable => this == GameMode.classic || this == GameMode.garden;

  /// Продолжение после проигрыша (только в бесконечных режимах).
  bool get allowsContinue => isResumable;
}
