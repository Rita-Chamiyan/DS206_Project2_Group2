SET NOCOUNT ON;

-------------------------------------------------------------------------------
-- STEP 0: EXPIRE PRODUCTS NO LONGER PRESENT IN SOURCE
-------------------------------------------------------------------------------
UPDATE DST
SET
    DST.effective_end_date = DATEADD(DAY, -1, CAST(GETDATE() AS DATE)),
    DST.is_current = 0,
    DST.is_deleted = 1
FROM dbo.DimProducts AS DST
LEFT JOIN dbo.Staging_Products AS SRC
    ON DST.ProductID_NK = SRC.ProductID
WHERE DST.is_current = 1
  AND SRC.ProductID IS NULL;

-------------------------------------------------------------------------------
-- STEP 1: EXPIRE OLD RECORDS WHEN PRODUCT DATA CHANGES
-------------------------------------------------------------------------------
UPDATE DST
SET
    DST.effective_end_date = DATEADD(DAY, -1, CAST(GETDATE() AS DATE)),
    DST.is_current = 0
FROM dbo.DimProducts AS DST
JOIN dbo.Staging_Products AS SRC
    ON DST.ProductID_NK = SRC.ProductID
   AND DST.is_current = 1
WHERE
       ISNULL(DST.ProductName, '') <> ISNULL(SRC.ProductName, '')
    OR ISNULL(DST.SupplierID, -1) <> ISNULL(SRC.SupplierID, -1)
    OR ISNULL(DST.CategoryID, -1) <> ISNULL(SRC.CategoryID, -1)
    OR ISNULL(DST.QuantityPerUnit, '') <> ISNULL(SRC.QuantityPerUnit, '')
    OR ISNULL(DST.UnitPrice, -1) <> ISNULL(SRC.UnitPrice, -1)
    OR ISNULL(DST.UnitsInStock, -1) <> ISNULL(SRC.UnitsInStock, -1)
    OR ISNULL(DST.UnitsOnOrder, -1) <> ISNULL(SRC.UnitsOnOrder, -1)
    OR ISNULL(DST.ReorderLevel, -1) <> ISNULL(SRC.ReorderLevel, -1)
    OR ISNULL(DST.Discontinued, 0) <> ISNULL(SRC.Discontinued, 0);

-------------------------------------------------------------------------------
-- STEP 2: INSERT BRAND NEW PRODUCTS
-------------------------------------------------------------------------------
INSERT INTO dbo.DimProducts (
    ProductID_NK,
    ProductName,
    SupplierID,
    CategoryID,
    QuantityPerUnit,
    UnitPrice,
    UnitsInStock,
    UnitsOnOrder,
    ReorderLevel,
    Discontinued,
    SOR_SK,
    staging_raw_id_sk,
    effective_start_date,
    effective_end_date,
    is_current,
    is_deleted
)
SELECT
    SRC.ProductID AS ProductID_NK,
    SRC.ProductName,
    SRC.SupplierID,
    SRC.CategoryID,
    SRC.QuantityPerUnit,
    SRC.UnitPrice,
    SRC.UnitsInStock,
    SRC.UnitsOnOrder,
    SRC.ReorderLevel,
    SRC.Discontinued,
    SOR.SOR_SK,
    SRC.staging_raw_id_sk,
    CAST(GETDATE() AS DATE) AS effective_start_date,
    NULL AS effective_end_date,
    1 AS is_current,
    0 AS is_deleted
FROM dbo.Staging_Products AS SRC
JOIN dbo.Dim_SOR AS SOR
    ON SOR.staging_table_name = 'Staging_Products'
LEFT JOIN dbo.DimProducts AS EXISTING
    ON SRC.ProductID = EXISTING.ProductID_NK
WHERE EXISTING.ProductID_NK IS NULL;

-------------------------------------------------------------------------------
-- STEP 3: INSERT UPDATED PRODUCTS AS NEW CURRENT VERSION
-------------------------------------------------------------------------------
INSERT INTO dbo.DimProducts (
    ProductID_NK,
    ProductName,
    SupplierID,
    CategoryID,
    QuantityPerUnit,
    UnitPrice,
    UnitsInStock,
    UnitsOnOrder,
    ReorderLevel,
    Discontinued,
    SOR_SK,
    staging_raw_id_sk,
    effective_start_date,
    effective_end_date,
    is_current,
    is_deleted
)
SELECT
    SRC.ProductID AS ProductID_NK,
    SRC.ProductName,
    SRC.SupplierID,
    SRC.CategoryID,
    SRC.QuantityPerUnit,
    SRC.UnitPrice,
    SRC.UnitsInStock,
    SRC.UnitsOnOrder,
    SRC.ReorderLevel,
    SRC.Discontinued,
    SOR.SOR_SK,
    SRC.staging_raw_id_sk,
    CAST(GETDATE() AS DATE) AS effective_start_date,
    NULL AS effective_end_date,
    1 AS is_current,
    0 AS is_deleted
FROM dbo.Staging_Products AS SRC
JOIN dbo.Dim_SOR AS SOR
    ON SOR.staging_table_name = 'Staging_Products'
JOIN (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY ProductID_NK
            ORDER BY effective_end_date DESC, Product_SK DESC
        ) AS rn
    FROM dbo.DimProducts
    WHERE is_current = 0
) AS EXPIRED
    ON SRC.ProductID = EXPIRED.ProductID_NK
LEFT JOIN dbo.DimProducts AS CURRENT_DST
    ON SRC.ProductID = CURRENT_DST.ProductID_NK
   AND CURRENT_DST.is_current = 1
WHERE EXPIRED.rn = 1
  AND CURRENT_DST.ProductID_NK IS NULL
  AND (
       ISNULL(EXPIRED.ProductName, '') <> ISNULL(SRC.ProductName, '')
    OR ISNULL(EXPIRED.SupplierID, -1) <> ISNULL(SRC.SupplierID, -1)
    OR ISNULL(EXPIRED.CategoryID, -1) <> ISNULL(SRC.CategoryID, -1)
    OR ISNULL(EXPIRED.QuantityPerUnit, '') <> ISNULL(SRC.QuantityPerUnit, '')
    OR ISNULL(EXPIRED.UnitPrice, -1) <> ISNULL(SRC.UnitPrice, -1)
    OR ISNULL(EXPIRED.UnitsInStock, -1) <> ISNULL(SRC.UnitsInStock, -1)
    OR ISNULL(EXPIRED.UnitsOnOrder, -1) <> ISNULL(SRC.UnitsOnOrder, -1)
    OR ISNULL(EXPIRED.ReorderLevel, -1) <> ISNULL(SRC.ReorderLevel, -1)
    OR ISNULL(EXPIRED.Discontinued, 0) <> ISNULL(SRC.Discontinued, 0)
  );
