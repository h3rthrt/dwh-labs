-- =============================================================================
-- Лабораторная работа № 1. Реализация структуры БД в модели 3NF
-- Вариант 8. Система обработки заказов в службе быта
-- СУБД: PostgreSQL 16
-- =============================================================================

BEGIN;

-- -----------------------------------------------------------------------------
-- Справочники
-- -----------------------------------------------------------------------------

-- Должности сотрудников
CREATE TABLE position (
    position_id  SERIAL         PRIMARY KEY,
    name         VARCHAR(100)   NOT NULL UNIQUE,
    base_salary  NUMERIC(10, 2) NOT NULL CHECK (base_salary >= 0)
);

COMMENT ON TABLE  position             IS 'Должности сотрудников службы быта';
COMMENT ON COLUMN position.name        IS 'Наименование должности';
COMMENT ON COLUMN position.base_salary IS 'Оклад, руб.';

-- Пункты приёма заказов
CREATE TABLE reception_point (
    point_id      SERIAL       PRIMARY KEY,
    address       VARCHAR(255) NOT NULL UNIQUE,
    phone         VARCHAR(20)  NOT NULL,
    opening_hours VARCHAR(100) NOT NULL
);

COMMENT ON TABLE  reception_point               IS 'Пункты приёма заказов';
COMMENT ON COLUMN reception_point.address       IS 'Адрес пункта';
COMMENT ON COLUMN reception_point.opening_hours IS 'Режим работы';

-- Категории услуг
CREATE TABLE service_category (
    category_id SERIAL       PRIMARY KEY,
    name        VARCHAR(100) NOT NULL UNIQUE
);

COMMENT ON TABLE service_category IS 'Категории услуг (ремонт обуви, химчистка и т. д.)';

-- Статусы заказа
CREATE TABLE order_status (
    status_id  SERIAL       PRIMARY KEY,
    code       VARCHAR(20)  NOT NULL UNIQUE,
    name       VARCHAR(100) NOT NULL,
    sort_order SMALLINT     NOT NULL UNIQUE
);

COMMENT ON TABLE  order_status            IS 'Этапы обработки заказа';
COMMENT ON COLUMN order_status.code       IS 'Код статуса для использования в приложении';
COMMENT ON COLUMN order_status.sort_order IS 'Порядковый номер этапа в процессе обработки';

-- Материалы и запчасти
CREATE TABLE material (
    material_id SERIAL         PRIMARY KEY,
    name        VARCHAR(150)   NOT NULL UNIQUE,
    unit        VARCHAR(20)    NOT NULL,
    unit_price  NUMERIC(10, 2) NOT NULL CHECK (unit_price >= 0)
);

COMMENT ON TABLE  material            IS 'Материалы и запчасти, расходуемые при выполнении работ';
COMMENT ON COLUMN material.unit       IS 'Единица измерения (шт., м, мл ...)';
COMMENT ON COLUMN material.unit_price IS 'Текущая цена за единицу, руб.';

-- -----------------------------------------------------------------------------
-- Основные сущности
-- -----------------------------------------------------------------------------

-- Сотрудники (приёмщики и мастера)
CREATE TABLE employee (
    employee_id SERIAL      PRIMARY KEY,
    position_id INTEGER     NOT NULL REFERENCES position (position_id),
    last_name   VARCHAR(50) NOT NULL,
    first_name  VARCHAR(50) NOT NULL,
    middle_name VARCHAR(50),
    phone       VARCHAR(20) NOT NULL UNIQUE,
    hire_date   DATE        NOT NULL DEFAULT CURRENT_DATE
);

COMMENT ON TABLE  employee           IS 'Сотрудники службы быта';
COMMENT ON COLUMN employee.hire_date IS 'Дата приёма на работу';

-- Клиенты
CREATE TABLE client (
    client_id     SERIAL       PRIMARY KEY,
    last_name     VARCHAR(50)  NOT NULL,
    first_name    VARCHAR(50)  NOT NULL,
    middle_name   VARCHAR(50),
    phone         VARCHAR(20)  NOT NULL UNIQUE,
    email         VARCHAR(100) UNIQUE,
    registered_at TIMESTAMP    NOT NULL DEFAULT now()
);

COMMENT ON TABLE  client               IS 'Клиенты службы быта';
COMMENT ON COLUMN client.registered_at IS 'Дата и время первого обращения';

-- Услуги (прайс-лист)
CREATE TABLE service (
    service_id    SERIAL         PRIMARY KEY,
    category_id   INTEGER        NOT NULL REFERENCES service_category (category_id),
    name          VARCHAR(150)   NOT NULL,
    base_price    NUMERIC(10, 2) NOT NULL CHECK (base_price >= 0),
    duration_days SMALLINT       NOT NULL CHECK (duration_days > 0),
    UNIQUE (category_id, name)
);

COMMENT ON TABLE  service               IS 'Прайс-лист услуг';
COMMENT ON COLUMN service.base_price    IS 'Текущая цена услуги, руб.';
COMMENT ON COLUMN service.duration_days IS 'Нормативный срок выполнения, дн.';

-- Заказы
CREATE TABLE orders (
    order_id    SERIAL    PRIMARY KEY,
    client_id   INTEGER   NOT NULL REFERENCES client (client_id),
    point_id    INTEGER   NOT NULL REFERENCES reception_point (point_id),
    receiver_id INTEGER   NOT NULL REFERENCES employee (employee_id),
    received_at TIMESTAMP NOT NULL DEFAULT now(),
    due_date    DATE      NOT NULL,
    issued_at   TIMESTAMP,
    comment     TEXT,
    CHECK (due_date >= received_at::date),
    CHECK (issued_at IS NULL OR issued_at >= received_at)
);

COMMENT ON TABLE  orders             IS 'Заказы клиентов (квитанции)';
COMMENT ON COLUMN orders.receiver_id IS 'Приёмщик, оформивший заказ';
COMMENT ON COLUMN orders.due_date    IS 'Плановая дата готовности';
COMMENT ON COLUMN orders.issued_at   IS 'Фактическая дата выдачи заказа клиенту';

-- Позиции заказа
CREATE TABLE order_item (
    item_id          SERIAL         PRIMARY KEY,
    order_id         INTEGER        NOT NULL REFERENCES orders (order_id) ON DELETE CASCADE,
    service_id       INTEGER        NOT NULL REFERENCES service (service_id),
    master_id        INTEGER        REFERENCES employee (employee_id),
    item_description VARCHAR(255)   NOT NULL,
    quantity         SMALLINT       NOT NULL DEFAULT 1 CHECK (quantity > 0),
    price            NUMERIC(10, 2) NOT NULL CHECK (price >= 0)
);

COMMENT ON TABLE  order_item                  IS 'Позиции заказа: какая услуга оказывается над каким изделием';
COMMENT ON COLUMN order_item.master_id        IS 'Мастер, выполняющий работу (назначается после приёма)';
COMMENT ON COLUMN order_item.item_description IS 'Описание изделия клиента (например, «Сапоги женские, чёрные»)';
COMMENT ON COLUMN order_item.price            IS 'Цена за единицу, зафиксированная на момент оформления заказа';

-- Расход материалов по позициям заказа (связь M:N)
CREATE TABLE item_material (
    item_id     INTEGER        NOT NULL REFERENCES order_item (item_id) ON DELETE CASCADE,
    material_id INTEGER        NOT NULL REFERENCES material (material_id),
    quantity    NUMERIC(10, 3) NOT NULL CHECK (quantity > 0),
    unit_price  NUMERIC(10, 2) NOT NULL CHECK (unit_price >= 0),
    PRIMARY KEY (item_id, material_id)
);

COMMENT ON TABLE  item_material            IS 'Материалы, израсходованные на позицию заказа';
COMMENT ON COLUMN item_material.unit_price IS 'Цена материала на момент списания, руб.';

-- История изменения статусов заказа
CREATE TABLE order_status_history (
    history_id  SERIAL    PRIMARY KEY,
    order_id    INTEGER   NOT NULL REFERENCES orders (order_id) ON DELETE CASCADE,
    status_id   INTEGER   NOT NULL REFERENCES order_status (status_id),
    employee_id INTEGER   NOT NULL REFERENCES employee (employee_id),
    changed_at  TIMESTAMP NOT NULL DEFAULT now(),
    note        TEXT,
    UNIQUE (order_id, status_id)
);

COMMENT ON TABLE  order_status_history             IS 'Журнал прохождения заказом этапов обработки';
COMMENT ON COLUMN order_status_history.employee_id IS 'Сотрудник, изменивший статус';

-- Оплаты
CREATE TABLE payment (
    payment_id SERIAL         PRIMARY KEY,
    order_id   INTEGER        NOT NULL REFERENCES orders (order_id) ON DELETE CASCADE,
    amount     NUMERIC(10, 2) NOT NULL CHECK (amount > 0),
    paid_at    TIMESTAMP      NOT NULL DEFAULT now(),
    method     VARCHAR(10)    NOT NULL CHECK (method IN ('cash', 'card', 'online'))
);

COMMENT ON TABLE  payment        IS 'Оплаты по заказу (предоплата, окончательный расчёт)';
COMMENT ON COLUMN payment.method IS 'Способ оплаты: cash — наличные, card — карта, online — онлайн';

-- -----------------------------------------------------------------------------
-- Индексы по внешним ключам
-- -----------------------------------------------------------------------------

CREATE INDEX idx_employee_position   ON employee (position_id);
CREATE INDEX idx_service_category    ON service (category_id);
CREATE INDEX idx_orders_client       ON orders (client_id);
CREATE INDEX idx_orders_point        ON orders (point_id);
CREATE INDEX idx_orders_receiver     ON orders (receiver_id);
CREATE INDEX idx_order_item_order    ON order_item (order_id);
CREATE INDEX idx_order_item_service  ON order_item (service_id);
CREATE INDEX idx_order_item_master   ON order_item (master_id);
CREATE INDEX idx_item_material_mat   ON item_material (material_id);
CREATE INDEX idx_status_history_ord  ON order_status_history (order_id);
CREATE INDEX idx_payment_order       ON payment (order_id);

-- -----------------------------------------------------------------------------
-- Представления (вычисляемые данные не хранятся в таблицах — требование 3NF)
-- -----------------------------------------------------------------------------

-- Текущий статус заказа — последняя запись в журнале статусов
CREATE VIEW v_order_current_status AS
SELECT DISTINCT ON (h.order_id)
       h.order_id,
       s.code       AS status_code,
       s.name       AS status_name,
       h.changed_at
  FROM order_status_history h
  JOIN order_status s USING (status_id)
 ORDER BY h.order_id, s.sort_order DESC;

-- Сводка по заказу: стоимость работ, материалов, оплачено, остаток
CREATE VIEW v_order_summary AS
SELECT o.order_id,
       c.last_name || ' ' || c.first_name                        AS client,
       o.received_at::date                                       AS received,
       o.due_date,
       cs.status_name,
       COALESCE(w.works, 0)                                      AS works_cost,
       COALESCE(m.materials, 0)                                  AS materials_cost,
       COALESCE(w.works, 0) + COALESCE(m.materials, 0)           AS total_cost,
       COALESCE(p.paid, 0)                                       AS paid,
       COALESCE(w.works, 0) + COALESCE(m.materials, 0)
           - COALESCE(p.paid, 0)                                 AS debt
  FROM orders o
  JOIN client c USING (client_id)
  LEFT JOIN v_order_current_status cs USING (order_id)
  LEFT JOIN (SELECT order_id, SUM(quantity * price) AS works
               FROM order_item GROUP BY order_id) w USING (order_id)
  LEFT JOIN (SELECT oi.order_id, ROUND(SUM(im.quantity * im.unit_price), 2) AS materials
               FROM item_material im
               JOIN order_item oi USING (item_id)
              GROUP BY oi.order_id) m USING (order_id)
  LEFT JOIN (SELECT order_id, SUM(amount) AS paid
               FROM payment GROUP BY order_id) p USING (order_id);

COMMIT;
