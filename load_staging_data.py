import pandas as pd
import pyodbc
import math

# ---------- Helpers ----------
def clean_value(value):
    if pd.isna(value):
        return None
    if isinstance(value, float) and math.isnan(value):
        return None
    return value


def clean_row(row, columns):
    return [clean_value(row[col]) for col in columns]


# ---------- Connection ----------
conn = pyodbc.connect(
    'DRIVER={ODBC Driver 18 for SQL Server};'
    'SERVER=WIN-3LU72C19LPR;'
    'DATABASE=ORDER_DDS;'
    'Trusted_Connection=yes;'
    'Encrypt=no;'
    'TrustServerCertificate=yes;'
)

cursor = conn.cursor()

xlsx = "data/raw/raw_data_source.xlsx"


# Optional: clear old staging data before loading again
staging_tables = [
    "Staging_Order_Details",
    "Staging_Orders",
    "Staging_Products",
    "Staging_Territories",
    "Staging_Suppliers",
    "Staging_Shippers",
    "Staging_Region",
    "Staging_Employees",
    "Staging_Customers",
    "Staging_Categories"
]

for table in staging_tables:
    cursor.execute(f"DELETE FROM dbo.{table}")

conn.commit()


# ── 1. Categories ──────────────────────────────────────────
df = pd.read_excel(xlsx, sheet_name="Categories").astype(object)

for _, row in df.iterrows():
    cursor.execute("""
        INSERT INTO dbo.Staging_Categories
        (CategoryID, CategoryName, Description)
        VALUES (?, ?, ?)
    """, *clean_row(row, ["CategoryID", "CategoryName", "Description"]))

print(f"Categories loaded: {len(df)} rows")


# ── 2. Customers ───────────────────────────────────────────
df = pd.read_excel(xlsx, sheet_name="Customers").astype(object)

for _, row in df.iterrows():
    cursor.execute("""
        INSERT INTO dbo.Staging_Customers
        (CustomerID, CompanyName, ContactName, ContactTitle,
         Address, City, Region, PostalCode, Country, Phone, Fax)
        VALUES (?,?,?,?,?,?,?,?,?,?,?)
    """, *clean_row(row, [
        "CustomerID", "CompanyName", "ContactName", "ContactTitle",
        "Address", "City", "Region", "PostalCode", "Country", "Phone", "Fax"
    ]))

print(f"Customers loaded: {len(df)} rows")


# ── 3. Employees ───────────────────────────────────────────
df = pd.read_excel(xlsx, sheet_name="Employees").astype(object)

for _, row in df.iterrows():
    cursor.execute("""
        INSERT INTO dbo.Staging_Employees
        (EmployeeID, LastName, FirstName, Title, TitleOfCourtesy,
         BirthDate, HireDate, Address, City, Region, PostalCode,
         Country, HomePhone, Extension, Notes, ReportsTo, PhotoPath)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
    """, *clean_row(row, [
        "EmployeeID", "LastName", "FirstName", "Title", "TitleOfCourtesy",
        "BirthDate", "HireDate", "Address", "City", "Region", "PostalCode",
        "Country", "HomePhone", "Extension", "Notes", "ReportsTo", "PhotoPath"
    ]))

print(f"Employees loaded: {len(df)} rows")


# ── 4. Region ──────────────────────────────────────────────
df = pd.read_excel(xlsx, sheet_name="Region").astype(object)

for _, row in df.iterrows():
    cursor.execute("""
        INSERT INTO dbo.Staging_Region
        (RegionID, RegionDescription, RegionCategory, RegionImportance)
        VALUES (?,?,?,?)
    """, *clean_row(row, [
        "RegionID", "RegionDescription", "RegionCategory", "RegionImportance"
    ]))

print(f"Region loaded: {len(df)} rows")


# ── 5. Shippers ────────────────────────────────────────────
df = pd.read_excel(xlsx, sheet_name="Shippers").astype(object)

for _, row in df.iterrows():
    cursor.execute("""
        INSERT INTO dbo.Staging_Shippers
        (ShipperID, CompanyName, Phone)
        VALUES (?,?,?)
    """, *clean_row(row, ["ShipperID", "CompanyName", "Phone"]))

print(f"Shippers loaded: {len(df)} rows")


# ── 6. Suppliers ───────────────────────────────────────────
df = pd.read_excel(xlsx, sheet_name="Suppliers").astype(object)

for _, row in df.iterrows():
    cursor.execute("""
        INSERT INTO dbo.Staging_Suppliers
        (SupplierID, CompanyName, ContactName, ContactTitle,
         Address, City, Region, PostalCode, Country, Phone, Fax, HomePage)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?)
    """, *clean_row(row, [
        "SupplierID", "CompanyName", "ContactName", "ContactTitle",
        "Address", "City", "Region", "PostalCode", "Country",
        "Phone", "Fax", "HomePage"
    ]))

print(f"Suppliers loaded: {len(df)} rows")


# ── 7. Territories ─────────────────────────────────────────
df = pd.read_excel(xlsx, sheet_name="Territories").astype(object)

for _, row in df.iterrows():
    cursor.execute("""
        INSERT INTO dbo.Staging_Territories
        (TerritoryID, TerritoryDescription, TerritoryCode, RegionID)
        VALUES (?,?,?,?)
    """, *clean_row(row, [
        "TerritoryID", "TerritoryDescription", "TerritoryCode", "RegionID"
    ]))

print(f"Territories loaded: {len(df)} rows")


# ── 8. Products ────────────────────────────────────────────
df = pd.read_excel(xlsx, sheet_name="Products").astype(object)

for _, row in df.iterrows():
    cursor.execute("""
        INSERT INTO dbo.Staging_Products
        (ProductID, ProductName, SupplierID, CategoryID,
         QuantityPerUnit, UnitPrice, UnitsInStock,
         UnitsOnOrder, ReorderLevel, Discontinued)
        VALUES (?,?,?,?,?,?,?,?,?,?)
    """, *clean_row(row, [
        "ProductID", "ProductName", "SupplierID", "CategoryID",
        "QuantityPerUnit", "UnitPrice", "UnitsInStock",
        "UnitsOnOrder", "ReorderLevel", "Discontinued"
    ]))

print(f"Products loaded: {len(df)} rows")


# ── 9. Orders ──────────────────────────────────────────────
df = pd.read_excel(xlsx, sheet_name="Orders").astype(object)

for _, row in df.iterrows():
    cursor.execute("""
        INSERT INTO dbo.Staging_Orders
        (OrderID, CustomerID, EmployeeID, OrderDate, RequiredDate,
         ShippedDate, ShipVia, Freight, ShipName, ShipAddress,
         ShipCity, ShipRegion, ShipPostalCode, ShipCountry, TerritoryID)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
    """, *clean_row(row, [
        "OrderID", "CustomerID", "EmployeeID", "OrderDate", "RequiredDate",
        "ShippedDate", "ShipVia", "Freight", "ShipName", "ShipAddress",
        "ShipCity", "ShipRegion", "ShipPostalCode", "ShipCountry", "TerritoryID"
    ]))

print(f"Orders loaded: {len(df)} rows")


# ── 10. OrderDetails ───────────────────────────────────────
df = pd.read_excel(xlsx, sheet_name="OrderDetails").astype(object)

for _, row in df.iterrows():
    cursor.execute("""
        INSERT INTO dbo.Staging_Order_Details
        (OrderID, ProductID, UnitPrice, Quantity, Discount)
        VALUES (?,?,?,?,?)
    """, *clean_row(row, [
        "OrderID", "ProductID", "UnitPrice", "Quantity", "Discount"
    ]))

print(f"OrderDetails loaded: {len(df)} rows")


conn.commit()
cursor.close()
conn.close()

print("\n✅ All staging tables loaded successfully!")