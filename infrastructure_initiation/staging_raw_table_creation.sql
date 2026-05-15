USE ORDER_DDS;
GO

IF OBJECT_ID('dbo.Staging_Categories', 'U') IS NOT NULL DROP TABLE dbo.Staging_Categories;
IF OBJECT_ID('dbo.Staging_Customers', 'U') IS NOT NULL DROP TABLE dbo.Staging_Customers;
IF OBJECT_ID('dbo.Staging_Employees', 'U') IS NOT NULL DROP TABLE dbo.Staging_Employees;
IF OBJECT_ID('dbo.Staging_Order_Details', 'U') IS NOT NULL DROP TABLE dbo.Staging_Order_Details;
IF OBJECT_ID('dbo.Staging_Orders', 'U') IS NOT NULL DROP TABLE dbo.Staging_Orders;
IF OBJECT_ID('dbo.Staging_Products', 'U') IS NOT NULL DROP TABLE dbo.Staging_Products;
IF OBJECT_ID('dbo.Staging_Region', 'U') IS NOT NULL DROP TABLE dbo.Staging_Region;
IF OBJECT_ID('dbo.Staging_Shippers', 'U') IS NOT NULL DROP TABLE dbo.Staging_Shippers;
IF OBJECT_ID('dbo.Staging_Suppliers', 'U') IS NOT NULL DROP TABLE dbo.Staging_Suppliers;
IF OBJECT_ID('dbo.Staging_Territories', 'U') IS NOT NULL DROP TABLE dbo.Staging_Territories;
GO

CREATE TABLE dbo.Staging_Categories (
    staging_raw_id_sk INT IDENTITY(1,1) PRIMARY KEY,
    CategoryID INT NOT NULL,
    CategoryName NVARCHAR(100),
    Description NVARCHAR(MAX)
);

CREATE TABLE dbo.Staging_Customers (
    staging_raw_id_sk INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID NVARCHAR(20) NOT NULL,
    CompanyName NVARCHAR(100),
    ContactName NVARCHAR(100),
    ContactTitle NVARCHAR(100),
    Address NVARCHAR(200),
    City NVARCHAR(100),
    Region NVARCHAR(100),
    PostalCode NVARCHAR(30),
    Country NVARCHAR(100),
    Phone NVARCHAR(50),
    Fax NVARCHAR(50)
);

CREATE TABLE dbo.Staging_Employees (
    staging_raw_id_sk INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT NOT NULL,
    LastName NVARCHAR(100),
    FirstName NVARCHAR(100),
    Title NVARCHAR(100),
    TitleOfCourtesy NVARCHAR(50),
    BirthDate DATE,
    HireDate DATE,
    Address NVARCHAR(200),
    City NVARCHAR(100),
    Region NVARCHAR(100),
    PostalCode NVARCHAR(30),
    Country NVARCHAR(100),
    HomePhone NVARCHAR(50),
    Extension NVARCHAR(20),
    ReportsTo INT
);

CREATE TABLE dbo.Staging_Order_Details (
    staging_raw_id_sk INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL,
    ProductID INT NOT NULL,
    UnitPrice DECIMAL(18,4),
    Quantity INT,
    Discount DECIMAL(18,4)
);

CREATE TABLE dbo.Staging_Orders (
    staging_raw_id_sk INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL,
    CustomerID NVARCHAR(20),
    EmployeeID INT,
    OrderDate DATE,
    RequiredDate DATE,
    ShippedDate DATE,
    ShipVia INT,
    Freight DECIMAL(18,4),
    ShipName NVARCHAR(100),
    ShipAddress NVARCHAR(200),
    ShipCity NVARCHAR(100),
    ShipRegion NVARCHAR(100),
    ShipPostalCode NVARCHAR(30),
    ShipCountry NVARCHAR(100),
    TerritoryID NVARCHAR(20)
);

CREATE TABLE dbo.Staging_Products (
    staging_raw_id_sk INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT NOT NULL,
    ProductName NVARCHAR(100),
    SupplierID INT,
    CategoryID INT,
    QuantityPerUnit NVARCHAR(100),
    UnitPrice DECIMAL(18,4),
    UnitsInStock INT,
    UnitsOnOrder INT,
    ReorderLevel INT,
    Discontinued BIT
);

CREATE TABLE dbo.Staging_Region (
    staging_raw_id_sk INT IDENTITY(1,1) PRIMARY KEY,
    RegionID INT NOT NULL,
    RegionDescription NVARCHAR(100)
);

CREATE TABLE dbo.Staging_Shippers (
    staging_raw_id_sk INT IDENTITY(1,1) PRIMARY KEY,
    ShipperID INT NOT NULL,
    CompanyName NVARCHAR(100),
    Phone NVARCHAR(50)
);

CREATE TABLE dbo.Staging_Suppliers (
    staging_raw_id_sk INT IDENTITY(1,1) PRIMARY KEY,
    SupplierID INT NOT NULL,
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
    HomePage NVARCHAR(MAX)
);

CREATE TABLE dbo.Staging_Territories (
    staging_raw_id_sk INT IDENTITY(1,1) PRIMARY KEY,
    TerritoryID NVARCHAR(20) NOT NULL,
    TerritoryDescription NVARCHAR(100),
    RegionID INT
);
GO
