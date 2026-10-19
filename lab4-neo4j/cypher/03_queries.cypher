// =============================================================================
// Лабораторная работа № 4. Выборки из социального графа
// Запросы из методических указаний переписаны под синтаксис Neo4j 5:
// START, node(*), HAS() и запросы без скобок вокруг узла больше не поддерживаются.
// Запуск: docker compose exec neo4j cypher-shell -u neo4j -p student123 -f /cypher/03_queries.cypher
// =============================================================================

// 1. Все вершины (с ограничением)
//    было: MATCH n RETURN n LIMIT 25
MATCH (n) RETURN n LIMIT 25;

// 2. Вершина по ID
//    было: START n = node(ID[, ID2]) RETURN n
//    ID назначаются СУБД, поэтому сначала узнаём их:
MATCH (n) RETURN id(n) AS id, labels(n) AS labels, n.name AS name ORDER BY id;
//    затем подставляем нужные значения (в чистой БД первые узлы получают ID 0, 1, ...)
MATCH (n) WHERE id(n) IN [0, 1] RETURN n;

// 3. Вершина по свойству
MATCH (n) WHERE n.name = 'Москва' RETURN n;

// 4. Пара вершин с определёнными ID
//    было: START a = node(9), b = node(18) RETURN a, b
MATCH (a), (b) WHERE id(a) = 0 AND id(b) = 8 RETURN a, b;

// 5. Вершины, у которых есть определённый атрибут / исходящее ребро
//    было: MATCH (n) WHERE HAS (n.name) RETURN n
MATCH (n) WHERE n.age IS NOT NULL RETURN n.name AS name, n.age AS age;
MATCH (n) WHERE (n)-[:WORKS_AT]->() RETURN n.name AS employee;

// 7. Количество вершин и связей
//    было: START n = node(*) RETURN count(n)
//          START r = relationship(*) RETURN count(r)
MATCH (n) RETURN count(n) AS nodes;
MATCH ()-[r]->() RETURN count(r) AS relationships;

// 8. Вершины, связанные с заданной (с указанием «любой» связи)
MATCH (n)-[]-(a) WHERE n.name = 'Иван' RETURN n, a;

// 9. То же, скобки типа связи опущены
MATCH (n)--(a) WHERE n.name = 'Иван' RETURN n, a;

// 10. Изолированные вершины (для проверки сначала создаём такую вершину)
//     было: MATCH n WHERE not (n--()) RETURN n LIMIT 25
CREATE (:Person {name: 'Новый пользователь', age: 18});
MATCH (n) WHERE NOT (n)--() RETURN n LIMIT 25;

// 11. Удаление изолированных вершин
MATCH (n) WHERE NOT (n)--() DELETE n;

// 12. Кратчайший путь между двумя вершинами
MATCH (a {name: 'Ольга'}), (b {name: 'Анна'}),
      p = shortestPath((a)-[*..5]-(b))
RETURN [x IN nodes(p) | x.name] AS path, length(p) AS hops;

//     Все кратчайшие пути с ограничением на тип связи (или-или) и длину цепочки
MATCH (a {name: 'Алексей'}), (b {name: 'Сергей'}),
      p = allShortestPaths((a)-[:FRIEND_OF|MARRIED*..5]-(b))
RETURN [x IN nodes(p) | x.name] AS path, length(p) AS hops;

// 13. Вершина с максимальным ID
MATCH (n) RETURN n ORDER BY id(n) DESC LIMIT 1;

// -----------------------------------------------------------------------------
// Дополнительные аналитические запросы
// -----------------------------------------------------------------------------

// 14. Рекомендация друзей: друзья друзей, с которыми нет прямой дружбы,
//     ранжированные по числу общих друзей и общих интересов
MATCH (me:Person {name: 'Алексей'})-[:FRIEND_OF]-(f)-[:FRIEND_OF]-(rec:Person)
WHERE rec <> me AND NOT (me)-[:FRIEND_OF]-(rec)
WITH me, rec, count(DISTINCT f) AS mutual
OPTIONAL MATCH (me)-[:LIKES]->(i)<-[:LIKES]-(rec)
RETURN rec.name AS recommended, mutual, collect(i.name) AS common_interests
ORDER BY mutual DESC, size(common_interests) DESC;

// 15. Количество жителей по городам и средний возраст
MATCH (p:Person)-[:LIVES_IN]->(c:City)
RETURN c.name AS city, count(p) AS people, round(avg(p.age), 1) AS avg_age
ORDER BY people DESC;

// 16. Коллеги: люди, работающие в одной компании
MATCH (a:Person)-[:WORKS_AT]->(o:Organization)<-[:WORKS_AT]-(b:Person)
WHERE a.name < b.name
RETURN o.name AS organization, a.name AS person1, b.name AS person2;

// 17. Самые «связанные» люди (степень вершины по социальным связям)
MATCH (p:Person)
RETURN p.name AS person,
       COUNT { (p)-[:FRIEND_OF|MARRIED|FOLLOWS]-() } AS social_degree
ORDER BY social_degree DESC
LIMIT 5;

// 18. Количество рёбер каждого типа
MATCH ()-[r]->() RETURN type(r) AS type, count(*) AS count ORDER BY count DESC;

// 6. Удаление всех вершин и связей (выполняется последним!)
//    было: MATCH (a) OPTIONAL MATCH (a)-[r1]-() DELETE a, r1
// MATCH (a) OPTIONAL MATCH (a)-[r1]-() DELETE a, r1;
// или короче:
// MATCH (n) DETACH DELETE n;
