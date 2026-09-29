# LinguaSchool — контекст проєкту

## Хто я і навіщо проєкт
Досвідчений розробник WordPress-плагінів, переходжу на Symfony. Це pet-проєкт для глибокого
вивчення Symfony та екосистеми: функціональна копія онлайн-школи англійської за зразком
englishdom.com (структура й функції; бренд, фото й тексти оригіналу НЕ використовуємо).
ФОКУС — БЕКЕНД. Пріоритет — навчання: пояснюй рішення, пропонуй ідіоматичний Symfony-підхід,
порівнюй із WP, де це допомагає. Не генеруй великі шматки бекенд-коду без пояснень.

## Стек
- Symfony 8.1, PHP 8.4+, FrankenPHP (шаблон dunglas/symfony-docker), PostgreSQL, Redis/Valkey, Mailpit
- Doctrine ORM + Migrations, Foundry, UUID v7, symfony/clock
- Публічна частина: Twig + Symfony UX Twig Components (SSR, SEO), сторінки працюють без JS
- Стилі: AssetMapper + symfonycasts/tailwind-bundle (standalone Tailwind 4, без Node) + daisyUI
- Vue 3 ВІДКЛАДЕНО. Інтерактивні місця мають плейсхолдери data-island + data-props
  з робочою SSR-розміткою всередині (каруселі — CSS scroll-snap, FAQ — <details>)
- Кабінет: API-first (JSON API, API Platform, Swagger UI, .http-файли); /app/* — Twig-заглушка
- Auth: сесійні cookie + CSRF (не JWT), login link, Google OAuth
- Адмінка: EasyAdmin
- Якість: PHPStan level max (без baseline), PHP-CS-Fixer (@Symfony, risky), Rector, Deptrac,
  PHPUnit (suites: unit/integration/functional, DAMA), lint:twig, lint:container
- Команди через Makefile: up, down, sh, css, db-reset, test, qa, fix

## Межа бекенд / UI
- Мій код: PHP-класи компонентів у src/<Module>/Twig/Components/ (дані, типізовані властивості),
  контролери, сутності, сервіси, тести
- Генерований AI: шаблони секцій templates/components/Home/, UI-kit templates/components/Ui/
  (анонімні компоненти з {% props %}), тема assets/styles/app.css
- Правила для UI-задач: лише Tailwind + daisyUI, семантичний HTML, без JavaScript, mobile-first
  від 360 px, доступність; у шаблонах жодної бізнес-логіки й запитів
- UI-коміти окремо з префіксом `ui:`

## Архітектура
Модульний моноліт: src/<Module>/. Модулі: Shared, Identity, Content, Catalog, Teaching,
Scheduling, GroupClasses, Billing, Learning, Vocabulary, Assessment, Leads, Notification.
- Складні модулі (Scheduling, Billing, Learning): шари Domain/Application/Infrastructure/UI
- Прості (Content, Catalog, Leads): пласко — Entity/, Repository/, Controller/, Twig/
- Модулі спілкуються через доменні події (Messenger) і публічні фасади; межі контролює Deptrac;
  усі можуть залежати від Shared, Shared — ні від кого
- Локалі: uk (default) і en, URL-префікси /ua/ і /en/; / → 301 на /ua/
- Перекладний контент: сутність + <Entity>Translation (locale, унікальний індекс (parent_id, locale))

## Ключові доменні правила (на майбутні етапи)
Урок 50 хв; перенесення/скасування ≥ 6 год до початку, 2 безкоштовні на місяць; пакети
8/1міс, 16/2міс, 24/3міс, 48/6міс з автопоновленням і нагадуванням за 3 дні; баланс уроків —
append-only ledger; групи до 7, розмовні клуби до 12 (A1–C1); гроші — цілі мінорні одиниці;
час в UTC + IANA-таймзона користувача.

## Roadmap
0 Фундамент → 1 Каркас публічного сайту → 2 Каталоги й блог → 3 Ліди й тест рівня →
4 Ідентифікація + API кабінету → 5 Розклад і уроки → 6 Білінг → 7 Навчальний контент →
8 Групи й клуби → 9 B2B/діти/аналітика → 10 Продакшн-якість → (опційно) Vue-фронтенд.

## Поточний стан
Етап 0 ще не розпочато. Детальний план етапів 0–1 — у docs/stage-0-1.md.

## Правила роботи
- Кожен крок — окремий невеликий коміт; після змін запускати `make qa` і `make test`
- Перед встановленням пакета перевіряти сумісність із Symfony 8.1
- Код: declare(strict_types=1), final-класи (крім Doctrine-сутностей), readonly де можливо,
  конструкторна ін'єкція, атрибути замість YAML для роутів і mapping
