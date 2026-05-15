SET NOCOUNT ON;

-------------------------------------------------------------------------------
-- STEP 0: STORE OLD SUPPLIER VALUES IN HISTORY TABLE BEFORE OVERWRITE
-------------------------------------------------------------------------------
INSERT INTO dbo.DimSuppliersHistory (
    SupplierID_NK,
    old_CompanyName,
    old_ContactName,
    old_Phone,
    changed_at
)
SELECT
    DST.SupplierID_NK,
    DST.CompanyName,
    DST.ContactName,
    DST.Phone,
    SYSDATETIME()
FROM dbo.DimSuppliers AS DST
JOIN dbo.Staging_Suppliers AS SRC
    ON DST.SupplierID_NK = SRC.SupplierID
WHERE
       ISNULL(DST.CompanyName, '') <> ISNULL(SRC.CompanyName, '')
    OR ISNULL(DST.ContactName, '') <> ISNULL(SRC.ContactName, '')
    OR ISNULL(DST.Phone, '') <> ISNULL(SRC.Phone, '');

-------------------------------------------------------------------------------
-- STEP 1: TYPE 1 OVERWRITE CURRENT SUPPLIER VALUES
-------------------------------------------------------------------------------
MERGE dbo.DimSuppliers AS DST
USING (
    SELECT
        SRC.SupplierID AS SupplierID_NK,
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
        SRC.HomePage,
        SOR.SOR_SK,
        SRC.staging_raw_id_sk
    FROM dbo.Staging_Suppliers AS SRC
    JOIN dbo.Dim_SOR AS SOR
        ON SOR.staging_table_name = 'Staging_Suppliers'
) AS SRC
ON SRC.SupplierID_NK = DST.SupplierID_NK
WHEN NOT MATCHED THEN
    INSERT (
        SupplierID_NK,
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
        HomePage,
        SOR_SK,
        staging_raw_id_sk
    )
    VALUES (
        SRC.SupplierID_NK,
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
        SRC.HomePage,
        SRC.SOR_SK,
        SRC.staging_raw_id_sk
    )
WHEN MATCHED AND (
       ISNULL(DST.CompanyName, '') <> ISNULL(SRC.CompanyName, '')
    OR ISNULL(DST.ContactName, '') <> ISNULL(SRC.ContactName, '')
    OR ISNULL(DST.ContactTitle, '') <> ISNULL(SRC.ContactTitle, '')
    OR ISNULL(DST.Address, '') <> ISNULL(SRC.Address, '')
    OR ISNULL(DST.City, '') <> ISNULL(SRC.City, '')
    OR ISNULL(DST.Region, '') <> ISNULL(SRC.Region, '')
    OR ISNULL(DST.PostalCode, '') <> ISNULL(SRC.PostalCode, '')
    OR ISNULL(DST.Country, '') <> ISNULL(SRC.Country, '')
    OR ISNULL(DST.Phone, '') <> ISNULL(SRC.Phone, '')
    OR ISNULL(DST.Fax, '') <> ISNULL(SRC.Fax, '')
    OR ISNULL(DST.HomePage, '') <> ISNULL(SRC.HomePage, '')
    OR ISNULL(DST.SOR_SK, -1) <> ISNULL(SRC.SOR_SK, -1)
    OR ISNULL(DST.staging_raw_id_sk, -1) <> ISNULL(SRC.staging_raw_id_sk, -1)
)
THEN
    UPDATE SET
        DST.CompanyName = SRC.CompanyName,
        DST.ContactName = SRC.ContactName,
        DST.ContactTitle = SRC.ContactTitle,
        DST.Address = SRC.Address,
        DST.City = SRC.City,
        DST.Region = SRC.Region,
        DST.PostalCode = SRC.PostalCode,
        DST.Country = SRC.Country,
        DST.Phone = SRC.Phone,
        DST.Fax = SRC.Fax,
        DST.HomePage = SRC.HomePage,
        DST.SOR_SK = SRC.SOR_SK,
        DST.staging_raw_id_sk = SRC.staging_raw_id_sk,
        DST.updated_at = SYSDATETIME();
