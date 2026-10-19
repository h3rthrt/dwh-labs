# Хранилища данных — лабораторные работы

Московский Политех, 9 семестр.

| № | Тема | Каталог |
|---|------|---------|
| 1 | Реляционная БД в модели 3NF (PostgreSQL), вариант 8 «Обработка заказов в службе быта» | [`lab1-postgresql`](lab1-postgresql) |
| 2 | Размещение материалов в репозитории GitHub | этот репозиторий |
| 3 | Документная СУБД MongoDB | [`lab3-mongodb`](lab3-mongodb) |
| 4 | Графовая СУБД Neo4j, социальный граф | [`lab4-neo4j`](lab4-neo4j) |

## Требования

- Docker Desktop (Docker Engine 24+, Docker Compose 2.20+)

## Быстрый старт

```bash
cd lab1-postgresql && docker compose up -d
```

| Сервис | Адрес | Логин / пароль |
|--------|-------|----------------|
| PostgreSQL | `localhost:5432`, БД `service_bureau` | `student` / `student` |
| MongoDB | `localhost:27017` | без аутентификации |
| Neo4j Browser | http://localhost:7474 (Bolt: `localhost:7687`) | `neo4j` / `student123` |

Клиент для PostgreSQL и MongoDB — WebStorm (*View → Tool Windows → Database →
+ → Data Source*, плагин *Database Tools and SQL*). Граф Neo4j просматривается
в Neo4j Browser.

## Лабораторная работа № 1. PostgreSQL

Структура БД создаётся автоматически при первом запуске контейнера
(скрипты из `lab1-postgresql/sql` монтируются в `/docker-entrypoint-initdb.d`).

| Файл | Назначение |
|------|------------|
| `sql/01_schema.sql` | DDL: 13 таблиц в 3NF, ограничения, индексы, представления |
| `sql/02_data.sql` | тестовые данные |
| `sql/03_queries.sql` | проверочные запросы |

```bash
cd lab1-postgresql
docker compose up -d
```

Запросы из `sql/03_queries.sql` выполняются в WebStorm (открыть файл →
*Attach Data Source* → `service_bureau` → ⌘↵) или через psql:

```bash
docker compose exec postgres psql -U student -d service_bureau -f /sql/03_queries.sql
```

Пересоздать БД с нуля: `docker compose down -v && docker compose up -d`.

## Лабораторная работа № 3. MongoDB

```bash
cd lab3-mongodb
docker compose up -d
docker compose exec mongo mongosh                                   # интерактивный клиент
docker compose exec mongo mongosh --file /scripts/01_basics.js      # команды из методички
docker compose exec mongo mongosh --file /scripts/02_service_bureau.js  # индивидуальное задание
```

## Лабораторная работа № 4. Neo4j

```bash
cd lab4-neo4j
docker compose up -d
docker compose exec neo4j cypher-shell -u neo4j -p student123 -f /cypher/01_matrix.cypher
docker compose exec neo4j cypher-shell -u neo4j -p student123 -f /cypher/02_social_graph.cypher
docker compose exec neo4j cypher-shell -u neo4j -p student123 -f /cypher/03_queries.cypher
```
