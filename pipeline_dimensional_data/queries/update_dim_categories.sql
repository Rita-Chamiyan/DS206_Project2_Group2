SET NOCOUNT ON;

MERGE dbo.DimCategories AS DST
USING (
    SELECT
        SRC.CategoryID AS CategoryID_NK,
        SRC.CategoryName,
        SRC.Description,
        SOR.SOR_SK,
        SRC.staging_raw_id_sk
    FROM dbo.Staging_Categories AS SRC
    JOIN dbo.Dim_SOR AS SOR
        ON SOR.staging_table_name = 'Staging_Categories'
) AS SRC
ON SRC.CategoryID_NK = DST.CategoryID_NK
WHEN NOT MATCHED THEN
    INSERT (
        CategoryID_NK,
        CategoryName,
        Description,
        SOR_SK,
        staging_raw_id_sk,
        is_deleted
    )
    VALUES (
        SRC.CategoryID_NK,
        SRC.CategoryName,
        SRC.Description,
        SRC.SOR_SK,
        SRC.staging_raw_id_sk,
        0
    )
WHEN MATCHED AND (
       ISNULL(DST.CategoryName, '') <> ISNULL(SRC.CategoryName, '')
    OR ISNULL(DST.Description, '') <> ISNULL(SRC.Description, '')
    OR ISNULL(DST.SOR_SK, -1) <> ISNULL(SRC.SOR_SK, -1)
    OR ISNULL(DST.staging_raw_id_sk, -1) <> ISNULL(SRC.staging_raw_id_sk, -1)
    OR ISNULL(DST.is_deleted, 0) <> 0
)
THEN
    UPDATE SET
        DST.CategoryName = SRC.CategoryName,
        DST.Description = SRC.Description,
        DST.SOR_SK = SRC.SOR_SK,
        DST.staging_raw_id_sk = SRC.staging_raw_id_sk,
        DST.is_deleted = 0,
        DST.updated_at = SYSDATETIME();

UPDATE DST
SET
    DST.is_deleted = 1,
    DST.updated_at = SYSDATETIME()
FROM dbo.DimCategories AS DST
LEFT JOIN dbo.Staging_Categories AS SRC
    ON DST.CategoryID_NK = SRC.CategoryID
WHERE SRC.CategoryID IS NULL;
