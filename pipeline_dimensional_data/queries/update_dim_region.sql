SET NOCOUNT ON;

MERGE dbo.DimRegion AS DST
USING (
    SELECT
        SRC.RegionID AS RegionID_NK,
        SRC.RegionDescription,
        SOR.SOR_SK,
        SRC.staging_raw_id_sk
    FROM dbo.Staging_Region AS SRC
    JOIN dbo.Dim_SOR AS SOR
        ON SOR.staging_table_name = 'Staging_Region'
) AS SRC
ON SRC.RegionID_NK = DST.RegionID_NK
WHEN NOT MATCHED THEN
    INSERT (
        RegionID_NK,
        RegionDescription,
        SOR_SK,
        staging_raw_id_sk
    )
    VALUES (
        SRC.RegionID_NK,
        SRC.RegionDescription,
        SRC.SOR_SK,
        SRC.staging_raw_id_sk
    )
WHEN MATCHED AND (
       ISNULL(DST.RegionDescription, '') <> ISNULL(SRC.RegionDescription, '')
    OR ISNULL(DST.SOR_SK, -1) <> ISNULL(SRC.SOR_SK, -1)
    OR ISNULL(DST.staging_raw_id_sk, -1) <> ISNULL(SRC.staging_raw_id_sk, -1)
)
THEN
    UPDATE SET
        DST.RegionDescription = SRC.RegionDescription,
        DST.SOR_SK = SRC.SOR_SK,
        DST.staging_raw_id_sk = SRC.staging_raw_id_sk,
        DST.updated_at = SYSDATETIME();
