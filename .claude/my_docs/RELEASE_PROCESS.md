# WasDrop — процесс релиза

Bundle / application id: `com.wasdrop` (prod), `com.wasdrop.dev` (dev).
Версия задаётся в корневом `pubspec.yaml`: `version: X.Y.Z+N` (N — build number, растёт с каждой загрузкой в стор).

## Перед первой загрузкой в TestFlight (один раз)

1. App Store Connect → My Apps → «+» → New App: платформа iOS, имя **WasDrop**, Bundle ID **`com.wasdrop`** (App ID уже зарегистрирован автоподписью при первом архиве), SKU любой, команда Pavel Hrytsenka. Без этой записи `xcodebuild -exportArchive` падает с «Error Downloading App Information» — Xcode ищет приложение по bundle id и получает пустой список.
2. Если архив уже собран, перезаливать без пересборки: `script/build.sh prod ipa --upload-only`.
3. Dev-флейвор (`com.wasdrop.dev`) в TestFlight не заливаем — это отдельный bundle id, для него пришлось бы заводить второе приложение.

## Чек-лист

1. **Версия.** Поднять `version:` в `pubspec.yaml` (SemVer + build number `+N`).
2. **Changelog.** В `.claude/changelog/CHANGELOG.md` переименовать `[Unreleased]` в `[X.Y.Z] — YYYY-MM-DD`, завести новый пустой `[Unreleased]`.
3. **Тексты для сторов.** Сохранить в `.claude/my_docs/release_notes_X.Y.Z.txt` (RU/EN, «Что нового» для App Store и Google Play — обычно копия секции changelog).
4. **Проверка.**
   ```bash
   script/prebuild_script.sh
   flutter analyze
   script/run_test_script.sh
   script/run.sh prod --release    # smoke-тест prod-сборки на устройстве
   ```
5. **Сборка.**
   ```bash
   script/build.sh prod aab            # Google Play → build/app/outputs/bundle/prodRelease/app-prod-release.aab
   script/build.sh prod ipa --upload   # App Store Connect / TestFlight
   script/build.sh prod ipa --upload-only   # только загрузка уже собранного архива
   # или интерактивно: script/build_app_builds.sh
   ```
6. **Загрузка.** AAB — вручную в Play Console (Internal testing → Production). IPA — уже в TestFlight после `--upload`; иначе Transporter.
7. **Тег.** `git tag vX.Y.Z && git push --tags`.
8. **Архив плана.** Отметить релиз в `.claude/plans/plan.md` (таблица «Архив планов»).

## Требования App Store Connect (уже в проекте)

- **Минимальная iOS 15.0** — `IPHONEOS_DEPLOYMENT_TARGET = 15.0` во всех конфигурациях pbxproj и `MinimumOSVersion` в `ios/Flutter/AppFrameworkInfo.plist` (ITMS-90068: с весны 2027 Apple не принимает MinimumOSVersion ниже 15.0). Если Flutter при `flutter create`/апгрейде вернёт 13.0 — поднять обратно.
- **Export compliance** — `ITSAppUsesNonExemptEncryption = false` в `ios/Runner/Info.plist`: сети и собственной криптографии в игре нет, поэтому вопрос про шифрование в App Store Connect не задаётся. Если появится сетевой слой с нестандартным шифрованием — пересмотреть.
- **Версия** — `CFBundleShortVersionString` билда должен совпадать с версией, заведённой в App Store Connect (первая запись — 1.0.0), иначе билд нельзя прикрепить к версии. Build number (`+N`) растёт с каждой загрузкой.

## Подпись

- **Android:** `android/key.properties` (не в git, шаблон — `android/key.properties.example`) + keystore. Без него release подписывается debug-ключом.
- **iOS:** команда Apple Developer — **Pavel Hrytsenka, Team ID `4YLBF6N3R4`** (та же, что у rvach), `DEVELOPMENT_TEAM` во всех конфигурациях pbxproj, автоматическая подпись. `script/build.sh` проверяет Team ID перед архивом и пишет его в `ios/exportOptions.plist` (создаётся при первом `--upload`, не в git). Для загрузки в App Store Connect нужен сертификат Apple Distribution этой команды — Xcode создаст его сам при `-allowProvisioningUpdates`, если Apple ID Павла добавлен в Xcode → Settings → Accounts на этом Mac (локально сейчас есть только Apple Development).

## Что где лежит

| Что | Где |
|---|---|
| Changelog (единый источник правды по версиям) | `.claude/changelog/CHANGELOG.md` |
| Тексты «Что нового» для сторов | `.claude/my_docs/release_notes_X.Y.Z.txt` |
| Бриф о продукте для работы над сторами (факты, лимиты полей, терминология на 6 языках) | `.claude/my_docs/STORE_BRIEF.md` |
| Описания / ключевые слова сторов | `.claude/my_docs/STORE_LISTINGS.md` (создать при первом релизе) |
| Артефакты сборки | `build/app/outputs/…`, `build/ios/ipa/`, `build/ios/archive/` |
