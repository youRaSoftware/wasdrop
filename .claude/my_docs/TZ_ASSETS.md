# WasDrop — шрифты, иконки, темы

> ТЗ от дизайнера (пакет `assets_pack`, 2026-09-08). **Реализовано 2026-09-08**: шрифты и лицензии в `core/resources/fonts/`, иконки в `core_ui/assets/icons/` (виджет `AppIcon`), темы — `GameThemes` в core_ui, выбор в `SettingsModel.themeId`, пикер `ThemePicker` в паузе и настройках. Отличия от текста ниже: линия проигрыша в ночной теме светлее стенки (затемнённая на тёмном стакане не видна); декор фона — процедурный (`ThemeDecorLayer`: звёзды у night, облака у sky, лепестки у rose); пикер есть и в настройках. Все темы открыты, `isLocked` — задел под подписку.

## Шрифты
Пара: **Unbounded** (дисплейный — лого и крупные заголовки) + **Rubik** (рабочий — весь UI, счёт, кнопки). Оба Google Fonts, лицензия OFL, полная кириллица+латиница.

| Роль | Шрифт | Вес | Размер (лог. px) |
|---|---|---|---|
| Лого в меню | Unbounded | 800 | 40–44 |
| Заголовки оверлеев (ПАУЗА, ИГРА ОКОНЧЕНА) | Unbounded | 600 | 18–20, letter-spacing .05em |
| Счёт HUD | Rubik | 700 | 34, tabular-nums |
| Подпись РЕКОРД | Rubik | 600 | 11, ls .06em |
| Кнопки | Rubik | 700 | 16–17 |
| Экран проигрыша, счёт | Rubik | 700 | 44, tabular-nums |
| Бейдж НОВЫЙ РЕКОРД | Rubik | 700 | 13 |

Скачать ttf: fonts.google.com/specimen/Rubik (400/600/700/900), fonts.google.com/specimen/Unbounded (600/800) → `core/resources/fonts/`.

pubspec (корень):
```yaml
fonts:
  - family: Rubik
    fonts:
      - asset: core/resources/fonts/Rubik-SemiBold.ttf
        weight: 600
      - asset: core/resources/fonts/Rubik-Bold.ttf
        weight: 700
      - asset: core/resources/fonts/Rubik-Black.ttf
        weight: 900
  - family: Unbounded
    fonts:
      - asset: core/resources/fonts/Unbounded-SemiBold.ttf
        weight: 600
      - asset: core/resources/fonts/Unbounded-ExtraBold.ttf
        weight: 800
```
В `app_fonts.dart`: заменить family 'Archivo' → 'Rubik'; добавить `static const String display = 'Unbounded';` и использовать в title/overlayTitle.

## Иконки (icons/)
8 SVG 24×24, штрих #33291A 1.8px, заливки из палитры 1a. Вместо эмодзи: trophy (🏆), sound_on/sound_off (🔊), settings (⚙️), pause (⏸), restart, menu_home, ad_play (▶).
Подключение: пакет `flutter_svg`, ассеты в `core_ui/assets/icons/` + в pubspec core_ui:
```yaml
flutter:
  assets:
    - assets/icons/
```
Использование: `SvgPicture.asset('assets/icons/trophy.svg', package: 'core_ui', width: 24)`. Для тёмной темы (ночной сад) штрих #33291A заменить на #F2EFE6 через colorFilter не получится (многоцветные) — либо второй комплект, либо оставить как есть на светлой подложке кнопки.

## Темы обоев (мокап, секция 6)
Модель: `GameTheme(id, name, bgTop, bgBottom, jarFill, jarWall, deadline, hudText, isLocked)`. Хранить выбор в Hive (settingsBox, ключ themeId). Пикер — горизонтальный ряд кружков-превью в оверлее паузы. Пока все isLocked: false; поле оставить под подписку.

| id | Название | bg top→bottom | jarFill | jarWall | hudText |
|---|---|---|---|---|---|
| cream | Крем (default) | #F7F2E7 | #ECE5D6 | #D9CFBB | #33291A |
| sunset | Персиковый закат | #FFE3C2→#F7B2A0 | rgba(255,244,230,.72) | #E8B490 | #5C3A24 |
| mint | Мятный сад | #DFF3E4→#BFE6CB | rgba(255,255,255,.62) | #9CC9A9 | #1F4A2E |
| night | Ночной сад | #1E2433→#141926 | #232B3D | #3A4358 | #F2EFE6 |
| rose | Пудрово-розовая | #FBE4EC→#F6CFDD | rgba(255,245,249,.7) | #E3A8C0 | #6E2E48 |
| sky | Небо и облака | #CBE8F7→#A9D6EF | rgba(255,255,255,.6) | #8FBEDA | #6E9FBD |

Цвет линии проигрыша: спокойный = jarWall затемнённый (см. мокап), тревога = #E5484D во всех темах (в night — #FF5D7A). Декор фона (звёзды, облака, сакура) — статичные полупрозрачные элементы, не влияют на геймплей.
