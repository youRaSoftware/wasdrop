# WasDrop — заметки для Claude Code

Merge-drop игра (жанр suika). Flutter, без сети. Архитектура скопирована с water_tracker / rvach: пакеты core / core_ui / domain / data / features / navigation, BLoC (Cubit), get_it (`appLocator`), go_router, Hive. Отличия: нет dio/retrofit, нет ui_kit_alpha (core_ui самодостаточен), добавлен flame_forge2d для физики. Идентификаторы: `com.wasdrop` (prod), `com.wasdrop.dev` (dev) — другие org-префиксы в проекте не используем.

## Рабочая папка Claude (`.claude/`)

**ВАЖНО:** все документы Claude живут в `.claude/`. Не создавать `.md` в корне проекта — там только `CLAUDE.md` и `README.md`.

```
.claude/
├── SKILLS_GUIDE.md             # Как пользоваться скиллами
├── settings.json               # Общие настройки Claude Code (в git); settings.local.json — локальные (не в git)
├── plans/
│   └── plan.md                 # Основной план: статус, фазы, бэклог, архив планов
├── changelog/
│   └── CHANGELOG.md            # User-facing changelog (Keep a Changelog + SemVer, RU/EN)
├── my_docs/
│   ├── WASDROP.md              # ТЗ: дизайн-токены, экраны, геймплей
│   ├── RELEASE_PROCESS.md      # Чек-лист релиза, что где лежит
│   └── release_notes_X.Y.Z.txt # Тексты «Что нового» для сторов (по релизам)
├── shared/
│   └── wasdrop_ui_reference.md # UI/архитектурный референс для create-* скиллов
└── skills/                     # create-feature-ui, create-feature-full, create-widget, analyze-feature, audit-section, llm-council
```

### Куда что класть
- **Планы** → `.claude/plans/` (основной — `plan.md`; большие отдельные задачи — свой файл)
- **Changelog** → `.claude/changelog/CHANGELOG.md`
- **ТЗ, релизы, аудиты, анализы, описания сторов** → `.claude/my_docs/`

### Планирование и логирование изменений
1. Нетривиальная задача → `EnterPlanMode`, изучить код, записать план в `.claude/plans/plan.md`
2. Согласовать → реализовать
3. Готово → добавить user-facing пункт в `CHANGELOG.md` под `[Unreleased]`, отметить в `plan.md`

## Flavors: dev / prod

Нативные флейворы + dart-define — передавать **оба**:

```bash
script/run.sh dev                 # = flutter run --flavor dev --dart-define=environment=dev
script/run.sh prod --release
```

| | dev | prod |
|---|---|---|
| Android applicationId | `com.wasdrop.dev` | `com.wasdrop` |
| iOS bundle id / scheme | `com.wasdrop.dev` / `dev` | `com.wasdrop` / `prod` |
| Имя | WasDrop Dev | WasDrop |
| Плашка «DEV» в углу | да | нет |

- Dart: `Flavor` + `AppConfig` в `core/lib/config/app_config.dart`; `lib/main.dart` читает `--dart-define=environment` (fallback — нативный `appFlavor`), `setupAppScope(flavor)` кладёт `AppConfig` в `appLocator`. Ветвиться по окружению только через `appLocator<AppConfig>()`, не через `kDebugMode`.
- Android: `productFlavors` в `android/app/build.gradle.kts` (+ `buildFeatures.resValues` для `app_name`), подпись release из `android/key.properties` (шаблон `key.properties.example`).
- iOS: конфигурации `Debug|Release|Profile-dev|prod`, схемы `dev` / `prod`, `APP_DISPLAY_NAME` → `CFBundleDisplayName`; `ios/Podfile` маппит конфигурации, `ios/Flutter/*.xcconfig` включают Pods-xcconfig всех флейворов.
- Android Studio: конфигурации запуска `.run/Dev.run.xml`, `.run/Prod.run.xml`.

## Скрипты (`script/`)

```bash
script/run.sh <dev|prod> [args]            # запуск
script/build.sh <dev|prod> <apk|aab|ipa> [--upload]   # релизная сборка (ipa --upload → App Store Connect)
script/build_app_builds.sh                 # то же интерактивно
script/prebuild_script.sh [--clean]        # pub get во всех пакетах (+ build_runner там, где объявлен)
script/run_test_script.sh                  # тесты по пакетам + общий coverage/lcov.info
```

Проверка перед коммитом: `flutter analyze` и `dart format core core_ui data domain features lib navigation`.

## Структура пакетов
- **core/** — `AppConfig`/`Flavor`, DI (`app_di.dart`), константы роутов и Hive-боксов; реэкспортирует bloc/get_it/go_router/navigation
- **core_ui/** — `AppColors`, `AppFonts`, `AppDimens`, `lightTheme`, виджеты `AppScaffold`, `PrimaryButton`, `IconCircleButton`, `BallView`
- **domain/** — `BallTier`, `GameStatsModel`, `SettingsModel`, интерфейсы репозиториев
- **data/** — Hive-провайдеры (`providers/local/`), реализации репозиториев, `DataDI.init()`
- **features/** — `menu/`, `game/` (cubit, screen, widgets, `engine/` — Flame/Forge2D)
- **navigation/** — `AppRouter` (go_router, `/menu`, `/game`, fade-переход)

Паттерны и стиль — `.claude/shared/wasdrop_ui_reference.md`.

## Дизайн (вариант 1a, фруктовый)
- Палитра тиров 1–11: E5484D F76B15 EFB008 8FBF1F 3BA55C 12A594 00A2C7 0090FF 6E56CF AB4ABA E93D82 (`core_ui/lib/src/theme/app_colors.dart`)
- Маркер тира: эмодзи-фрукты 🍒🍓🍊🍋🍏🥝🫐🍇🍑🍈🍉 (`BallTier.emoji`), запасной канал — цифра
- Радиусы шаров (мировые единицы, мир 360 wide): 6.7 8.3 10.3 13.0 16.3 20.3 25.3 31.7 39.7 49.7 62.0
- Фон F7F2E7, поверхности FFFDF6, стакан ECE5D6, текст 33291A, акцент F76B15, тревога E5484D
- Шрифт Archivo (файлы в `core/resources/fonts/` — скачать, см. README), счёт tabular-nums, primary-кнопка: градиент FF8A34→F76B15, тень 0 6 0 D95806
- Мокапы: `WasDrop Mockups.dc.html` в дизайн-проекте; полное ТЗ — `.claude/my_docs/WASDROP.md`

## Геймплей (TODO — ядро набросано в `features/lib/game/engine/wasdrop_game.dart`)
- Слияние: два одинаковых тира при контакте → тир+1, счёт += 2^tier, вспышка+«+N»
- Проигрыш: шар выше линии (y < deadlineY) дольше 1.5 c
- Очередь: текущий + следующий шар, тиры 1–5 случайно (веса 5:4:3:2:1)
- Продолжение за рекламу — заглушка (`continueAfterAd` в GameCubit); в dev — тестовые блоки (`AppConfig.useTestAds`)
