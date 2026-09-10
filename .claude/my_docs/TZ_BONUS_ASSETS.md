# ТЗ: ассеты для бонусов «Встряхнуть» и «Бомбочка»

> Для Claude Design (2026-09-10). **Реализовано 2026-09-10**: иконки в `core_ui/assets/icons/` (`AppIcons.shake/bomb`), спрайты в `features/assets/images/fx/` (`FxSprites`), звуки пока плейсхолдеры. Механика — CLAUDE.md «Геймплей → Бонусы» и `plans/plan.md`, «Фаза 3б». Стиль — тот же, что у спрайтов фруктов (`TZ_SPRITES.md`) и иконок интерфейса (`TZ_ASSETS.md`): кавай, толстый тёмно-коричневый контур, плоские заливки с мягким бликом, палитра игры.

## Контекст: как работают бонусы

Под стаканом появляется полоса с двумя круглыми кнопками (52 px, светлая подложка `#FFFDF6`, обводка 2 px `#E4DCC9` — как кнопки паузы и звука) и бейджем-счётчиком зарядов. Кнопки рисуем в коде из существующих компонентов, для них нужны только иконки.

- **Встряхнуть** — игрок трясёт телефон (или жмёт кнопку): все фрукты подпрыгивают и перемешиваются по физике, стакан вздрагивает. Нужен для того, чтобы «расшевелить» кучу и подтолкнуть одинаковые фрукты друг к другу.
- **Бомбочка** — игрок жмёт кнопку, стакан приглушается, появляется подсказка «Выберите фрукт»; тап по любому фрукту — на нём вспыхивает бомбочка, взрыв, фрукт исчезает, соседи слегка разлетаются.

Что делаем в коде без ассетов: бейджи со счётчиком, затемнение кнопки при нуле зарядов, приглушение стакана и кольцо-подсветка под пальцем в режиме выбора, дрожание стакана, частицы, тексты подсказок.

## Список ассетов

| # | Файл | Формат | Для чего |
|---|---|---|---|
| 1 | `core_ui/assets/icons/shake.svg` | SVG 24×24 | иконка кнопки «Встряхнуть» |
| 2 | `core_ui/assets/icons/bomb.svg` | SVG 24×24 | иконка кнопки «Бомбочка» |
| 3 | `features/assets/images/fx/bomb.png` | PNG 512×512, прозрачный фон | бомбочка, которая появляется на выбранном фрукте перед взрывом |
| 4 | `features/assets/images/fx/boom_1.png`, `boom_2.png`, `boom_3.png` | PNG 512×512, прозрачный фон | взрыв, три кадра: вспышка → облако → рассеивание. Если три кадра сложно — один `boom.png`, анимируем масштабом и прозрачностью |
| 5 | `features/assets/images/fx/shake_hint.png` | PNG 512×512, прозрачный фон | (опционально) картинка для подсказки «Потрясите телефон» при первом заходе. Без неё подсказка будет текстовой |

Звуки (`sfx_shake.wav` — дребезг фруктов в банке, `sfx_bomb.wav` — мягкий мультяшный «бум») — из той же партии, что и остальная замена временного звука; на старте используем плейсхолдеры.

## Требования к иконкам (1–2)

Как у восьми существующих иконок: viewBox 24×24, штрих `#33291A` 1.8 px со скруглёнными концами и стыками, заливки из палитры игры, без градиентов и теней, без встроенных растров и метаданных. Иконки многоцветные и не перекрашиваются кодом, стоят на светлой подложке. Должны читаться при 22–24 px.

- **shake.svg** — стеклянная банка/стакан с двумя-тремя фруктами внутри и «линиями движения» по бокам (по две дуги слева и справа), фрукты чуть подброшены. Альтернатива: телефон с линиями движения, но банка ближе к игре.
- **bomb.svg** — круглая чёрно-графитовая бомбочка `#33291A`/`#4A3F2E` с бликом, короткий фитиль, на конце искра-звёздочка оранжево-жёлтая (`#F76B15` / `#EFB008`). Добродушная, без черепов и огня.

## Требования к спрайтам (3–5)

Как у фруктов: 512×512, прозрачный фон, объект занимает ~90–95 % кадра, под объектом нет тени, контур тёмно-коричневый `#33291A` толщиной как у фруктов, мягкий блик. Ничего не должно выходить за кадр.

- **bomb.png** — та же бомбочка, что в иконке, но крупно и с «лицом» в стиле фруктов (маленькие глаза, щёчки, хитрая улыбка) — она ляжет поверх выбранного фрукта на 300 мс. Фитиль с искрой сверху справа.
- **boom_1.png** — вспышка: восьмиконечная звезда-«бум» с белым центром, жёлтой `#EFB008` и оранжевой `#F76B15` заливкой, контур коричневый.
- **boom_2.png** — облако взрыва: круглые кучевые «пухи» оранжево-жёлтые с белыми бликами, крупнее вспышки, несколько искр-звёздочек по краям.
- **boom_3.png** — рассеивание: полупрозрачные светлые «пухи» и мелкие искры, центр пустой.
- **shake_hint.png** (опционально) — телефон в вертикальной ориентации с нашей игрой на экране (условно: стакан и пара фруктов), по бокам линии движения, вокруг два-три подпрыгивающих фрукта (вишня, мандарин).

## Бустер «Увеличить» (добавлен 2026-09-10)

Третий бонус: игрок жмёт кнопку, стакан приглушается, подсказка «Нажмите на фрукт, чтобы увеличить его на уровень»; тап по любому фрукту (кроме арбуза) — он с «попом» превращается в следующий по цепочке прямо на месте, со вспышкой слияния. Один раз за партию.

| # | Файл | Формат | Для чего |
|---|---|---|---|
| 6 | `core_ui/assets/icons/upgrade.svg` | SVG 24×24 | иконка кнопки «Увеличить». **Сейчас стоит временная** (зелёный кружок-яблоко и оранжевая стрелка вверх, нарисована вручную в коде) — заменить |
| 7 | `features/assets/images/fx/grow.png` | PNG 512×512, прозрачный фон | (опционально) вспышка роста: кольцо искр-звёздочек и стрелочек вверх, центр пустой — накладывается на растущий фрукт. Без неё используем вспышку слияния |

- **upgrade.svg** — маленький фрукт (вишня или яблоко в палитре) и над ним/рядом крупная стрелка вверх `#F76B15` с контуром, либо фрукт с тремя искрами роста. Должно читаться при 22 px и отличаться от иконки бомбочки силуэтом.

## Промпты для Claude Design (можно вставлять как есть)

Общий стиль:

```
Kawaii mobile-game asset in the style of a cute fruit merge puzzle: bold dark-brown outline (#33291A), flat fills with a soft gloss highlight, cheerful and friendly, no gradients, no drop shadow, transparent background. Palette: cream #F7F2E7, brown #33291A, orange #F76B15, yellow #EFB008, red #E5484D, green #3BA55C, teal #12A594, blue #0090FF, purple #6E56CF, pink #E93D82.
```

Иконки:

```
Flat 24x24 UI icon, SVG, 1.8px dark-brown (#33291A) rounded stroke, multi-colour flat fills from the palette, readable at 22px, no gradients or shadows.
1) "shake": a glass jar with two or three small fruits bouncing inside, motion arcs on both sides.
2) "bomb": a round graphite bomb with a highlight, short fuse, orange-yellow spark star at the tip, friendly, no skulls or fire.
```

Спрайты:

```
512x512 PNG, transparent background, object fills about 90–95% of the frame, no shadow under the object, same outline weight and gloss as the fruit characters.
1) "bomb": round graphite bomb with a cute kawaii face (small eyes, blush cheeks, sly smile), short fuse with a spark at the top right.
2) "boom_1": comic explosion flash, eight-point burst star, white core, yellow #EFB008 and orange #F76B15 fill, brown outline.
3) "boom_2": comic explosion cloud, round puffy orange-yellow blobs with white highlights, a few small spark stars around the edge.
4) "boom_3": dissipating explosion, semi-transparent light puffs and tiny sparks, empty centre.
5) "shake_hint" (optional): upright phone with a jar and fruits on the screen, motion lines on both sides, a cherry and a tangerine bouncing around it.
6) "grow" (optional): a ring of small sparkle stars and tiny upward arrows in yellow #EFB008 and orange #F76B15 with brown outlines, empty centre — an overlay for a fruit growing one level.
```

Иконка бустера:

```
Flat 24x24 UI icon, SVG, 1.8px dark-brown (#33291A) rounded stroke, multi-colour flat fills from the palette, readable at 22px, no gradients or shadows.
3) "upgrade": a small cute fruit (cherry or apple) with a bold orange (#F76B15) upward arrow above it, or with three sparkle stars — "grow one level"; silhouette must differ from the bomb icon.
```

## Как сдавать

Папка с файлами по именам из таблицы. SVG — без метаданных c2pa и без встроенных PNG (проверю и вычищу при подключении, как в прошлый раз). PNG — без теней под объектом и без белого фона внутри контуров (после прошлого пакета вычищали остатки фона у арбуза и дыни).
