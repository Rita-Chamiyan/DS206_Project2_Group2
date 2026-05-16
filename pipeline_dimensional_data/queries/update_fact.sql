USE {database_name};

INSERT INTO {schema_name}.FactOrders (
    SnapshotDate,
    OrderID_NK,
    ProductID_NK,
    Customer_SK,
    Employee_SK,
    Product_SK,
    Category_SK,
    Supplier_SK,
    Shipper_SK,
    Territory_SK,
    Region_SK,
    OrderDate,
    RequiredDate,
    ShippedDate,
    UnitPrice,
    Quantity,
    Discount,
    Freight,
    GrossAmount,
    DiscountAmount,
    NetAmount,
    SOR_SK_Order,
    staging_orders_raw_id_sk,
    SOR_SK_OrderDetails,
    staging_order_details_raw_id_sk,
    execution_id
)
SELECT
    CAST(GETDATE() AS DATE) AS SnapshotDate,
    o.OrderID AS OrderID_NK,
    od.ProductID AS ProductID_NK,

    dc.Customer_SK,
    de.Employee_SK,
    dp.Product_SK,
    dcat.Category_SK,
    dsup.Supplier_SK,
    dship.Shipper_SK,
    dt.Territory_SK,
    dr.Region_SK,

    o.OrderDate,
    o.RequiredDate,
    o.ShippedDate,
    od.UnitPrice,
    od.Quantity,
    od.Discount,
    o.Freight,

    od.UnitPrice * od.Quantity AS GrossAmount,
    od.UnitPrice * od.Quantity * od.Discount AS DiscountAmount,
    od.UnitPrice * od.Quantity * (1 - od.Discount) AS NetAmount,

    sor_orders.SOR_SK AS SOR_SK_Order,
    o.staging_raw_id_sk AS staging_orders_raw_id_sk,
    sor_order_details.SOR_SK AS SOR_SK_OrderDetails,
    od.staging_raw_id_sk AS staging_order_details_raw_id_sk,
    '{execution_id}' AS execution_id

FROM {schema_name}.Staging_Orders o
INNER JOIN {schema_name}.Staging_Order_Details od
    ON o.OrderID = od.OrderID

LEFT JOIN {schema_name}.DimCustomers dc
    ON o.CustomerID = dc.CustomerID_NK
    AND dc.is_current = 1

LEFT JOIN {schema_name}.DimEmployees de
    ON o.EmployeeID = de.EmployeeID_NK
    AND de.is_deleted = 0

LEFT JOIN {schema_name}.DimProducts dp
    ON od.ProductID = dp.ProductID_NK
    AND dp.is_current = 1
    AND dp.is_deleted = 0

LEFT JOIN {schema_name}.DimCategories dcat
    ON dp.CategoryID = dcat.CategoryID_NK
    AND dcat.is_deleted = 0

LEFT JOIN {schema_name}.DimSuppliers dsup
    ON dp.SupplierID = dsup.SupplierID_NK

LEFT JOIN {schema_name}.DimShippers dship
    ON o.ShipVia = dship.ShipperID_NK

LEFT JOIN {schema_name}.DimTerritories dt
    ON o.TerritoryID = dt.TerritoryID_NK

LEFT JOIN {schema_name}.DimRegion dr
    ON dt.CurrentRegionID = dr.RegionID_NK

LEFT JOIN {schema_name}.Dim_SOR sor_orders
    ON sor_orders.staging_table_name = 'Staging_Orders'

LEFT JOIN {schema_name}.Dim_SOR sor_order_details
    ON sor_order_details.staging_table_name = 'Staging_Order_Details'

WHERE o.OrderDate >= '{start_date}'
  AND o.OrderDate <= '{end_date}'
  AND dc.Customer_SK IS NOT NULL
  AND de.Employee_SK IS NOT NULL
  AND dp.Product_SK IS NOT NULL
  AND dship.Shipper_SK IS NOT NULL
  AND dt.Territory_SK IS NOT NULL;WHERE o.OrderDate >= '{start_date}'
  AND o.OrderDate <= '{end_date}';
