import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'settings_service.dart';

/// Звук и хаптика приложения.
///
/// Читает тумблеры из [SettingsService] (звуки / музыка / вибрация) и
/// подписан на их изменения: музыка-луп (`FlameAudio.bgm`) играет, пока
/// включены и «Звуки», и «Музыка». SFX из `core/resources/audio/`
/// (пока плейсхолдеры, см. README там). Кнопки дизайн-системы дёргают
/// [tap] через `ButtonFeedback` (назначается в `lib/main_common.dart`).
class AudioService {
  static const String assetPrefix = 'core/resources/audio/';
  static const double musicVolume = 0.35;

  static const String _music = 'music_loop.m4a';
  static const String _tap = 'sfx_tap.wav';
  static const String _drop = 'sfx_drop.wav';
  static const String _gameOver = 'sfx_game_over.wav';
  static const String _record = 'sfx_record.wav';
  static const String _shake = 'sfx_shake.wav';
  static const String _bomb = 'sfx_bomb.wav';

  static String _merge(BallTier tier) =>
      'sfx_merge_${tier.number.toString().padLeft(2, '0')}.wav';

  final SettingsService _settings;

  bool _ready = false;
  SettingsModel _last = const SettingsModel.empty();

  AudioService(this._settings);

  bool get soundOn => _settings.value.soundOn;

  bool get hapticsOn => _settings.value.hapticsOn;

  bool get musicPlays => _settings.value.musicPlays;

  /// Прогревает кэш SFX, подписывается на настройки и запускает музыку,
  /// если она включена. Ошибки аудио не роняют приложение — игра работает
  /// без звука.
  Future<void> init() async {
    _last = _settings.value;
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
        _shake,
        _bomb,
        for (final BallTier tier in BallTier.values) _merge(tier),
      ]);
      _ready = true;
    } catch (error) {
      debugPrint('AudioService: init failed, running silent: $error');
    }
    _settings.settings.addListener(_onSettingsChanged);
    await _syncMusic();
  }

  void _onSettingsChanged() {
    final SettingsModel next = _settings.value;
    // Включили вибрацию — сразу дать её почувствовать.
    if (next.hapticsOn && !_last.hapticsOn) {
      unawaited(HapticFeedback.lightImpact());
    }
    _last = next;
    unawaited(_syncMusic());
  }

  Future<void> _syncMusic() async {
    if (!_ready) return;
    if (musicPlays) {
      await startMusic();
    } else {
      await stopMusic();
    }
  }

  Future<void> startMusic() async {
    if (!_ready || !musicPlays || FlameAudio.bgm.isPlaying) return;
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
    _settings.settings.removeListener(_onSettingsChanged);
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

  /// Бонус «Встряхнуть»: дребезг фруктов в стакане.
  void shake() {
    _sfx(_shake, 0.7);
    _haptic(HapticFeedback.mediumImpact);
  }

  /// Бонус «Бомбочка»: взрыв.
  void bomb() {
    _sfx(_bomb, 0.9);
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
