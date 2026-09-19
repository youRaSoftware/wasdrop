# Game Center — что завести в App Store Connect (1.1)

Код готов (`GameCenterService`, `GameAchievement`, `GameCenterService.leaderboardIds`), entitlement `com.apple.developer.game-center` в `ios/Runner/Runner.entitlements`. Без записей в ASC вход в Game Center работает, а отправка счёта и достижений молча падает в лог — игра не страдает. Идентификаторы ниже должны совпадать с кодом **буква в букву**.

Где: App Store Connect → My Apps → Fruity Drop → **Services → Game Center** (в новом интерфейсе — вкладка «Game Center» в разделе приложения) → «Enable Game Center». Иконки достижений — `store/achievements/*.png` (512×512, генерирует `script/gen_achievement_icons.sh`). Локализации — шесть языков (en-US основной, ru, de-DE, fr-FR, hu, ja).

## Лидерборды (3, Classic leaderboard)

| Reference name | Leaderboard ID | Тип | Score format | Sort | Score range |
|---|---|---|---|---|---|
| Classic | `com.wasdrop.leaderboard.classic` | Classic | Integer | High to Low | 0 … 1 000 000 |
| Time attack | `com.wasdrop.leaderboard.timed` | Classic | Integer | High to Low | 0 … 1 000 000 |
| Daily challenge | `com.wasdrop.leaderboard.daily` | **Recurring**, период 1 день, старт 00:00 UTC | Integer | High to Low | 0 … 1 000 000 |
| Wonder Garden *(добавлен 2026-09-19 — завести)* | `com.wasdrop.leaderboard.garden` | Classic | Integer | High to Low | 0 … 1 000 000 |

Локализованные названия (Leaderboard name; Score format suffix — пусто):

| Locale | Classic | Time attack | Daily challenge | Wonder Garden |
|---|---|---|---|---|
| en-US | Classic | Time attack | Daily challenge | Wonder Garden |
| ru | Классика | На время | Вызов дня | Сад чудес |
| de-DE | Klassik | Auf Zeit | Tages-Challenge | Wundergarten |
| fr-FR | Classique | Contre la montre | Défi du jour | Jardin magique |
| hu | Klasszikus | Időre | Napi kihívás | Csodakert |
| ja | クラシック | タイムアタック | デイリーチャレンジ | ふしぎな庭 |

Leaderboard set не нужен. Для Daily в коде счёт отправляется в текущий период автоматически (recurring leaderboard принимает счёт в активную «occurrence»).

## Достижения (10, points в сумме 1000, не больше 100 на одно, all «not hidden», «achievable more than once» — No)

| Reference | Achievement ID | Points | Иконка (`store/achievements/`) |
|---|---|---|---|
| Lemon | `com.wasdrop.fruit.lemon` | 50 | `fruit_lemon.png` |
| Kiwi | `com.wasdrop.fruit.kiwi` | 75 | `fruit_kiwi.png` |
| Grape | `com.wasdrop.fruit.grape` | 100 | `fruit_grape.png` |
| Melon | `com.wasdrop.fruit.melon` | 100 | `fruit_melon.png` |
| Watermelon | `com.wasdrop.fruit.watermelon` | 100 | `fruit_watermelon.png` |
| Score 1 000 | `com.wasdrop.score.1k` | 100 | `score_1k.png` |
| Score 10 000 | `com.wasdrop.score.10k` | 100 | `score_10k.png` |
| 10 games | `com.wasdrop.games.10` | 100 | `games_10.png` |
| 100 games | `com.wasdrop.games.100` | 100 | `games_100.png` |
| 25 orders | `com.wasdrop.missions.25` | 75 | `missions_25.png` |

Локализации (Title / Pre-earned description / Earned description — одна фраза для обоих описаний):

**en-US**
- Lemon — First lemon / Merge two tangerines into a lemon.
- Kiwi — First kiwi / Grow a kiwi from two apples.
- Grape — First grapes / Merge two blueberries into grapes.
- Melon — First melon / Merge two peaches into a melon.
- Watermelon — Watermelon! / Grow the biggest fruit of all.
- Score 1 000 — Thousand / Score 1 000 points in one game.
- Score 10 000 — Ten thousand / Score 10 000 points in one game.
- 10 games — Regular / Play 10 games.
- 100 games — Fruit fanatic / Play 100 games.
- 25 orders — Reliable supplier / Complete 25 orders.

**ru**
- Lemon — Первый лимон / Слей два мандарина в лимон.
- Kiwi — Первое киви / Вырасти киви из двух яблок.
- Grape — Первый виноград / Слей две черники в виноград.
- Melon — Первая дыня / Слей два персика в дыню.
- Watermelon — Арбуз! / Вырасти самый большой фрукт.
- Score 1 000 — Тысяча / Набери 1 000 очков за одну партию.
- Score 10 000 — Десять тысяч / Набери 10 000 очков за одну партию.
- 10 games — Завсегдатай / Сыграй 10 партий.
- 100 games — Фруктовый фанат / Сыграй 100 партий.
- 25 orders — Надёжный поставщик / Выполни 25 заказов.

**de-DE**
- Lemon — Erste Zitrone / Verschmelze zwei Mandarinen zu einer Zitrone.
- Kiwi — Erste Kiwi / Züchte aus zwei Äpfeln eine Kiwi.
- Grape — Erste Trauben / Verschmelze zwei Heidelbeeren zu Trauben.
- Melon — Erste Melone / Verschmelze zwei Pfirsiche zu einer Melone.
- Watermelon — Wassermelone! / Züchte die größte Frucht von allen.
- Score 1 000 — Tausend / Erreiche 1 000 Punkte in einem Spiel.
- Score 10 000 — Zehntausend / Erreiche 10 000 Punkte in einem Spiel.
- 10 games — Stammgast / Spiele 10 Partien.
- 100 games — Obst-Fan / Spiele 100 Partien.
- 25 orders — Zuverlässiger Lieferant / Erledige 25 Aufträge.

**fr-FR**
- Lemon — Premier citron / Fusionne deux mandarines en un citron.
- Kiwi — Premier kiwi / Fais pousser un kiwi à partir de deux pommes.
- Grape — Premier raisin / Fusionne deux myrtilles en raisin.
- Melon — Premier melon / Fusionne deux pêches en un melon.
- Watermelon — Pastèque ! / Fais pousser le plus gros fruit de tous.
- Score 1 000 — Mille / Marque 1 000 points en une partie.
- Score 10 000 — Dix mille / Marque 10 000 points en une partie.
- 10 games — Habitué / Joue 10 parties.
- 100 games — Fan de fruits / Joue 100 parties.
- 25 orders — Fournisseur fiable / Réussis 25 commandes.

**hu**
- Lemon — Első citrom / Egyesíts két mandarint citrommá.
- Kiwi — Első kivi / Növessz kivit két almából.
- Grape — Első szőlő / Egyesíts két áfonyát szőlővé.
- Melon — Első sárgadinnye / Egyesíts két barackot sárgadinnyévé.
- Watermelon — Görögdinnye! / Növeszd meg a legnagyobb gyümölcsöt.
- Score 1 000 — Ezer / Érj el 1 000 pontot egy játékban.
- Score 10 000 — Tízezer / Érj el 10 000 pontot egy játékban.
- 10 games — Törzsvendég / Játssz 10 játékot.
- 100 games — Gyümölcsrajongó / Játssz 100 játékot.
- 25 orders — Megbízható beszállító / Teljesíts 25 megbízást.

**ja**
- Lemon — はじめてのレモン / みかん2つを合体してレモンに。
- Kiwi — はじめてのキウイ / りんご2つからキウイを育てよう。
- Grape — はじめてのぶどう / ブルーベリー2つを合体してぶどうに。
- Melon — はじめてのメロン / もも2つを合体してメロンに。
- Watermelon — いちばん大きな果物！ / いちばん大きな果物を育てよう。（スイカ = suika — после 4.1(a) в ASC переименовать）
- Score 1 000 — 1000点 / 1ゲームで1 000点を獲得。
- Score 10 000 — 10000点 / 1ゲームで10 000点を獲得。
- 10 games — 常連 / 10ゲームをプレイ。
- 100 games — フルーツ大好き / 100ゲームをプレイ。
- 25 orders — 頼れる納品者 / オーダーを25回達成。

## Проверка
1. Xcode → Runner → Signing & Capabilities: capability **Game Center** должна появиться из entitlements (автоподпись добавит её в App ID `com.wasdrop` и `com.wasdrop.dev`).
2. На устройстве войти в Game Center (Настройки → Game Center) — в меню появится кнопка-кубок, на экране проигрыша «Рекорды».
3. Sandbox: prod-сборка (`script/run.sh prod`) — счёт после партии виден в лидерборде; dev-флейвор лидербордов не имеет.
4. Достижения приходят системным баннером; повторно в сессии не отправляются.
