SET NOCOUNT ON;

-------------------------------------------------------------------------------
-- STEP 0: EXPIRE CUSTOMERS NO LONGER PRESENT IN SOURCE
-------------------------------------------------------------------------------
UPDATE DST
SET
    DST.effective_end_date = DATEADD(DAY, -1, CAST(GETDATE() AS DATE)),
    DST.is_current = 0
FROM dbo.DimCustomers AS DST
LEFT JOIN dbo.Staging_Customers AS SRC
    ON DST.CustomerID_NK = SRC.CustomerID
WHERE DST.is_current = 1
  AND SRC.CustomerID IS NULL;

-------------------------------------------------------------------------------
-- STEP 1: EXPIRE OLD RECORDS WHEN CUSTOMER DATA CHANGES
-------------------------------------------------------------------------------
UPDATE DST
SET
    DST.effective_end_date = DATEADD(DAY, -1, CAST(GETDATE() AS DATE)),
    DST.is_current = 0
FROM dbo.DimCustomers AS DST
JOIN dbo.Staging_Customers AS SRC
    ON DST.CustomerID_NK = SRC.CustomerID
   AND DST.is_current = 1
WHERE
       ISNULL(DST.CompanyName, '') <> ISNULL(SRC.CompanyName, '')
    OR ISNULL(DST.ContactName, '') <> ISNULL(SRC.ContactName, '')
    OR ISNULL(DST.ContactTitle, '') <> ISNULL(SRC.ContactTitle, '')
    OR ISNULL(DST.Address, '') <> ISNULL(SRC.Address, '')
    OR ISNULL(DST.City, '') <> ISNULL(SRC.City, '')
    OR ISNULL(DST.Region, '') <> ISNULL(SRC.Region, '')
    OR ISNULL(DST.PostalCode, '') <> ISNULL(SRC.PostalCode, '')
    OR ISNULL(DST.Country, '') <> ISNULL(SRC.Country, '')
    OR ISNULL(DST.Phone, '') <> ISNULL(SRC.Phone, '')
    OR ISNULL(DST.Fax, '') <> ISNULL(SRC.Fax, '');

-------------------------------------------------------------------------------
-- STEP 2: INSERT BRAND NEW CUSTOMERS
-------------------------------------------------------------------------------
INSERT INTO dbo.DimCustomers (
    CustomerID_NK,
    CompanyName,
    ContactName,
    ContactTitle,
    Address,
    City,
    Region,
    PostalCode,
    Country,
    Phone,
    Fax,
    SOR_SK,
    staging_raw_id_sk,
    effective_start_date,
    effective_end_date,
    is_current
)
SELECT
    SRC.CustomerID AS CustomerID_NK,
    SRC.CompanyName,
    SRC.ContactName,
    SRC.ContactTitle,
    SRC.Address,
    SRC.City,
    SRC.Region,
    SRC.PostalCode,
    SRC.Country,
    SRC.Phone,
    SRC.Fax,
    SOR.SOR_SK,
    SRC.staging_raw_id_sk,
    CAST(GETDATE() AS DATE) AS effective_start_date,
    NULL AS effective_end_date,
    1 AS is_current
FROM dbo.Staging_Customers AS SRC
JOIN dbo.Dim_SOR AS SOR
    ON SOR.staging_table_name = 'Staging_Customers'
LEFT JOIN dbo.DimCustomers AS EXISTING
    ON SRC.CustomerID = EXISTING.CustomerID_NK
WHERE EXISTING.CustomerID_NK IS NULL;

-------------------------------------------------------------------------------
-- STEP 3: INSERT UPDATED CUSTOMERS AS NEW CURRENT VERSION
-------------------------------------------------------------------------------
INSERT INTO dbo.DimCustomers (
    CustomerID_NK,
    CompanyName,
    ContactName,
    ContactTitle,
    Address,
    City,
    Region,
    PostalCode,
    Country,
    Phone,
    Fax,
    SOR_SK,
    staging_raw_id_sk,
    effective_start_date,
    effective_end_date,
    is_current
)
SELECT
    SRC.CustomerID AS CustomerID_NK,
    SRC.CompanyName,
    SRC.ContactName,
    SRC.ContactTitle,
    SRC.Address,
    SRC.City,
    SRC.Region,
    SRC.PostalCode,
    SRC.Country,
    SRC.Phone,
    SRC.Fax,
    SOR.SOR_SK,
    SRC.staging_raw_id_sk,
    CAST(GETDATE() AS DATE) AS effective_start_date,
    NULL AS effective_end_date,
    1 AS is_current
FROM dbo.Staging_Customers AS SRC
JOIN dbo.Dim_SOR AS SOR
    ON SOR.staging_table_name = 'Staging_Customers'
JOIN (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY CustomerID_NK
            ORDER BY effective_end_date DESC, Customer_SK DESC
        ) AS rn
    FROM dbo.DimCustomers
    WHERE is_current = 0
) AS EXPIRED
    ON SRC.CustomerID = EXPIRED.CustomerID_NK
LEFT JOIN dbo.DimCustomers AS CURRENT_DST
    ON SRC.CustomerID = CURRENT_DST.CustomerID_NK
   AND CURRENT_DST.is_current = 1
WHERE EXPIRED.rn = 1
  AND CURRENT_DST.CustomerID_NK IS NULL
  AND (
       ISNULL(EXPIRED.CompanyName, '') <> ISNULL(SRC.CompanyName, '')
    OR ISNULL(EXPIRED.ContactName, '') <> ISNULL(SRC.ContactName, '')
    OR ISNULL(EXPIRED.ContactTitle, '') <> ISNULL(SRC.ContactTitle, '')
    OR ISNULL(EXPIRED.Address, '') <> ISNULL(SRC.Address, '')
    OR ISNULL(EXPIRED.City, '') <> ISNULL(SRC.City, '')
    OR ISNULL(EXPIRED.Region, '') <> ISNULL(SRC.Region, '')
    OR ISNULL(EXPIRED.PostalCode, '') <> ISNULL(SRC.PostalCode, '')
    OR ISNULL(EXPIRED.Country, '') <> ISNULL(SRC.Country, '')
    OR ISNULL(EXPIRED.Phone, '') <> ISNULL(SRC.Phone, '')
    OR ISNULL(EXPIRED.Fax, '') <> ISNULL(SRC.Fax, '')
  );
