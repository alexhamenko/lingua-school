# Правила роботи з репозиторієм

## Повідомлення комітів

Формат - [Conventional Commits 1.0.0](https://www.conventionalcommits.org/uk/v1.0.0/).

```
<type>(<scope>)!: <description>

[body]

[footer(s)]
```

| Частина | Обов'язкова | Правило |
| --- | --- | --- |
| `type` | так | один із типів нижче |
| `(scope)` | ні | область зміни; пропускаємо, якщо зміна наскрізна |
| `!` | ні | breaking change (зміна контракту API, несумісна міграція) |
| `description` | так | англійською, імператив (`add`, не `added`/`adds`), з малої літери, без крапки, до ~72 символів |
| body | ні | **чому** і **що саме**, якщо не очевидно з заголовка; відділяється порожнім рядком |
| footer | ні | `BREAKING CHANGE: ...`, `Refs: #123` |

`Co-Authored-By` не додаємо.

### Типи

| Тип | Коли | Приклад |
| --- | --- | --- |
| `feat` | нова функціональність, помітна користувачу або клієнту API | `feat(content): add FAQ page` |
| `fix` | виправлення помилки або невірної конфігурації | `fix(routing): redirect / to /ua/ with 301` |
| `refactor` | зміна коду без зміни поведінки | `refactor(content): extract translation fallback to trait` |
| `perf` | оптимізація без зміни поведінки | `perf(content): fetch translations in one query` |
| `test` | лише тести | `test(content): cover PageRepository::findPublishedBySlug` |
| `docs` | лише документація (`*.md`, docblocks) | `docs: add commit conventions` |
| `style` | форматування без зміни логіки (результат `make fix`) | `style: apply php-cs-fixer @Symfony ruleset` |
| `build` | Dockerfile, compose, Makefile, збірка статики | `build(docker): pin PostgreSQL 16` |
| `ci` | GitHub Actions, Dependabot | `ci: run make qa on pull requests` |
| `chore` | рутина: залежності, конфіги інструментів, `.gitignore` | `chore(deps): install symfony/orm-pack` |
| `revert` | відкат коміту | `revert: feat(content): add FAQ page` |
| `ui` | **власний тип проєкту**: шаблони, UI-kit і стилі, згенеровані AI | `ui(home): add Testimonials section markup` |

### Scope

- **Модулі:** `shared`, `identity`, `content`, `catalog`, `teaching`, `scheduling`, `group-classes`,
  `billing`, `learning`, `vocabulary`, `assessment`, `leads`, `notification`
- **Інфраструктура:** `deps`, `deps-dev`, `docker`, `ci`, `qa`, `db`, `i18n`, `routing`, `admin`, `security`
- **UI:** `home`, `layout`, `ui-kit`, `theme`

Список не закритий: нова область додається сюди разом із першим комітом, що її використовує.

### Як обрати тип (швидкий алгоритм)

1. Змінилась поведінка для користувача? Нове - `feat`, виправлене - `fix`.
2. Змінився лише код, поведінка та сама? `refactor` (або `perf`, якщо мета - швидкість).
3. Змінились лише тести / документація / форматування? `test` / `docs` / `style`.
4. Шаблони й стилі від AI? `ui`.
5. Інфраструктура: збірка й контейнери - `build`, CI - `ci`, решта - `chore`.
6. Важко обрати один тип - коміт змішує кілька змін, його варто розбити.

### Типові сценарії

**Встановлення пакета через Flex.** Один пакет - один коміт; у тілі перелік того, що змінив рецепт
(`composer.json`, `composer.lock`, `symfony.lock`, `config/reference.php` змінюються щоразу, їх не перелічуємо):

```
chore(deps): install symfony/orm-pack

Flex recipe changes:
- config/bundles.php: register DoctrineBundle, DoctrineMigrationsBundle
- config/packages: add doctrine.yaml, doctrine_migrations.yaml
- .env: add DATABASE_URL
- compose.yaml, compose.override.yaml: add database service (postgres:16-alpine)
- Dockerfile: install pdo_pgsql extension
- add migrations/, src/Entity/, src/Repository/ placeholders
```

Dev-пакет - `chore(deps-dev): install symfony/maker-bundle`.

**Правки після рецепта** - окремим комітом, щоб в історії було видно, що зробив Flex, а що ми:

```
fix(docker): align PostgreSQL serverVersion with database image
```

**Нова сутність і міграція** - разом, бо міграція без сутності не має сенсу:

```
feat(content): add Page entity with translations

Page holds locale-independent fields, PageTranslation holds texts
per locale with a unique (page_id, locale) index.
```

**Налаштування інструменту якості:**

```
chore(qa): configure PHPStan at level max
```

**Згенерована верстка** - завжди окремо від PHP-коду компонента:

```
feat(content): add Testimonials component data
ui(home): add Testimonials section markup
```

**Breaking change** (актуально з API кабінету, етап 4):

```
feat(api)!: rename /lessons endpoint to /bookings

BREAKING CHANGE: clients must switch to /api/bookings.
```

### Перед комітом

- `make qa` і `make test` зелені (коли Makefile з'явиться)
- `git diff --staged` - у коміті лише те, що описано в заголовку
- жодних секретів: реальні значення - у `.env.local` або `secrets:set`
