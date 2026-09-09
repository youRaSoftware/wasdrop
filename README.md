# Fruity Drop (проект wasdrop)

Merge-drop игра (suika-подобная). Мультипакетный проект (core / core_ui / domain / data / features / navigation), Cubit + get_it + go_router + Hive. Физика — flame_forge2d. Сети нет.

## Первый запуск
1. `script/prebuild_script.sh` — `flutter pub get` во всех пакетах
2. `script/run.sh dev` — запуск dev-флейвора (или конфигурация **Dev** в Android Studio)

Шрифты Rubik (600 / 700 / 900) и Unbounded (600 / 800), оба OFL, лежат в `core/resources/fonts/`.

## Flavors
`dev` (`com.wasdrop.dev`, «Fruity Dev», плашка DEV) и `prod` (`com.wasdrop`, «Fruity Drop»). Передаются и нативно, и через dart-define:

```bash
flutter run --flavor dev --dart-define=environment=dev
flutter run --flavor prod --dart-define=environment=prod
```

## Скрипты
| Скрипт | Что делает |
|---|---|
| `script/run.sh <dev\|prod> [args]` | `flutter run` с нужным флейвором |
| `script/build.sh <dev\|prod> <apk\|aab\|ipa> [--upload]` | релизная сборка; `ipa --upload` отправляет в App Store Connect |
| `script/build_app_builds.sh` | то же, интерактивно |
| `script/prebuild_script.sh [--clean]` | pub get (+ build_runner, если появится) во всех пакетах |
| `script/run_test_script.sh` | unit-тесты по пакетам, общий `coverage/lcov.info` |
| `script/gen_placeholder_audio.py` | перегенерировать плейсхолдер-звуки и музыкальный луп в `core/resources/audio/` |
| `script/gen_dev_icons.sh` | перегенерировать dev-иконки с плашкой DEV из `store/` (iOS + Android) |
| `flutter test integration_test -d <deviceId> --flavor dev --dart-define=environment=dev` | смоук-тест игры на симуляторе/устройстве |

Подпись Android — `android/key.properties` (шаблон `android/key.properties.example`). Процесс релиза — `.claude/my_docs/RELEASE_PROCESS.md`.

## Иконки
Исходники для сторов и Icon Composer — `store/`; наборы для платформ уже разложены (`ios/Runner/Assets.xcassets`, `android/app/src/main/res`, dev-вариант с плашкой DEV — `android/app/src/dev/res` и `AppIcon-Dev.appiconset`).

## Документация
Все документы — в `.claude/`: ТЗ `my_docs/WASDROP.md`, план `plans/plan.md`, changelog `changelog/CHANGELOG.md`, скиллы Claude Code — `SKILLS_GUIDE.md`.

## Статус
Собирается и запускается (iOS-симулятор, dev). Движок на flame 1.38 + flame_forge2d 0.20 (Box2D v3). Текущие задачи — `.claude/plans/plan.md`. Дизайн — вариант 1a (тёплый фруктовый) из мокапов WasDrop.

## Экраны
- `/menu` — меню (лого, рекорд, ИГРАТЬ, звук/настройки)
- `/game` — игра: HUD (счёт, рекорд, следующий шар), стакан, физика; оверлеи паузы и проигрыша внутри GameForm
