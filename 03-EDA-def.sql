-- =====================================================
-- BLOQUE 1: VENTAS POR ESTADO
-- Objetivo: analizar el rendimiento geográfico
-- =====================================================

-- Q1: Facturación total por estado
-- JOINs para relacionar ventas con clientes y su localización
-- GROUP BY para agregar ingresos por estado

SELECT
    g.state,
    SUM(f.price) AS revenue
FROM fact_order_items f
JOIN dim_customers c ON f.customer_id = c.customer_id
JOIN dim_geography g ON c.geography_id = g.geography_id
GROUP BY g.state;

-- Q2: Número total de productos vendidos por estado
-- COUNT(*) mide volumen de ventas, no valor monetario

SELECT
    g.state,
    COUNT(*) AS total_items
FROM fact_order_items f
JOIN dim_customers c ON f.customer_id = c.customer_id
JOIN dim_geography g ON c.geography_id = g.geography_id
GROUP BY g.state;

-- Q3: Ticket medio por estado
-- AVG(price) permite comparar poder adquisitivo por región

SELECT
    g.state,
    ROUND(AVG(f.price), 2) AS avg_ticket
FROM fact_order_items f
JOIN dim_customers c ON f.customer_id = c.customer_id
JOIN dim_geography g ON c.geography_id = g.geography_id
GROUP BY g.state;

-- Q4: Top 5 estados por facturación
-- ORDER BY + LIMIT para ranking de regiones más rentables

SELECT
    g.state,
    SUM(f.price) AS revenue
FROM fact_order_items f
JOIN dim_customers c ON f.customer_id = c.customer_id
JOIN dim_geography g ON c.geography_id = g.geography_id
GROUP BY g.state
ORDER BY revenue DESC
LIMIT 5;

-- Q5: Porcentaje de facturación por estado
-- Subquery para calcular el peso relativo de cada estado

SELECT
    g.state,
    ROUND(
        SUM(f.price) * 100.0 /
        (SELECT SUM(price) FROM fact_order_items),
        2
    ) AS revenue_percentage
FROM fact_order_items f
JOIN dim_customers c ON f.customer_id = c.customer_id
JOIN dim_geography g ON c.geography_id = g.geography_id
GROUP BY g.state;


-- =====================================================
-- BLOQUE 2: PRODUCTOS
-- Objetivo: analizar categorías y características
-- =====================================================

-- Q1: Clasificación de productos por peso
-- CASE crea una variable categórica derivada

SELECT
    product_id,
    category,
    CASE
        WHEN weight_g < 500 THEN 'Light'
        WHEN weight_g BETWEEN 500 AND 2000 THEN 'Medium'
        ELSE 'Heavy'
    END AS weight_class
FROM dim_products;

-- Q2: Facturación total por categoría
-- JOIN con productos y agregación por categoría

SELECT
    p.category,
    ROUND(SUM(f.price), 2) AS revenue
FROM fact_order_items f
JOIN dim_products p ON f.product_id = p.product_id
GROUP BY p.category;

-- Q3: Categoría más rentable
-- Subquery + ORDER BY para obtener la top categoría

SELECT category
FROM (
    SELECT
        p.category,
        SUM(f.price) AS revenue
    FROM fact_order_items f
    JOIN dim_products p ON f.product_id = p.product_id
    GROUP BY p.category
)
ORDER BY revenue DESC
LIMIT 1;

-- Q4: Número de productos vendidos por categoría
-- Permite comparar volumen frente a facturación

SELECT
    p.category,
    COUNT(*) AS items_sold
FROM fact_order_items f
JOIN dim_products p ON f.product_id = p.product_id
GROUP BY p.category;

-- Q5: Precio medio por categoría
-- Identifica categorías premium o low-cost

SELECT
    p.category,
    ROUND(AVG(f.price), 2) AS avg_price
FROM fact_order_items f
JOIN dim_products p ON f.product_id = p.product_id
GROUP BY p.category;

-- Q6: Categorías con precio medio superior a la media global
-- HAVING filtra resultados agregados

SELECT
    p.category,
    ROUND(AVG(f.price), 2) AS avg_price
FROM fact_order_items f
JOIN dim_products p ON f.product_id = p.product_id
GROUP BY p.category
HAVING AVG(f.price) > (SELECT AVG(price) FROM fact_order_items);


-- =====================================================
-- BLOQUE 3: TIEMPO
-- Objetivo: analizar tendencias y estacionalidad
-- =====================================================

-- Q1: Ventas mensuales
-- CTE para crear una tabla temporal reutilizable

WITH monthly_sales AS (
    SELECT
        d.year,
        d.month,
        ROUND(SUM(f.price), 2) AS revenue
    FROM fact_order_items f
    JOIN dim_dates d ON f.order_date = d.date_id
    GROUP BY d.year, d.month
)
SELECT * FROM monthly_sales;

-- Q2: Crecimiento mensual de ventas
-- LAG compara el mes actual con el anterior

SELECT
    year,
    month,
    revenue,
    ROUND(revenue - LAG(revenue) OVER (ORDER BY year, month),2) AS monthly_growth
FROM (
    SELECT
        d.year,
        d.month,
        ROUND(SUM(f.price), 2) AS revenue
    FROM fact_order_items f
    JOIN dim_dates d ON f.order_date = d.date_id
    GROUP BY d.year, d.month
);

-- Q3: Ranking de meses por facturación
-- RANK ordena los meses según ingresos

SELECT
    year,
    month,
    ROUND(revenue, 2) AS revenue,
    RANK() OVER (ORDER BY revenue DESC) AS revenue_rank
FROM (
    SELECT
        d.year,
        d.month,
        SUM(f.price) AS revenue
    FROM fact_order_items f
    JOIN dim_dates d ON f.order_date = d.date_id
    GROUP BY d.year, d.month
);

-- Q4: Facturación anual
-- Permite ver evolución a alto nivel

SELECT
    d.year,
    ROUND(SUM(f.price), 2) AS revenue
FROM fact_order_items f
JOIN dim_dates d ON f.order_date = d.date_id
GROUP BY d.year;

-- Q5: Ticket medio mensual
-- Combina análisis temporal y valor medio

SELECT
    d.year,
    d.month,
    ROUND(AVG(f.price), 2) AS avg_ticket
FROM fact_order_items f
JOIN dim_dates d ON f.order_date = d.date_id
GROUP BY d.year, d.month;

-- Q6: Meses con ventas superiores a la media global
-- Identifica meses excepcionalmente buenos

SELECT
    year,
    month,
    ROUND(revenue, 2) AS revenue
FROM (
    SELECT
        d.year,
        d.month,
        SUM(f.price) AS revenue
    FROM fact_order_items f
    JOIN dim_dates d ON f.order_date = d.date_id
    GROUP BY d.year, d.month
)
WHERE revenue > (SELECT AVG(price) FROM fact_order_items);

-- =====================================================
-- BLOQUE 4: ANÁLISIS DE CLIENTES Y CATEGORÍAS
-- Objetivo: segmentar clientes, analizar su valor y comparar rendimiento por categoría
-- =====================================================

-- Q1: Gasto total y número de compras por cliente
-- INNER JOIN entre la tabla de hechos y la dimensión de clientes
-- Agregaciones SUM y COUNT agrupadas por cliente
-- Finalidad:
-- Medir el valor económico de cada cliente
-- Identificar clientes de alto y bajo gasto

SELECT
    c.customer_id,
    COUNT(f.order_id) AS total_items,
    ROUND(SUM(f.price), 2) AS total_spent
FROM fact_order_items f
JOIN dim_customers c
ON f.customer_id = c.customer_id
GROUP BY c.customer_id;

-- Q2: Segmentación de clientes según gasto (CASE)
-- Clasifica clientes en Low / Medium / High value
-- Subquery con agregación del gasto total por cliente
-- CASE para clasificar clientes en segmentos
-- Finalidad:
-- Crear segmentos de clientes (Low / Medium / High Value)
-- Apoyar estrategias de fidelización y marketing

SELECT
    customer_id,
    total_spent,
    CASE
        WHEN total_spent < 100 THEN 'Low Value'
        WHEN total_spent BETWEEN 100 AND 500 THEN 'Medium Value'
        ELSE 'High Value'
    END AS customer_segment
FROM (
    SELECT
        c.customer_id,
        SUM(f.price) AS total_spent
    FROM fact_order_items f
    JOIN dim_customers c
    ON f.customer_id = c.customer_id
    GROUP BY c.customer_id
);

-- Q3: Clientes sin compras (LEFT JOIN)
-- LEFT JOIN permite detectar clientes sin registros en la fact table
-- Filtro de registros sin correspondencia en la tabla de hechos
-- Finalidad:
-- Detectar clientes inactivos
-- Identificar oportunidades de reactivación

SELECT
    c.customer_id
FROM dim_customers c
LEFT JOIN fact_order_items f
ON c.customer_id = f.customer_id
WHERE f.customer_id IS NULL;


-- Q4: CTE encadenadas para análisis por categoría
-- Primera CTE: calcula la facturación por categoría
-- Segunda CTE: aplica función ventana RANK
-- Finalidad:
-- Comparar el rendimiento de las categorías
-- Identificar las más y menos rentables

WITH category_sales AS (
    SELECT
        p.category,
        ROUND(SUM(f.price), 2) AS revenue
    FROM fact_order_items f
    JOIN dim_products p
    ON f.product_id = p.product_id
    GROUP BY p.category
),
category_ranking AS (
    SELECT
        category,
        revenue,
        RANK() OVER (ORDER BY revenue DESC) AS category_rank
    FROM category_sales
)
SELECT *
FROM category_ranking;


-- Q5: Función ventana con PARTITION BY
-- Ranking de clientes dentro de cada estado según gasto
-- JOINs entre ventas, clientes y geografía
-- Agregación del gasto por cliente
-- Función ventana con PARTITION BY estado
-- Finalidad:
-- Comparar clientes dentro de su región
-- Detectar clientes clave a nivel local

SELECT
    g.state,
    c.customer_id,
    ROUND(SUM(f.price), 2) AS total_spent,
    RANK() OVER (
        PARTITION BY g.state
        ORDER BY SUM(f.price) DESC
    ) AS state_rank
FROM fact_order_items f
JOIN dim_customers c
ON f.customer_id = c.customer_id
JOIN dim_geography g
ON c.geography_id = g.geography_id
GROUP BY g.state, c.customer_id;


-- Q6: Uso de la VIEW vw_sales_summary
-- Reutiliza la vista creada en el schema para análisis agregado
-- Finalidad:
-- Simplificar análisis repetitivos

SELECT
    year,
    month,
    category,
    total_items,
    total_revenue
FROM vw_sales_summary
ORDER BY total_revenue DESC;
