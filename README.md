# VEYRA: Clash of Realms

Оригинальный Unity 6 / C# проект мобильной MOBA. Старый Godot-прототип убран из основной ветки; резервная копия истории находится в ветке `backup-before-unity-reset`.

## Текущий этап — игровой greybox-прототип
- Unity 6, версия редактора: `6000.0.32f1`.
- Сцена `Assets/Scenes/Arena.unity` запускает игровой bootstrap автоматически.
- Процедурная 3D-арена, три линии, две базы, шесть башен и простые декорации.
- Выбор Kairon (боец), Eliara (маг), Rain (стрелок).
- Матч 5 на 5: игрок, четыре союзных бота и пять противников.
- Простая логика ботов, башни, атака, три активных навыка, здоровье, золото, опыт и уровни.
- Камера сверху под углом, сенсорное управление перетаскиванием слева и кнопки навыков справа.

## Открыть в Unity
1. Установить Unity Hub и Unity Editor `6000.0.32f1`.
2. Скачать репозиторий и открыть его корневую папку как Unity project.
3. Открыть сцену `Assets/Scenes/Arena.unity` и нажать Play.

## Сборка Android через GitHub Actions
В репозитории есть workflow `.github/workflows/android-build.yml`. Для сборки нужен Unity Personal license file:
1. В GitHub открыть Settings → Secrets and variables → Actions.
2. Создать repository secret `UNITY_LICENSE` и вставить содержимое Unity license file.
3. При необходимости добавить `UNITY_EMAIL` и `UNITY_PASSWORD` как secrets.
4. Открыть Actions → VEYRA Android build → Run workflow.
5. После успешной сборки скачать artifact `VEYRA-Android-APK`.

Unity license file выдаётся Unity для Unity Personal/платной лицензии. Не отправляй пароль или файл лицензии в чат.

## Честный статус
Это ранний greybox, не готовая коммерческая игра и пока не проверенный запуском Unity APK. Вместо финальных моделей используются примитивы. Полноценные анимации, 10+ героев, лесные монстры и босс, магазин предметов, баланс, матчмейкинг и онлайн 5v5 ещё предстоит реализовать. Для подтверждения компиляции нужен запуск Unity Editor или успешная GitHub Actions сборка.
