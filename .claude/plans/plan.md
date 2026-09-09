# WasDrop — План разработки

> Merge-drop игра (жанр suika): роняем шары в стакан, два одинаковых сливаются в следующий тир.
> Стек: Flutter + Cubit (flutter_bloc) + get_it + go_router + Hive + flame_forge2d. Без сети.
> ТЗ и дизайн-токены: [my_docs/WASDROP.md](../my_docs/WASDROP.md) · UI-референс для скиллов: [shared/wasdrop_ui_reference.md](../shared/wasdrop_ui_reference.md)

---

## Текущий статус: **Фаза 3 — полировка: физика, настройки**

Движок на flame 1.38 + flame_forge2d 0.20 (Box2D v3), все 11 спрайтов, звук, экран настроек; смоук-тест (`integration_test/game_smoke_test.dart`) проходит на iOS-симуляторе. Ближайшая цель — тревога у линии, rewarded ad, splash, Android.

---

## Что уже сделано

### Инфраструктура
- [x] Мультипакетная структура: core / core_ui / domain / data / features / navigation
- [x] DI на get_it (`appLocator`, `setupAppScope(flavor)`), Hive-боксы `statsBox` / `settingsBox`
- [x] go_router: `/menu`, `/game` (fade-переход), `AppRouter` в DI
- [x] Flavors dev / prod: Android productFlavors, iOS конфигурации `Debug|Release|Profile-dev|prod` + схемы `dev` / `prod`, `AppConfig` в `appLocator`, плашка «DEV» в dev-сборке
- [x] Скрипты: `script/run.sh`, `script/build.sh`, `script/build_app_builds.sh`, `script/prebuild_script.sh`, `script/run_test_script.sh`
- [x] `.run/Dev.run.xml`, `.run/Prod.run.xml` для Android Studio
- [x] `.claude/` — планы, changelog, документы, скиллы

### Domain / Data
- [x] `BallTier` (1–11: эмодзи, `mergeScore = 2^tier`, `next`)
- [x] `GameStatsModel` (bestScore, gamesPlayed), `SettingsModel` (soundOn, hapticsOn)
- [x] `StatsRepository` / `SettingsRepository` + Hive-реализации

### UI (core_ui)
- [x] Токены: `AppColors` (палитра 1a), `AppFonts` (Archivo), `AppDimens`, `lightTheme`
- [x] Виджеты: `AppScaffold`, `PrimaryButton`, `IconCircleButton`, `BallView`

### Features
- [x] `menu` — MenuScreen (лого, рекорд, ИГРАТЬ, 🔊 / ⚙️ — заглушки)
- [x] `game` — GameCubit/GameState, GameScreen/GameForm, HUD, PauseOverlay, GameOverOverlay
- [x] `game/engine` — WasDropGame (Forge2D, стены, прицел, бросок), BallBody

---

## Что нужно сделать

### Фаза 1: Первый запуск (ТЕКУЩАЯ)
- [x] Шрифт Archivo (600/800/900) в `core/resources/fonts/`
- [x] `flutter pub get`, flame ^1.38 + flame_forge2d ^0.20, движок переписан под Box2D v3 API
- [x] `flutter analyze` без ошибок
- [x] `script/run.sh dev` — меню открывается на iOS-симуляторе (шрифт, плашка DEV)
- [x] Игра: бросок по тапу, падение, слияние двух t1 → t2 (+2) — покрыто `integration_test/game_smoke_test.dart`, прошёл на iPhone 17 Pro (симулятор) 2026-09-06
- [ ] Линия проигрыша (1.5 с над линией → game over) — проверить руками
- [x] Android: dev-флейвор собрался (`flutter build apk --flavor dev --debug`) и запустился на эмуляторе Small_Phone (Android 17 preview, образ с 16 KB страницами): сплеш с физикой, меню, Box2D через FFI грузится без ошибок (2026-09-09). Геймплей на Android руками ещё не проверяли
- [x] Иконка приложения: iOS `AppIcon` / `AppIcon-Dev`, Android mipmap + adaptive (dev source set с плашкой DEV), store-размеры в `store/` (2026-09-07)
- [x] Сплеш на Flutter: `SplashGame` — фрукты сыплются с неба и складываются в кучу, лого проявляется, 2.6 с или тап → меню (2026-09-08)
- [x] Нативный LaunchScreen: кремовый фон + скруглённая иконка по центру (iOS storyboard, Android `launch_background` + системный splash 12+), генератор `script/gen_launch_images.sh` (2026-09-09)
- [x] Рекорд обновляется и сохраняется по ходу партии (раньше писался при закрытии кубита после перехода, и меню показывало 0); плашка рекорда в меню крупнее (2026-09-08)

### Фаза 2: Геймплей до играбельного состояния
- [x] Слияние: контакт двух одинаковых → шар тир+1 в средней точке, очки `2^тир` (проверено смоук-тестом)
- [x] Вспышка (белое кольцо + свечение цвета нового тира), всплывающее «+N» цветом `scoreGain`, «поп» нового шара — `engine/merge_effects.dart` (2026-09-06)
- [x] Подвешенный текущий шар едет за пальцем, пунктир прицела (рейкаст) и пунктирная линия проигрыша (2026-09-06)
- [x] Физическое дно = видимое дно (высота мира от пропорции виджета), радиусы увеличены до suika-пропорций (2026-09-06)
- [x] «Больше инерции»: гравитация 1000 (бросок ≈ 1–1.3 с вместо 1.8; 1500 показалось слишком быстро), масштаб Box2D 120 ед/м, адаптивные шаги (6 при 60 fps), фрукты катятся (rollingResistance 0.02 — Box2D масштабирует его радиусом большего тела) и засыпают в покое, слияние по контакту с наследованием импульса; все ручки в `engine/physics_tuning.dart` (план `plans/2026-09-08_physics_settings.md`, 2026-09-08)
- [x] Края фруктов: спрайт подгоняется к физическому кругу по контуру (МНК), бока круглых фруктов совпадают с кругом в пределах 1 % — соседи больше не «заходят» друг на друга и вплотную лежащие одинаковые сливаются (2026-09-08)
- [x] Вытянутые фрукты (виноград, лимон, клубника) — скруглённые многоугольники Box2D по силуэту (`FruitSprite.shape`), остаток формы 2–3 % вместо 8–12 % у круга; катятся с покачиванием, ложатся на бок (смоук-тест: виноград после падения лежит под 45–135°) (2026-09-08)
- [ ] Тревога: линия краснеет со свечением, красная растяжка сверху стакана
- [ ] Проигрыш: покоящийся шар выше линии дольше 1.5 c → `gameOver()`
- [x] Кулдаун между бросками 450 мс (`WasDropGame.dropCooldown`)
- [ ] Джекпот: слияние двух t11 — шары исчезают (бонус — TODO)

### Фаза 2б: Спрайты фруктов (ТЗ `my_docs/TZ_SPRITES.md`)
- [x] Спрайты вместо градиента: загрузка по манифесту, подгонка тела по альфа-каналу, fallback на градиент+эмодзи (2026-09-07)
- [x] «Ойк» при ударе: squash 1.12×0.88 + открытый рот, порог 60 ед/с, debounce 400 мс; оба шара с открытым ртом в кадре перед слиянием (2026-09-07)
- [x] Яблоко (t5) как заглушка для всех тиров (2026-09-07)
- [x] Вишня t1 (2026-09-07), клубника t2, мандарин t3, лимон t4 (2026-09-08)
- [x] Киви, черника, виноград, персик, дыня, арбуз (t6–t11), заглушка-яблоко убрана (ТЗ § 5, 2026-09-08)
- [x] HUD «следующий шар» и меню (`BallView(image:)`) на спрайтах (2026-09-08)

### Фаза 3: Полировка и настройки
- [x] Звук и хаптика: `AudioService` (музыка-луп + SFX на тап/бросок/слияние/проигрыш/рекорд, хаптика), тумблеры «Звук» и «Вибрация» в паузе, 🔊/🔇 в меню (2026-09-06). Аудио пока плейсхолдеры из `script/gen_placeholder_audio.py` — заменить на настоящие
- [x] Экран настроек `/settings` (⚙️ в меню): Звуки / Музыка / Вибрация, Линия прицела, статистика (рекорд, игр, слияний, самый большой фрукт) со сбросом, цепочка фруктов, версия и лицензии; `SettingsService` вынесен из `AudioService`; статистика партии пишется при проигрыше/рестарте/выходе (2026-09-08)
- [ ] Rewarded ad — «Продолжить за рекламу»: после просмотра снять верхний слой шаров (`continueAfterAd`)
- [x] Анимации: нажатие кнопок (`AppPressable`), появление оверлеев (`AppOverlay`), каскадный вход меню, декоративные шары (2026-09-06)
- [x] Сохранение партии: `GameRepository` (`gameBox`), автосейв раз в 2 с / в фоне / при выходе в меню, «Продолжить» и «Новая игра» в меню, восстановление шаров с углами и скоростями (2026-09-09)
- [x] Название: витринное «Fruity Drop: Merge Puzzle», под иконкой «Fruity Drop» / «Fruity Dev» (pbxproj, gradle, `AppConfig`, лого) (2026-09-09)
- [x] Локализация: `easy_localization`, шесть языков (en, ru, de, fr, hu, ja), `LocaleKeys` из `core/resources/translations`, пикер «Язык» в настройках, `CFBundleLocalizations` (план `plans/2026-09-08_localization.md`, 2026-09-08)
- [x] Пакет дизайнера (`my_docs/TZ_ASSETS.md`): шрифты Rubik + Unbounded вместо Archivo, 8 SVG-иконок вместо эмодзи (`AppIcon`), темы-обои `GameThemes` × 6 с пикером в паузе и настройках, `AppThemeScope`, статичный декор (звёзды/облака/лепестки) (2026-09-08)

### Фаза 4: Релиз
- [ ] Ключ подписи Android (`android/key.properties`), Apple Team / профили
- [ ] Store-листинги (`.claude/my_docs/STORE_LISTINGS.md`), скриншоты
- [ ] Первый релиз 1.0.0 — процесс: [my_docs/RELEASE_PROCESS.md](../my_docs/RELEASE_PROCESS.md)

---

## Бэклог / идеи
- Локализация: показать переводы de/fr/hu/ja носителям; добавить языки — новый JSON + значение в `AppLocalizationEnum`
- Настройки, отложенные до релиза: «Политика конфиденциальности», «Оценить приложение», «Написать разработчику» (нужны URL, `url_launcher` / `in_app_review`), тёмная тема, выбор способа броска (тап / отпускание)
- Таблица рекордов, ежедневные задания
- Подписка: закрытые темы-обои (`GameTheme.isLocked`, пикер уже показывает замок), тёмный комплект иконок для ночной темы
- Физика: если после ручной проверки «слишком прыгает / липнет» — крутить `PhysicsTuning` (restitution, angularDamping, gravity)

---

## Архив планов

| Дата | План | Статус |
|---|---|---|
| 2026-09-06 | Перенос `.claude`-структуры из rvach, flavors dev/prod, скрипты сборки | ✅ Готово |
| 2026-09-07 | Первая загрузка в TestFlight: запись `com.wasdrop` (Apple ID 6809236566) в App Store Connect, билд 1.0.0 (1) доставлен; iOS ≥ 15, export compliance в Info.plist | ✅ Готово |
| 2026-09-08 | [Инерция в физике + экран настроек](2026-09-08_physics_settings.md) | ✅ Готово |
| 2026-09-08 | [Пакет дизайнера: шрифты Rubik + Unbounded, SVG-иконки, темы-обои](2026-09-08_assets_pack.md) | ✅ Готово |
| 2026-09-08 | [Мультиязычность: en, ru, de, fr, hu, ja](2026-09-08_localization.md) | ✅ Готово |
| 2026-09-09 | [Название Fruity Drop + сохранение партии](2026-09-09_rename_and_save_game.md) | ✅ Готово |
| 2026-09-09 | Нативный экран запуска iOS/Android с иконкой на кремовом фоне | ✅ Готово |
