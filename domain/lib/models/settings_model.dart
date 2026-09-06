import 'package:equatable/equatable.dart';

class SettingsModel extends Equatable {
  final bool soundOn;
  final bool hapticsOn;

  const SettingsModel({required this.soundOn, required this.hapticsOn});

  const SettingsModel.empty() : this(soundOn: true, hapticsOn: false);

  SettingsModel copyWith({bool? soundOn, bool? hapticsOn}) {
    return SettingsModel(
      soundOn: soundOn ?? this.soundOn,
      hapticsOn: hapticsOn ?? this.hapticsOn,
    );
  }

  @override
  List<Object?> get props => <Object?>[soundOn, hapticsOn];
}
