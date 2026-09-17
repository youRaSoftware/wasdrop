part of 'jars_cubit.dart';

class JarsState extends Equatable {
  /// Звёзды заказов — валюта открытия стаканов.
  final int stars;

  /// Выбранный стакан (настройка `jarId`).
  final String selectedId;

  const JarsState({required this.stars, required this.selectedId});

  bool isUnlocked(JarShape jar) => jar.isUnlocked(stars);

  JarsState copyWith({int? stars, String? selectedId}) => JarsState(
        stars: stars ?? this.stars,
        selectedId: selectedId ?? this.selectedId,
      );

  @override
  List<Object?> get props => <Object?>[stars, selectedId];
}
