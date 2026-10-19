// =============================================================================
// Лабораторная работа № 4. Практическое задание из лекции: граф «Матрица»
// Запуск: docker compose exec neo4j cypher-shell -u neo4j -p student123 -f /cypher/01_matrix.cypher
// =============================================================================

MATCH (n) DETACH DELETE n;

CREATE (neo:Person:Human {name: 'Thomas Andersson', age: 29})
CREATE (trinity:Person:Human {name: 'Trinity'})
CREATE (morpheus:Person:Human {name: 'Morpheus', occupation: 'Total badass', rank: 'Captain'})
CREATE (cypher:Person:Human {name: 'Cypher', last_name: 'Reagan'})
CREATE (smith:Person:Program {name: 'Agent Smith', language: 'C++', version: '1.0b'})
CREATE (architect:Person:Program {name: 'The Architect'})

CREATE (neo)-[:KNOWS {age: '3 days'}]->(trinity)
CREATE (neo)-[:KNOWS]->(morpheus)
CREATE (morpheus)-[:KNOWS {age: '12 years'}]->(trinity)
CREATE (morpheus)-[:KNOWS {disclosure: 'public'}]->(cypher)
CREATE (cypher)-[:KNOWS {age: '6 months', disclosure: 'secret'}]->(smith)
CREATE (smith)-[:CODED_BY]->(architect);

// Примеры из лекции: создание узла и связей через MERGE
CREATE (n:Person {name: 'Mike'}) RETURN n;
CREATE (:Person {name: 'Anna'});
CREATE (:Person {name: 'Alex'});
CREATE (:Movie {title: 'The Terminator', released: 1984});

MATCH (a:Person {name: 'Mike'}), (b:Person {name: 'Anna'})
MERGE (a)-[r:MARRIED]->(b);

MATCH (a:Person {name: 'Alex'}), (b:Movie {title: 'The Terminator'})
MERGE (a)-[r:FAVORITE]->(b);

// Кого знают друзья Нео (друзья друзей)
MATCH (:Person {name: 'Thomas Andersson'})-[:KNOWS*2..3]->(fof)
RETURN DISTINCT fof.name AS friend_of_friend;

// Кто создал программу, которую знает Сайфер
MATCH (:Person {name: 'Cypher'})-[:KNOWS]->(p:Program)-[:CODED_BY]->(creator)
RETURN p.name AS program, creator.name AS creator;
