# Claude Code Skills — Руководство по использованию

## Что такое Skills?

Skills — это кастомные команды для Claude Code с подробными инструкциями по созданию кода в нашем проекте. В отличие от обычного описания задачи в чате, skills могут **автоматически** подхватываться Claude, когда он понимает, что задача соответствует описанию скилла.

## Доступные Skills

| Команда | Когда использовать | Что создаёт |
|---|---|---|
| `/create-feature-ui` | Нужен экран / фича на существующих репозиториях или моках (настройки, таблица рекордов) | State, Cubit, Screen, Form, виджеты, роут, экспорт в `features.dart` |
| `/create-feature-full` | Фича с новыми сохраняемыми данными (новый Hive-бокс) и экранами | Model, Repository (interface + impl), Hive provider, DI, + всё из `create-feature-ui` |
| `/create-widget` | Нужен переиспользуемый UI-компонент дизайн-системы | Виджет в `core_ui/lib/src/widgets/` + экспорт в barrel |
| `/analyze-feature` | Нужен контекст по существующей фиче (игра, меню, движок) | Документ-описание архитектуры в `.claude/my_docs/{feature}.md` |
| `/audit-section` | Полный аудит раздела перед релизом | Отчёт: вертикальный анализ (Hive → Repository → Model → Cubit → State → UI + движок) + горизонтальный (дубли, мёртвый код, паттерны, соответствие ТЗ) |
| `/llm-council` | Спорное решение, которое надо обкатать с разных сторон | Вердикт совета из 5 независимых AI-советников |

## Как использовать

### Способ 1: Явный вызов (slash-команда)

```
/create-feature-ui
```

Claude загрузит скилл и спросит детали. Или сразу с аргументами:

```
/analyze-feature game — нужен полный контекст по игровому экрану и движку
```

### Способ 2: Авто-триггер (просто опишите задачу)

```
Сделай экран настроек: тумблеры «Звук» и «Вибрация», кнопка «Готово» — на SettingsRepository.
```

Claude увидит «экран» + существующий репозиторий → `create-feature-ui`.

```
Напомни, как устроен движок — что там с бросками и слиянием?
```

«нужен контекст / как устроен» → `analyze-feature`.

### Способ 3: Явная ссылка в тексте

```
Используя create-feature-full, сделай ежедневные задания: хранить прогресс в Hive, экран списка заданий.
```

## Что давать Claude при вызове

### create-feature-ui
- Название фичи, описание, список экранов
- Номера кадров мокапа (`.claude/my_docs/WASDROP.md` § 2) или скриншот

### create-feature-full
- Название фичи
- Какие данные сохранять (поля, тип, имя бокса)
- Список экранов

### create-widget
- Название виджета
- Описание поведения и вариантов, из какого кадра мокапа

### analyze-feature
- Название фичи или путь в `features/lib/`
- (Опционально) путь для сохранения документа (по умолчанию `.claude/my_docs/{feature}.md`)

### audit-section
- Название раздела, путь к фиче
- Пути к документации (ТЗ — `.claude/my_docs/WASDROP.md`, документы из `analyze-feature`)
- (Опционально) путь для отчёта

### llm-council
- Вопрос или решение с контекстом: варианты, ставки, что уже пробовали

## Примеры реальных запросов

### UI фича
```
/create-feature-ui

Фича: Settings (Настройки)
Описание: экран с тумблерами звука и вибрации, открывается из меню по ⚙️
Экраны:
- SettingsScreen — заголовок НАСТРОЙКИ, два тумблера, кнопка ГОТОВО → /menu
```

### Полная фича
```
/create-feature-full

Фича: DailyStats (Статистика дня)
Данные: dailyStatsBox — todayBest:int, streakDays:int, lastPlayedAt:String (ISO)
Экраны:
- StatsScreen — лучший результат за сегодня, серия дней
```

### Виджет
```
/create-widget

Виджет: SecondaryButton
Описание: плоская пилюля secondarySurface с подписью secondaryText (кадры 5–6), сейчас приватный _SecondaryButton в pause_overlay.dart — вынести в core_ui
```

### Анализ фичи
```
/analyze-feature

Фича: Game (игровой экран + движок)
Путь: features/lib/game/
Результат: .claude/my_docs/game.md
```

### Аудит раздела
```
/audit-section

Раздел: Game
Фича: features/lib/game/
Документация: .claude/my_docs/WASDROP.md
Результат: .claude/my_docs/game_audit.md
```

## Структура файлов

```
.claude/
├── skills/
│   ├── analyze-feature/SKILL.md
│   ├── audit-section/SKILL.md
│   ├── create-feature-full/SKILL.md
│   ├── create-feature-ui/SKILL.md
│   ├── create-widget/SKILL.md
│   └── llm-council/SKILL.md
├── shared/
│   └── wasdrop_ui_reference.md   ← UI/архитектурный референс (токены, виджеты, стиль кода) — его читают create-* скиллы
├── my_docs/                      ← ТЗ (WASDROP.md), процесс релиза, документы из analyze-feature / audit-section
├── plans/plan.md                 ← основной план разработки
├── changelog/CHANGELOG.md        ← user-facing changelog по релизам
├── settings.json                 ← общие настройки Claude Code (в git)
└── SKILLS_GUIDE.md               ← этот файл
```

## FAQ

**Q: Claude вызвал не тот скилл?**
A: Уточните запрос или вызовите нужный явно через slash-команду.

**Q: Можно ли редактировать skills?**
A: Да, это обычные `.md` файлы — правьте `SKILL.md` в нужной папке.

**Q: Как добавить новый skill?**
A: Создайте `.claude/skills/{name}/SKILL.md` с frontmatter (`name`, `description`) и содержимым.

**Q: Откуда скиллы знают про дизайн-систему?**
A: `create-*`, `analyze-feature` и `audit-section` обязаны прочитать `.claude/shared/wasdrop_ui_reference.md` — это источник правды по токенам, виджетам и стилю кода. Если меняете `AppColors` / `AppFonts` / `AppDimens` или добавляете виджет в `core_ui` — обновите и референс.
