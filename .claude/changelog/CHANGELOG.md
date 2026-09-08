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
- Новое: все 11 фруктов нарисованы спрайтами (в стакане, в подсказке «следующий» и в меню) и «ойкают» при ударе — сплющиваются и открывают рот
- Изменено: все фрукты ещё крупнее — вишня теперь размером с прежнюю клубнику, арбуз почти во всю ширину стакана
- Исправлено: мелкие фрукты при падении на дно проваливались в него и «всплывали» обратно; фрукт, рождённый слиянием на дне, тоже появлялся из-под пола
- Изменено: физика стала «тяжелее» и живее — фрукты падают быстрее и с ускорением, скатываются по склону кучи, а не замирают, слегка отскакивают при ударе; слившийся фрукт сохраняет разгон родителей
- Исправлено: соседние фрукты больше не «заходят» друг на друга — рисунок точнее совпадает с физическим телом, и одинаковые фрукты, лежащие вплотную, надёжно сливаются
- Изменено: виноград, лимон и клубника физически овальные, а не круглые — катятся с покачиванием, ложатся на бок и вклиниваются между соседями носиками
- Новое: шесть тем-обоев (Крем, Персиковый закат, Мятный сад, Ночной сад, Пудрово-розовая, Небо и облака) — фон, стакан и линия проигрыша перекрашиваются, у ночной звёзды, у неба облака, у розовой лепестки; выбор в паузе и в настройках, запоминается
- Изменено: новые шрифты — Rubik для интерфейса и Unbounded для лого и заголовков; вместо эмодзи нарисованные иконки (кубок, звук, настройки, пауза, повтор, домой, реклама)
- Новое: заставка при запуске — фрукты сыплются с неба и складываются в кучу, лого проявляется поверх; тап пропускает
- Изменено: новая иконка приложения — яблоко с мандарином, вишней и виноградом на кремовом фоне (iOS, Android, сторы)
- Исправлено: у клубники, киви, черники, винограда, персика и дыни были перепутаны спокойное лицо и «ойк» (в покое они сидели с открытым ртом); у арбуза и дыни убраны белые остатки фона внутри завитка хвостика
- Исправлено: рекорд в меню показывал 0 после партии — теперь он обновляется и сохраняется сразу, как только счёт его превысил (и в HUD тоже); плашка рекорда в меню стала крупнее
- Новое: экран настроек (⚙️ в меню): тумблеры «Звуки», «Музыка», «Вибрация», «Линия прицела»; статистика — рекорд, сыгранные игры, слияния, самый большой фрукт — со сбросом; цепочка всех 11 фруктов с названиями; версия и лицензии

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
- New: all 11 fruits are drawn as sprites (in the jar, in the «next» hint and in the menu) and go «oof» on impact — squash and open their mouth
- Changed: all fruits are bigger again — the cherry is now the size of the old strawberry, the watermelon nearly spans the jar
- Fixed: small fruits sank into the floor on landing and floated back up; a fruit born from a merge on the floor also emerged from under it
- Changed: heavier, livelier physics — fruits fall faster and accelerate, roll down the pile instead of freezing, bounce slightly on impact; a merged fruit keeps its parents' momentum
- Fixed: neighbouring fruits no longer overlap each other — the artwork matches the physical body more precisely, and equal fruits lying side by side merge reliably
- Changed: the grape, lemon and strawberry are physically oval rather than round — they wobble as they roll, come to rest on their side and wedge between neighbours with their tips
- New: six wallpaper themes (Cream, Peach Sunset, Mint Garden, Night Garden, Powder Rose, Sky and Clouds) — background, jar and game-over line recolour, with stars, clouds or petals; pick one in pause or in settings, the choice is remembered
- Changed: new typefaces — Rubik for the interface and Unbounded for the logo and titles; drawn icons (trophy, sound, settings, pause, restart, home, ad) replace emoji
- New: launch splash — fruits rain down and pile up while the logo fades in; tap to skip
- Changed: new app icon — an apple with a tangerine, cherry and grape on a cream background (iOS, Android, stores)
- Fixed: strawberry, kiwi, blueberry, grape, peach and melon had their calm and "oof" faces swapped (they sat with open mouths); white background leftovers inside the watermelon and melon stem curls removed
- Fixed: the menu showed a best score of 0 after a game — the record now updates and is saved the moment the score beats it (in the HUD too); the record chip in the menu is bigger
- New: settings screen (⚙️ in the menu): Sounds, Music, Vibration and Aim line toggles; statistics — best score, games played, merges, biggest fruit — with a reset; the chain of all 11 fruits with names; version and licenses
