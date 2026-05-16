USE ORDER_DDS;
GO

IF OBJECT_ID('dbo.FactOrdersError', 'U') IS NOT NULL DROP TABLE dbo.FactOrdersError;
IF OBJECT_ID('dbo.FactOrders', 'U') IS NOT NULL DROP TABLE dbo.FactOrders;

IF OBJECT_ID('dbo.DimTerritories', 'U') IS NOT NULL DROP TABLE dbo.DimTerritories;
IF OBJECT_ID('dbo.DimSuppliersHistory', 'U') IS NOT NULL DROP TABLE dbo.DimSuppliersHistory;
IF OBJECT_ID('dbo.DimSuppliers', 'U') IS NOT NULL DROP TABLE dbo.DimSuppliers;
IF OBJECT_ID('dbo.DimShippers', 'U') IS NOT NULL DROP TABLE dbo.DimShippers;
IF OBJECT_ID('dbo.DimRegion', 'U') IS NOT NULL DROP TABLE dbo.DimRegion;
IF OBJECT_ID('dbo.DimProducts', 'U') IS NOT NULL DROP TABLE dbo.DimProducts;
IF OBJECT_ID('dbo.DimEmployees', 'U') IS NOT NULL DROP TABLE dbo.DimEmployees;
IF OBJECT_ID('dbo.DimCustomers', 'U') IS NOT NULL DROP TABLE dbo.DimCustomers;
IF OBJECT_ID('dbo.DimCategories', 'U') IS NOT NULL DROP TABLE dbo.DimCategories;
IF OBJECT_ID('dbo.Dim_SOR', 'U') IS NOT NULL DROP TABLE dbo.Dim_SOR;
GO

CREATE TABLE dbo.Dim_SOR (
    SOR_SK INT IDENTITY(1,1) PRIMARY KEY,
    staging_table_name NVARCHAR(128) NOT NULL UNIQUE
);

INSERT INTO dbo.Dim_SOR (staging_table_name)
VALUES
('Staging_Categories'),
('Staging_Customers'),
('Staging_Employees'),
('Staging_Order_Details'),
('Staging_Orders'),
('Staging_Products'),
('Staging_Region'),
('Staging_Shippers'),
('Staging_Suppliers'),
('Staging_Territories');

CREATE TABLE dbo.DimCategories (
    Category_SK INT IDENTITY(1,1) PRIMARY KEY,
    CategoryID_NK INT NOT NULL,
    CategoryName NVARCHAR(100),
    Description NVARCHAR(MAX),
    SOR_SK INT NOT NULL,
    staging_raw_id_sk INT NOT NULL,
    is_deleted BIT DEFAULT 0,
    created_at DATETIME2 DEFAULT SYSDATETIME(),
    updated_at DATETIME2 DEFAULT SYSDATETIME()
);

CREATE TABLE dbo.DimCustomers (
    Customer_SK INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID_NK NVARCHAR(20) NOT NULL,
    CompanyName NVARCHAR(100),
    ContactName NVARCHAR(100),
    ContactTitle NVARCHAR(100),
    Address NVARCHAR(200),
    City NVARCHAR(100),
    Region NVARCHAR(100),
    PostalCode NVARCHAR(30),
    Country NVARCHAR(100),
    Phone NVARCHAR(50),
    Fax NVARCHAR(50),
    SOR_SK INT NOT NULL,
    staging_raw_id_sk INT NOT NULL,
    effective_start_date DATETIME2 DEFAULT SYSDATETIME(),
    effective_end_date DATETIME2 NULL,
    is_current BIT DEFAULT 1
);

CREATE TABLE dbo.DimEmployees (
    Employee_SK INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID_NK INT NOT NULL,
    LastName NVARCHAR(100),
    FirstName NVARCHAR(100),
    Title NVARCHAR(100),
    BirthDate DATE,
    HireDate DATE,
    ReportsTo INT,
    SOR_SK INT NOT NULL,
    staging_raw_id_sk INT NOT NULL,
    is_deleted BIT DEFAULT 0,
    created_at DATETIME2 DEFAULT SYSDATETIME(),
    updated_at DATETIME2 DEFAULT SYSDATETIME()
);

CREATE TABLE dbo.DimProducts (
    Product_SK INT IDENTITY(1,1) PRIMARY KEY,
    ProductID_NK INT NOT NULL,
    ProductName NVARCHAR(100),
    SupplierID INT,
    CategoryID INT,
    QuantityPerUnit NVARCHAR(100),
    UnitPrice DECIMAL(18,4),
    UnitsInStock INT,
    UnitsOnOrder INT,
    ReorderLevel INT,
    Discontinued BIT,
    SOR_SK INT NOT NULL,
    staging_raw_id_sk INT NOT NULL,
    effective_start_date DATETIME2 DEFAULT SYSDATETIME(),
    effective_end_date DATETIME2 NULL,
    is_current BIT DEFAULT 1,
    is_deleted BIT DEFAULT 0
);

CREATE TABLE dbo.DimRegion (
    Region_SK INT IDENTITY(1,1) PRIMARY KEY,
    RegionID_NK INT NOT NULL,
    RegionDescription NVARCHAR(100),
    SOR_SK INT NOT NULL,
    staging_raw_id_sk INT NOT NULL,
    created_at DATETIME2 DEFAULT SYSDATETIME(),
    updated_at DATETIME2 DEFAULT SYSDATETIME()
);

CREATE TABLE dbo.DimShippers (
    Shipper_SK INT IDENTITY(1,1) PRIMARY KEY,
    ShipperID_NK INT NOT NULL,
    CompanyName NVARCHAR(100),
    Phone NVARCHAR(50),
    SOR_SK INT NOT NULL,
    staging_raw_id_sk INT NOT NULL,
    created_at DATETIME2 DEFAULT SYSDATETIME(),
    updated_at DATETIME2 DEFAULT SYSDATETIME()
);

CREATE TABLE dbo.DimSuppliers (
    Supplier_SK INT IDENTITY(1,1) PRIMARY KEY,
    SupplierID_NK INT NOT NULL,
    CompanyName NVARCHAR(100),
    ContactName NVARCHAR(100),
    ContactTitle NVARCHAR(100),
    Address NVARCHAR(200),
    City NVARCHAR(100),
    Region NVARCHAR(100),
    PostalCode NVARCHAR(30),
    Country NVARCHAR(100),
    Phone NVARCHAR(50),
    Fax NVARCHAR(50),
    HomePage NVARCHAR(MAX),
    SOR_SK INT NOT NULL,
    staging_raw_id_sk INT NOT NULL,
    created_at DATETIME2 DEFAULT SYSDATETIME(),
    updated_at DATETIME2 DEFAULT SYSDATETIME()
);

CREATE TABLE dbo.DimSuppliersHistory (
    Supplier_History_SK INT IDENTITY(1,1) PRIMARY KEY,
    SupplierID_NK INT NOT NULL,
    old_CompanyName NVARCHAR(100),
    old_ContactName NVARCHAR(100),
    old_Phone NVARCHAR(50),
    changed_at DATETIME2 DEFAULT SYSDATETIME()
);

CREATE TABLE dbo.DimTerritories (
    Territory_SK INT IDENTITY(1,1) PRIMARY KEY,
    TerritoryID_NK NVARCHAR(20) NOT NULL,
    TerritoryDescription NVARCHAR(100),
    CurrentRegionID INT,
    PriorRegionID INT,
    SOR_SK INT NOT NULL,
    staging_raw_id_sk INT NOT NULL,
    created_at DATETIME2 DEFAULT SYSDATETIME(),
    updated_at DATETIME2 DEFAULT SYSDATETIME()
);

CREATE TABLE dbo.FactOrders (
    FactOrder_SK INT IDENTITY(1,1) PRIMARY KEY,
    SnapshotDate DATE NOT NULL,
    OrderID_NK INT NOT NULL,
    ProductID_NK INT NOT NULL,
    Customer_SK INT NULL,
    Employee_SK INT NULL,
    Product_SK INT NULL,
    Category_SK INT NULL,
    Supplier_SK INT NULL,
    Shipper_SK INT NULL,
    Territory_SK INT NULL,
    Region_SK INT NULL,
    OrderDate DATE,
    RequiredDate DATE,
    ShippedDate DATE,
    UnitPrice DECIMAL(18,4),
    Quantity INT,
    Discount DECIMAL(18,4),
    Freight DECIMAL(18,4),
    GrossAmount DECIMAL(18,4),
    DiscountAmount DECIMAL(18,4),
    NetAmount DECIMAL(18,4),
    SOR_SK_Order INT NULL,
    staging_orders_raw_id_sk INT NULL,
    SOR_SK_OrderDetails INT NULL,
    staging_order_details_raw_id_sk INT NULL,
    execution_id NVARCHAR(100),
    created_at DATETIME2 DEFAULT SYSDATETIME()
);

CREATE TABLE dbo.FactOrdersError (
    FactOrderError_SK INT IDENTITY(1,1) PRIMARY KEY,
    OrderID_NK INT NULL,
    ProductID_NK INT NULL,
    CustomerID_NK NVARCHAR(20) NULL,
    EmployeeID_NK INT NULL,
    ShipperID_NK INT NULL,
    TerritoryID_NK NVARCHAR(20) NULL,
    ErrorReason NVARCHAR(500),
    SOR_SK_Order INT NULL,
    staging_orders_raw_id_sk INT NULL,
    SOR_SK_OrderDetails INT NULL,
    staging_order_details_raw_id_sk INT NULL,
    execution_id NVARCHAR(100),
    created_at DATETIME2 DEFAULT SYSDATETIME()
);
GO
