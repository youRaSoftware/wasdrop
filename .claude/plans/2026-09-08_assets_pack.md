# План: шрифты Rubik + Unbounded, SVG-иконки, темы-обои (по `assets_pack/ASSETS.md`)

## Контекст

Дизайнер передал `assets_pack/`: `ASSETS.md` (спецификация) и 8 SVG-иконок 24×24. Спецификация просит три вещи:

1. **Шрифты**: заменить Archivo на пару **Rubik** (весь UI) + **Unbounded** (лого и заголовки оверлеев).
2. **Иконки**: 8 SVG вместо эмодзи (🏆 🔊 🔇 ⚙️ ⏸ ▶) и Material-иконки паузы; штрих `#33291A` 1.8 px, заливки из палитры 1a. SVG содержат по ~8 КБ метаданных c2pa — вырезать.
3. **Темы-обои**: модель `GameTheme(id, name, bgTop, bgBottom, jarFill, jarWall, deadline, hudText, isLocked)`, 6 тем (cream по умолчанию, sunset, mint, night, rose, sky), выбор хранится в Hive (`settingsBox`, ключ `themeId`), пикер — горизонтальный ряд кружков-превью в оверлее паузы; пока все открыты, поле `isLocked` — задел под подписку. Линия проигрыша: спокойная = затемнённый `jarWall`, тревога = `#E5484D` (в night — `#FF5D7A`). Декор фона (звёзды, облака, сакура) — статичные полупрозрачные элементы.

Макета «секция 6» в проекте нет (файл `.dc.html` не найден), источник цветов — таблица в `ASSETS.md`.

---

## Часть 1. Шрифты

- Скачать статические TTF по ссылкам Google Fonts API (проверены, отдают TTF по весам): Rubik 600/700/900, Unbounded 600/800 → `core/resources/fonts/`. Archivo (3 TTF + `OFL.txt`) удалить; вместо него `OFL-Rubik.txt` и `OFL-Unbounded.txt` из `google/fonts` (`ofl/rubik/OFL.txt`, `ofl/unbounded/OFL.txt`, оба доступны) → в assets корневого `pubspec.yaml`, обе регистрируются в `LicenseRegistry` в `lib/main_common.dart` (сейчас регистрируется одна Archivo).
- `pubspec.yaml`: секция `fonts` по спецификации (Rubik 600/700/900, Unbounded 600/800).
- `core_ui/lib/src/theme/app_fonts.dart`: `family = 'Rubik'`, `+ display = 'Unbounded'`; стили по таблице: `title` — Unbounded 800/44, `overlayTitle` — Unbounded 600/20, letterSpacing 1 (0.05em), `score` — Rubik 700/34 tabular, `best` — Rubik 600/11 ls 0.66, `button` — Rubik 700/17; game-over счёт 44 и бейдж 13 остаются `copyWith`. `app_theme.dart`: `fontFamily: AppFonts.family` уже так.

## Часть 2. Иконки

- `core_ui/pubspec.yaml`: `flutter_svg: ^2.3.0` (чистый Dart, SwiftPM не задет), `flutter: assets: - assets/icons/`; файлы → `core_ui/assets/icons/*.svg` без блока `<metadata>…</metadata>` и атрибута `xmlns:c2pa` (с 8 КБ до ~1 КБ каждый).
- Новый `core_ui/lib/src/widgets/app_icon.dart`: `enum AppIcons { trophy, soundOn, soundOff, settings, pause, restart, menuHome, adPlay }` (имя файла из enum) + `AppIcon(icon, {size = 24})` → `SvgPicture.asset('assets/icons/x.svg', package: 'core_ui', width:, height:)`. Экспорт в `widgets.dart`.
- Кнопки получают необязательный `icon` (Widget?), рисуется слева от подписи с зазором 8: `PrimaryButton`, `SecondaryButton`, `AppTextButton` (`core_ui/lib/src/widgets/`).
- Замены:
  - `features/lib/menu/screen/menu_screen.dart`: плашка «🏆 рекорд N» → `AppIcon(trophy, 18)` + текст; 🔊/🔇 → `soundOn/soundOff`; ⚙️ → `settings`. Кнопке ⚙️ дать `key: MenuScreen.settingsButtonKey` (нужен смоук-тесту вместо `find.text('⚙️')`).
  - `features/lib/game/widgets/game_hud.dart`: `Icons.pause` → `AppIcon(pause, 22)`.
  - `features/lib/game/widgets/game_over_overlay.dart`: бейдж «🏆 НОВЫЙ РЕКОРД» → иконка + текст; «Заново» — `icon: restart`; «В меню» — `menuHome`; «▶ Продолжить за рекламу» → `adPlay` + «Продолжить за рекламу».
  - `features/lib/game/widgets/pause_overlay.dart`: «Заново» — `restart`, «В меню» — `menuHome`.
  - Стрелка «назад» и шевроны в настройках остаются Material (SVG для них нет).

## Часть 3. Темы-обои

### 3.1 Модель и хранение
- `core_ui/lib/src/theme/game_theme.dart` (цвета — это `Color`, поэтому core_ui, а не domain): `class GameTheme { id, name, bgTop, bgBottom, jarFill, jarWall, deadline, deadlineAlert, hudText, decor, isLocked }`, `GameThemes.all` (6 тем из таблицы; `deadline` = `jarWall` затемнённый на 15 %, `deadlineAlert` = `AppColors.alert`, у night `#FF5D7A`; `hudText` по таблице), `GameThemes.byId(id)` с fallback на `cream`. `enum ThemeDecor { none, stars, clouds, petals }` — night/sky/rose.
- `domain/lib/models/settings_model.dart`: `+ String themeId` (default `'cream'`); Hive-провайдер и репозиторий — ключ `themeId`; `core/lib/services/settings_service.dart`: `setThemeId`.

### 3.2 Доставка темы в UI
- `core_ui/lib/src/theme/app_theme_scope.dart`: `AppThemeScope` (InheritedWidget с `GameTheme`, `AppThemeScope.of(context)`). `lib/app.dart` оборачивает `builder` в `ValueListenableBuilder<SettingsModel>` на `appLocator<SettingsService>().settings` → `AppThemeScope(theme: GameThemes.byId(id))` (поверх DEV-баннера как сейчас). core_ui не знает о DI — паттерн сохраняется.
- `AppScaffold` (`core_ui/lib/src/widgets/app_scaffold.dart`): фон — `LinearGradient(bgTop → bgBottom)` из scope + слой декора `ThemeDecorPainter` (CustomPainter, детерминированный набор фигур: звёзды — точки трёх размеров, облака — сгруппированные круги с альфой 0.5, лепестки — повёрнутые эллипсы; рисуется один раз, `RepaintBoundary`). `Scaffold.backgroundColor` прозрачный.
- Текст, зависящий от темы (`hudText`): счёт и «РЕКОРД» в HUD (`game_hud.dart`), лого в меню (`menu_screen.dart`, «Drop» остаётся accent), заголовок и подписи секций в настройках (`settings_form.dart`, `settings_section.dart`); вторичный текст — `hudText` с альфой 0.6. Панели/кнопки/карточки остаются светлыми `surface` (по спецификации иконки не перекрашиваются, на светлой подложке читаются во всех темах).
- Стакан (`features/lib/game/screen/game_form.dart`): `DecoratedBox` — `jarFill`/`jarWall` из scope (у пяти тем `jarFill` полупрозрачный — градиент просвечивает).
- Движок (`features/lib/game/engine/wasdrop_game.dart`): `backgroundColor()` → прозрачный (Flame рисует его как `Container(color:)`, прозрачный ничего не закрашивает — проверено в `game_widget.dart`), стакан красит `GameForm`; `_JarOverlay` берёт тему через уже переданный `settings` (`GameThemes.byId(settings.value.themeId)`): линия — `deadline`/`deadlineAlert`, пунктир прицела — `hudText` с альфой 0.45.

### 3.3 Пикер
- `core_ui/lib/src/widgets/theme_picker.dart`: `ThemePicker(themes, selectedId, onSelect)` — ряд кружков 36 px (`AppPressable`): заливка — градиент `bgTop → bgBottom`, внутри точка `jarFill` на `jarWall`-обводке, выбранный — кольцо `accent` 2.5 px, `isLocked` — замок `Icons.lock_rounded` 14 px поверх и тап без действия. Шесть кружков + зазоры 8 = 256 px, входит в панель паузы (280 − 2·24 = 232 — **не входит**: сделать кружки 32 px и зазор 8 → 232 ровно, либо панель паузы 300). Решение: панель паузы `width: 300`, кружки 34 px.
- `pause_overlay.dart`: под тумблерами разделитель, подпись «Обои» (стиль `best`) и `ThemePicker`, `onSelect: settings.setThemeId`. Тот же пикер — на экране настроек в секции «Игра» (`settings_form.dart`), чтобы тему можно было выбрать не только из партии.

### 3.4 Что не входит
Подписка/разблокировка (все `isLocked: false`), анимированный декор, тёмный комплект иконок (по спецификации не нужен).

---

## Документы и уборка
- `assets_pack/ASSETS.md` → `.claude/my_docs/TZ_ASSETS.md` (ТЗ хранятся там по правилам проекта), `assets_pack/` удалить после переноса иконок.
- `CLAUDE.md`: «Дизайн» (шрифты Rubik/Unbounded, иконки `AppIcon`, темы `GameThemes` + `AppThemeScope`), структура core_ui; `.claude/my_docs/WASDROP.md` § 1 токены; `.claude/shared/wasdrop_ui_reference.md` § 1.2 (типографика), 1.4 (иконки — теперь SVG через `AppIcon`), 1.5 (новые виджеты), 4.7 (`themeId`); `.claude/plans/plan.md` (Фаза 3 + бэклог: подписка на темы); `.claude/changelog/CHANGELOG.md` RU/EN.

## Проверка
1. `script/prebuild_script.sh` (новая зависимость), `flutter analyze`, `dart format`.
2. Смоук-тест `integration_test/game_smoke_test.dart`: ⚙️ ищется по ключу; добавить: в паузе есть `ThemePicker`, тап по кружку `night` → `settings.value.themeId == 'night'` и `SettingsRepository` вернул то же, фон стакана/движка не ломает физику (прежние проверки), вернуть `cream` в конце.
3. Скриншоты на симуляторе через временный тест: меню (шрифты, иконки), пауза с пикером, игра в темах `night` и `sunset` (полупрозрачный стакан, цвет линии, текст HUD), проигрыш с иконками кнопок.
4. `flutter build ios --simulator` + запуск dev-сборки.
