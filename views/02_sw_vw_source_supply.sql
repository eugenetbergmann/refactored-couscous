-- SW_vw_Source_Supply
-- Adapter View: 4-tier supply hierarchy with credibility flags
-- SQL Server 2016 compatible, NOLOCK required

CREATE VIEW dbo.SW_vw_Source_Supply
AS
WITH Config AS (
    SELECT
        CAST(GETDATE() AS DATE) AS Today,
        DATEADD(DAY, -7, CAST(GETDATE() AS DATE)) AS StaleThreshold,
        DATEADD(DAY, 30, CAST(GETDATE() AS DATE)) AS PlanningHorizon,
        'QC-%' AS QuarLocationPattern,
        14 AS WFQReleaseDays
),
Tier1_OnHand AS (
    SELECT
        TRIM(q.ITEMNMBR) AS ITEMNMBR,
        TRIM(q.LOCNCODE) AS LOCNCODE,
        q.QTYONHND AS SupplyQty,
        CAST(GETDATE() AS DATE) AS ExpectedDate,
        1 AS Tier,
        'HIGH' AS StateConfidence,
        'ON_HAND' AS SupplyType,
        NULL AS LotNumber,
        NULL AS EstimatedReleaseDate,
        1 AS IsCreditable
    FROM dbo.IV00102 q WITH (NOLOCK)
    WHERE q.QTYONHND > 0
),
Tier2_InTransit AS (
    SELECT
        TRIM(p.ITEMNMBR) AS ITEMNMBR,
        'INTRANSIT' AS LOCNCODE,
        (p.QTYORDER - COALESCE(r.QTYSHPPD, 0)) AS SupplyQty,
        CASE
            WHEN p.PROMDATE IS NULL OR p.PROMDATE = '1900-01-01' THEN NULL
            ELSE p.PROMDATE
        END AS ExpectedDate,
        2 AS Tier,
        CASE WHEN p.PROMDATE IS NULL OR p.PROMDATE = '1900-01-01' THEN 'LOW'
              WHEN p.PROMDATE < (SELECT Today FROM Config) THEN 'LOW'
             ELSE 'HIGH' END AS StateConfidence,
        'IN_TRANSIT' AS SupplyType,
        NULL AS LotNumber,
        NULL AS EstimatedReleaseDate,
        CASE WHEN p.PROMDATE >= (SELECT Today FROM Config) THEN 1 ELSE 0 END AS IsCreditable
    FROM dbo.POP10100 p WITH (NOLOCK)
    LEFT JOIN dbo.POP10500 r WITH (NOLOCK) ON p.PONUMBER = r.PONUMBER
    WHERE p.PSTATUS NOT IN ('CANCELLED', 'CLOSED')
      AND (p.QTYORDER - COALESCE(r.QTYSHPPD, 0)) > 0
),
Tier3_Quarantine AS (
    SELECT
        TRIM(iv.ITEMNMBR) AS ITEMNMBR,
        TRIM(iv.LOCNCODE) AS LOCNCODE,
        SUM(iv.TRXQTY) AS SupplyQty,
        MAX(iv.TRXDATE) AS ReceiptDate,
        3 AS Tier,
        'MEDIUM' AS StateConfidence,
        'QUARANTINE' AS SupplyType,
        TRIM(iv.LOTNUMBR) AS LotNumber,
        DATEADD(DAY, (SELECT WFQReleaseDays FROM Config), MAX(iv.TRXDATE)) AS EstimatedReleaseDate,
        CASE WHEN DATEADD(DAY, (SELECT WFQReleaseDays FROM Config), MAX(iv.TRXDATE))
                  <= (SELECT PlanningHorizon FROM Config)
             THEN 1 ELSE 0 END AS IsCreditable
    FROM dbo.IV00300 iv WITH (NOLOCK)
    CROSS JOIN Config c
    WHERE iv.LOCNCODE LIKE c.QuarLocationPattern
      AND iv.TRXDATE >= DATEADD(DAY, -90, c.Today)
    GROUP BY iv.ITEMNMBR, iv.LOCNCODE
    HAVING SUM(iv.TRXQTY) > 0
),
Tier4_CrossSuffix AS (
    SELECT
        i.ITEMNMBR AS ITEMNMBR,
        alt.ITEMNMBR AS CrossSuffix_ITEMNMBR,
        alt.QtyOnHand AS SupplyQty,
        CAST(GETDATE() AS DATE) AS ExpectedDate,
        4 AS Tier,
        'LOW' AS StateConfidence,
        'CROSS_SUFFIX' AS SupplyType,
        NULL AS LotNumber,
        NULL AS EstimatedReleaseDate,
        0 AS IsCreditable
    FROM dbo.SW_vw_Source_ItemMaster i
    JOIN dbo.SW_vw_Source_ItemMaster alt
        ON i.Base_ITEMNMBR = alt.Base_ITEMNMBR
        AND i.ITEMNMBR != alt.ITEMNMBR
    WHERE alt.QtyOnHand > 0
)
SELECT * FROM Tier1_OnHand
UNION ALL
SELECT * FROM Tier2_InTransit
UNION ALL
SELECT * FROM Tier3_Quarantine
UNION ALL
SELECT * FROM Tier4_CrossSuffix;