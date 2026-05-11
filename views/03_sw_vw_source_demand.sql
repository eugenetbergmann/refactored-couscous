-- SW_vw_Source_Demand
-- Adapter View: Filtered demand with exclusion reasons
-- SQL Server 2016 compatible, NOLOCK required

CREATE VIEW dbo.SW_vw_Source_Demand
AS
WITH Config AS (
    SELECT
        CAST(GETDATE() AS DATE) AS Today,
        DATEADD(DAY, -7, CAST(GETDATE() AS DATE)) AS StaleThreshold,
        DATEADD(DAY, 90, CAST(GETDATE() AS DATE)) AS DemandHorizon
),
SOPDemand AS (
    SELECT
        TRIM(s.ITEMNMBR) AS ITEMNMBR,
        CAST(s.DUEDATE AS DATE) AS DueDate,
        s.QTYORDER AS DemandQty,
        'SOP' AS DemandSource,
        TRIM(s.SALESORDLIN) AS SourceID,
        NULL AS FGItem,
        NULL AS Client,
        CASE
            WHEN s.DUEDATE < (SELECT StaleThreshold FROM Config) THEN 'STALE'
            WHEN s.DUEDATE > (SELECT DemandHorizon FROM Config) THEN 'FUTURE'
            ELSE NULL
        END AS FilterReason
    FROM dbo.SOP10200 s WITH (NOLOCK)
    WHERE s.QTYORDER > 0
),
MODemand AS (
    SELECT
        TRIM(w.ITEMNMBR) AS ITEMNMBR,
        CAST(w.DUEDATE AS DATE) AS DueDate,
        w.QTYORD AS DemandQty,
        'MO' AS DemandSource,
        TRIM(w.MANUFACTUREORDER_I) AS SourceID,
        TRIM(w.ITEMNMBR) AS FGItem,
        NULL AS Client,
        CASE
            WHEN w.WOSTAT = 3 THEN 'CANCELLED'
            WHEN w.DUEDATE < (SELECT StaleThreshold FROM Config) THEN 'STALE'
            ELSE NULL
        END AS FilterReason
    FROM dbo.WO010032 w WITH (NOLOCK)
    WHERE w.QTYORD > 0
       AND w.WOSTAT != 3
),
MRPDemand AS (
    SELECT
        TRIM(m.ITEMNMBR) AS ITEMNMBR,
        CAST(m.REQDATE AS DATE) AS DueDate,
        m.QTYREQ AS DemandQty,
        'MRP' AS DemandSource,
        TRIM(m.MANUFACTUREORDER_I) AS SourceID,
        NULL AS FGItem,
        NULL AS Client,
        CASE
            WHEN NOT EXISTS (
                SELECT 1 FROM dbo.WO010032 w
                WHERE TRIM(w.MANUFACTUREORDER_I) = TRIM(m.MANUFACTUREORDER_I)
            ) THEN 'MPK_NOISE'
            ELSE NULL
        END AS FilterReason
     FROM dbo.MRP1000 m WITH (NOLOCK)
    WHERE m.QTYREQ > 0
),
AllDemand AS (
    SELECT * FROM SOPDemand
    UNION ALL
    SELECT * FROM MODemand
    UNION ALL
    SELECT * FROM MRPDemand
)
SELECT
    ITEMNMBR,
    DueDate,
    DemandQty,
    DemandSource,
    SourceID,
    FGItem,
    Client,
    FilterReason,
    CASE WHEN ROW_NUMBER() OVER (
        PARTITION BY ITEMNMBR, DueDate, DemandQty, DemandSource
        ORDER BY SourceID
    ) > 1 THEN 'DUPLICATE' ELSE FilterReason END AS FinalFilterReason
FROM AllDemand;