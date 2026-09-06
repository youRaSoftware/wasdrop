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
- iOS: конфигурации `Debug|Release|Profile-dev|prod`, схемы `dev` / `prod`, `APP_DISPLAY_NAME` → `CFBundleDisplayName`. CocoaPods не используется (все плагины — Swift Packages); если появится плагин без SwiftPM и Flutter сгенерирует Podfile — добавить в него маппинг `'Debug-dev' => :debug` и т.д. и инклюды `Pods-Runner.debug-dev.xcconfig` в `ios/Flutter/*.xcconfig`.
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

Смоук-тест игры на симуляторе/устройстве (меню → игра → слияние → броски), `integration_test/game_smoke_test.dart`:

```bash
flutter test integration_test -d <deviceId> --flavor dev --dart-define=environment=dev
```

Два обязательных правила для таких тестов: (1) `binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive`, иначе движок тикает только на `pump()` и `pump(3 s)` даёт физике один шаг с dt = 3 с (шары пролетают друг сквозь друга); (2) никакого `pumpAndSettle` — Flame рисует кадры непрерывно, и он никогда не вернётся, только `pump(Duration)`.

## Структура пакетов
- **core/** — `AppConfig`/`Flavor`, DI (`app_di.dart`), константы роутов и Hive-боксов; реэкспортирует bloc/get_it/go_router/navigation
- **core_ui/** — `AppColors`, `AppFonts`, `AppDimens`, `lightTheme`, виджеты `AppScaffold`, `PrimaryButton`, `IconCircleButton`, `BallView`
- **domain/** — `BallTier`, `GameStatsModel`, `SettingsModel`, интерфейсы репозиториев
- **data/** — Hive-провайдеры (`providers/local/`), реализации репозиториев, `DataDI.init()`
- **features/** — `menu/`, `game/` (cubit, screen, widgets, `engine/` — Flame/Forge2D)
- **navigation/** — `AppRouter` (go_router, `/menu`, `/game`, fade-переход)

Паттерны и стиль — `.claude/shared/wasdrop_ui_reference.md`.

## Иконки приложения
- iOS: `ios/Runner/Assets.xcassets/AppIcon.appiconset` (prod) и `AppIcon-Dev.appiconset` (с плашкой DEV); dev-конфигурации в pbxproj используют `ASSETCATALOG_COMPILER_APPICON_NAME = "AppIcon-Dev"`.
- Android: `android/app/src/main/res/mipmap-*/ic_launcher.png` + адаптивная иконка `mipmap-anydpi-v26/ic_launcher.xml` (фон — градиент `drawable/ic_launcher_background.xml`, передний план `ic_launcher_foreground.png`); dev-вариант с плашкой лежит в `android/app/src/dev/res/`.
- Store-размеры и Icon Composer-бандл — `store/` (`appstore_icon_1024.png`, `playstore_icon_512.png`, `AppIcon.icon`).
- Плашка DEV: `script/gen_dev_icons.sh` (Swift/CoreGraphics в `script/make_dev_icons.swift`) берёт исходники из `store/` и перегенерирует `AppIcon-Dev.appiconset` и `android/app/src/dev/res`. При смене иконки: разложить prod-набор руками, затем запустить скрипт.

## Дизайн (вариант 1a, фруктовый)
- Палитра тиров 1–11: E5484D F76B15 EFB008 8FBF1F 3BA55C 12A594 00A2C7 0090FF 6E56CF AB4ABA E93D82 (`core_ui/lib/src/theme/app_colors.dart`)
- Маркер тира: эмодзи-фрукты 🍒🍓🍊🍋🍏🥝🫐🍇🍑🍈🍉 (`BallTier.emoji`), запасной канал — цифра
- Радиусы шаров (мировые единицы, мир 360 wide): 12 15 19 24 30 37 46 56 70 86 105 (увеличены относительно мокапа до пропорций классической suika, 2026-09-06); высота мира — от пропорции виджета стакана
- Фон F7F2E7, поверхности FFFDF6, стакан ECE5D6, текст 33291A, акцент F76B15, тревога E5484D
- Шрифт Archivo (600/800/900, OFL, файлы в `core/resources/fonts/`), счёт tabular-nums, primary-кнопка: градиент FF8A34→F76B15, тень 0 6 0 D95806
- Мокапы: `WasDrop Mockups.dc.html` в дизайн-проекте; полное ТЗ — `.claude/my_docs/WASDROP.md`

## Движок
- flame 1.38 + flame_forge2d 0.20 (forge2d 0.15 = привязка к Box2D v3, API `BodyDef`/`ShapeDef`/`Circle`/`Segment`, контакты через `ContactCallbacks` в `userData`). Flame с 1.38 на 32-битном `vector_math` — не понижать версии по отдельности.
- Мир в «логических» единицах (ширина 360), для Box2D объявлено `lengthUnitsPerMeter: 36` (стакан ≈ 10 м в ширину, высота от пропорции виджета). Гравитация 400 ед/с².
- `WasDropGame.onRemove` уничтожает физический мир (Box2D ограничивает число миров).
- Стенки стакана — толстые (40 ед.) статические коробки за краем видимой области, `subStepCount = 8`; высота мира пересчитывается в `onGameResize`.

## Звук, хаптика, кнопки
- `AudioService` (`core/lib/services/audio_service.dart`, в `appLocator`): настройки звука/вибрации (`settings` — `ValueNotifier<SettingsModel>`, сохраняются через `SettingsRepository`), музыка-луп через `FlameAudio.bgm`, SFX через `FlameAudio.play`. События: `tap()`, `drop()`, `merge(tier)`, `gameOver(isRecord:)`. Ошибки аудио не роняют игру.
- Ассеты в `core/resources/audio/` — **плейсхолдеры**, синтезированы `script/gen_placeholder_audio.py` (SFX wav + `music_loop.m4a`, iOS не играет OGG). Заменять, сохраняя имена файлов.
- Кнопки дизайн-системы построены на `AppPressable` (степень нажатия 0…1 в builder) и дёргают `ButtonFeedback.trigger()`; хук назначается в `lib/main_common.dart` на `AudioService.tap`. В core_ui нет прямых вызовов `HapticFeedback`.
- Оверлеи — `AppOverlay` (затемнение `scrim` + панель с анимацией появления); тумблеры — `AppToggleRow`; вторичные кнопки — `SecondaryButton` (filled/outlined), текстовые — `AppTextButton`.

## Геймплей (TODO — ядро в `features/lib/game/engine/wasdrop_game.dart`)
- Слияние: два одинаковых тира при контакте → тир+1, счёт += 2^tier; эффекты в `engine/merge_effects.dart` (`MergeFlash`, `ScorePopup`) + `BallBody(popIn: true)`
- Управление: текущий шар висит вверху (y = 44) и едет за пальцем, отпускание/тап — бросок, кулдаун 450 мс; пунктир прицела — рейкаст вниз до первого препятствия
- Проигрыш: покоящийся шар выше линии (y < 96) дольше 1.5 c
- Очередь: текущий + следующий шар, тиры 1–5 случайно (веса 5:4:3:2:1)
- Продолжение за рекламу — заглушка (`continueAfterAd` в GameCubit); в dev — тестовые блоки (`AppConfig.useTestAds`)
- ⚙️ в меню — заглушка, экран настроек не сделан (Фаза 3)
