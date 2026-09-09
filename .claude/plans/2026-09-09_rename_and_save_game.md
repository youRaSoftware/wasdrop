# План: название «Fruity Drop: Merge Puzzle» + сохранение партии

## Контекст

1. Новое название игры для сторов — **Fruity Drop: Merge Puzzle** (25 символов, в лимит 30 App Store / Google Play). Под иконкой нужно короче: **Fruity Drop** (11 символов, iOS не обрезает), dev-сборка — **Fruity Dev**. Внутреннее имя проекта/пакетов (`wasdrop`) и bundle id `com.wasdrop` не меняются — запись в App Store Connect уже создана под этим id, а имя в сторе задаётся в консолях, не в коде.
2. Партия не переживает закрытие приложения: состояние живёт только в `GameCubit` и мире Box2D. Нужно сохранять партию и предлагать продолжить из меню.

---

## Часть 1. Название

- iOS: `APP_DISPLAY_NAME` в `ios/Runner.xcodeproj/project.pbxproj` — `WasDrop` → `"Fruity Drop"` (7 мест), `"WasDrop Dev"` → `"Fruity Dev"` (2 места).
- Android: `android/app/build.gradle.kts` — `resValue("string", "app_name", …)`: `Fruity Dev` / `Fruity Drop`.
- Dart: `core/lib/config/app_config.dart` — `appName` `Fruity Drop` / `Fruity Dev` (заголовок `MaterialApp`, страница лицензий).
- Лого в меню и сплеше (`menu_screen.dart`, `splash_screen.dart`): «Was»+«Drop» → «Fruity »+«Drop» (второе слово акцентом, как сейчас). `AppFonts.title` 42 px Unbounded — «Fruity Drop» ≈ 330 px, в ширину экрана входит.
- `pubspec.yaml` description, `README.md` заголовок и строка про флейворы, `CLAUDE.md` первая строка (внутреннее имя wasdrop, витринное Fruity Drop), `TESTFLIGHT_TEST_INFO.md` (WasDrop → Fruity Drop), `TZ_ASSETS.md`/`WASDROP.md` не трогаем (исторические ТЗ).
- В App Store Connect имя меняется руками: App Information → Name «Fruity Drop: Merge Puzzle» (и Subtitle при желании); в Google Play — Store listing → App name. Напомнить в ответе.

## Часть 2. Сохранение партии

### Данные
- `domain/lib/models/game_snapshot.dart`: `BallSnapshot(tier, x, bottomOffset, angle, vx, vy)` — `bottomOffset` = расстояние центра до дна (высота мира зависит от экрана, x — нет); `GameSnapshot(score, current, next, merges, bestTier, balls, savedAt)`. Экспорт из `domain.dart`.
- `domain/lib/repositories/game_repository.dart`: `load() → GameSnapshot?`, `save(GameSnapshot)`, `clear()`.
- `data/lib/providers/local/game_hive_provider.dart` (бокс `gameBox`, ключ `snapshot`, значение — `Map` с примитивами и списком списков `[tier, x, dy, angle, vx, vy]`; адаптеры не нужны), `data/lib/repositories/game_repository_impl.dart`; `StorageConstants.gameBox` + литерал в `DataDI.init()`; регистрация в DI.

### Движок и кубит
- `BallBody`: новый параметр `initialAngle` → `BodyDef(rotation: Rot.fromAngle(angle))`.
- `WasDropGame({cubit, settings, GameSnapshot? resumeFrom})`: в `onLoad` после `_layoutWorld` — `_restore(snapshot)`: шары по `x`, `worldHeight − bottomOffset`, угол, скорость. `captureBalls()` → `List<BallSnapshot>` из смонтированных, не сливающихся `BallBody`.
- `GameCubit({…, GameRepository gameRepository, GameSnapshot? resumeFrom})`: начальное состояние из снимка (score, current, next, merges, bestTier; `_runSaved = false`), **статус `paused`** — восстановленная партия открывается в оверлее паузы, «Продолжить» запускает физику. `saveSnapshot(List<BallSnapshot> balls)`: при `playing`/`paused` → `gameRepository.save(...)`; `gameOver()` и `restart()` → `gameRepository.clear()`.
- `GameForm` (`WidgetsBindingObserver`): сохранение при `AppLifecycleState.inactive/paused/hidden`, по таймеру каждые 2 с во время игры, и перед `goNamed('menu')`. Снимок = `cubit.saveSnapshot(_game.captureBalls())`.

### Меню и роут
- `MenuScreen._loadStats` дополнительно грузит `GameRepository.load()`. Если снимок есть: `PrimaryButton` «Продолжить» (`goNamed('game', extra: snapshot)`) и под ней `AppTextButton` «Новая игра» (`clear()` → `goNamed('game')`); иначе «Играть» как сейчас. Ключи `menu_continue`, `menu_newGame` во все шесть JSON + перегенерация `LocaleKeys`.
- Роут `/game`: `GameScreen(resumeFrom: state.extra as GameSnapshot?)` — `navigation/pubspec.yaml` получает зависимость `domain`. `GameScreen` передаёт снимок в кубит и в `GameForm` → `WasDropGame`.

### Проверка
- Смоук-тест: после бросков — `cubit.saveSnapshot(game.captureBalls())`, `GameRepository.load()` возвращает столько же шаров и тот же счёт; «В меню» → в меню есть «Продолжить»; тап → игра открывается в паузе с тем же счётом и числом шаров; «Продолжить» → статус playing; затем `restart()` → `load()` = null. Проверить в конце, что снимок очищен.
- Скриншот меню с «Продолжить» / «Новая игра» на симуляторе; домашний экран с подписью «Fruity Dev».
- `flutter analyze`, `dart format`, пересборка dev.

## Документы
- `CLAUDE.md` (название, `GameRepository`/`gameBox`, где сохраняется партия), `WASDROP.md` § 2 меню (Продолжить / Новая игра) и § 3 (снимок партии), UI-референс § 4.3 (третья пара провайдер/репозиторий) и § 2.1 (`GameScreen(resumeFrom:)`), `plan.md`, `CHANGELOG.md` RU/EN, `TESTFLIGHT_TEST_INFO.md`.
