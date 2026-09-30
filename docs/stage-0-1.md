# LinguaSchool: етапи 0 і 1 — детальний план

Sep 28, 2026 · @Alex Hamenko

Після етапів 0 і 1 (приблизно 3–4 тижні) у вас є робочий Docker-проєкт на Symfony 8.1 з CI, двомовна головна сторінка, статичні сторінки та адмінка для контенту.

Фокус — бекенд. Стилі та базовий UI-kit генерує AI, Vue відкладено: на його місці лишаються плейсхолдери `data-island`, а сторінки повністю працюють без JavaScript.

## Етап 0. Фундамент (≈1 тиждень)

### 0.1 Середовище (≈1 день)

Базою беремо шаблон [dunglas/symfony-docker](https://github.com/dunglas/symfony-docker): FrankenPHP, Caddy з HTTPS на localhost, вбудований Mercure і готовий GitHub Actions workflow.

1. Встановіть Docker Desktop / Docker Engine з Compose v2, Git, PhpStorm з плагіном Symfony Support.
2. Створіть репозиторій через «Use this template» на сторінці шаблону і клонуйте його.
3. Зберіть і запустіть із потрібною версією: `docker compose build --pull --no-cache`, потім `SYMFONY_VERSION=8.1.* docker compose up --wait`. Перевірте актуальний синтаксис у `docs/options.md` шаблону.
4. Відкрийте `https://localhost`, прийміть self-signed сертифікат, побачте welcome-сторінку Symfony.
5. Переконайтеся, що в `composer.json` є `"extra": {"symfony": {"require": "8.1.*"}}` і `"php": ">=8.5"`.
6. Перший коміт одразу після генерації — щоб бачити, що змінюють Flex-рецепти далі.

**Сервіси Docker після етапу 0**

| Сервіс | Звідки | Навіщо |
| --- | --- | --- |
| `php` (FrankenPHP) | Шаблон | Застосунок, HTTP, Mercure hub |
| `database` (PostgreSQL) | Рецепт `symfony/orm-pack` | Основна БД |
| `mailer` (Mailpit) | Рецепт `symfony/mailer` | Перегляд листів у dev |
| `redis` (Valkey або Redis) | Додаєте вручну в `compose.yaml` | Кеш, сесії, lock, rate limit (потрібні з етапу 2–3) |

Порада: окремо від `compose.override.yaml` (dev) тримайте `compose.prod.yaml` з шаблону без змін — він знадобиться на етапі деплою.

### 0.2 Пакети Composer (≈0,5 дня)

Встановлюйте по одному пакету з окремим комітом і читайте, що додав Flex-рецепт у `config/`, `.env` і `compose.yaml`. Команди виконуються всередині контейнера: `docker compose exec php composer require …`. Якщо пакет ще не підтримує 8.1 — Composer одразу скаже, і це теж корисний досвід.

| Пакет | Тип | Навіщо на етапах 0–1 |
| --- | --- | --- |
| `symfony/orm-pack` | prod | Doctrine ORM, DBAL, Migrations |
| `symfony/twig-bundle` | prod | Шаблони |
| `twig/extra-bundle`, `twig/intl-extra`, `twig/string-extra`, `twig/html-extra` | prod | Автореєстрація Twig-розширень (сам бандл фільтрів не дає); `format_currency`/`format_datetime`, `u.truncate`/`slug`, `html_classes()`. Markdown, cssinliner, inky, cache - коли знадобляться |
| `symfony/ux-twig-component` | prod | Секції головної та UI-kit як компоненти |
| `symfony/asset-mapper` | prod | Статика без Node і бандлера |
| `symfonycasts/tailwind-bundle` | prod | Tailwind через standalone-бінарник |
| `symfony/translation`, `symfony/intl` | prod | Мультимовність |
| `symfony/validator`, `symfony/form` | prod | Валідація, форми (заявки — етап 3) |
| `symfony/uid`, `symfony/clock` | prod | UUID v7, тестований час |
| `symfony/mailer` | prod | Підтягне Mailpit у compose |
| `symfony/security-bundle` | prod | Поки лише для захисту `/admin` |
| `easycorp/easyadmin-bundle` | prod | Адмінка контенту |
| `symfony/maker-bundle` | dev | Генерація сутностей, контролерів |
| `symfony/debug-pack`, `symfony/web-profiler-bundle` | dev | Профайлер, dump |
| `symfony/test-pack` | dev | PHPUnit, BrowserKit, DomCrawler |
| `zenstruck/foundry` | dev | Фабрики й фікстури |
| `dama/doctrine-test-bundle` | dev | Відкат транзакцій між тестами |
| `phpstan/phpstan`, `phpstan/phpstan-symfony`, `phpstan/phpstan-doctrine` | dev | Статичний аналіз |
| `friendsofphp/php-cs-fixer` | dev | Code style |
| `rector/rector` | dev | Автоматичні рефакторинги й апгрейди |
| `deptrac/deptrac` | dev | Контроль меж між модулями |

### 0.3 Якість коду (≈1 день)

Налаштовуємо все на порожньому проєкті, поки немає технічного боргу: потім підняти рівень PHPStan набагато важче.

1. **PHPStan** — `phpstan.dist.neon`: `level: max`, `paths: [src, tests]`, розширення symfony і doctrine; вкажіть `symfony.containerXmlPath` на `var/cache/dev/App_KernelDevDebugContainer.xml` і `doctrine.objectManagerLoader` на `tests/object-manager.php`. Baseline не створюйте.
2. **PHP-CS-Fixer** — `.php-cs-fixer.dist.php` з наборами `@Symfony`, `@Symfony:risky`, `@PHP84Migration`; `declare_strict_types`, `final_class` для нових класів (крім сутностей Doctrine).
3. **Rector** — `rector.php` з `->withPhpSets()`, `->withAttributesSets()`, наборами Symfony/Doctrine і `->withPreparedSets(deadCode: true, codeQuality: true, typeDeclarations: true)`. У CI запускаємо лише `--dry-run`.
4. **Deptrac** — `deptrac.yaml`: шар на кожен модуль (`Shared`, `Content`, …) через collector `directory`. Правило: будь-який модуль може залежати від `Shared`; `Shared` — ні від кого. Нові модулі додаєте в конфіг разом із папкою.
5. **PHPUnit** — `phpunit.dist.xml` з трьома suites: `unit` (`tests/Unit`), `integration` (`tests/Integration`, KernelTestCase + БД), `functional` (`tests/Functional`, WebTestCase). Увімкніть розширення DAMA для відкату транзакцій.
6. **Тестова БД** — `.env.test` з окремою базою; команди `doctrine:database:create --env=test` і `doctrine:migrations:migrate --env=test` винесіть у Makefile.

Порада з досвіду WP: у PhpStorm підключіть PHPStan і CS-Fixer як inspections — помилки видно одразу в редакторі, а не лише в CI.

### 0.4 Стилі без Node: AssetMapper + Tailwind + daisyUI (≈0,5 дня)

Фронтенд-збірки на старті немає: Vue відкладено, стилі й UI-kit генерує AI. Потрібен лише мінімум, щоб Twig-шаблони мали CSS.

1. `composer require symfony/asset-mapper symfonycasts/tailwind-bundle`, далі `bin/console tailwind:init`. Бандл завантажить standalone-бінарник Tailwind, Node не потрібен.
2. `assets/styles/app.css`: `@import "tailwindcss";`, `@source` на `templates/**/*.twig`, daisyUI у варіанті для standalone-бінарника (за актуальною інструкцією daisyUI) і власна тема з основним кольором \~`#4fc87a`.
3. У `base.html.twig`: `<link rel="stylesheet" href="{{ asset('styles/app.css') }}">` і `{{ importmap('app') }}`.
4. Dev: `bin/console tailwind:build --watch` окремим процесом (ціль `make css`). Prod і CI: `tailwind:build --minify` + `asset-map:compile`.
5. `assets/app.js` лишається майже порожнім; JavaScript на етапах 0–1 не пишемо.

Коли дійде до Vue: `pentatrion/vite-bundle` + `vite-plugin-symfony`, Node-сервіс у compose, заміна `importmap()` на `vite_entry_*_tags()` у `base.html.twig`. Оцінка — близько пів дня.

### 0.5 Makefile, CI, готовність (≈1 день)

**Makefile** — одна точка входу для вас і для Claude Code:

| Ціль | Що робить |
| --- | --- |
| `make up` / `make down` | `docker compose up --wait` / `down` |
| `make sh` | Shell у контейнері `php` |
| `make css` | `tailwind:build --watch` |
| `make db-reset` | drop → create → migrate → fixtures (dev) |
| `make test` | Тестова БД + `phpunit` |
| `make qa` | `phpstan`, `php-cs-fixer --dry-run`, `rector --dry-run`, `deptrac`, `lint:twig`, `lint:container`, `doctrine:schema:validate` |
| `make fix` | `php-cs-fixer fix`, `rector process` |

**CI (GitHub Actions)** — розширте workflow із шаблону до одного job: збірка образу, `make qa`, `make test` з PostgreSQL, `tailwind:build --minify` + `asset-map:compile` як smoke-перевірка статики. Увімкніть branch protection: merge у `main` лише із зеленим CI. Працюйте короткими гілками й PR навіть наодинці — так видно історію рішень.

**Готовність етапу 0**

- [ ] `make up` піднімає проєкт з нуля на чистій машині
- [ ] `https://localhost` відкривається, профайлер працює
- [ ] `make qa` і `make test` зелені (є хоча б один smoke-тест)
- [ ] Tailwind + daisyUI збираються, `base.html.twig` підхоплює стилі
- [ ] CI зелений на PR, `main` захищений
- [ ] README: як запустити, які команди є
- [ ] `CLAUDE.md` у корені з контекстом проєкту

## Етап 1. Каркас публічного сайту (≈2–3 тижні)

### 1.1 Модулі й локалізований роутинг (≈2 дні)

1. Видаліть дефолтні `src/Controller`, `src/Entity`, `src/Repository`. Створіть `src/Shared/` і `src/Content/` (пласкі підпапки `Entity/`, `Repository/`, `Controller/`, `Twig/`).
2. У `config/packages/doctrine.yaml` — mapping на кожен модуль (`dir: '%kernel.project_dir%/src/Content/Entity'`, `prefix: 'App\Content\Entity'`). У `config/routes.yaml` — імпорт атрибутних роутів із `src/*/Controller/`.
3. Локалі: `uk` (за замовчуванням) і `en`. Префікси в URL як в оригіналі — `/ua/` і `/en/` — через локалізований префікс у `routes.yaml`: `prefix: { uk: '/ua', en: '/en' }`. Корінь `/` → 301 на `/ua/` (окремий контролер або визначення мови з `Accept-Language`).
4. `framework.enabled_locales: [uk, en]`, `default_locale: uk`, переклади в `translations/messages+intl-icu.uk.yaml` і `.en.yaml`. Ключі за секціями: `home.hero.title`, `footer.contacts` тощо.
5. Перемикач мов у хедері генерує той самий роут з іншим `_locale` (`app.request.attributes.get('_route')` + `_route_params`); у `<head>` — `hreflang` для кожної локалі і `x-default`.
6. Двомовний контент у БД — власні таблиці перекладів (див. 1.2), а не сторонній бандл: так ви зрозумієте Doctrine-зв'язки й індекси.

**Що вивчаєте:** Routing (атрибути, localized routes, requirements), Translation, ICU MessageFormat, конфігурація бандлів.

### 1.2 Сутності Content, міграції, фікстури (≈3 дні)

Патерн для перекладного контенту: основна сутність тримає мовно-незалежні поля, а `…Translation` — тексти для однієї локалі, з унікальним індексом `(parent_id, locale)`.

| Сутність | Поля | Переклад |
| --- | --- | --- |
| `Page` | id (UUID v7), key (`about`, `contacts`, `terms-of-use`…), isPublished, updatedAt | `PageTranslation`: locale, slug, title, body (HTML), metaTitle, metaDescription |
| `Faq` | id, category (`general`, `prices`, `teachers`), position, isPublished | `FaqTranslation`: locale, question, answer |
| `Review` | id, authorName, avatar, source (`enguide`, `instagram`), videoUrl (nullable), position, isPublished | `ReviewTranslation`: locale, text |
| `Stat` | id, value (`70k+`, `1100`), position | `StatTranslation`: locale, label |
| `MenuItem` | id, location (`header`, `footer-1`…), position, routeName або url | `MenuItemTranslation`: locale, label |

1. Генеруйте через `make:entity`, потім приберіть зайве й додайте типи: `Uuid` як id з `UuidV7`, `DateTimeImmutable`, конструктор замість сетерів там, де поле обов'язкове.
2. Репозиторії з методами під конкретні сторінки: `PageRepository::findPublishedBySlug(string $slug, string $locale)` з одним JOIN на переклад — перевірте в профайлері, що це один запит.
3. Міграції: `make:migration`, уважно читайте згенерований SQL перед `migrate`. Одна міграція на логічну зміну.
4. Foundry-фабрики для кожної сутності + story `ContentStory` з реалістичними українськими й англійськими текстами (ваші власні, не з оригіналу). `make db-reset` дає наповнений сайт.
5. Невеликий Twig-хелпер `trans_field(entity, 'title')` або метод `getTranslation(locale)` з fallback на `uk`.

**Що вивчаєте:** Doctrine mapping атрибутами, зв'язки OneToMany, індекси, Migrations, Foundry, профайлер запитів.

### 1.3 Layout і головна сторінка (≈4–5 днів вашого часу)

`templates/base.html.twig` з блоками `title`, `meta`, `body`; компоненти `Header` (перемикач «Для дорослих / Для компаній / Для дітей», мова, «Увійти»), `Footer` (меню з `MenuItem`, контакти), `PromoBar`, `CookieBanner`. Кожна секція головної — окремий Twig Component.

**Межа між бекендом і згенерованим UI**

| Шар | Де лежить | Хто пише |
| --- | --- | --- |
| Секції-компоненти (дані) | `src/Content/Twig/Components/*.php` — отримують дані з репозиторіїв/провайдерів, віддають типізовані публічні властивості | Ви |
| Шаблони секцій | `templates/components/Home/*.html.twig` — лише розмітка з UI-kit, без запитів і логіки | AI |
| UI-kit | `templates/components/Ui/*.html.twig` — анонімні компоненти з `{% props %}`: `Button`, `Card`, `Badge`, `Container`, `Section`, `SectionHeading`, `Accordion`, `Carousel` | AI |
| Тема | `assets/styles/app.css` — Tailwind + daisyUI, дизайн-токени | AI |

Спочатку ви пишете PHP-класи й навмисно «голі» шаблони (заголовок + `dump` даних), потім віддаєте AI бриф на верстку. Згенерований код комітьте окремо з префіксом `ui:`.

**Секції головної**

| Секція (зверху вниз) | Компонент | Дані | На етапі 1 |
| --- | --- | --- | --- |
| Hero + фото-картки | `HomeHero` | Переклади | Статична сітка |
| Стрічка бейджів | `BadgeMarquee` | Статичний масив | CSS-анімація |
| «Твій прогрес в одному місці» | `InOnePlace` | Переклади | Bento-сітка |
| Групові заняття | `GroupClassesPromo` | Переклади | — |
| «Не знаєш свій рівень?» | `LevelTestCta` | Переклади | Посилання-заглушка |
| Айсберг «більше ніж здається» | `MoreThanSeems` | Переклади | — |
| Якості викладачів | `TeacherTraits` | Переклади | — |
| Банер пробного уроку | `TrialBanner` | — | Статична форма без відправки (етап 3) |
| Курси під будь-яку мету | `CoursesCarousel` | `CourseTeaserProviderInterface` | CSS scroll-snap + плейсхолдер `data-island` |
| Мобільні застосунки | `MobileApps` | Переклади | — |
| Відгуки студентів | `Testimonials` | `Review` з БД | CSS scroll-snap + плейсхолдер `data-island` |
| Лічильники | `Stats` | `Stat` з БД | Статичні числа |
| FAQ | `FaqList` | `Faq` (`general`, 6 шт.) | `<details>` |
| SEO-лонгрід | `SeoArticle` | `Page` з key `home-seo` | — |

**Плейсхолдер під майбутній Vue:** контейнер отримує `data-island="CoursesCarousel"` і `data-props="{{ props|json_encode|e('html_attr') }}"`, а всередині — робоча SSR-розмітка. Поки немає JS, який монтує острівці, атрибути просто ігноруються.

**Бриф для AI (шаблон):** скріншот референсу; список UI-компонентів з їхніми props; для кожної секції — які змінні приходять у шаблон; обмеження: лише Tailwind + daisyUI, семантичний HTML, без JavaScript, mobile-first від 360 px, доступність (alt, aria-label, контраст).

Навчальний момент — `CourseTeaserProviderInterface`. На етапі 1 його реалізує `YamlCourseTeaserProvider` (читає `config/content/courses.yaml`), а на етапі 2 ви заміните її на Doctrine-реалізацію з модуля Catalog, змінивши один alias у `services.yaml`.

### 1.4 Статичні сторінки й адмінка (≈3–4 дні)

**Сторінки етапу 1:** контакти, «Наша команда», відгуки (повний список `Review` з пагінацією), FAQ (усі категорії), три юридичні сторінки, 404/500 у стилі сайту. Одна дія `PageController::show(string $slug)` для сторінок з `Page` і окремі контролери там, де є своя логіка (відгуки, FAQ).

1. Сторінки з `Page` рендеряться через `#[MapEntity]` або явний виклик репозиторію; неопублікована або відсутня сторінка → `NotFoundHttpException`.
2. SEO-мінімум уже тут: `<title>`, `meta description`, canonical, OpenGraph з полів перекладу; окремий Twig-компонент `SeoMeta`.
3. Кастомні сторінки помилок: `templates/bundles/TwigBundle/Exception/error404.html.twig` і `error.html.twig`; перевірка через `/_error/404` у dev.

**EasyAdmin:**

1. `DashboardController` на `/admin` + CRUD-контролери для `Page`, `Faq`, `Review`, `Stat`, `MenuItem`.
2. Переклади редагуються як `CollectionField` з вкладеною формою `…TranslationType` (поле locale + тексти) — хороша вправа на Symfony Forms.
3. Поле `body` — `TextEditorField`; сортування за `position`; фільтр `isPublished`.
4. Тимчасовий захист: у `security.yaml` in-memory користувач `admin` з хешованим паролем з `.env.local` і `form_login` для firewall `admin`; `access_control` на `^/admin` → `ROLE_ADMIN`. Повноцінна автентифікація з'явиться на етапі 4.
5. Після кожної зміни контенту — інвалідація кешу фрагментів (якщо вже додали кешування).

**Що вивчаєте:** контролери й argument resolvers, Twig-наслідування і компоненти, Forms (CollectionType), Security basics, EasyAdmin.

### 1.5 Тести й готовність етапу 1 (≈2 дні, паралельно з рештою)

1. **Functional:** data provider з усіма публічними роутами × обидві локалі → статус 200, є `<title>`, є `hreflang` для `uk` і `en`; `/` → 301 на `/ua/`; неіснуючий slug → 404; `/admin` без логіну → редирект на логін.
2. **Integration:** `PageRepository::findPublishedBySlug` повертає лише опубліковане і в правильній локалі; fallback перекладу на `uk`.
3. **Unit:** `YamlCourseTeaserProvider`, Twig-хелпер перекладів.
4. **Компоненти:** `InteractsWithTwigComponents` — рендер секцій-компонентів із фікстурними даними, перевірка ключових елементів через DomCrawler. Це захищає бекенд-контракт, коли AI переписує шаблони.
5. Lighthouse вручну на головній: ціль ≥ 90 для Performance і SEO на мобільному.

**Готовність етапу 1**

- [ ] Головна зі всіма 14 секціями в `uk` і `en`, адаптивна до 360 px
- [ ] Контакти, команда, відгуки, FAQ, юридичні сторінки, 404/500
- [ ] Перемикач мов зберігає поточну сторінку, `hreflang` і canonical коректні
- [ ] Увесь контент редагується в EasyAdmin, включно з перекладами
- [ ] `make db-reset` наповнює сайт фікстурами
- [ ] Сторінки працюють без JavaScript; плейсхолдери `data-island` на місці
- [ ] Профайлер: жодна сторінка не робить більше \~5 SQL-запитів
- [ ] `make qa` і `make test` зелені, Deptrac не має порушень

**Наступний крок:** етап 2 (каталоги курсів і викладачів, блог) — деталізуємо, коли дійдете.
