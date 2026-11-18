-- Запрос для подсчета общего количества покупателей из таблицы customers
SELECT COUNT(customer_id) AS customers_count
FROM customers;

-- Топ-10 продавцов с наибольшей выручкой
-- Выводит имя и фамилию продавца (seller), количество проведенных сделок (operations)
-- и суммарную выручку (income), округленную вниз до целого. Отсортировано по убыванию выручки.
SELECT
    CONCAT(e.first_name, ' ', e.last_name) AS seller,
    COUNT(s.sales_id) AS operations,
    FLOOR(SUM(p.price * s.quantity)) AS income
FROM sales AS s
INNER JOIN employees AS e ON s.sales_person_id = e.employee_id
INNER JOIN products AS p ON s.product_id = p.product_id
GROUP BY seller
ORDER BY income DESC
LIMIT 10;

-- Продавцы, чья средняя выручка за сделку ниже средней выручки по всем продавцам
-- Выводит имя и фамилию продавца (seller) и среднюю выручку за сделку (average_income),
-- округленную вниз до целого. Отсортировано по возрастанию средней выручки.
WITH seller_stats AS (
    SELECT
        CONCAT(e.first_name, ' ', e.last_name) AS seller,
        FLOOR(AVG(p.price * s.quantity)) AS average_income,
        FLOOR(AVG(AVG(p.price * s.quantity)) OVER ()) AS overall_avg_income
    FROM sales AS s
    INNER JOIN employees AS e ON s.sales_person_id = e.employee_id
    INNER JOIN products AS p ON s.product_id = p.product_id
    GROUP BY seller
)
SELECT
    seller,
    average_income
FROM seller_stats
WHERE average_income < overall_avg_income
ORDER BY average_income ASC;

-- Выручка продавцов по дням недели
-- Выводит имя и фамилию продавца (seller), день недели на английском (day_of_week)
-- и суммарную выручку за этот день (income), округленную вниз до целого.
-- Отсортировано по порядковому номеру дня недели (ISODOW) и имени продавца (seller).
SELECT
    CONCAT(e.first_name, ' ', e.last_name) AS seller,
    LOWER(TRIM(TO_CHAR(s.sale_date, 'day'))) AS day_of_week,
    FLOOR(SUM(p.price * s.quantity)) AS income
FROM sales AS s
INNER JOIN employees AS e ON s.sales_person_id = e.employee_id
INNER JOIN products AS p ON s.product_id = p.product_id
GROUP BY
    seller,
    TRIM(TO_CHAR(s.sale_date, 'day')),
    EXTRACT(ISODOW FROM s.sale_date)
ORDER BY
    EXTRACT(ISODOW FROM s.sale_date),
    seller;
