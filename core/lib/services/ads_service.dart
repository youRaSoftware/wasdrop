import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/ads_config.dart';
import '../config/app_config.dart';
import 'audio_service.dart';
import 'premium_service.dart';

/// Чем закончился показ rewarded-ролика.
enum AdResult {
  /// Досмотрен — награду выдаём.
  earned,

  /// Закрыт до конца — награды нет.
  dismissed,

  /// Не загрузился (нет сети, нет заполнения, SDK не инициализирован).
  unavailable,
}

/// Rewarded-реклама (AdMob): «Продолжить за рекламу» и пополнение
/// зарядов бонусов. Пока только iOS: без `APPLICATION_ID` в Android-манифесте
/// SDK падает, поэтому на других платформах сервис — заглушка.
///
/// Согласие (UMP, GDPR / ATT) и SDK: [init] в фоне при запуске обновляет
/// статус согласия и, если рекламу уже можно запрашивать (согласие не
/// нужно или дано раньше), инициализирует SDK и предзагружает ролик. Форма
/// согласия показывается не на сплеше, а при первом [showRewarded] —
/// игрок сам нажал кнопку рекламы. Без сети всё тихо проваливается и
/// повторяется при следующем [showRewarded]. У премиума ничего не делаем.
class AdsService {
  final AppConfig _config;
  final PremiumService _premium;
  final AudioService _audio;

  bool _consentUpdated = false;
  bool _initialized = false;
  Future<void>? _initializing;
  RewardedAd? _preloaded;
  bool _showing = false;

  AdsService(this._config, this._premium, this._audio);

  bool get supported => Platform.isIOS;

  /// Нужна ли в настройках строка «Настройки рекламы» (UMP: пользователь
  /// из региона с обязательным согласием может его изменить).
  Future<bool> privacyOptionsRequired() async {
    if (!supported || _premium.isPremium.value) return false;
    try {
      final PrivacyOptionsRequirementStatus status = await ConsentInformation
          .instance
          .getPrivacyOptionsRequirementStatus();
      return status == PrivacyOptionsRequirementStatus.required;
    } catch (_) {
      return false;
    }
  }

  Future<void> showPrivacyOptions() async {
    if (!supported) return;
    final Completer<void> done = Completer<void>();
    await ConsentForm.showPrivacyOptionsForm((FormError? error) {
      if (error != null) {
        debugPrint('AdsService: privacy form: ${error.message}');
      }
      done.complete();
    });
    return done.future;
  }

  Future<void> init() async {
    if (!supported || _premium.isPremium.value) return;
    try {
      await _updateConsent();
      if (await ConsentInformation.instance.canRequestAds()) {
        await _initSdk();
      }
    } catch (error) {
      debugPrint('AdsService: init failed: $error');
    }
  }

  /// UMP: обновить статус согласия (нужна сеть; повторяем, пока не вышло).
  Future<void> _updateConsent() async {
    if (_consentUpdated) return;
    final Completer<bool> updated = Completer<bool>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(
        consentDebugSettings: _config.useTestAds
            ? ConsentDebugSettings(
                debugGeography: DebugGeography.debugGeographyEea,
              )
            : null,
      ),
      () => updated.complete(true),
      (FormError error) {
        debugPrint('AdsService: consent update failed: ${error.message}');
        updated.complete(false);
      },
    );
    _consentUpdated = await updated.future;
  }

  /// Показывает форму согласия, если она требуется.
  Future<void> _showConsentFormIfRequired() async {
    final Completer<void> dismissed = Completer<void>();
    await ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) {
      if (error != null) {
        debugPrint('AdsService: consent form: ${error.message}');
      }
      dismissed.complete();
    });
    await dismissed.future;
  }

  Future<void> _initSdk() {
    if (_initialized) return Future<void>.value();
    return _initializing ??= () async {
      try {
        await MobileAds.instance.initialize();
        _initialized = true;
        unawaited(_preload());
      } catch (error) {
        debugPrint('AdsService: SDK init failed: $error');
      } finally {
        _initializing = null;
      }
    }();
  }

  /// Полная подготовка перед показом: согласие (с формой) и SDK.
  Future<bool> _prepare() async {
    if (_initialized) return true;
    try {
      await _updateConsent();
      if (!await ConsentInformation.instance.canRequestAds()) {
        await _showConsentFormIfRequired();
      }
      if (!await ConsentInformation.instance.canRequestAds()) return false;
      await _initSdk();
    } catch (error) {
      debugPrint('AdsService: prepare failed: $error');
    }
    return _initialized;
  }

  String _unitId(AdPlacement placement) {
    if (_config.useTestAds) return AdsConfig.testRewardedUnitId;
    return switch (placement) {
      AdPlacement.continueGame => AdsConfig.prodContinueUnitId,
      AdPlacement.refill => AdsConfig.prodRefillUnitId,
    };
  }

  Future<RewardedAd?> _load(AdPlacement placement) async {
    final Completer<RewardedAd?> loaded = Completer<RewardedAd?>();
    await RewardedAd.load(
      adUnitId: _unitId(placement),
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: loaded.complete,
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('AdsService: load failed: ${error.message}');
          loaded.complete(null);
        },
      ),
    );
    return loaded.future.timeout(
      AdsConfig.loadTimeout,
      onTimeout: () => null,
    );
  }

  Future<void> _preload() async {
    if (_preloaded != null || !_initialized) return;
    _preloaded = await _load(AdPlacement.continueGame);
  }

  /// Показывает ролик и ждёт, чем он закончился. Пока ролик на экране,
  /// музыка приглушена.
  Future<AdResult> showRewarded(AdPlacement placement) async {
    if (!supported || _showing) return AdResult.unavailable;
    if (!await _prepare()) return AdResult.unavailable;

    RewardedAd? ad = _preloaded;
    _preloaded = null;
    ad ??= await _load(placement);
    if (ad == null) return AdResult.unavailable;

    _showing = true;
    final Completer<AdResult> result = Completer<AdResult>();
    bool earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdShowedFullScreenContent: (RewardedAd _) =>
          unawaited(_audio.stopMusic()),
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        ad.dispose();
        if (!result.isCompleted) {
          result.complete(earned ? AdResult.earned : AdResult.dismissed);
        }
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        debugPrint('AdsService: show failed: ${error.message}');
        ad.dispose();
        if (!result.isCompleted) result.complete(AdResult.unavailable);
      },
    );
    try {
      await ad.show(
        onUserEarnedReward: (AdWithoutView _, RewardItem __) => earned = true,
      );
    } catch (error) {
      debugPrint('AdsService: show threw: $error');
      if (!result.isCompleted) result.complete(AdResult.unavailable);
    }
    final AdResult outcome = await result.future;
    _showing = false;
    unawaited(_audio.startMusic());
    unawaited(_preload());
    return outcome;
  }
}
