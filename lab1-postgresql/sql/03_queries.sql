-- =============================================================================
-- Проверочные запросы к БД службы быта
-- Запуск: docker compose exec postgres psql -U student -d service_bureau -f /sql/03_queries.sql
-- =============================================================================

-- 1. Список таблиц и количество строк в каждой
SELECT relname AS table_name, n_live_tup AS rows
  FROM pg_stat_user_tables
 ORDER BY relname;

-- 2. Сводка по всем заказам: стоимость, оплата, задолженность, текущий статус
SELECT * FROM v_order_summary ORDER BY order_id;

-- 3. Порядок обработки конкретного заказа (журнал статусов)
SELECT h.changed_at,
       s.name                               AS status,
       e.last_name || ' ' || e.first_name   AS employee,
       p.name                               AS position,
       h.note
  FROM order_status_history h
  JOIN order_status s USING (status_id)
  JOIN employee e     USING (employee_id)
  JOIN position p     USING (position_id)
 WHERE h.order_id = 2
 ORDER BY s.sort_order;

-- 4. Заказы, просроченные относительно плановой даты готовности
SELECT o.order_id, o.due_date, cs.status_name,
       CURRENT_DATE - o.due_date AS days_overdue
  FROM orders o
  JOIN v_order_current_status cs USING (order_id)
 WHERE cs.status_code IN ('accepted', 'in_progress')
   AND o.due_date < CURRENT_DATE
 ORDER BY days_overdue DESC;

-- 5. Загрузка мастеров: число позиций и выручка по работам
SELECT e.last_name || ' ' || e.first_name AS master,
       p.name                             AS position,
       COUNT(oi.item_id)                  AS items,
       COALESCE(SUM(oi.quantity * oi.price), 0) AS revenue
  FROM employee e
  JOIN position p USING (position_id)
  LEFT JOIN order_item oi ON oi.master_id = e.employee_id
 WHERE p.name LIKE 'Мастер%'
 GROUP BY e.employee_id, p.name
 ORDER BY revenue DESC;

-- 6. Выручка по категориям услуг
SELECT sc.name AS category,
       COUNT(*) AS items,
       SUM(oi.quantity * oi.price) AS revenue
  FROM order_item oi
  JOIN service s           USING (service_id)
  JOIN service_category sc USING (category_id)
 GROUP BY sc.name
 ORDER BY revenue DESC;

-- 7. Позиции, для которых ещё не назначен мастер
SELECT oi.order_id, oi.item_description, s.name AS service
  FROM order_item oi
  JOIN service s USING (service_id)
 WHERE oi.master_id IS NULL;

-- 8. Расход материалов
SELECT m.name, m.unit, SUM(im.quantity) AS used, ROUND(SUM(im.quantity * im.unit_price), 2) AS cost
  FROM item_material im
  JOIN material m USING (material_id)
 GROUP BY m.material_id
 ORDER BY cost DESC;
