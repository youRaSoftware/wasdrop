# WasDrop — План разработки

> Merge-drop игра (жанр suika): роняем шары в стакан, два одинаковых сливаются в следующий тир.
> Стек: Flutter + Cubit (flutter_bloc) + get_it + go_router + Hive + flame_forge2d. Без сети.
> ТЗ и дизайн-токены: [my_docs/WASDROP.md](../my_docs/WASDROP.md) · UI-референс для скиллов: [shared/wasdrop_ui_reference.md](../shared/wasdrop_ui_reference.md)

---

## Текущий статус: **Фаза 2 — играбельное ядро: бросок, слияние, прицел**

Движок на flame 1.38 + flame_forge2d 0.20 (Box2D v3), смоук-тест проходит на iOS-симуляторе. Ближайшая цель — вспышка «+N», тревога у линии, звук.

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
- [ ] Android: первый запуск dev-флейвора на эмуляторе
- [x] Иконка приложения: iOS `AppIcon` / `AppIcon-Dev`, Android mipmap + adaptive (dev source set с плашкой DEV), store-размеры в `store/` (2026-09-07)
- [ ] Splash / LaunchScreen с иконкой

### Фаза 2: Геймплей до играбельного состояния
- [x] Слияние: контакт двух одинаковых → шар тир+1 в средней точке, очки `2^тир` (проверено смоук-тестом)
- [x] Вспышка (белое кольцо + свечение цвета нового тира), всплывающее «+N» цветом `scoreGain`, «поп» нового шара — `engine/merge_effects.dart` (2026-09-06)
- [x] Подвешенный текущий шар едет за пальцем, пунктир прицела (рейкаст) и пунктирная линия проигрыша (2026-09-06)
- [x] Физическое дно = видимое дно (высота мира от пропорции виджета), радиусы увеличены до suika-пропорций (2026-09-06)
- [ ] Тревога: линия краснеет со свечением, красная растяжка сверху стакана
- [ ] Проигрыш: покоящийся шар выше линии дольше 1.5 c → `gameOver()`
- [x] Кулдаун между бросками 450 мс (`WasDropGame.dropCooldown`)
- [ ] Джекпот: слияние двух t11 — шары исчезают (бонус — TODO)

### Фаза 3: Полировка и настройки
- [x] Звук и хаптика: `AudioService` (музыка-луп + SFX на тап/бросок/слияние/проигрыш/рекорд, хаптика), тумблеры «Звук» и «Вибрация» в паузе, 🔊/🔇 в меню (2026-09-06). Аудио пока плейсхолдеры из `script/gen_placeholder_audio.py` — заменить на настоящие
- [ ] Экран настроек (⚙️ в меню)
- [ ] Rewarded ad — «Продолжить за рекламу»: после просмотра снять верхний слой шаров (`continueAfterAd`)
- [x] Анимации: нажатие кнопок (`AppPressable`), появление оверлеев (`AppOverlay`), каскадный вход меню, декоративные шары (2026-09-06)

### Фаза 4: Релиз
- [ ] Ключ подписи Android (`android/key.properties`), Apple Team / профили
- [ ] Store-листинги (`.claude/my_docs/STORE_LISTINGS.md`), скриншоты
- [ ] Первый релиз 1.0.0 — процесс: [my_docs/RELEASE_PROCESS.md](../my_docs/RELEASE_PROCESS.md)

---

## Бэклог / идеи
- Локализация (сейчас все строки — русские литералы в виджетах)
- Таблица рекордов, ежедневные задания
- Темы (тёмная)

---

## Архив планов

| Дата | План | Статус |
|---|---|---|
| 2026-09-06 | Перенос `.claude`-структуры из rvach, flavors dev/prod, скрипты сборки | ✅ Готово |
