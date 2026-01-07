-- Activa la comprobación de claves foráneas en SQLite
PRAGMA foreign_keys = ON;

-- LIMPIEZA DEL ESQUEMA
-- Elimina vistas y tablas si existen para permitir una ejecución limpia del script desde cero

DROP VIEW IF EXISTS vw_sales_summary;
DROP TABLE IF EXISTS fact_order_items;
DROP TABLE IF EXISTS dim_customers;
DROP TABLE IF EXISTS dim_sellers;
DROP TABLE IF EXISTS dim_products;
DROP TABLE IF EXISTS dim_dates;
DROP TABLE IF EXISTS dim_geography;

-- DIM_GEOGRAPHY
-- Dimensión geográfica normalizada (ciudad y estado)
-- Evita duplicidades y permite análisis por región

CREATE TABLE dim_geography (
    geography_id INTEGER PRIMARY KEY,
    city TEXT NOT NULL,
    state TEXT NOT NULL,
    UNIQUE(city, state)
);

-- DIM_CUSTOMERS
-- Dimensión de clientes
-- Relaciona cada cliente con su ubicación geográfica

CREATE TABLE dim_customers (
    customer_id TEXT PRIMARY KEY,
    customer_unique_id TEXT NOT NULL,
    geography_id INTEGER NOT NULL,
    FOREIGN KEY (geography_id)
        REFERENCES dim_geography(geography_id)
);

-- DIM_SELLERS
-- Dimensión de vendedores
-- Permite analizar ventas por vendedor y localización

CREATE TABLE dim_sellers (
    seller_id TEXT PRIMARY KEY,
    geography_id INTEGER NOT NULL,
    FOREIGN KEY (geography_id)
        REFERENCES dim_geography(geography_id)
);

-- DIM_PRODUCTS
-- Dimensión de productos
-- Contiene categoría y características físicas

CREATE TABLE dim_products (
    product_id TEXT PRIMARY KEY,
    category TEXT,
    weight_g INTEGER CHECK (weight_g >= 0)
);

-- Dimensión temporal (tabla calendario)
-- Facilita análisis por día, mes y año

CREATE TABLE dim_dates (
    date_id TEXT PRIMARY KEY,
    day INTEGER,
    month INTEGER,
    year INTEGER
);

-- FACT TABLE
-- Tabla de hechos principal
-- Cada fila representa un producto vendido en un pedido

CREATE TABLE fact_order_items (
    order_item_id INTEGER PRIMARY KEY,
    order_id TEXT NOT NULL,
    customer_id TEXT NOT NULL,
    seller_id TEXT NOT NULL,
    product_id TEXT NOT NULL,
    order_date TEXT NOT NULL,
    price REAL CHECK (price >= 0),
    freight_value REAL CHECK (freight_value >= 0),

    FOREIGN KEY (customer_id) REFERENCES dim_customers(customer_id),
    FOREIGN KEY (seller_id) REFERENCES dim_sellers(seller_id),
    FOREIGN KEY (product_id) REFERENCES dim_products(product_id),
    FOREIGN KEY (order_date) REFERENCES dim_dates(date_id)
);

-- ÍNDICE
-- Optimiza consultas analíticas basadas en fecha

CREATE INDEX idx_fact_order_date
ON fact_order_items(order_date);

-- VIEW
-- Resume ventas por año, mes y categoría de producto

CREATE VIEW vw_sales_summary AS
SELECT
    d.year,
    d.month,
    p.category,
    COUNT(*) AS total_items,
    SUM(f.price) AS total_revenue
FROM fact_order_items f
JOIN dim_dates d ON f.order_date = d.date_id
JOIN dim_products p ON f.product_id = p.product_id
GROUP BY d.year, d.month, p.category;


-- COMPROBACIÓN RÁPIDA IMPORTACIÓN DATOS
-- Verifica que los CSV de Kaggle se han importado

-- Número total de clientes importados desde el CSV
SELECT COUNT(*) FROM olist_customers_dataset;

-- Número total de pedidos importados desde el CSV
SELECT COUNT(*) FROM olist_orders_dataset;

-- Número total de líneas de pedido importadas desde el CSV
SELECT COUNT(*) FROM olist_order_items_dataset;