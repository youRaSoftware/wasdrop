# WasDrop (Fruity Drop) — заметки для Claude Code

Merge-drop игра (жанр suika). Витринное название — **Fruity Drop: Merge Puzzle** (в сторах, задаётся в App Store Connect / Google Play Console), под иконкой — **Fruity Drop** (dev — **Fruity Dev**): `APP_DISPLAY_NAME` в pbxproj, `resValue app_name` в gradle, `AppConfig.appName`. Внутреннее имя проекта, пакетов и bundle id остаётся `wasdrop` / `com.wasdrop`. Flutter, без сети. Архитектура скопирована с water_tracker / rvach: пакеты core / core_ui / domain / data / features / navigation, BLoC (Cubit), get_it (`appLocator`), go_router, Hive. Отличия: нет dio/retrofit, нет ui_kit_alpha (core_ui самодостаточен), добавлен flame_forge2d для физики. Идентификаторы: `com.wasdrop` (prod), `com.wasdrop.dev` (dev) — другие org-префиксы в проекте не используем.

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
│   ├── STORE_BRIEF.md          # Бриф о продукте для чата Claude: тактика листингов на 6 языках
│   ├── TZ_BONUS_ASSETS.md      # ТЗ на ассеты бонусов «Встряхнуть» и «Бомбочка» (для Claude Design)
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
- Ориентация — только портрет, на трёх уровнях: `SystemChrome.setPreferredOrientations` в `lib/main_common.dart`, `UISupportedInterfaceOrientations` (+ `UIRequiresFullScreen`, без него App Store требует все ориентации для iPad multitasking) в Info.plist, `android:screenOrientation="portrait"` в манифесте. Нативные нужны для экрана запуска и iPad.
- iOS: минимальная версия 15.0 (требование App Store с 2027), `ITSAppUsesNonExemptEncryption = false` в Info.plist; конфигурации `Debug|Release|Profile-dev|prod`, схемы `dev` / `prod`, `APP_DISPLAY_NAME` → `CFBundleDisplayName`. Подпись: команда Pavel Hrytsenka, `DEVELOPMENT_TEAM = 4YLBF6N3R4` во всех конфигурациях (тот же `IOS_TEAM_ID` в `script/build.sh`); не менять на другие команды из связки ключей. CocoaPods не используется (все плагины — Swift Packages); если появится плагин без SwiftPM и Flutter сгенерирует Podfile — добавить в него маппинг `'Debug-dev' => :debug` и т.д. и инклюды `Pods-Runner.debug-dev.xcconfig` в `ios/Flutter/*.xcconfig`.
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

Два обязательных правила для таких тестов: (1) `binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive`, иначе движок тикает только на `pump()` и `pump(3 s)` даёт физике один шаг с dt = 3 с (шары пролетают друг сквозь друга); (2) никакого `pumpAndSettle` — Flame рисует кадры непрерывно, и он никогда не вернётся, только `pump(Duration)`; (3) после ухода с игрового экрана не трогать тела старого `WasDropGame`: его мир Box2D уничтожен в `onRemove`, а хэндлы тел не знают об этом — чтение `body.position` возвращает мусор или роняет процесс SIGSEGV (так однажды упал сам тест, печатая позиции первой партии после «Продолжить»).

## Структура пакетов
- **core/** — `AppConfig`/`Flavor`, `AdsConfig`, `AppLinks`, DI (`app_di.dart`), сервисы `SettingsService`/`AudioService`/`PremiumService`/`AdsService`, `ShakeDetector` (акселерометр через `sensors_plus`, не в DI — живёт с игровым экраном), локализация (`localization/`: `AppLocalizationEnum`, `LocaleKeys`, `FruitLabel`; переводы в `resources/translations/`), константы роутов и Hive-боксов; реэкспортирует bloc/get_it/go_router/navigation/easy_localization
- **core_ui/** — `AppColors`, `AppFonts`, `AppDimens`, `lightTheme`, виджеты `AppScaffold`, `PrimaryButton`, `IconCircleButton`, `BallView`
- **domain/** — `BallTier` (эмодзи как fallback, `next`, `fromNumber`), `GameStatsModel` (рекорд, игры, слияния, лучший тир), `SettingsModel` (звуки, музыка, вибрация, линия прицела, тема-обои `themeId`, язык `localeCode`), `GameSnapshot`/`BallSnapshot` (сохранённая партия), `GameRules` (заряды, продолжения, пополнения), `PremiumProducts`, интерфейсы репозиториев (`StatsRepository`, `SettingsRepository`, `GameRepository`, `PremiumRepository`)
- **data/** — Hive-провайдеры (`providers/local/`), реализации репозиториев, `DataDI.init()`
- **features/** — `splash/` (экран + `engine/splash_game.dart`), `menu/`, `premium/` (paywall), `game/` (cubit, screen, widgets — HUD, оверлеи, `bonus_bar.dart`; `engine/` — Flame/Forge2D: `physics_tuning.dart`, общий мир `jar_physics_world.dart`, стенки `jar_walls.dart`, эффекты `merge_effects.dart` / `bonus_effects.dart`, спрайты `fruit_sprites.dart` / `fx_sprites.dart`), `settings/` (cubit, screen, widgets)
- **navigation/** — `AppRouter` (go_router, стартовый `/splash`, затем `/menu`, `/game`, `/settings`, `/premium`, fade-переход)

Паттерны и стиль — `.claude/shared/wasdrop_ui_reference.md`.

## Иконки приложения
- iOS: `ios/Runner/Assets.xcassets/AppIcon.appiconset` (prod) и `AppIcon-Dev.appiconset` (с плашкой DEV); dev-конфигурации в pbxproj используют `ASSETCATALOG_COMPILER_APPICON_NAME = "AppIcon-Dev"`.
- Android: `android/app/src/main/res/mipmap-*/ic_launcher.png` + адаптивная иконка `mipmap-anydpi-v26/ic_launcher.xml` (фон — градиент `drawable/ic_launcher_background.xml`, передний план `ic_launcher_foreground.png`); dev-вариант с плашкой лежит в `android/app/src/dev/res/`.
- Store-размеры и Icon Composer-бандл — `store/` (`appstore_icon_1024.png`, `playstore_icon_512.png`, `AppIcon.icon`).
- Плашка DEV: `script/gen_dev_icons.sh` (Swift/CoreGraphics в `script/make_dev_icons.swift`) берёт исходники из `store/` и перегенерирует `AppIcon-Dev.appiconset` и `android/app/src/dev/res`. При смене иконки: разложить prod-набор руками, затем запустить скрипт и `script/gen_launch_images.sh`.
- Нативный экран запуска (до первого кадра Flutter): кремовый фон `F7F2E7` и иконка со скруглёнными углами 120 pt/dp по центру. iOS — `LaunchScreen.storyboard` + `LaunchImage.imageset` (1x/2x/3x); Android — `drawable*/launch_background.xml` (цвет `@color/launch_background` + `drawable-*/launch_image.png`), на Android 12+ системный splash берёт тот же фон из `values-v31/styles.xml` (и `values-night-v31`, потому что квалификатор `night` перебивает `v31`). Картинки генерирует `script/gen_launch_images.sh` (Swift `script/make_launch_image.swift`, скругление 22.37 % стороны как у домашнего экрана iOS) из `store/appstore_icon_1024.png`. iOS кэширует storyboard — после правок переустанавливать приложение.

## Дизайн (вариант 1a, фруктовый)
- Палитра тиров 1–11: E5484D F76B15 EFB008 8FBF1F 3BA55C 12A594 00A2C7 0090FF 6E56CF AB4ABA E93D82 (`core_ui/lib/src/theme/app_colors.dart`)
- Маркер тира: эмодзи-фрукты 🍒🍓🍊🍋🍏🥝🫐🍇🍑🍈🍉 (`BallTier.emoji`) — только как запасная отрисовка без спрайта; в UI эмодзи больше не используются (иконки — SVG, см. ниже)
- Радиусы шаров (мировые единицы, мир 360 wide): 15 19 24 30 37 46 56 70 86 105 130 (крупнее мокапа и классической suika: вишня 8 % ширины, арбуз 72 %; 2026-09-07); высота мира — от пропорции виджета стакана
- Тема cream (по умолчанию): фон F7F2E7, поверхности FFFDF6, стакан ECE5D6, текст 33291A, акцент F76B15, тревога E5484D; остальные темы — см. «Темы-обои» ниже
- Шрифты (ТЗ `.claude/my_docs/TZ_ASSETS.md`): **Rubik** 600/700/900 — весь UI, счёт (tabular-nums), кнопки; **Unbounded** 600/800 — лого и заголовки оверлеев (`AppFonts.display`). Оба OFL, TTF в `core/resources/fonts/`, лицензии `OFL-Rubik.txt` / `OFL-Unbounded.txt` регистрируются в `LicenseRegistry` (`lib/main_common.dart`). Primary-кнопка: градиент FF8A34→F76B15, тень 0 6 0 D95806
- Иконки UI — SVG 24×24 в `core_ui/assets/icons/` (штрих 33291A 1.8 px, заливки из палитры; метаданные c2pa из исходников вырезаны), виджет `AppIcon(AppIcons.trophy | soundOn | soundOff | settings | pause | restart | menuHome | adPlay | shake | bomb | upgrade | crown)` на `flutter_svg`. Многоцветные, не перекрашиваются — ставить на светлые подложки. Кнопки `PrimaryButton`/`SecondaryButton`/`AppTextButton` принимают `icon`. Стрелка «назад» и шевроны — Material.
- Темы-обои: `GameTheme`/`GameThemes` (`core_ui/lib/src/theme/game_theme.dart`; cream по умолчанию, sunset, mint, night, rose, sky; поля bgTop/bgBottom, jarFill (часто полупрозрачный), jarWall, deadline/deadlineAlert, hudText, decor, isLocked — премиум-тема: mint, night, rose, sky; `GameThemes.lockedIds`). Выбор — `SettingsModel.themeId` (Hive `themeId`), `SettingsService.setThemeId`. Доставка в UI — `AppThemeScope` (InheritedWidget, ставится в `lib/app.dart` из настроек; `AppThemeScope.of(context)`): `AppScaffold` рисует градиент и статичный декор (`ThemeDecorLayer`: звёзды/облака/лепестки), HUD/меню/настройки красят текст `hudText`, `GameForm` — стакан, `_JarOverlay` — линию и прицел; движок фон не рисует (`backgroundColor` прозрачный). Пикер `ThemePicker` — в паузе и в настройках («Игра → Обои»), ключи кружков `theme_<id>`; закрытые (`lockedIds`) рисуются с замком-бейджем и по тапу зовут `onLockedTap` (paywall). Панели/кнопки/карточки во всех темах светлые `surface`.
- Мокапы: `WasDrop Mockups.dc.html` в дизайн-проекте; полное ТЗ — `.claude/my_docs/WASDROP.md`

## Движок
- flame 1.38 + flame_forge2d 0.20 (forge2d 0.15 = привязка к Box2D v3, API `BodyDef`/`ShapeDef`/`Circle`/`Segment`, контакты через `ContactCallbacks` в `userData`). Flame с 1.38 на 32-битном `vector_math` — не понижать версии по отдельности.
- **Все числа физики — в `features/lib/game/engine/physics_tuning.dart`** (`PhysicsTuning`), крутить «на ощупь» только там. Мир в «логических» единицах (ширина 360), для Box2D объявлено `unitsPerMeter = 120` (стакан ≈ 3 м; от масштаба зависят только допуски: спекулятивная дистанция контакта 0.02 м = 2.4 ед., люфт покоя 0.6 ед.; Box2D фиксирует масштаб при первом мире — источник один). Гравитация 1000 ед/с², потолок скорости 800 ед/с (бросок сверху донизу ≈ 1–1.3 с; 1500 казалось слишком быстро, 400 — «ватно»).
- Число шагов Box2D на кадр адаптивное (`_JarWorld`): `ceil(dt · maxSpeed / speculativeDistance)`, при 60 fps = 6, максимум 24; кадр длиннее 1/30 с замедляется, а не догоняется. Причина: Box2D заводит контакт только на спекулятивной дистанции, а CCD включает лишь телам, проходящим за шаг больше половины радиуса — если шар проходит за шаг больше 2.4 ед., контакт с дном возникает уже внутри дна (вишня проваливалась на 16 % диаметра и всплывала). `WorldDef` создаётся вручную: forge2d передаёт скорости (`maxContactPushSpeed`, `restitutionThreshold`, `hitEventThreshold`, `BodyDef.sleepThreshold`) в Box2D без пересчёта в единицы мира, поэтому «метровые» дефолты умножены на `unitsPerMeter`; `contactHertz = 120`.
- Материал фрукта: friction 0.5, restitution 0.12, rollingResistance 0.02, angularDamping 0.6. Box2D умножает лимит сопротивления качению на радиус *большего* из двух тел (`contact.c`: `max(rrA, rrB) * maxRadius`), поэтому при 0.1 вишня на плече арбуза была «приклеена»; торможение качения по дну даёт угловое демпфирование.
- Слияние — по контакту Box2D (`beginContact` с шаром того же тира; он возникает уже при зазоре ≤ 2.4 ед., под выступом спрайта это незаметно). Более строгий порог «по реальному касанию» пробовали и откатили: пары, улёгшиеся вплотную с зазором 1–2 ед., не сливались вовсе. Новый шар наследует взвешенную по массе скорость родителей (потолок 600 ед/с), его круг зажат внутри стакана (`merge()`), а составляющая скорости «в стену» гасится: иначе более крупный шар на дне/у стенки сразу пересекал пол и Box2D выталкивал его 100–200 мс — выглядело как «проваливание».
- `WasDropGame.onRemove` уничтожает физический мир (Box2D ограничивает число миров). Мир (`JarPhysicsWorld.standard()`, адаптивные шаги) и стенки (`buildJarWalls`) общие для игры и сплеша.
- Сплеш (`features/lib/splash/`): `SplashGame` на том же движке и `BallBody` — 16 фруктов (t1–t9, мелкие чаще) сыплются сверху каждые 90 мс и складываются в кучу у нижнего края экрана (стенки — края экрана, слияний нет), поверх проявляется лого; через 2.6 с или по тапу — `goNamed('menu')`. Стартовый роут `/splash`. До него — нативный экран запуска с иконкой на кремовом фоне (см. «Иконки приложения»).
- Сохранение партии: `GameRepository` (Hive-бокс `gameBox`, ключ `snapshot`, `GameSnapshot` — счёт, очередь, слияния, лучший тир, шары как `[tier, x, расстояние до дна, угол, vx, vy]`; расстояние до дна вместо y, потому что высота мира зависит от экрана). `GameForm` сохраняет по таймеру раз в 2 с, при уходе приложения в фон (`WidgetsBindingObserver`) и перед выходом в меню; `gameOver`/`restart` стирают снимок, пустая партия тоже. Меню при наличии снимка показывает «Продолжить» (`goNamed('game', extra: snapshot)`) и «Новая игра»; восстановленная партия открывается в паузе (`GameCubit(resumeFrom:)`, шары ставит `WasDropGame._restore` с сохранённым углом через `BallBody.initialAngle`).
- Рекорд «живой»: `GameCubit.onMerge` поднимает `bestScore` в состоянии, как только счёт его превысил, и сразу сохраняет в `StatsRepository` (`_persistBest`); «НОВЫЙ РЕКОРД» сравнивает счёт с рекордом на начало партии (`_startBest`). Раньше рекорд писался только при закрытии кубита, а он закрывается после fade-перехода — меню успевало прочитать старое значение.
- Стенки стакана — толстые (40 ед.) статические коробки за краем видимой области; высота мира пересчитывается в `onGameResize`.

## Звук, хаптика, кнопки
- `SettingsService` (`core/lib/services/settings_service.dart`, в `appLocator`): все настройки (`settings` — `ValueNotifier<SettingsModel>`: `soundOn`, `musicOn`, `hapticsOn`, `aimLineOn`, `themeId`), сохраняются через `SettingsRepository`; тумблеры в меню/паузе/настройках зовут `setSoundOn`, `setThemeId` и т.д. Движок получает нотифаер через `WasDropGame(settings:)` и читает `aimLineOn` (линия прицела).
- `AudioService` (`core/lib/services/audio_service.dart`, в `appLocator`, принимает `SettingsService`): подписан на настройки, музыка-луп через `FlameAudio.bgm` играет при `soundOn && musicOn`, SFX через `FlameAudio.play`. События: `tap()`, `drop()`, `merge(tier)`, `gameOver(isRecord:)`, `shake()`, `bomb()`. Ошибки аудио не роняют игру.
- Экран настроек `/settings` (`features/lib/settings/`, открывается из ⚙️ в меню через `pushNamed`): секции «Премиум» (ссылка на paywall или статус), «Звук» (Звуки / Музыка / Вибрация), «Игра» (Линия прицела, Обои — `ThemePicker`, Язык — `LanguageOverlay`), «Статистика» (рекорд, игр, слияний, самый большой фрукт; сброс с подтверждением), «Фрукты» (цепочка 11 спрайтов, `BallTier.title`), «О приложении» (версия через `package_info_plus`, «Лицензии» → `showLicensePage`, «Восстановить покупки», «Настройки рекламы» по требованию UMP; OFL шрифтов Rubik и Unbounded регистрируются в `lib/main_common.dart` из `core/resources/fonts/OFL-*.txt`). Статистика партии (`merges`, `bestTier`) копится в `GameState` и записывается в `StatsRepository` при проигрыше, рестарте и закрытии кубита.
- Ассеты в `core/resources/audio/` — **плейсхолдеры**, синтезированы `script/gen_placeholder_audio.py` (SFX wav + `music_loop.m4a`, iOS не играет OGG). Заменять, сохраняя имена файлов.
- Кнопки дизайн-системы построены на `AppPressable` (степень нажатия 0…1 в builder) и дёргают `ButtonFeedback.trigger()`; хук назначается в `lib/main_common.dart` на `AudioService.tap`. В core_ui нет прямых вызовов `HapticFeedback`.
- Оверлеи — `AppOverlay` (затемнение `scrim` + панель с анимацией появления); тумблеры — `AppToggleRow`; вторичные кнопки — `SecondaryButton` (filled/outlined), текстовые — `AppTextButton`.

## Премиум и реклама (iOS, релиз 1.0)
- **Покупка «Премиум навсегда»** — non-consumable `com.wasdrop.premium.lifetime` (`PremiumProducts`, domain), 7.99 USD, заведена в App Store Connect. Даёт: без рекламы, все обои (`GameTheme.isLocked`: mint, night, rose, sky; бесплатные — cream, sunset), продолжение и пополнение зарядов без роликов (лимиты те же). `PremiumService` (`core/lib/services/premium_service.dart`, в `appLocator`): `isPremium` (ValueNotifier, кэш в Hive `premiumBox` через `PremiumRepository` — офлайн работает), `store` (цена из стора / недоступен), `events` (purchased/restored/nothingToRestore/pending/cancelled/failed), `buy()`, `restore()`; плагин `in_app_purchase` (StoreKit 2, верификация транзакций на стороне StoreKit, сервера нет). `lib/app.dart` откатывает закрытую тему на cream, если премиума нет.
- **Paywall** — `features/lib/premium/` (`PremiumCubit`, `PremiumScreen`/`PremiumForm`), роут `/premium` через `pushNamed('premium')`. Входы: замок в `ThemePicker` (`lockedIds`/`onLockedTap`; пауза и настройки), секция «Премиум» в настройках, «Убрать рекламу» на экране проигрыша. Обязательное для Apple: «Восстановить покупки» (paywall + «О приложении»), ссылки на политику (`AppLinks.privacyPolicy` — **TODO вписать URL**) и стандартную EULA Apple (`AppLinks.termsOfUse`), `url_launcher`.
- **Тест покупки**: dev-флейвор `com.wasdrop.dev` продуктов в ASC не имеет — запуск схемы `dev` **из Xcode** использует `ios/Runner/Products.storekit` (StoreKit Configuration, подключён в `dev.xcscheme`); при `flutter run` paywall покажет «App Store недоступен». Sandbox с тестером — prod-сборка на устройстве (`script/run.sh prod`). Тесты: `PremiumService.setPremium()` (`@visibleForTesting`).
- **Реклама** — `AdsService` (`core/lib/services/ads_service.dart`, `google_mobile_ads`): только iOS (`supported`), у премиума не инициализируется. `init()` в фоне из `setupAppScope`: UMP-согласие (`requestConsentInfoUpdate` → `loadAndShowConsentFormIfRequired`; в dev debug-география EEA) → `MobileAds.initialize` → предзагрузка rewarded. `showRewarded(AdPlacement.continueGame|refill)` → `earned | dismissed | unavailable` (таймаут загрузки 8 с), музыка на время ролика останавливается. ID — `AdsConfig` (`core/lib/config/ads_config.dart`): в dev тестовые Google, в prod **TODO** после создания аккаунта AdMob (app id и два rewarded-блока); Info.plist: `GADApplicationIdentifier = $(GAD_APPLICATION_ID)` (pbxproj, во всех конфигурациях пока тестовый id), `SKAdNetworkItems` (50 штук из документации Google), `NSUserTrackingUsageDescription`; `OTHER_LDFLAGS -ObjC` для GMA SDK. Настройки → «О приложении» → «Настройки рекламы» появляется, когда UMP требует (`privacyOptionsRequired`). Android: `INTERNET` и `APPLICATION_ID` в манифест не добавлены — до Android-релиза.
- Перед выкладкой: реальные AdMob ID, URL политики, App Privacy в ASC (Device ID, Product Interaction, Advertising Data, Crash/Performance/Other Diagnostics — Third-Party Advertising), скриншот paywall в карточке покупки.

## Локализация
- `easy_localization` (как в rvach). Языки: en (основной и fallback), ru, de, fr, hu, ja. Переводы — `core/resources/translations/<lang>-<REGION>.json` (ассеты `core/pubspec.yaml`), одинаковая структура ключей во всех шести файлах.
- Ключи — сгенерированный `LocaleKeys` (`core/lib/localization/locale_keys.g.dart`, коммитится): `script/prebuild_script.sh` перегенерирует его после pub get (`dart run easy_localization:generate -f keys -o locale_keys.g.dart -O lib/localization -S resources/translations` в `core/`). В виджетах — **`context.tr(LocaleKeys.menu_play)`** (форма с контекстом подписывает виджет на смену языка; `LocaleKeys.x.tr()` без контекста оставляет const-экраны вроде меню со старым текстом до пересоздания), плейсхолдер `{score}` через `namedArgs:`; вне виджетов (тесты) — `LocaleKeys.x.tr()`. **Литералов в виджетах нет**: новый текст = ключ во все шесть JSON (сначала английский) + перегенерация. Капс — в переводе, не `toUpperCase()`.
- Названия фруктов — `FruitLabel.of(context, tier)` (core), тем — `themeLabel(context, theme)` (`features/lib/settings/widgets/theme_label.dart`); у `BallTier` и `GameTheme` названий нет. Имена языков (`AppLocalizationEnum.languageDisplayName`) — на самом языке, не переводятся.
- Подключение: `lib/main_common.dart` оборачивает `App` в `EasyLocalization(startLocale: из настроек, saveLocale: false)`; `lib/app.dart` отдаёт `context.localizationDelegates / supportedLocales / locale` в `MaterialApp.router`. Выбранный язык — `SettingsModel.localeCode` (null = системный, Hive-ключ `locale`); пикер `LanguageOverlay` в настройках («Игра → Язык») зовёт `SettingsService.setLocale` **и** `context.setLocale` / `context.resetLocale`. Устройство с языком вне списка получает английский.
- iOS: `CFBundleLocalizations` в `Info.plist` (en, ru, de, fr, hu, ja). Японские глифы — системный шрифт через fallback (Rubik/Unbounded их не содержат).
- Переводы на de/fr/hu/ja написаны без носителей — перед релизом показать носителям.

## Спрайты фруктов (ТЗ — `.claude/my_docs/TZ_SPRITES.md`)
- Спрайты бонусов — `features/assets/images/fx/` (`bomb.png`, `boom_1..3.png`, `shake_hint.png`, 512×512), грузит `FxSprites`; без файлов эффекты рисуются процедурно.
- Файлы `features/assets/images/fruits/t{N}_idle.png` / `t{N}_squish.png` (512×512, прозрачный фон), объявлены в `features/pubspec.yaml`; ключ ассета `packages/features/assets/images/fruits/...`. Есть все 11 фруктов; без спрайта (например, у нового тира) — fallback градиент + эмодзи (`BallBody.paintBall`). HUD «следующий шар» и шары в меню показывают те же спрайты через `BallView(image: FruitAssets.idle(tier))`.
- **Физическая форма берётся из спрайта** (`FruitSprite.shape`, измеряется по альфа-каналу при загрузке, порог 200, чтобы не считать телом ореол после удаления фона; в каждой строке — самый длинный непрозрачный отрезок). Сначала подгоняется круг: контур — края строк шире 60 % от самой широкой (без стебля/листика), круг прижат к нижней точке силуэта, X центра — середина самой широкой строки, радиус — методом наименьших квадратов. Если контур отклоняется от круга ≤ 5 % — тело круг (восемь фруктов, 0.7–3.8 %). Иначе (виноград, лимон, клубника: 8–12 %) — **скруглённый многоугольник Box2D** (`Polygon(points, radius:)`, ≤ 8 вершин): тело — строки от первой шире 20 % до низа, в 8 направлениях берутся опорные точки силуэта, сдвигаются внутрь на радиус скругления ρ (0.4–0.8 наименьшего полугабарита, выбирается по наименьшему расхождению опорных функций силуэта и формы в 72 направлениях; остаток 2–3 %). Номинальный радиус тира (`AppDimens.ballRadii`) для многоугольника = средняя опорная функция; `FruitSprite.extent/minExtent` — наибольший/наименьший полугабарит (спавн при слиянии, тесты «не ниже пола»). Такие фрукты катятся с покачиванием и ложатся на бок. Прежняя оценка круга «среднее полуширины и полувысоты» занижала высоту круглого тела (строка 60 % ширины у круга на 0.2 R ниже макушки) и давала круг на 3–5 % уже спрайта — соседи «заходили друг на друга». Стебель/листик выступают за форму — это норма. Требование «95 % кадра» из ТЗ соблюдать вручную не нужно, но под фруктом в PNG не должно быть теней.
- Стакан в `GameForm`: холст лежит внутри обводки (`Padding` на `jarWallWidth`), физическое дно = верх стенки; нижние углы скруглены `jarInnerCornerRadius`, а в физике им соответствуют 45° скосы, чтобы фрукт в углу не обрезался.
- Реакция на удар в `BallBody`: скорость до удара берётся из прошлого `update`, порог `squishSpeed = 60`, сплющивание 1.12×0.88 → 1 за 250 мс (easeOutBack, в мировых осях), рот открыт 300 мс, debounce 400 мс. Дно и стенки помечены `userData: JarWalls()`, иначе Forge2D не дал бы `beginContact`.

## Геймплей (TODO — ядро в `features/lib/game/engine/wasdrop_game.dart`)
- Слияние: два одинаковых тира при касании → тир+1 с унаследованным импульсом, счёт += 2^tier; эффекты в `engine/merge_effects.dart` (`MergeFlash`, `ScorePopup`) + `BallBody(popIn: true)`
- Управление: текущий шар висит вверху (y = 44) и едет за пальцем, отпускание/тап — бросок, кулдаун 450 мс; пунктир прицела — рейкаст вниз до первого препятствия
- Проигрыш: покоящийся шар выше линии (y < 96) дольше 1.5 c
- Очередь: текущий + следующий шар, тиры 1–5 случайно (веса 5:4:3:2:1; `GameCubit.firstDropTier`)
- Продолжение и пополнение зарядов (2026-09-11): `GameCubit.requestContinue()` (одно на партию, `GameRules.continuesPerGame`) показывает rewarded-ролик (премиуму — сразу), затем `GameForm._continue` зовёт `WasDropGame.clearTopLayer()` (снимает фрукты с центром выше `deadlineY + PhysicsTuning.continueClearDepth` и всё, что выше линии, со вспышками) и `resumeAfterContinue()`. Кнопка бонуса без зарядов предлагает пополнение (`requestRefill`, `GameRules.refillsPerBonus` раз за партию на бонус; бейдж с иконкой рекламы, у премиума «+»). Лимиты живут в `GameState.continues/*Refills` и в снимке партии. Статистика: после продолжения партия не считается второй раз (`_continued`), слияния пишутся дельтой (`_savedMerges`).
- Бонусы (2026-09-10, ТЗ на ассеты `.claude/my_docs/TZ_BONUS_ASSETS.md`): полоса `BonusBar` под стаканом, заряды на партию в `GameRules` (domain: встряска 3, бомбочка 1, увеличение 1), остаток — в `GameState.shakes/bombs/upgrades` и в снимке партии. Кнопка **взводит** бонус (`GameCubit.armBonus`, `GameState.armed: Bonus?`, один за раз; повторный тап, пауза и проигрыш снимают), над стаканом висит пилюля-подсказка (`GameForm.bonusHintKey`). **Встряхнуть**: взведён → ждём `ShakeDetector` (акселерометр без гравитации, порог 15 м/с²; `ShakeDetector.simulate()` — для тестов и симулятора, у которого датчика нет) → `useShake()` (заряд, звук) → `WasDropGame.shake()`: прирост скорости вверх 560 ед/с у дна (×0.45 у линии проигрыша, своя случайная доля 0.6–1 у каждого фрукта) и ±240 вбок, вращение, все «ойкают», камера дрожит 0.4 с; кулдаун 1.5 с в движке; боковые стенки продолжены на 300 ед. выше верха (`wallTopMargin`), чтобы фрукт не перелетел через стенку. **Бомбочка** и **Увеличить** — режим выбора (`pickMode`): стакан приглушён, подвешенный фрукт и прицел скрыты, бросок заблокирован; тап по фрукту → `pickAt`: бомбочка — `explode` (заряд списан сразу, фрукт помечен `merging`, 0.3 с `BombFuse` со спрайтом `fx/bomb.png`, затем `BoomEffect` из `fx/boom_N.png` и радиальный толчок соседей в 2.5 радиуса); увеличение — `upgrade` (фрукт на месте заменяется следующим тиром с «попом» и `MergeFlash`, очков нет, `bestTier` обновляется; арбуз только «ойкает»); тап мимо — отмена. Спавн внутри стакана общий со слиянием (`_spawnInside`). Числа — `PhysicsTuning` («Бонусы»). Иконка `upgrade.svg` — временная, нарисована вручную, ждёт дизайнера.
- ⚙️ в меню — экран настроек `/settings` (см. «Звук, хаптика, кнопки»)
