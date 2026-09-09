# План: мультиязычность (ru, en, ja, de, hu, fr)

## Контекст

Весь текст интерфейса — русские литералы в виджетах (56 строк в `features/`, названия фруктов в `domain/lib/enums/ball_tier.dart`, названия тем в `core_ui/lib/src/theme/game_theme.dart`). Нужны английский, японский, немецкий, венгерский и французский, выбор языка в настройках и следование системному языку по умолчанию. Подход берём из rvach (архитектура wasdrop скопирована оттуда): **`easy_localization` 3.0.8**, JSON-переводы в `core/resources/translations/`, `AppLocalizationEnum` + сгенерированные `LocaleKeys` в `core/lib/localization/`, `LocaleKeys.x.tr()` в виджетах.

Переводы пишу сам; перед релизом стоит показать носителям — особенно японский и венгерский.

---

## 1. Пакет и файлы переводов

- `core/pubspec.yaml`: `easy_localization: ^3.0.8`, `flutter: assets: - resources/translations/`.
- `core/resources/translations/{en-US,ru-RU,de-DE,fr-FR,hu-HU,ja-JP}.json` — одинаковая структура ключей (алфавитно по разделам):
  - `menu`: play, best (`"Рекорд {score}"`)
  - `hud`: best (`"РЕКОРД {score}"`)
  - `pause`: title, resume, restart, menu, sound, vibration, wallpapers
  - `gameOver`: title, newRecord, best (`"рекорд — {score}"`), restart, menu, continueAd
  - `settings`: title, sound, sounds, music, vibration, game, aimLine, wallpapers, language, languageSystem, stats, best, gamesPlayed, merges, biggestFruit, reset, fruits, about, version, licenses, resetTitle, resetBody, resetConfirm, cancel
  - `fruits`: cherry … watermelon (11)
  - `themes`: cream, sunset, mint, night, rose, sky
  - Капс сохраняем в переводах там, где он в дизайне (PLAY / JOUER / SPIELEN / JÁTÉK; у японского капса нет). Плейсхолдер один — `{score}`, через `tr(namedArgs:)`.
- `core/lib/localization/app_localization_enum.dart` — как в rvach: `en(Locale('en','US'), 'English')`, `ru`, `de`, `fr`, `hu('Magyar')`, `ja('日本語')`; `languageDisplayName` — имя языка на нём самом (не переводится); `fallbackLocale = en`; `langFolderPath = 'packages/core/resources/translations'`; `byCode(String)`.
- `core/lib/localization/locale_keys.g.dart` — генерируется: `cd core && dart run easy_localization:generate -f keys -o locale_keys.g.dart -O lib/localization -S resources/translations`; коммитится (`*.g.dart` уже исключены из анализа). Команду добавить в `script/prebuild_script.sh` (после pub get, если в `core/pubspec.yaml` есть easy_localization).
- `core/lib/core.dart`: экспорт `package:easy_localization/easy_localization.dart`, `localization/app_localization_enum.dart`, `localization/locale_keys.g.dart`, `localization/fruit_label.dart`.
- `core/lib/localization/fruit_label.dart`: `FruitLabel.of(BallTier)` → `LocaleKeys.fruits_*.tr()` (core зависит от domain). Названия тем — `'themes.${theme.id}'.tr()` через хелпер `themeLabel(GameTheme)` в `features/lib/settings/widgets/theme_label.dart` (core_ui не может зависеть от core).

## 2. Подключение

- `lib/main_common.dart`: `await EasyLocalization.ensureInitialized()` до `runApp`; `runApp(EasyLocalization(supportedLocales:, fallbackLocale:, path:, startLocale: <из настроек или null>, saveLocale: false, child: App()))`. Источник правды — наш Hive, а не shared_preferences easy_localization (поэтому `saveLocale: false`).
- `lib/app.dart`: `MaterialApp.router(localizationsDelegates: context.localizationDelegates, supportedLocales: context.supportedLocales, locale: context.locale, …)` — даёт и Material-локализацию встроенных экранов (страница лицензий).
- Системный язык вне списка → `en` (fallback). Совпадение по коду языка (`de-AT` → `de-DE`) easy_localization делает сам.
- `ios/Runner/Info.plist`: `CFBundleLocalizations` = en, ru, de, fr, hu, ja (App Store покажет языки, системные диалоги — на языке пользователя). Android — ничего.

## 3. Настройка «Язык»

- `domain/lib/models/settings_model.dart`: `+ String? localeCode` (null — системный); Hive-провайдер/репозиторий — ключ `locale`; `SettingsService.setLocale(String?)`.
- Экран настроек, секция «Игра» → строка «Язык» (`SettingsLinkRow` получает необязательный `value`: текущее имя языка или «Системный») → `LanguageOverlay` (`AppOverlay`): список «Системный» + 6 языков (`AppPressable`-строки, выбранная — с галочкой `accent`). Выбор: `settings.setLocale(code)` + `context.setLocale(locale)` / `context.resetLocale()` для системного; оверлей закрывается. Состояние оверлея — в `SettingsCubit` (`choosingLanguage`), как у сброса статистики.
- Пикер живёт в `features/lib/settings/widgets/language_overlay.dart`.

## 4. Замена литералов

- `features/`: все 56 строк → `LocaleKeys.….tr()` (`tr(namedArgs: {'score': '$n'})` для трёх строк со счётом). Файлы: `menu_screen.dart`, `game_hud.dart`, `pause_overlay.dart`, `game_over_overlay.dart`, `settings_form.dart`, `reset_stats_overlay.dart`, `fruit_chain.dart` (`FruitLabel.of`), `settings_form.dart` «Самый большой фрукт» (`FruitLabel.of`), `splash_screen.dart` (без текста, только лого — не трогаем).
- `domain`: убрать `BallTier.title` (и `_titles`); `fromNumber` остаётся.
- `core_ui`: убрать `GameTheme.name`; `ThemePicker` получает `labelOf: String Function(GameTheme)` для `Semantics` (features передаёт `themeLabel`).
- Лого «WasDrop», DEV-баннер, `+N` в игре — без перевода. `showLicensePage(applicationName: config.appName)` как есть.

## 5. Шрифты
Rubik и Unbounded покрывают латиницу с диакритикой (ő ű é ç) и кириллицу; японские глифы берутся из системного шрифта через fallback Flutter (Hiragino / Noto). Проверить скриншотом: меню, пауза и настройки на `ja` и `hu`.

## 6. Проверка
1. `script/prebuild_script.sh` (pub get + генерация ключей), `flutter analyze`, `dart format`.
2. Смоук-тест `integration_test/game_smoke_test.dart`: русские литералы → `LocaleKeys.….tr()` (работает и вне виджетов после инициализации); добавить: в настройках открыть «Язык» → выбрать `日本語` → заголовок экрана = `LocaleKeys.settings_title.tr()` на японском и `settings.value.localeCode == 'ja'`; вернуть «Системный» (`localeCode == null`).
3. Скриншоты через временный тест: меню/пауза/настройки/проигрыш на `en`, `ja`, `hu`, `de`, `fr` — переполнения кнопок и строк, японские глифы.
4. `flutter build ios --simulator`, запуск.

## Документы
- `.claude/shared/wasdrop_ui_reference.md` § 3 — переписать: `easy_localization`, `LocaleKeys.x.tr()`, никаких литералов в виджетах, новый ключ добавляется во все 6 JSON + перегенерация, имена языков — в enum, капс — в переводе; § 4.7 `localeCode`.
- `CLAUDE.md`: раздел «Локализация» (пакет, файлы, команда генерации, правило «ключ во все шесть файлов», выбор языка в настройках, `CFBundleLocalizations`), структура core.
- `.claude/my_docs/WASDROP.md` § 2 (настройки: «Язык»), § 3 (нет), § 4 архитектура; `TESTFLIGHT_TEST_INFO.md` — строка «интерфейс только на русском» → список языков.
- `.claude/plans/plan.md`: бэклог «Локализация» → сделано; `.claude/changelog/CHANGELOG.md` RU/EN.
