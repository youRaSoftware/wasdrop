# Changelog

Все значимые user-facing изменения в WasDrop. / All notable user-facing changes to WasDrop.

Формат / Format: [Keep a Changelog](https://keepachangelog.com/1.1.0/) · Versioning: [SemVer](https://semver.org/).

При выпуске новой версии в стор переименовать `[Unreleased]` в `[X.Y.Z] — YYYY-MM-DD` (версия = `version:` в `pubspec.yaml`) и завести новый пустой `[Unreleased]` сверху. Тексты для сторов складывать в `.claude/my_docs/release_notes_X.Y.Z.txt`.
On release, rename `[Unreleased]` to `[X.Y.Z] — YYYY-MM-DD` and start a fresh empty `[Unreleased]` on top.

## [Unreleased]

### RU

**Что нового:**

- Новое: меню с рекордом и кнопкой «Играть»; игровой экран — стакан, физика шаров, HUD со счётом, рекордом и следующим шаром
- Новое: оверлеи паузы (Продолжить / Заново / В меню) и проигрыша (счёт, бейдж «Новый рекорд», «Продолжить за рекламу» — заглушка)
- Новое: рекорд и число сыгранных игр сохраняются на устройстве
- Новое: текущий фрукт висит над стаканом и едет за пальцем, пунктир прицела показывает, куда он упадёт
- Изменено: фрукты крупнее (пропорции классической suika), стакан заполняется до самого дна
- Новое: анимация слияния — вспышка в точке контакта, всплывающее «+N» и «поп» нового фрукта
- Новое: музыка и звуки (бросок, слияние, проигрыш, рекорд, нажатия) с вибрацией; тумблеры «Звук» и «Вибрация» в паузе, кнопка звука в меню
- Новое: живые кнопки (проседают и сжимаются при нажатии), анимированное появление меню и панелей паузы и проигрыша
- Новое: иконка приложения (пять шаров на тёплом фоне), адаптивная иконка на Android

### EN

**What's new:**

- New: main menu with best score and Play button; game screen — jar, ball physics, HUD with score, best and next ball
- New: pause overlay (Resume / Restart / Menu) and game-over overlay (score, "New record" badge, "Continue for an ad" stub)
- New: best score and games played are stored on device
- New: the current fruit hangs above the jar and follows your finger, a dashed aim line shows where it lands
- Changed: bigger fruits (classic suika proportions), the jar fills all the way to the bottom
- New: merge animation — a flash at the contact point, a floating «+N» and a pop of the new fruit
- New: music and sound effects (drop, merge, game over, record, taps) with haptics; Sound and Vibration toggles in pause, a sound button in the menu
- New: tactile buttons (they sink and squeeze when pressed), animated entrance for the menu and the pause / game-over panels
- New: app icon (five balls on a warm background), adaptive icon on Android
