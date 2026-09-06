# WasDrop — План разработки

> Merge-drop игра (жанр suika): роняем шары в стакан, два одинаковых сливаются в следующий тир.
> Стек: Flutter + Cubit (flutter_bloc) + get_it + go_router + Hive + flame_forge2d. Без сети.
> ТЗ и дизайн-токены: [my_docs/WASDROP.md](../my_docs/WASDROP.md) · UI-референс для скиллов: [shared/wasdrop_ui_reference.md](../shared/wasdrop_ui_reference.md)

---

## Текущий статус: **Фаза 0 — скелет собран, первый запуск не пройден**

Код написан по мокапам без проверки компиляции. Ближайшая цель — довести `script/run.sh dev` до рабочего экрана меню и игры.

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
- [ ] Скачать шрифт Archivo (600/800/900) в `core/resources/fonts/` — без него `flutter build` падает на assets
- [ ] `flutter pub get` во всех пакетах, починить импорты / версии flame и flame_forge2d
- [ ] `flutter analyze` без ошибок
- [ ] `script/run.sh dev` — меню открывается, игра запускается, шары падают
- [ ] Иконка приложения (dev / prod) и splash

### Фаза 2: Геймплей до играбельного состояния
- [ ] Слияние: контакт двух одинаковых → шар тир+1 в средней точке, очки `2^тир`
- [ ] Вспышка (белое кольцо + свечение) и всплывающее «+N» цветом `scoreGain`
- [ ] Пунктирная линия проигрыша (отступ 38 от верха стакана) и вертикальный пунктир прицела
- [ ] Тревога: линия краснеет со свечением, красная растяжка сверху стакана
- [ ] Проигрыш: покоящийся шар выше линии дольше 1.5 c → `gameOver()`
- [ ] Кулдаун между бросками 450 мс
- [ ] Джекпот: слияние двух t11 — шары исчезают (бонус — TODO)

### Фаза 3: Полировка и настройки
- [ ] Звук и хаптика (тумблеры в паузе, 🔊 в меню; `SettingsRepository`)
- [ ] Экран настроек (⚙️ в меню)
- [ ] Rewarded ad — «Продолжить за рекламу»: после просмотра снять верхний слой шаров (`continueAfterAd`)
- [ ] Анимации оверлеев, декоративные шары в меню

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
