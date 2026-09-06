import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Звук и хаптика приложения.
///
/// Держит текущие настройки в [settings] (тумблеры «Звук» / «Вибрация»
/// в меню и паузе подписываются на него), сохраняет их через
/// [SettingsRepository], крутит фоновую музыку и играет SFX из
/// `core/resources/audio/` (пока плейсхолдеры, см. README там). Кнопки
/// дизайн-системы дёргают [tap] через `ButtonFeedback` (назначается
/// в `lib/main_common.dart`).
class AudioService {
  static const String assetPrefix = 'core/resources/audio/';
  static const double musicVolume = 0.35;

  static const String _music = 'music_loop.m4a';
  static const String _tap = 'sfx_tap.wav';
  static const String _drop = 'sfx_drop.wav';
  static const String _gameOver = 'sfx_game_over.wav';
  static const String _record = 'sfx_record.wav';

  static String _merge(BallTier tier) =>
      'sfx_merge_${tier.number.toString().padLeft(2, '0')}.wav';

  final SettingsRepository _repository;

  /// Текущие настройки звука и вибрации (для `ValueListenableBuilder`).
  final ValueNotifier<SettingsModel> settings =
      ValueNotifier<SettingsModel>(const SettingsModel.empty());

  bool _ready = false;

  AudioService(this._repository);

  bool get soundOn => settings.value.soundOn;

  bool get hapticsOn => settings.value.hapticsOn;

  /// Загружает настройки, прогревает кэш SFX и запускает музыку, если звук
  /// включён. Ошибки аудио не роняют приложение — игра работает без звука.
  Future<void> init() async {
    settings.value = await _repository.getSettings();
    try {
      FlameAudio.updatePrefix(assetPrefix);
      await FlameAudio.bgm.initialize();
      // Позиция трека не нужна, а её опрос держит Flutter в режиме
      // «кадр каждый тик» всё время, пока играет музыка.
      FlameAudio.bgm.audioPlayer.positionUpdater = null;
      await FlameAudio.audioCache.loadAll(<String>[
        _tap,
        _drop,
        _gameOver,
        _record,
        for (final BallTier tier in BallTier.values) _merge(tier),
      ]);
      _ready = true;
    } catch (error) {
      debugPrint('AudioService: init failed, running silent: $error');
    }
    await startMusic();
  }

  Future<void> setSoundOn(bool value) async {
    if (value == soundOn) return;
    settings.value = settings.value.copyWith(soundOn: value);
    await _repository.saveSettings(settings.value);
    if (value) {
      await startMusic();
    } else {
      await stopMusic();
    }
  }

  Future<void> setHapticsOn(bool value) async {
    if (value == hapticsOn) return;
    settings.value = settings.value.copyWith(hapticsOn: value);
    await _repository.saveSettings(settings.value);
    if (value) unawaited(HapticFeedback.lightImpact());
  }

  Future<void> startMusic() async {
    if (!_ready || !soundOn || FlameAudio.bgm.isPlaying) return;
    try {
      await FlameAudio.bgm.play(_music, volume: musicVolume);
    } catch (error) {
      debugPrint('AudioService: music failed: $error');
    }
  }

  Future<void> stopMusic() async {
    if (!_ready) return;
    await FlameAudio.bgm.stop();
  }

  /// Останавливает музыку и освобождает плеер (тесты; в приложении сервис
  /// живёт до конца процесса).
  Future<void> dispose() async {
    if (!_ready) return;
    _ready = false;
    await FlameAudio.bgm.dispose();
  }

  // --- События игры / UI --------------------------------------------------

  /// Нажатие любой кнопки дизайн-системы.
  void tap() {
    _sfx(_tap, 0.5);
    _haptic(HapticFeedback.selectionClick);
  }

  /// Шар брошен.
  void drop() {
    _sfx(_drop, 0.7);
    _haptic(HapticFeedback.lightImpact);
  }

  /// Слились два шара тира [tier] — тон растёт с тиром.
  void merge(BallTier tier) {
    _sfx(_merge(tier), 0.8);
    _haptic(HapticFeedback.mediumImpact);
  }

  /// Проигрыш (или новый рекорд).
  void gameOver({required bool isRecord}) {
    _sfx(isRecord ? _record : _gameOver, 0.9);
    _haptic(HapticFeedback.heavyImpact);
  }

  void _sfx(String file, double volume) {
    if (!_ready || !soundOn) return;
    unawaited(
      FlameAudio.play(file, volume: volume).then<void>(
        (AudioPlayer _) {},
        onError: (Object error) =>
            debugPrint('AudioService: $file failed: $error'),
      ),
    );
  }

  void _haptic(Future<void> Function() feedback) {
    if (!hapticsOn) return;
    unawaited(feedback());
  }
}
