// =============================================================================
// Лабораторная работа № 3. Индивидуальное задание
// Документная модель системы обработки заказов в службе быта (вариант 8).
// Запуск: docker compose exec mongo mongosh --file /scripts/02_service_bureau.js
// =============================================================================

// Заголовок блока вывода, чтобы результаты запросов было легко различить
function section(title) {
  print("\n" + "=".repeat(70));
  print("  " + title);
  print("=".repeat(70));
}

db = db.getSiblingDB("service_bureau");
db.dropDatabase();

section("Создание коллекции orders с валидатором $jsonSchema");

// Валидация структуры документа заказа ($jsonSchema)
printjson(db.createCollection("orders", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["number", "client", "point", "receivedAt", "dueDate", "items", "statuses"],
      properties: {
        number:     { bsonType: "int" },
        client:     { bsonType: "object", required: ["name", "phone"] },
        point:      { bsonType: "string" },
        receivedAt: { bsonType: "date" },
        dueDate:    { bsonType: "date" },
        items: {
          bsonType: "array",
          minItems: 1,
          items: {
            bsonType: "object",
            required: ["service", "category", "item", "qty", "price"],
            properties: {
              qty:   { bsonType: "int", minimum: 1 },
              price: { bsonType: ["int", "double", "decimal"], minimum: 0 },
            },
          },
        },
        statuses: { bsonType: "array" },
        payments: { bsonType: "array" },
      },
    },
  },
}));

// В документной модели данные, которые читаются вместе, хранятся вместе:
// позиции, история статусов и оплаты вложены в документ заказа.
section("insertMany: 4 заказа");
printjson(db.orders.insertMany([
  {
    number: 1,
    client: { name: "Иванов Сергей", phone: "+7 916 200-00-01" },
    point: "ул. Большая Семёновская, 38",
    receivedAt: ISODate("2026-10-01T10:20:00Z"),
    dueDate: ISODate("2026-10-04"),
    items: [
      { service: "Замена набоек", category: "Ремонт обуви", item: "Туфли женские", qty: 1, price: 600,
        master: "Попов Н.С.", materials: [{ name: "Набойка полиуретановая", qty: 1, price: 150 }] },
      { service: "Профилактика подошвы", category: "Ремонт обуви", item: "Туфли женские", qty: 1, price: 1200,
        master: "Попов Н.С.", materials: [{ name: "Профилактика резиновая", qty: 1, price: 400 }] },
    ],
    statuses: [
      { status: "accepted",    at: ISODate("2026-10-01T10:20:00Z") },
      { status: "in_progress", at: ISODate("2026-10-02T09:00:00Z") },
      { status: "ready",       at: ISODate("2026-10-03T16:00:00Z") },
      { status: "issued",      at: ISODate("2026-10-04T18:10:00Z") },
    ],
    payments: [{ amount: 2350, method: "card", at: ISODate("2026-10-04T18:10:00Z") }],
  },
  {
    number: 2,
    client: { name: "Петрова Мария", phone: "+7 916 200-00-02", email: "petrova@yandex.ru" },
    point: "ул. Большая Семёновская, 38",
    receivedAt: ISODate("2026-10-02T12:00:00Z"),
    dueDate: ISODate("2026-10-07"),
    comment: "Позвонить по готовности",
    items: [
      { service: "Ушивание платья", category: "Ремонт и пошив одежды", item: "Платье вечернее", qty: 1, price: 2500,
        master: "Васильева Е.А." },
      { service: "Укорачивание брюк", category: "Ремонт и пошив одежды", item: "Брюки мужские", qty: 2, price: 700,
        master: "Васильева Е.А." },
    ],
    statuses: [
      { status: "accepted",    at: ISODate("2026-10-02T12:00:00Z") },
      { status: "in_progress", at: ISODate("2026-10-03T10:00:00Z") },
      { status: "ready",       at: ISODate("2026-10-07T17:45:00Z") },
      { status: "issued",      at: ISODate("2026-10-08T11:30:00Z") },
    ],
    payments: [
      { amount: 1000, method: "cash", at: ISODate("2026-10-02T12:05:00Z") },
      { amount: 2900, method: "card", at: ISODate("2026-10-08T11:30:00Z") },
    ],
  },
  {
    number: 3,
    client: { name: "Козлова Ольга", phone: "+7 916 200-00-04" },
    point: "Щёлковское ш., 2",
    receivedAt: ISODate("2026-10-10T11:30:00Z"),
    dueDate: ISODate("2026-10-17"),
    items: [
      { service: "Чистка механизма", category: "Ремонт часов", item: "Часы механические", qty: 1, price: 3500,
        master: "Морозов Г.П." },
    ],
    statuses: [
      { status: "accepted",    at: ISODate("2026-10-10T11:30:00Z") },
      { status: "in_progress", at: ISODate("2026-10-11T10:00:00Z") },
    ],
    payments: [{ amount: 2000, method: "online", at: ISODate("2026-10-10T11:35:00Z") }],
  },
  {
    number: 4,
    client: { name: "Соколова Екатерина", phone: "+7 916 200-00-06" },
    point: "ул. Большая Семёновская, 38",
    receivedAt: ISODate("2026-10-15T09:55:00Z"),
    dueDate: ISODate("2026-10-22"),
    items: [
      { service: "Замена молнии на куртке", category: "Ремонт и пошив одежды", item: "Куртка зимняя", qty: 1, price: 1800 },
    ],
    statuses: [{ status: "accepted", at: ISODate("2026-10-15T09:55:00Z") }],
    payments: [],
  },
]));

section("Индексы");
db.orders.createIndex({ number: 1 }, { unique: true });
db.orders.createIndex({ "client.phone": 1 });
db.orders.createIndex({ "items.category": 1 });
printjson(db.orders.getIndexes().map(i => i.name));

// 1. Заказы клиента по номеру телефона (поиск по полю вложенного документа)
section("1. Заказы клиента +7 916 200-00-02");
printjson(db.orders.find({ "client.phone": "+7 916 200-00-02" }, { number: 1, items: 1, _id: 0 }).toArray());

// 2. Заказы, содержащие ремонт обуви (поиск по элементам массива)
section("2. Заказы с ремонтом обуви");
printjson(db.orders.find({ "items.category": "Ремонт обуви" }, { number: 1, "client.name": 1, _id: 0 }).toArray());

// 3. Заказы, последний статус которых не «выдан» (выражение $expr + $last)
section("3. Невыданные заказы");
printjson(db.orders.find(
  { $expr: { $ne: [{ $last: "$statuses.status" }, "issued"] } },
  { number: 1, dueDate: 1, _id: 0 },
).toArray());

// 4. Стоимость, оплата и задолженность по каждому заказу (агрегация)
section("4. Сводка по заказам");
printjson(db.orders.aggregate([
  { $project: {
      _id: 0,
      number: 1,
      client: "$client.name",
      works: { $sum: { $map: { input: "$items", as: "i", in: { $multiply: ["$$i.qty", "$$i.price"] } } } },
      materials: { $sum: { $map: {
        input: "$items", as: "i",
        in: { $sum: { $map: { input: { $ifNull: ["$$i.materials", []] }, as: "m",
                              in: { $multiply: ["$$m.qty", "$$m.price"] } } } },
      } } },
      paid: { $sum: "$payments.amount" },
      status: { $last: "$statuses.status" },
  } },
  { $addFields: { debt: { $subtract: [{ $add: ["$works", "$materials"] }, "$paid"] } } },
  { $sort: { number: 1 } },
]).toArray());

// 5. Выручка по категориям услуг ($unwind + $group)
section("5. Выручка по категориям");
printjson(db.orders.aggregate([
  { $unwind: "$items" },
  { $group: { _id: "$items.category",
              items: { $sum: 1 },
              revenue: { $sum: { $multiply: ["$items.qty", "$items.price"] } } } },
  { $sort: { revenue: -1 } },
]).toArray());

// 6. Перевод заказа в следующий статус (обновление с $push)
section("6. Заказ 3 готов к выдаче");
printjson(db.orders.updateOne(
  { number: 3 },
  { $push: { statuses: { status: "ready", at: new Date() } } },
));
printjson(db.orders.findOne({ number: 3 }, { statuses: 1, _id: 0 }));

// 7. Назначение мастера на позицию заказа (позиционный оператор $)
section("7. Назначение мастера");
printjson(db.orders.updateOne(
  { number: 4, "items.service": "Замена молнии на куртке" },
  { $set: { "items.$.master": "Васильева Е.А." } },
));
