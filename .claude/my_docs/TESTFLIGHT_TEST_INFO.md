# TestFlight — Test Information (внешнее тестирование)

Заполняется один раз в App Store Connect → TestFlight → Test Information; «What to Test» — при добавлении каждой сборки во внешнюю группу. Первая внешняя сборка проходит Beta App Review (обычно 1–2 дня); входа в приложении нет, поэтому «Sign-in required» снята.

## Beta App Description (≤ 4000 символов)

```
Fruity Drop — расслабляющая головоломка в жанре merge-drop: бросайте фрукты в стакан, два одинаковых при касании сливаются в следующий, более крупный — от вишни до арбуза. Цель — набрать как можно больше очков и не дать куче вырасти выше линии.

Что есть в этой версии
• 11 фруктов с живыми лицами: «ойкают» при ударе; вытянутые (виноград, лимон, клубника) катятся с покачиванием и ложатся на бок
• физика с весом и инерцией, слияние сохраняет разгон фруктов
• настройки: звуки, музыка, вибрация, линия прицела, статистика (рекорд, игры, слияния, самый большой фрукт), цепочка фруктов
• 6 тем-обоев — выбор в паузе или в настройках
• заставка с падающими фруктами

На что обратить внимание
• ощущение физики: скорость падения, отскок, как фрукты катятся и укладываются в кучу
• слияния: всегда ли сливаются одинаковые фрукты, лежащие рядом; не «проваливаются» ли фрукты в дно и друг в друга
• линия проигрыша: срабатывает ли вовремя, нет ли ложных проигрышей
• темы: читаемость счёта и линии на каждом фоне, особенно «Ночной сад»
• вибрация на реальном устройстве (по умолчанию выключена — включите в настройках)
• плавность при полном стакане, нагрев, расход батареи

Известные ограничения сборки
• рекламы и покупок в этой сборке нет, «Продолжить» после проигрыша даётся бесплатно раз за партию
• интерфейс на шести языках (русский, английский, немецкий, французский, венгерский, японский) — переводы без носителей, замечания по формулировкам очень нужны; язык меняется в настройках

Как сообщить о проблеме: кнопка «Отправить отзыв» в TestFlight (скриншот с пометкой очень помогает) или письмо на почту ниже. Пожалуйста, укажите модель устройства и версию iOS.
```

## What to Test (для каждой сборки, ≤ 4000; поле English (U.S.) для внешней ссылки — по-английски)

Build 1.0.0 — the "orders, jars and modes" build (2026-09-17):

Fruity Drop is a cosy fruit-merge puzzle: drop fruit into a jar, two of a kind that touch grow into the next one, keep the pile below the line.

New in this build — please try all of it:
• Orders: three goals at the top of the game screen (get a lemon, merges in a row, points…). Do they complete when you expect? Does the "Order done!" pop-up feel right? Tap the panel to open the orders screen.
• Jars: Menu → "Jar" button. Vase, Bowl and Shelf are open; Flask, Slope and Hourglass unlock with stars from orders. Does fruit ever get stuck, sink into a wall or fly out of a jar?
• Modes: "Time attack" (2 minutes) and "Daily challenge" (one attempt a day, same fruit for everyone) under the Play button. Is the timer readable? Does the daily button show your score afterwards?
• Game Center: sign in on the device (Settings → Game Center), then look for the trophy button in the menu and "Leaderboards" on the game-over screen. Do scores and achievements appear?
• Boosters: Shake (tap the button, then shake the phone), Bomb and Grow. Are the charges enough or too many?
• Menu: tilt the phone — the fruit pile should follow; turn it upside down and the pile falls to the top.
• First launch shows a three-step "How to play"; it is also in Settings.
• The red glow at the top of the jar when a fruit sits above the line.
    
Also check as before: physics feel (falling speed, bounce, rolling), merges of fruit lying side by side, game-over timing, wallpapers (pause → Wallpapers), settings surviving a restart, vibration (enable it in Settings).

Known: no ads and no purchases in this build; the interface is in six languages, translations were made without native speakers — wording feedback is very welcome (change the language in Settings).

How to report: TestFlight → "Send Beta Feedback" (a screenshot helps a lot) or the feedback email. Please mention the device model and iOS version.

## Остальные поля

| Поле | Что вписать |
|---|---|
| Feedback Email | Почта, куда TestFlight пришлёт отзывы тестеров (видна тестерам). Почта аккаунта разработчика или отдельный ящик проекта |
| Contact Information | Имя, фамилия, телефон, почта того, кто отвечает Apple на вопросы по Beta App Review. Тестерам не показывается |
| Sign-in required | **Снять галочку**: аккаунтов в игре нет, User Name / Password оставить пустыми |
| Privacy Policy URL (если запросят) | Ссылка на политику — см. бэклог в `plans/plan.md`; для внешнего тестирования App Store Connect может её потребовать |

Export compliance уже в `Info.plist` (`ITSAppUsesNonExemptEncryption = false`), вопрос о шифровании при загрузке сборки не появится.
