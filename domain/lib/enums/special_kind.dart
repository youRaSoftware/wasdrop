/// Особые фрукты режима «Сад чудес» (`GameMode.garden`): подмешиваются в
/// очередь и ломают правило каждый по-своему. Спрайты —
/// `features/assets/images/special/<name>_idle|squish.png`.
enum SpecialKind {
  /// Сливается с любым обычным фруктом, которого коснулась первым, и даёт
  /// его следующий тир.
  rainbow(radius: 24, every: 12, minDrop: 3),

  /// Обволакивает первый фрукт, на который упала, и уносит его из стакана
  /// (на дне или особом — просто лопается).
  bubble(radius: 30, every: 15, minDrop: 6),

  /// Ни с чем не сливается; гибнет от бомбочки или слияния рядом (+50).
  rotten(radius: 34, every: 18, minDrop: 10),

  /// Замораживает фрукт, на который упала: тот 3 броска не сливается.
  ice(radius: 20, every: 20, minDrop: 8);

  /// Радиус тела (мировые единицы, мир 360 в ширину).
  final double radius;

  /// Средний интервал появления в бросках (±2) и с какого броска возможен.
  final int every;
  final int minDrop;

  const SpecialKind({
    required this.radius,
    required this.every,
    required this.minDrop,
  });

  /// Очки за уничтожение гнилушки слиянием рядом.
  static const int rottenReward = 50;

  /// На сколько бросков замораживает льдинка.
  static const int frozenDrops = 3;

  /// Сколько секунд пузырик с фруктом всплывает из стакана.
  static const double bubbleCarrySeconds = 1.4;
}
