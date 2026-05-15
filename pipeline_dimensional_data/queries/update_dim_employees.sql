SET NOCOUNT ON;

MERGE dbo.DimEmployees AS DST
USING (
    SELECT
        SRC.EmployeeID AS EmployeeID_NK,
        SRC.LastName,
        SRC.FirstName,
        SRC.Title,
        SRC.BirthDate,
        SRC.HireDate,
        SRC.ReportsTo,
        SOR.SOR_SK,
        SRC.staging_raw_id_sk
    FROM dbo.Staging_Employees AS SRC
    JOIN dbo.Dim_SOR AS SOR
        ON SOR.staging_table_name = 'Staging_Employees'
) AS SRC
ON SRC.EmployeeID_NK = DST.EmployeeID_NK
WHEN NOT MATCHED THEN
    INSERT (
        EmployeeID_NK,
        LastName,
        FirstName,
        Title,
        BirthDate,
        HireDate,
        ReportsTo,
        SOR_SK,
        staging_raw_id_sk,
        is_deleted
    )
    VALUES (
        SRC.EmployeeID_NK,
        SRC.LastName,
        SRC.FirstName,
        SRC.Title,
        SRC.BirthDate,
        SRC.HireDate,
        SRC.ReportsTo,
        SRC.SOR_SK,
        SRC.staging_raw_id_sk,
        0
    )
WHEN MATCHED AND (
       ISNULL(DST.LastName, '') <> ISNULL(SRC.LastName, '')
    OR ISNULL(DST.FirstName, '') <> ISNULL(SRC.FirstName, '')
    OR ISNULL(DST.Title, '') <> ISNULL(SRC.Title, '')
    OR ISNULL(DST.BirthDate, '19000101') <> ISNULL(SRC.BirthDate, '19000101')
    OR ISNULL(DST.HireDate, '19000101') <> ISNULL(SRC.HireDate, '19000101')
    OR ISNULL(DST.ReportsTo, -1) <> ISNULL(SRC.ReportsTo, -1)
    OR ISNULL(DST.SOR_SK, -1) <> ISNULL(SRC.SOR_SK, -1)
    OR ISNULL(DST.staging_raw_id_sk, -1) <> ISNULL(SRC.staging_raw_id_sk, -1)
    OR ISNULL(DST.is_deleted, 0) <> 0
)
THEN
    UPDATE SET
        DST.LastName = SRC.LastName,
        DST.FirstName = SRC.FirstName,
        DST.Title = SRC.Title,
        DST.BirthDate = SRC.BirthDate,
        DST.HireDate = SRC.HireDate,
        DST.ReportsTo = SRC.ReportsTo,
        DST.SOR_SK = SRC.SOR_SK,
        DST.staging_raw_id_sk = SRC.staging_raw_id_sk,
        DST.is_deleted = 0,
        DST.updated_at = SYSDATETIME();

UPDATE DST
SET
    DST.is_deleted = 1,
    DST.updated_at = SYSDATETIME()
FROM dbo.DimEmployees AS DST
LEFT JOIN dbo.Staging_Employees AS SRC
    ON DST.EmployeeID_NK = SRC.EmployeeID
WHERE SRC.EmployeeID IS NULL;
