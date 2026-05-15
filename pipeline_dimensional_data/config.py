from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]


# Config file
CONFIG_FILE_PATH = PROJECT_ROOT / "sql_server_config.cfg"
CONFIG_SECTION_NAME = "sql_server"


# Database and schema
DATABASE_NAME = "ORDER_DDS"
SCHEMA_NAME = "dbo"


# Main folders
INFRASTRUCTURE_PATH = PROJECT_ROOT / "infrastructure_initiation"
QUERIES_PATH = PROJECT_ROOT / "pipeline_dimensional_data" / "queries"
LOGS_PATH = PROJECT_ROOT / "logs"


# Infrastructure SQL files
DIMENSIONAL_DATABASE_CREATION_SQL = (
    INFRASTRUCTURE_PATH / "dimensional_database_creation.sql"
)

STAGING_RAW_TABLE_CREATION_SQL = (
    INFRASTRUCTURE_PATH / "staging_raw_table_creation.sql"
)

DIMENSIONAL_DB_TABLE_CREATION_SQL = (
    INFRASTRUCTURE_PATH / "dimensional_db_table_creation.sql"
)


# Dimension update SQL files
DIMENSION_SQL_FILES = [
    QUERIES_PATH / "update_dim_categories.sql",
    QUERIES_PATH / "update_dim_customers.sql",
    QUERIES_PATH / "update_dim_employees.sql",
    QUERIES_PATH / "update_dim_products.sql",
    QUERIES_PATH / "update_dim_region.sql",
    QUERIES_PATH / "update_dim_shippers.sql",
    QUERIES_PATH / "update_dim_suppliers.sql",
    QUERIES_PATH / "update_dim_territories.sql",
]


# Optional combined dimension script
# Keep this only for compatibility because the file exists in your folder.
UPDATE_DIMENSIONS_SQL = QUERIES_PATH / "update_dimensions.sql"


# Fact update SQL files
UPDATE_FACT_SQL = QUERIES_PATH / "update_fact.sql"
UPDATE_FACT_ERROR_SQL = QUERIES_PATH / "update_fact_error.sql"


# Staging table names
STAGING_TABLES = {
    "categories": "Staging_Categories",
    "customers": "Staging_Customers",
    "employees": "Staging_Employees",
    "order_details": "Staging_Order_Details",
    "orders": "Staging_Orders",
    "products": "Staging_Products",
    "region": "Staging_Region",
    "shippers": "Staging_Shippers",
    "suppliers": "Staging_Suppliers",
    "territories": "Staging_Territories",
}


# Dimension table names
DIMENSION_TABLES = {
    "categories": "DimCategories",
    "customers": "DimCustomers",
    "employees": "DimEmployees",
    "products": "DimProducts",
    "region": "DimRegion",
    "shippers": "DimShippers",
    "suppliers": "DimSuppliers",
    "territories": "DimTerritories",
    "sor": "Dim_SOR",
}


# Fact table names
FACT_TABLE = "FactOrders"
FACT_ERROR_TABLE = "FactOrdersError"