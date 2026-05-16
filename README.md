# DS206 Project 2 — Group 6

This project builds a dimensional data warehouse named `ORDER_DDS` using SQL Server.

The project includes:

- staging tables
- dimension and fact tables
- fact and error loading procedures
- a Python ETL pipeline
- logging and execution tracking
- automated tests
- a command-line interface (CLI) entry point
---

# Group 6 Dimensional Requirements

According to the project specification:

- DimCategories — SCD1 with delete
- DimCustomers — SCD2
- DimEmployees — SCD1 with delete
- DimProducts — SCD2 with delete (closing)
- DimRegion — SCD1
- DimShippers — SCD1
- DimSuppliers — SCD4
- DimTerritories — SCD3
- FactOrders — SNAPSHOT

Project requirements reference: 

---

# Project Structure


infrastructure_initiation/
pipeline_dimensional_data/
tests/
logs/
dashboard/

main.py
utils.py
logging.py
sql_server_config.cfg
README.md
---

# Setup Instructions

## 1. Clone Repository

bash git clone https://github.com/Rita-Chamiyan/DS206_Project2_Group2.git cd DS206_Project2_Group6

---

## 2. Install Dependencies

bash pip install pyodbc pytest pandas openpyxl 

---

## 3. Configure SQL Server Connection

Edit:

text sql_server_config.cfg 

Example:

ini [sql_server] server = localhost port = 1433 database = ORDER_DDS username = sa password = CHANGE_ME driver = ODBC Driver 18 for SQL Server trust_server_certificate = yes 

Replace CHANGE_ME with your own SQL Server password.

Optional local private config:

bash cp sql_server_config.cfg local_sql_server_config.cfg 

local_sql_server_config.cfg should NOT be committed.

---

# Database Initialization

Run these SQL scripts in order:

## 1. Create Database

text infrastructure_initiation/dimensional_database_creation.sql 

## 2. Create Staging Tables

text infrastructure_initiation/staging_raw_table_creation.sql 

## 3. Create Dimension and Fact Tables

text infrastructure_initiation/dimensional_db_table_creation.sql 

These scripts create:

- staging raw tables
- Dim_SOR
- dimension tables
- FactOrders
- FactOrdersError

---

# Loading Raw Data

Load the Excel/source data into the staging tables.

Mapping:

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

Do NOT manually insert staging_raw_id_sk values because SQL Server generates them automatically.

---

# Running the Pipeline

The pipeline can be executed from the command line:

bash python main.py --start_date=1996-01-01 --end_date=1998-12-31 

The pipeline performs:

1. Dimension ingestion
2. Fact error ingestion
3. Fact snapshot ingestion

---

# Logging

Pipeline logs are written to:

text logs/logs_dimensional_data_pipeline.txt 

Each run contains a unique execution_id.

---

# Running Tests

Run tests from the tests directory:

bash cd tests python -m pytest test_utils.py cd .. 

The tests use mocking and do not require a live SQL Server connection.

---

# Notes

- local_sql_server_config.cfg is ignored by Git.
- Do not commit personal passwords.
- Raw data files, zip files, and system files are ignored by Git.
- Dashboard file location:

text dashboard/group6_dashboard.pbix 



