# WONDER_GARDEN.md — интеграция режима «Сад чудес» (Fruity Drop 1.1)

Ассеты: `features/assets/images/special/` — rainbow / bubble / rotten / ice (idle+squish, PNG 512, прозрачный фон, тело альфа ≥200) + `ice_overlay.png`, `bubble_pop.png`, `ice_crack.png`. Иконка режима `core_ui/assets/icons/garden.svg`. Мокапы: секция 17 в WasDrop Mockups.dc.html (17a–17e), ответы на вопросы ТЗ — в шапке секции.

## pubspec (features)
```yaml
flutter:
  assets:
    - assets/images/fruits/
    - assets/images/fx/
    - assets/images/special/
```

## Модель
```dart
enum SpecialKind { rainbow, bubble, rotten, ice }
// радиусы (мировые ед., мир 360): rainbow 24, bubble 30, rotten 34, ice 20
// частота (1 на N бросков): rainbow 12, bubble 15, rotten 18 (не раньше 10-го), ice 20
```
Очередь: GameCubit._rollTier() в режиме garden с шансом подмешивает SpecialKind вместо BallTier; в state добавить `SpecialKind? currentSpecial / nextSpecial`. Окошко «следующий»: если special — рамка светится цветом фрукта (пульсирующее кольцо кодом, box-shadow #C973F0 для радужки) + бейдж NEW при первом появлении.

## Механики (engine/wasdrop_game.dart)
- **Rainbow**: BallBody с флагом isRainbow; в beginContact сливается с ЛЮБЫМ BallBody → спавнит tier.next этого фрукта, очки как обычное слияние. В полёте — ColorFiltered hue-rotate анимация (спрайт статичный).
- **Bubble**: гравитация инвертирована (body.gravityScale = -0.3), всплывает; таймер 5 с → удалить, показать bubble_pop.png (0.3 с, scale 1→1.4, fade), очков 0; при контакте — лёгкий импульс соседям (куча «дышит»).
- **Rotten**: merge-логика игнорирует (tier == null); уничтожается бомбочкой или слиянием в радиусе 1.5r → удалить, +50, вспышка boom_1.
- **Ice**: при первом контакте с фруктом — прилипает (joint) и вешает на жертву ice_overlay.png (масштаб под радиус, opacity .9); жертва не сливается 3 броска (счётчик в userData), потом ice_crack.png (0.3 с) и разморозка; бомбочка снимает лёд сразу.
- squish-состояния: как у обычных — при сильном контакте 250 мс + squash 1.1×0.9.

## Режим и меню
- `GameMode.garden` рядом с classic/timed/daily; свой Hive-снимок (gardenBox) и лидерборд Game Center (`garden_best`).
- Меню: сетка 2×2 карточек режимов (см. 17d), «Сад чудес» — фиолетовая рамка #C973F0 + NEW до первого запуска.
- Первый вход: оверлей онбординга, 4 строки «спрайт → текст» (17d низ): Радужка сливается с любым · Пузырик всплывает и встряхивает · Гнилушка мешает, взорви или слей рядом (+50) · Льдинка морозит на 3 броска.
- Новые типы заказов: mergeRainbowWith(tier), popBubbles(n) — прогресс из событий движка.

## Скрин стора
17e «Special fruits change the rules» — экспортировать по запросу (1290×2796).

## TODO код
- [ ] SpecialKind в domain + вероятности спавна
- [ ] BallBody.special ветки в beginContact/update
- [ ] ice_overlay как child-компонент замороженного BallBody
- [ ] пульс-кольцо у окошка «следующий»
- [ ] заказы popBubbles/mergeRainbowWith + строки локализации (6 языков)
- [ ] Магнитик и Тыква-бомба — 1.2
