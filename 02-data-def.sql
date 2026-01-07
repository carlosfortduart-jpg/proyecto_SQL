-- INICIO DE TRANSACCIÓN
-- Garantiza que la carga de datos sea atómica

BEGIN TRANSACTION;

-- LIMPIEZA PREVIA DE DIMENSIONES Y HECHOS
-- Se eliminan datos para permitir recarga limpia

DELETE FROM fact_order_items;
DELETE FROM dim_customers;
DELETE FROM dim_geography;
DELETE FROM dim_dates;
DELETE FROM dim_products;

-- CARGA DE DIM_GEOGRAPHY
-- Se crea la dimensión geográfica normalizando texto
-- (lower + trim) para evitar problemas de JOIN

INSERT INTO dim_geography (city, state)
SELECT DISTINCT
    LOWER(TRIM(customer_city)) AS city,
    LOWER(TRIM(customer_state)) AS state
FROM olist_customers_dataset;

-- COMPROBACIÓN DE DIM_GEOGRAPHY
-- Verifica que la dimensión geográfica tiene datos

SELECT COUNT(*) AS total_geographies
FROM dim_geography;

-- CARGA DE DIM_CUSTOMERS
-- Asocia cada cliente con su localización geográfica

INSERT INTO dim_customers
SELECT
    c.customer_id,
    c.customer_unique_id,
    g.geography_id
FROM olist_customers_dataset c
JOIN dim_geography g
ON LOWER(TRIM(c.customer_city)) = g.city
AND LOWER(TRIM(c.customer_state)) = g.state;

-- COMPROBACIÓN DE DIM_CUSTOMERS
-- Verifica que los clientes se han cargado correctamente

SELECT COUNT(*) AS total_customers
FROM dim_customers;

-- CARGA DE DIM_DATES
-- Se genera la dimensión temporal a partir de pedidos

INSERT OR IGNORE INTO dim_dates
SELECT DISTINCT
    DATE(order_purchase_timestamp) AS date_id,
    CAST(STRFTIME('%d', order_purchase_timestamp) AS INTEGER) AS day,
    CAST(STRFTIME('%m', order_purchase_timestamp) AS INTEGER) AS month,
    CAST(STRFTIME('%Y', order_purchase_timestamp) AS INTEGER) AS year
FROM olist_orders_dataset;

-- COMPROBACIÓN DE DIM_DATES
-- Muestra algunas fechas cargadas

SELECT * FROM dim_dates LIMIT 5;

-- CARGA DE DIM_PRODUCTS
-- Inserta catálogo de productos con categoría y peso

INSERT INTO dim_products (
    product_id,
    category,
    weight_g
)
SELECT
    product_id,
    product_category_name,
    product_weight_g
FROM olist_products_dataset;

-- COMPROBACIÓN DE DIM_PRODUCTS
-- Verifica que los productos se han cargado

SELECT COUNT(*) AS total_products
FROM dim_products;

-- CARGA DE FACT_ORDER_ITEMS
-- Inserta la tabla de hechos solo con clientes válidos
-- Garantiza integridad referencial con dim_customers

INSERT INTO fact_order_items (
    order_id,
    customer_id,
    seller_id,
    product_id,
    order_date,
    price,
    freight_value
)
SELECT
    oi.order_id,
    o.customer_id,
    oi.seller_id,
    oi.product_id,
    DATE(o.order_purchase_timestamp),
    oi.price,
    oi.freight_value
FROM olist_order_items_dataset oi
JOIN olist_orders_dataset o
ON oi.order_id = o.order_id
JOIN dim_customers c
ON o.customer_id = c.customer_id;

-- AJUSTE DE PRECIOS
-- Ejemplo de transformación: incremento del 2%
-- en productos de bajo precio

UPDATE fact_order_items
SET price = price * 1.02
WHERE price < 50;

-- LIMPIEZA FINAL
-- Elimina registros inconsistentes (precios nulos)

DELETE FROM fact_order_items
WHERE price IS NULL;

-- CONFIRMACIÓN DE LA TRANSACCIÓN
-- Guarda todos los cambios realizados

COMMIT;

-- COMPROBACIONES FINALES DEL MODELO
-- Verifica que todas las tablas tienen datos

SELECT COUNT(*) AS total_fact_rows FROM fact_order_items;
SELECT COUNT(*) AS total_customers FROM dim_customers;
SELECT COUNT(*) AS total_geographies FROM dim_geography;
SELECT COUNT(*) AS total_dates FROM dim_dates;

-- Muestra ejemplos de la dimensión geográfica
SELECT * FROM dim_geography LIMIT 5;

