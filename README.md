# Sales Analytics ELT Pipeline — Snowflake Data Warehouse

A hands-on Snowflake ELT project that loads CSV and semi-structured JSON sales data, validates raw data, transforms it into a star schema, and produces analytical reporting datasets.

## Architecture

```
CSV / JSON files
      |
      v
External/Internal Stage
      |
      v
RAW schema
  - raw_orders
  - raw_customers
  - raw_products
  - raw_order_items
  - raw_events (VARIANT)
      |
      v
STAGING schema
  - cleaned and typed data
  - JSON flattening
  - duplicate / NULL checks
      |
      v
PRODUCTION schema
  - dim_customer
  - dim_product
  - dim_date
  - fact_sales
      |
      v
Analytics Views
  - monthly sales
  - product performance
  - customer revenue
  - regional performance
```

## Snowflake concepts demonstrated

- SQL and relational data modeling
- CSV and JSON file formats
- Snowflake stages
- `COPY INTO` bulk ingestion
- `VARIANT` for semi-structured JSON
- `LATERAL FLATTEN` for nested JSON
- Raw → Staging → Production ELT architecture
- Star-schema modeling with fact and dimension tables
- SQL transformations, joins, CTEs and window functions
- Data-quality validation for NULLs, duplicates and record counts
- Stored procedure for reusable data-quality checks
- Views for analytical reporting
- Snowflake Streams for incremental CDC
- Snowflake Tasks for scheduled processing
- MERGE for incremental upserts
- Time Travel for validation and recovery
- Zero-copy cloning for safe testing

## Project structure

```
data/
  customers.csv
  products.csv
  orders.csv
  order_items.csv
  customer_events.json

sql/
  01_setup.sql
  02_ingestion.sql
  03_transform.sql
  04_data_quality.sql
  05_analytics.sql
  06_incremental_cdc.sql
  07_time_travel_and_clone.sql
```

## How to run

1. Create or select a Snowflake warehouse.
2. Open `sql/01_setup.sql` and run it.
3. Upload the files from `data/` to the Snowflake stage created by the script.
4. Run `sql/02_ingestion.sql`.
5. Run `sql/03_transform.sql`.
6. Run `sql/04_data_quality.sql`.
7. Run `sql/05_analytics.sql`.
8. Run `sql/06_incremental_cdc.sql` to demonstrate Streams, Tasks and MERGE.
9. Run `sql/07_time_travel_and_clone.sql` to demonstrate Time Travel and zero-copy cloning.

## Important note

The repository contains reproducible Snowflake SQL and sample source data. Snowflake execution depends on the user's Snowflake account, warehouse and stage configuration; the SQL files are the implementation and learning artifact.
