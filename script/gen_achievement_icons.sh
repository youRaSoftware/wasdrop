#!/usr/bin/env bash
# Иконки достижений Game Center (512×512 PNG) → store/achievements/.
# Фрукты — из спрайтов features/assets/images/fruits, остальные — подписи
# Rubik Black на кремовом круге. Загружать в App Store Connect руками.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
swift "$ROOT/script/make_achievement_icons.swift" "$ROOT" "$ROOT/store/achievements"
