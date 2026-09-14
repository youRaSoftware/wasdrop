import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';

import '../constants/app_constants.dart';

/// Оценка приложения в сторе (`in_app_review`).
///
/// Кнопка «Оценить приложение» зовёт [openStore]: страница отзыва в App
/// Store / Google Play открывается всегда. Системный шит ([requestReview])
/// на кнопку не вешаем: iOS показывает его не чаще трёх раз в год и без
/// гарантий, тап «не срабатывал» бы; он для мягкого запроса по инициативе
/// игры (пока не подключён). Офлайн стор покажет свою ошибку сети — игра
/// сеть не проверяет. Ошибки платформы не роняют экран настроек.
class ReviewService {
  final InAppReview _review;

  ReviewService({InAppReview? review})
      : _review = review ?? InAppReview.instance;

  /// Есть куда вести: на iOS нужен [AppConstants.appStoreId], на Android
  /// пакет берётся из рантайма.
  bool get canOpenStore =>
      Platform.isAndroid || AppConstants.appStoreId.isNotEmpty;

  /// Открывает страницу отзыва в сторе.
  Future<void> openStore() async {
    if (!canOpenStore) return;
    try {
      await _review.openStoreListing(appStoreId: AppConstants.appStoreId);
    } catch (error) {
      debugPrint('ReviewService: openStoreListing failed: $error');
    }
  }

  /// Системный запрос оценки (StoreKit / Play In-App Review): может молча
  /// не показаться (квоты платформ).
  Future<void> requestReview() async {
    try {
      if (await _review.isAvailable()) await _review.requestReview();
    } catch (error) {
      debugPrint('ReviewService: requestReview failed: $error');
    }
  }
}
