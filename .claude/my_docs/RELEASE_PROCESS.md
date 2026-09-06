# WasDrop — процесс релиза

Bundle / application id: `com.wasdrop` (prod), `com.wasdrop.dev` (dev).
Версия задаётся в корневом `pubspec.yaml`: `version: X.Y.Z+N` (N — build number, растёт с каждой загрузкой в стор).

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
   # или интерактивно: script/build_app_builds.sh
   ```
6. **Загрузка.** AAB — вручную в Play Console (Internal testing → Production). IPA — уже в TestFlight после `--upload`; иначе Transporter.
7. **Тег.** `git tag vX.Y.Z && git push --tags`.
8. **Архив плана.** Отметить релиз в `.claude/plans/plan.md` (таблица «Архив планов»).

## Подпись

- **Android:** `android/key.properties` (не в git, шаблон — `android/key.properties.example`) + keystore. Без него release подписывается debug-ключом.
- **iOS:** Team `UN2WKHKN59` в проекте, автоматическая подпись; `ios/exportOptions.plist` создаётся скриптом при первом `--upload` (не в git).

## Что где лежит

| Что | Где |
|---|---|
| Changelog (единый источник правды по версиям) | `.claude/changelog/CHANGELOG.md` |
| Тексты «Что нового» для сторов | `.claude/my_docs/release_notes_X.Y.Z.txt` |
| Описания / ключевые слова сторов | `.claude/my_docs/STORE_LISTINGS.md` (создать при первом релизе) |
| Артефакты сборки | `build/app/outputs/…`, `build/ios/ipa/`, `build/ios/archive/` |
