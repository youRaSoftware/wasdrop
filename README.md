# WasDrop

Merge-drop игра (suika-подобная). Мультипакетный проект (core / core_ui / domain / data / features / navigation), Cubit + get_it + go_router + Hive. Физика — flame_forge2d. Сети нет.

## Первый запуск
1. Скачать шрифт Archivo (600 / 800 / 900) в `core/resources/fonts/` (`Archivo-SemiBold.ttf`, `Archivo-ExtraBold.ttf`, `Archivo-Black.ttf`) — или временно убрать секцию `fonts` из `pubspec.yaml`
2. `script/prebuild_script.sh` — `flutter pub get` во всех пакетах
3. `script/run.sh dev` — запуск dev-флейвора (или конфигурация **Dev** в Android Studio)

## Flavors
`dev` (`com.wasdrop.dev`, «WasDrop Dev», плашка DEV) и `prod` (`com.wasdrop`, «WasDrop»). Передаются и нативно, и через dart-define:

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
| `script/run_test_script.sh` | тесты по пакетам, общий `coverage/lcov.info` |

Подпись Android — `android/key.properties` (шаблон `android/key.properties.example`). Процесс релиза — `.claude/my_docs/RELEASE_PROCESS.md`.

## Документация
Все документы — в `.claude/`: ТЗ `my_docs/WASDROP.md`, план `plans/plan.md`, changelog `changelog/CHANGELOG.md`, скиллы Claude Code — `SKILLS_GUIDE.md`.

## Статус
Код написан без проверки компиляции — мелкие правки (импорты `Vector2` в движке, версии flame) ожидаемы, см. `.claude/plans/plan.md` «Фаза 1». Дизайн — вариант 1a (тёплый фруктовый) из мокапов WasDrop.

## Экраны
- `/menu` — меню (лого, рекорд, ИГРАТЬ, звук/настройки)
- `/game` — игра: HUD (счёт, рекорд, следующий шар), стакан, физика; оверлеи паузы и проигрыша внутри GameForm
