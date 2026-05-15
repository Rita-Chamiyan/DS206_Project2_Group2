SET NOCOUNT ON;

MERGE dbo.DimTerritories AS DST
USING (
    SELECT
        SRC.TerritoryID AS TerritoryID_NK,
        SRC.TerritoryDescription,
        SRC.RegionID AS CurrentRegionID,
        SOR.SOR_SK,
        SRC.staging_raw_id_sk
    FROM dbo.Staging_Territories AS SRC
    JOIN dbo.Dim_SOR AS SOR
        ON SOR.staging_table_name = 'Staging_Territories'
) AS SRC
ON SRC.TerritoryID_NK = DST.TerritoryID_NK
WHEN NOT MATCHED THEN
    INSERT (
        TerritoryID_NK,
        TerritoryDescription,
        CurrentRegionID,
        PriorRegionID,
        SOR_SK,
        staging_raw_id_sk
    )
    VALUES (
        SRC.TerritoryID_NK,
        SRC.TerritoryDescription,
        SRC.CurrentRegionID,
        NULL,
        SRC.SOR_SK,
        SRC.staging_raw_id_sk
    )
WHEN MATCHED AND (
       ISNULL(DST.TerritoryDescription, '') <> ISNULL(SRC.TerritoryDescription, '')
    OR ISNULL(DST.CurrentRegionID, -1) <> ISNULL(SRC.CurrentRegionID, -1)
    OR ISNULL(DST.SOR_SK, -1) <> ISNULL(SRC.SOR_SK, -1)
    OR ISNULL(DST.staging_raw_id_sk, -1) <> ISNULL(SRC.staging_raw_id_sk, -1)
)
THEN
    UPDATE SET
        DST.TerritoryDescription = SRC.TerritoryDescription,
        DST.PriorRegionID =
            CASE
                WHEN ISNULL(DST.CurrentRegionID, -1) <> ISNULL(SRC.CurrentRegionID, -1)
                THEN DST.CurrentRegionID
                ELSE DST.PriorRegionID
            END,
        DST.CurrentRegionID = SRC.CurrentRegionID,
        DST.SOR_SK = SRC.SOR_SK,
        DST.staging_raw_id_sk = SRC.staging_raw_id_sk,
        DST.updated_at = SYSDATETIME();
