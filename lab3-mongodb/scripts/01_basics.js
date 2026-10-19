// =============================================================================
// Лабораторная работа № 3. Основы работы с MongoDB
// Все команды из методических указаний в синтаксисе mongosh (MongoDB 7).
// Запуск: docker compose exec mongo mongosh --file /scripts/01_basics.js
// =============================================================================

// Заголовок блока вывода, чтобы результаты запросов было легко различить
function section(title) {
  print("\n" + "=".repeat(70));
  print("  " + title);
  print("=".repeat(70));
}

// --- 4.2 Клиент MongoDB ------------------------------------------------------
section("db — текущая база (по умолчанию test)");
print(db.getName());

section("show databases");
printjson(db.adminCommand({ listDatabases: 1 }).databases.map(d => d.name));

section("use sandbox");
db = db.getSiblingDB("sandbox");     // аналог `use sandbox` для скрипта
print(db.getName());

// --- 4.3.2 Запросы -----------------------------------------------------------
// В mongosh метод insert() устарел, вместо него используются insertOne/insertMany
section("insertOne: John, Mary");
printjson(db.humans.insertOne({ name: "John", age: 30 }));
printjson(db.humans.insertOne({ name: "Mary", age: 23 }));

section("find() — все документы коллекции humans");
printjson(db.humans.find().toArray());

section("show collections");
printjson(db.getCollectionNames());

// --- 4.3.2.1 Одноуровневый поиск ---------------------------------------------
section("insertMany: John 25, Анна 27");
printjson(db.humans.insertMany([
  { name: "John", age: 25 },
  { name: "Анна", age: 27 },
]));

section("name = John");
printjson(db.humans.find({ name: "John" }).toArray());

section("age < 26");
printjson(db.humans.find({ age: { $lt: 26 } }).toArray());

section("25 <= age < 28");
printjson(db.humans.find({ age: { $gte: 25, $lt: 28 } }).toArray());

section("name = John И age > 28");
printjson(db.humans.find({ name: "John", age: { $gt: 28 } }).toArray());

section("name = John ИЛИ name = Mary");
printjson(db.humans.find({ $or: [{ name: "John" }, { name: "Mary" }] }).toArray());

section("name IN (John, Mary)");
printjson(db.humans.find({ name: { $in: ["John", "Mary"] } }).toArray());

section("name NOT IN (John, Mary)");
printjson(db.humans.find({ name: { $nin: ["John", "Mary"] } }).toArray());

// --- 4.3.2.2 Многоуровневый поиск --------------------------------------------
section("insertMany: sportsmen");
printjson(db.sportsmen.insertMany([
  {
    name: "Dominik Hasek",
    clubs: [
      { clubName: "HC Pardubice",      firstYear: 1980, lastYear: 1989 },
      { clubName: "Chicago Blackhawks", firstYear: 1990, lastYear: 1992 },
      { clubName: "Buffalo Sabres",    firstYear: 1992, lastYear: 2001 },
      { clubName: "HC Spartak Moscow", firstYear: 2010, lastYear: 2011 },
    ],
  },
  {
    name: "Jaromir Jagr",
    clubs: [
      { clubName: "HC Kladno",           firstYear: 1988, lastYear: 1990 },
      { clubName: "Pittsburgh Penguins", firstYear: 1990, lastYear: 2001 },
      { clubName: "Avangard Omsk",       firstYear: 2008, lastYear: 2011 },
    ],
  },
  {
    name: "Petr Nedved",
    clubs: [
      { clubName: "HC Pardubice",      firstYear: 1985, lastYear: 1989 },
      { clubName: "Vancouver Canucks", firstYear: 1990, lastYear: 1993 },
    ],
  },
]));

section("Первый клуб — HC Pardubice");
printjson(db.sportsmen.find({ "clubs.0.clubName": "HC Pardubice" }, { name: 1, _id: 0 }).toArray());

section("Играл когда-либо в HC Pardubice");
printjson(db.sportsmen.find({ "clubs.clubName": "HC Pardubice" }, { name: 1, _id: 0 }).toArray());

section("Играл в клубе, начиная с 2008 года и позже");
printjson(db.sportsmen.find(
  { clubs: { $elemMatch: { firstYear: { $gte: 2008 } } } },
  { name: 1, _id: 0 },
).toArray());

// --- Удаление ----------------------------------------------------------------
section("deleteMany({ name: \"Анна\" })");
printjson(db.humans.deleteMany({ name: "Анна" }));

section("drop() — коллекции humans и sportsmen");
printjson(db.humans.drop());
printjson(db.sportsmen.drop());

section("dropDatabase()");
printjson(db.dropDatabase());
