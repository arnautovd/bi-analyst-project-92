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

-- Количество покупателей в возрастных группах (16-25, 26-40, 40+)
-- Разделяет покупателей на категории по возрасту и считает количество покупателей в каждой категории.
-- Отсортировано по возрастной группе.
SELECT
    CASE
        WHEN age BETWEEN 16 AND 25 THEN '16-25'
        WHEN age BETWEEN 26 AND 40 THEN '26-40'
        ELSE '40+'
    END AS age_category,
    COUNT(*) AS age_count
FROM customers
GROUP BY age_category
ORDER BY age_category;

-- Количество уникальных покупателей и выручка по месяцам
-- Группирует данные по дате продажи в формате ГОД-МЕСЯЦ (YYYY-MM),
-- подсчитывает количество уникальных покупателей и общую выручку (округление вниз до целого).
-- Отсортировано по дате по возрастанию.
SELECT
    TO_CHAR(s.sale_date, 'YYYY-MM') AS selling_month,
    COUNT(DISTINCT s.customer_id) AS total_customers,
    FLOOR(SUM(p.price * s.quantity)) AS income
FROM sales AS s
INNER JOIN products AS p ON s.product_id = p.product_id
GROUP BY selling_month
ORDER BY selling_month ASC;

-- Покупатели, первая покупка которых была акционной (цена товара равна 0)
-- Находит первую по дате сделку каждого покупателя с помощью оконной функции ROW_NUMBER()
-- и отбирает тех, у кого цена в первой сделке была 0.
-- Отсортировано по id покупателя.
WITH customer_first_sales AS (
    SELECT
        s.customer_id,
        s.sale_date,
        s.sales_person_id,
        p.price,
        ROW_NUMBER() OVER (
            PARTITION BY s.customer_id
            ORDER BY s.sale_date
        ) AS rn
    FROM sales AS s
    INNER JOIN products AS p ON s.product_id = p.product_id
)
SELECT
    CONCAT(c.first_name, ' ', c.last_name) AS customer,
    cfs.sale_date,
    CONCAT(e.first_name, ' ', e.last_name) AS seller
FROM customer_first_sales AS cfs
INNER JOIN customers AS c ON cfs.customer_id = c.customer_id
INNER JOIN employees AS e ON cfs.sales_person_id = e.employee_id
WHERE cfs.rn = 1 AND cfs.price = 0
ORDER BY c.customer_id;
