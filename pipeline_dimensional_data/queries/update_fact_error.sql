USE {database_name};

INSERT INTO {schema_name}.FactOrdersError (
    OrderID_NK,
    ProductID_NK,
    CustomerID_NK,
    EmployeeID_NK,
    ShipperID_NK,
    TerritoryID_NK,
    ErrorReason,
    SOR_SK_Order,
    staging_orders_raw_id_sk,
    SOR_SK_OrderDetails,
    staging_order_details_raw_id_sk,
    execution_id
)
SELECT
    o.OrderID AS OrderID_NK,
    od.ProductID AS ProductID_NK,
    o.CustomerID AS CustomerID_NK,
    o.EmployeeID AS EmployeeID_NK,
    o.ShipVia AS ShipperID_NK,
    o.TerritoryID AS TerritoryID_NK,

    CONCAT(
        CASE WHEN dc.Customer_SK IS NULL THEN 'Missing Customer natural key; ' ELSE '' END,
        CASE WHEN de.Employee_SK IS NULL THEN 'Missing Employee natural key; ' ELSE '' END,
        CASE WHEN dp.Product_SK IS NULL THEN 'Missing Product natural key; ' ELSE '' END,
        CASE WHEN dship.Shipper_SK IS NULL THEN 'Missing Shipper natural key; ' ELSE '' END,
        CASE WHEN dt.Territory_SK IS NULL THEN 'Missing Territory natural key; ' ELSE '' END
    ) AS ErrorReason,

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

LEFT JOIN {schema_name}.DimShippers dship
    ON o.ShipVia = dship.ShipperID_NK

LEFT JOIN {schema_name}.DimTerritories dt
    ON o.TerritoryID = dt.TerritoryID_NK

LEFT JOIN {schema_name}.Dim_SOR sor_orders
    ON sor_orders.staging_table_name = 'Staging_Orders'

LEFT JOIN {schema_name}.Dim_SOR sor_order_details
    ON sor_order_details.staging_table_name = 'Staging_Order_Details'

WHERE o.OrderDate >= '{start_date}'
  AND o.OrderDate <= '{end_date}'
  AND (
      dc.Customer_SK IS NULL
      OR de.Employee_SK IS NULL
      OR dp.Product_SK IS NULL
      OR dship.Shipper_SK IS NULL
      OR dt.Territory_SK IS NULL
  );
