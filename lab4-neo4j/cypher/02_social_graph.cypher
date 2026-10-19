// =============================================================================
// Лабораторная работа № 4. Социальный граф
// 15 узлов (8 Person, 2 City, 2 Organization, 3 Interest), 40 рёбер
// Запуск: docker compose exec neo4j cypher-shell -u neo4j -p student123 -f /cypher/02_social_graph.cypher
// =============================================================================

MATCH (n) DETACH DELETE n;

CREATE CONSTRAINT person_name IF NOT EXISTS FOR (p:Person) REQUIRE p.name IS UNIQUE;
CREATE CONSTRAINT city_name IF NOT EXISTS FOR (c:City) REQUIRE c.name IS UNIQUE;
CREATE CONSTRAINT org_name IF NOT EXISTS FOR (o:Organization) REQUIRE o.name IS UNIQUE;
CREATE CONSTRAINT interest_name IF NOT EXISTS FOR (i:Interest) REQUIRE i.name IS UNIQUE;

// --- Узлы --------------------------------------------------------------------
CREATE
  // Люди
  (alexey:Person   {name: 'Алексей',   last_name: 'Орлов',     age: 21, gender: 'м'}),
  (maria:Person    {name: 'Мария',     last_name: 'Белова',    age: 20, gender: 'ж'}),
  (ivan:Person     {name: 'Иван',      last_name: 'Громов',    age: 22, gender: 'м'}),
  (olga:Person     {name: 'Ольга',     last_name: 'Ершова',    age: 27, gender: 'ж'}),
  (dmitry:Person   {name: 'Дмитрий',   last_name: 'Ершов',     age: 29, gender: 'м'}),
  (ekaterina:Person{name: 'Екатерина', last_name: 'Зимина',    age: 35, gender: 'ж'}),
  (sergey:Person   {name: 'Сергей',    last_name: 'Котов',     age: 31, gender: 'м'}),
  (anna:Person     {name: 'Анна',      last_name: 'Миронова',  age: 19, gender: 'ж'}),

  // Города
  (moscow:City {name: 'Москва',          country: 'Россия', population: 13100000}),
  (spb:City    {name: 'Санкт-Петербург', country: 'Россия', population: 5600000}),

  // Организации
  (polytech:Organization:University {name: 'Московский Политех', type: 'университет', founded: 1865}),
  (yandex:Organization:Company      {name: 'Яндекс',             type: 'компания',    founded: 1997}),

  // Интересы
  (coding:Interest   {name: 'Программирование', category: 'IT'}),
  (photo:Interest    {name: 'Фотография',       category: 'искусство'}),
  (football:Interest {name: 'Футбол',           category: 'спорт'}),

// --- Рёбра -------------------------------------------------------------------
  // FRIEND_OF — дружба (1–10)
  (alexey)-[:FRIEND_OF {since: 2023, closeness: 'близкий'}]->(maria),
  (alexey)-[:FRIEND_OF {since: 2023, closeness: 'близкий'}]->(ivan),
  (maria)-[:FRIEND_OF {since: 2021, closeness: 'обычный'}]->(olga),
  (ivan)-[:FRIEND_OF {since: 2020, closeness: 'обычный'}]->(dmitry),
  (olga)-[:FRIEND_OF {since: 2019, closeness: 'близкий'}]->(ekaterina),
  (dmitry)-[:FRIEND_OF {since: 2018, closeness: 'близкий'}]->(sergey),
  (ekaterina)-[:FRIEND_OF {since: 2024, closeness: 'обычный'}]->(anna),
  (sergey)-[:FRIEND_OF {since: 2022, closeness: 'обычный'}]->(anna),
  (maria)-[:FRIEND_OF {since: 2024, closeness: 'обычный'}]->(ekaterina),
  (ivan)-[:FRIEND_OF {since: 2025, closeness: 'обычный'}]->(sergey),

  // MARRIED — брак (11)
  (dmitry)-[:MARRIED {since: 2022}]->(olga),

  // FOLLOWS — односторонняя подписка (12–13)
  (anna)-[:FOLLOWS {since: 2025, notifications: true}]->(alexey),
  (sergey)-[:FOLLOWS {since: 2024, notifications: false}]->(maria),

  // LIVES_IN — место жительства (14–21)
  (alexey)-[:LIVES_IN {since: 2005}]->(moscow),
  (maria)-[:LIVES_IN {since: 2006}]->(moscow),
  (ivan)-[:LIVES_IN {since: 2022}]->(moscow),
  (olga)-[:LIVES_IN {since: 2017}]->(moscow),
  (dmitry)-[:LIVES_IN {since: 2015}]->(moscow),
  (ekaterina)-[:LIVES_IN {since: 1990}]->(moscow),
  (sergey)-[:LIVES_IN {since: 2020}]->(spb),
  (anna)-[:LIVES_IN {since: 2007}]->(spb),

  // STUDIES_AT / WORKS_AT — учёба и работа (22–29)
  (alexey)-[:STUDIES_AT {faculty: 'ИТ', course: 4}]->(polytech),
  (maria)-[:STUDIES_AT {faculty: 'ИТ', course: 3}]->(polytech),
  (ivan)-[:STUDIES_AT {faculty: 'ИТ', course: 4}]->(polytech),
  (anna)-[:STUDIES_AT {faculty: 'Издательское дело', course: 1, form: 'дистанционная'}]->(polytech),
  (olga)-[:WORKS_AT {position: 'аналитик', since: 2021}]->(yandex),
  (dmitry)-[:WORKS_AT {position: 'backend-разработчик', since: 2019}]->(yandex),
  (sergey)-[:WORKS_AT {position: 'тимлид', since: 2018, remote: true}]->(yandex),
  (ekaterina)-[:WORKS_AT {position: 'доцент', since: 2015}]->(polytech),

  // LIKES — интересы (30–38)
  (alexey)-[:LIKES {level: 'профи'}]->(coding),
  (ivan)-[:LIKES {level: 'любитель'}]->(coding),
  (dmitry)-[:LIKES {level: 'профи'}]->(coding),
  (maria)-[:LIKES {level: 'любитель'}]->(photo),
  (ekaterina)-[:LIKES {level: 'профи'}]->(photo),
  (anna)-[:LIKES {level: 'новичок'}]->(photo),
  (sergey)-[:LIKES {level: 'любитель'}]->(football),
  (ivan)-[:LIKES {level: 'любитель'}]->(football),
  (olga)-[:LIKES {level: 'новичок'}]->(football),

  // LOCATED_IN — расположение организаций (39–40)
  (polytech)-[:LOCATED_IN {address: 'ул. Большая Семёновская, 38'}]->(moscow),
  (yandex)-[:LOCATED_IN {address: 'ул. Льва Толстого, 16'}]->(moscow);

// Проверка: количество узлов и рёбер
MATCH (n) RETURN count(n) AS nodes;
MATCH ()-[r]->() RETURN count(r) AS relationships;
