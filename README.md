# DS206 Project 2 — Group 6

This project builds a dimensional data store named `ORDER_DDS` using SQL Server. It includes staging tables, dimension tables, fact/error loading scripts, a Python pipeline, tests, a CLI entry point, and a Power BI dashboard folder.

---

# Group 6 Dimensional Requirements

According to the project specification:

- `DimCategories` — SCD1 with delete
- `DimCustomers` — SCD2
- `DimEmployees` — SCD1 with delete
- `DimProducts` — SCD2 with delete/closing
- `DimRegion` — SCD1
- `DimShippers` — SCD1
- `DimSuppliers` — SCD4
- `DimTerritories` — SCD3
- `FactOrders` — snapshot fact table

---

# Project Structure

```text
infrastructure_initiation/
pipeline_dimensional_data/
pipeline_dimensional_data/queries/
tests/
logs/
dashboard/
data/raw/raw_data_source.xlsx
main.py
utils.py
sql_server_config_template.cfg
README.md
```

---

# Setup Instructions

## 1. Clone Repository

```bash
git clone https://github.com/Rita-Chamiyan/DS206_Project2_Group6.git
cd DS206_Project2_Group6
```

## 2. Install Dependencies

```bash
pip install pyodbc pytest openpyxl
```

The project does not require `pandas` for the pipeline.

## 3. Configure SQL Server Connection

The project does not track personal SQL Server credentials. Create your own local config file by copying the template:

```bash
cp sql_server_config_template.cfg sql_server_config.cfg
```

Then open `sql_server_config.cfg` and fill in your own SQL Server connection details:

```ini
[sql_server]
server = localhost
port = 1433
database = ORDER_DDS
username = sa
password = YOUR_PASSWORD_HERE
driver = ODBC Driver 18 for SQL Server
trust_server_certificate = yes
encrypt = no
```

`sql_server_config.cfg` is ignored by Git and should not be committed. Only `sql_server_config_template.cfg` is committed as the shared template.

---

# Database Initialization

Run these SQL scripts in order before running the Python pipeline.

## 1. Create Database

```text
infrastructure_initiation/dimensional_database_creation.sql
```

Run this script while connected to the `master` database.

## 2. Create Staging Tables

```text
infrastructure_initiation/staging_raw_table_creation.sql
```

Run this script after `ORDER_DDS` has been created.

## 3. Create Dimension and Fact Tables

```text
infrastructure_initiation/dimensional_db_table_creation.sql
```

These scripts create:

- staging raw tables
- `Dim_SOR`
- dimension tables
- `FactOrders`
- `FactOrdersError`

---

# Raw Data File

The pipeline loads raw Excel/source data from this project-relative path:

```text
data/raw/raw_data_source.xlsx
```

The Excel workbook must contain these sheets:

| Excel Sheet | SQL Table |
|---|---|
| Categories | Staging_Categories |
| Customers | Staging_Customers |
| Employees | Staging_Employees |
| OrderDetails | Staging_Order_Details |
| Orders | Staging_Orders |
| Products | Staging_Products |
| Region | Staging_Region |
| Shippers | Staging_Shippers |
| Suppliers | Staging_Suppliers |
| Territories | Staging_Territories |

Do not manually insert `staging_raw_id_sk` values because SQL Server generates them automatically.

---

# Running the Pipeline

The pipeline can be executed from the command line:

```bash
python main.py --start_date=1996-01-01 --end_date=1998-12-31
```

The pipeline performs:

1. Excel/source data loading into staging tables
2. Dimension ingestion
3. Fact error ingestion
4. Fact snapshot ingestion

---

# Running Tests

Run tests from the project root:

```bash
python -m pytest tests/test_utils.py
```

The tests use mocking and do not require a live SQL Server connection.

---

# Notes

- Do not commit personal passwords.
- `sql_server_config.cfg` is ignored by Git.
- `sql_server_config_template.cfg` is the shared template.
- Dashboard file location: `dashboard/group6_dashboard.pbix`.
