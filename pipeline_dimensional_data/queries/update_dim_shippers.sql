SET NOCOUNT ON;

MERGE dbo.DimShippers AS DST
USING (
    SELECT
        SRC.ShipperID AS ShipperID_NK,
        SRC.CompanyName,
        SRC.Phone,
        SOR.SOR_SK,
        SRC.staging_raw_id_sk
    FROM dbo.Staging_Shippers AS SRC
    JOIN dbo.Dim_SOR AS SOR
        ON SOR.staging_table_name = 'Staging_Shippers'
) AS SRC
ON SRC.ShipperID_NK = DST.ShipperID_NK
WHEN NOT MATCHED THEN
    INSERT (
        ShipperID_NK,
        CompanyName,
        Phone,
        SOR_SK,
        staging_raw_id_sk
    )
    VALUES (
        SRC.ShipperID_NK,
        SRC.CompanyName,
        SRC.Phone,
        SRC.SOR_SK,
        SRC.staging_raw_id_sk
    )
WHEN MATCHED AND (
       ISNULL(DST.CompanyName, '') <> ISNULL(SRC.CompanyName, '')
    OR ISNULL(DST.Phone, '') <> ISNULL(SRC.Phone, '')
    OR ISNULL(DST.SOR_SK, -1) <> ISNULL(SRC.SOR_SK, -1)
    OR ISNULL(DST.staging_raw_id_sk, -1) <> ISNULL(SRC.staging_raw_id_sk, -1)
)
THEN
    UPDATE SET
        DST.CompanyName = SRC.CompanyName,
        DST.Phone = SRC.Phone,
        DST.SOR_SK = SRC.SOR_SK,
        DST.staging_raw_id_sk = SRC.staging_raw_id_sk,
        DST.updated_at = SYSDATETIME();
