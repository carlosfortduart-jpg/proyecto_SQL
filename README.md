# PROYECTO SQL – ANÁLISIS DE E-COMMERCE

**Autor:** Carlos Fort Duart  
**Fecha:** 7/1/2026  
**Asignatura:** SQL / Bases de Datos  
**Herramientas:** SQLite, DBeaver  

---

## 1. Introducción

Este proyecto tiene como objetivo el diseño, implementación y análisis de una base de datos relacional orientada al análisis, utilizando SQL. Para ello se ha trabajado con el dataset **Brazilian E-Commerce (Olist)**, disponible en la plataforma Kaggle, el cual contiene información real de pedidos realizados en un marketplace brasileño.

El dataset proporciona datos detallados sobre clientes, pedidos, productos, vendedores, fechas y localización geográfica. A partir de esta información se ha construido un **modelo en estrella (Star Schema)**, separando una **tabla de hechos** y varias **tablas de dimensiones**, con el fin de facilitar el análisis exploratorio y la obtención de métricas relevantes para la toma de decisiones de negocio.

### Información utilizada del dataset

Para el desarrollo del proyecto se han utilizado principalmente los siguientes archivos:
- `olist_customers_dataset`: información de clientes y su localización.
- `olist_orders_dataset`: información de pedidos y fechas de compra.
- `olist_order_items_dataset`: detalle de los productos vendidos en cada pedido.
- `olist_products_dataset`: catálogo de productos y categorías.
- `olist_sellers_dataset`: información de los vendedores.

El alcance del proyecto se centra en el análisis de ventas, clientes, productos, geografía y evolución temporal. No se han incluido otros módulos del dataset (pagos, reviews o logística avanzada) para mantener un enfoque analítico claro y coherente con los objetivos del proyecto.

---

## 2. Explicación del archivo `01_schema.sql`

El archivo `01_schema.sql` define completamente el **esquema de la base de datos**, incluyendo la creación de tablas, claves primarias, claves foráneas, restricciones, índices y vistas.

### Modelo de datos

Se ha diseñado un **modelo en estrella**, compuesto por:

- **Tabla de hechos**
  - `fact_order_items`: representa cada producto vendido en un pedido. Contiene las métricas principales del negocio, como el precio del producto y el coste de envío.

- **Tablas de dimensiones**
  - `dim_customers`: información de los clientes.
  - `dim_geography`: información geográfica normalizada (ciudad y estado).
  - `dim_products`: catálogo de productos y categorías.
  - `dim_dates`: dimensión temporal (día, mes y año).
  - `dim_sellers`: información de los vendedores.

### Decisiones de diseño

- Todas las tablas cuentan con **Primary Key** para garantizar unicidad.
- Se utilizan **Foreign Keys** para relacionar la tabla de hechos con las dimensiones.
- Se aplican restricciones como `NOT NULL`, `UNIQUE` y `CHECK` para asegurar la integridad de los datos.
- Se crea un **índice** sobre la fecha de la tabla de hechos para optimizar consultas temporales.
- Se define una **vista (`vw_sales_summary`)** que resume las ventas por año, mes y categoría, facilitando consultas analíticas recurrentes.

Este diseño permite realizar análisis complejos de forma eficiente y estructurada.

---

## 3. Explicación del archivo `02_data.sql`

El archivo `02_data.sql` se encarga de la **carga, transformación y limpieza de los datos**, partiendo de los archivos CSV originales importados previamente como tablas staging.

### Proceso seguido

1. **Gestión transaccional**  
   Se utiliza `BEGIN TRANSACTION` y `COMMIT` para asegurar que la carga de datos sea atómica y consistente.

2. **Carga de dimensiones**  
   - Se cargan primero las tablas de dimensiones.
   - Se aplica normalización de texto (`LOWER`, `TRIM`) en campos geográficos para evitar problemas de coincidencia.
   - Se garantiza la integridad referencial antes de cargar la tabla de hechos.

3. **Carga de la tabla de hechos**  
   - `fact_order_items` se carga únicamente con registros que tienen correspondencia válida en las dimensiones.
   - Se emplean `JOINs` con las tablas staging y las dimensiones.

4. **Transformaciones adicionales**  
   - Uso de `UPDATE` para simular ajustes de negocio sobre los precios.
   - Uso de `DELETE` para eliminar registros inconsistentes.

Este archivo refleja un flujo básico de **ETL (Extract, Transform, Load)** típico en proyectos de análisis de datos.

---

## 4. Explicación del archivo `03_eda.sql`

El archivo `03_eda.sql` constituye el **núcleo del proyecto**, donde se realiza el **Análisis Exploratorio de Datos (EDA)** utilizando SQL.

### Contenido del análisis

El EDA se estructura en varios bloques temáticos:

- **Análisis geográfico**  
  Ventas, volumen de productos y ticket medio por estado.

- **Análisis de productos**  
  Ventas por categoría, clasificación de productos mediante `CASE` y detección de categorías premium.

- **Análisis temporal**  
  Ventas mensuales y anuales, crecimiento mes a mes y ranking de meses mediante funciones ventana.

- **Análisis avanzado**  
  Segmentación de clientes, detección de clientes sin compras (`LEFT JOIN`), uso de **CTEs encadenadas**, **funciones ventana** (`RANK`, `LAG`, `PARTITION BY`) y reutilización de la vista `vw_sales_summary`.

El archivo hace uso de las principales funcionalidades vistas en el curso:
- `JOINs` (INNER y LEFT)
- `CASE`
- Agregaciones (`SUM`, `AVG`, `COUNT`)
- Subconsultas
- CTEs (`WITH`)
- Funciones ventana (`OVER`)
- Vistas

Todas las consultas están comentadas, explicando su finalidad técnica y su utilidad para el negocio.

---

## 5. Conclusiones

Este proyecto demuestra la construcción de un modelo analítico completo a partir de datos reales de e-commerce. El uso de un **modelo en estrella** ha permitido separar claramente hechos y dimensiones, facilitando el análisis y la escalabilidad del sistema.

El análisis exploratorio ha permitido:
- Identificar regiones con mayor volumen y facturación.
- Detectar categorías de productos más rentables.
- Analizar la evolución temporal de las ventas.
- Segmentar clientes según su valor económico.

En conjunto, el proyecto refleja un uso correcto y avanzado de SQL tanto para el diseño de bases de datos analíticas como para la obtención de información relevante orientada a la toma de decisiones de negocio.

