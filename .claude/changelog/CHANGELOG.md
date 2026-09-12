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
- Изменено: новая иконка приложения — арбуз с клубникой, мандарином и персиком на мятном фоне (iOS, Android, сторы)
- Новое: нативный экран запуска — вместо белого экрана до старта игры показывается иконка на кремовом фоне (iOS и Android)
- Исправлено: экран больше не поворачивается в альбомную ориентацию (в том числе экран запуска и iPad) — игра только в портрете
- Новое: бонусы под стаканом — «Встряхнуть» (три раза за партию: нажмите кнопку и потрясите телефон, фрукты подпрыгнут и перемешаются), «Бомбочка» (раз за партию: выберите любой фрукт, и он взорвётся, расталкивая соседей) и «Увеличить» (раз за партию: выбранный фрукт становится на уровень больше); заряды сохраняются вместе с партией
- Новое: партия сохраняется — если закрыть приложение посреди игры, в меню появится «Продолжить» (и «Новая игра»); восстановленная партия открывается в паузе
- Изменено: игра называется Fruity Drop (в сторах — Fruity Drop: Merge Puzzle), под иконкой «Fruity Drop»
- Новое: интерфейс на шести языках — русский, английский, немецкий, французский, венгерский, японский; по умолчанию язык устройства, выбор в настройках («Игра → Язык»)
- Новое: на iOS 18+ игра заявляет поддержку Game Mode (система снижает фоновую активность и отдаёт игре приоритет)
- Новое: в меню внизу лежит живая куча фруктов — они сыплются при входе, их можно подбрасывать тапом; на iPad меню собрано в центре, а не растянуто на всю ширину
- (скрыто в 1.0, включается флагом монетизации) Новое: покупка «Премиум навсегда» (iOS) — без рекламы, «Продолжить» и пополнение зарядов без роликов; экран покупки открывается из настроек, из закрытых обоев и с экрана проигрыша, там же «Восстановить покупки»
- Новое: «Продолжить» после проигрыша — верхний слой фруктов исчезает и партия продолжается (один раз за партию); кнопка бонуса без зарядов пополняет их (по разу на бонус за партию). В 1.0 бесплатно; с включённой монетизацией — за rewarded-ролик, без сети «Реклама сейчас недоступна»
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
- Changed: new app icon — a watermelon with a strawberry, tangerine and peach on a mint background (iOS, Android, stores)
- New: native launch screen — the app icon on a cream background replaces the white screen shown before the game starts (iOS and Android)
- Fixed: the screen no longer rotates to landscape (launch screen and iPad included) — the game is portrait only
- New: bonuses under the jar — Shake (three per run: tap the button, then shake your phone and the fruits jump and reshuffle), Bomb (one per run: pick any fruit and it blows up, pushing its neighbours away) and Grow (one per run: the picked fruit becomes one level bigger); charges are saved with the run
- New: the game is saved — close the app mid-run and the menu offers Continue (and New game); a resumed run opens paused
- Changed: the game is now called Fruity Drop (Fruity Drop: Merge Puzzle in the stores), «Fruity Drop» under the icon
- New: the interface speaks six languages — Russian, English, German, French, Hungarian, Japanese; follows the device language by default, switchable in Settings → Game → Language
- New: on iOS 18+ the game opts into Game Mode (the system reduces background activity and prioritises the game)
- New: a live pile of fruit at the bottom of the menu — it rains in and you can flick the fruit; on iPad the menu is centred instead of stretched
- (hidden in 1.0 behind the monetization flag) New: "Premium Forever" purchase (iOS) — no ads, Continue and bonus refills without videos; the purchase screen opens from Settings, from a locked wallpaper and from the game-over panel, with "Restore purchases"
- New: Continue after game over — the top layer of fruit disappears and the game goes on (once per game); a bonus button with no charges refills them (once per bonus per game). Free in 1.0; with monetization on it costs a rewarded video, offline it says "Ads are unavailable right now"
- Fixed: strawberry, kiwi, blueberry, grape, peach and melon had their calm and "oof" faces swapped (they sat with open mouths); white background leftovers inside the watermelon and melon stem curls removed
- Fixed: the menu showed a best score of 0 after a game — the record now updates and is saved the moment the score beats it (in the HUD too); the record chip in the menu is bigger
- New: settings screen (⚙️ in the menu): Sounds, Music, Vibration and Aim line toggles; statistics — best score, games played, merges, biggest fruit — with a reset; the chain of all 11 fruits with names; version and licenses
