-- ETB_ItemMaster
-- Adapter View: Item master with consumption statistics and risk classification
-- SQL Server 2016 compatible, NOLOCK required

ALTER VIEW dbo.ETB_ItemMaster
AS
WITH ConsumptionHistory AS (
    SELECT
        TRIM(a.ITEMNMBR) AS ITEMNMBR,
        CAST(a.MRPISSUEDATE_I AS DATE) AS TxnDate,
        ABS(a.QTY_ISSUED_I + a.QTY_BACKFLUSHED_I) AS ConsumptionQty,
        TRIM(a.MANUFACTUREORDER_I) AS MO_Number
    FROM dbo.PK010033 a WITH (NOLOCK)
    JOIN dbo.WO010032 w WITH (NOLOCK)
        ON TRIM(w.MANUFACTUREORDER_I) = TRIM(a.MANUFACTUREORDER_I)
     WHERE w.MANUFACTUREORDERST_I NOT IN (2, 3)
      AND a.QTY_ISSUED_I + a.QTY_BACKFLUSHED_I > 0
      AND CAST(a.MRPISSUEDATE_I AS DATE) >= DATEADD(DAY, -365, CAST(GETDATE() AS DATE))
),
ConsumptionStats AS (
    SELECT
        ITEMNMBR,
        COUNT(DISTINCT MO_Number) AS BatchCount,
        AVG(ConsumptionQty) AS AvgConsumption,
        STDEV(ConsumptionQty) AS StdevConsumption,
        MAX(ConsumptionQty) AS MaxConsumption,
        MIN(ConsumptionQty) AS MinConsumption
    FROM ConsumptionHistory
    GROUP BY ITEMNMBR
),
PercentileStats AS (
    SELECT DISTINCT
        ITEMNMBR,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY ConsumptionQty)
            OVER (PARTITION BY ITEMNMBR) AS P75Consumption,
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY ConsumptionQty)
            OVER (PARTITION BY ITEMNMBR) AS P95Consumption
    FROM ConsumptionHistory
),
ConsumptionStatsWithPercentiles AS (
    SELECT
        cs.ITEMNMBR,
        cs.BatchCount,
        cs.AvgConsumption,
        cs.StdevConsumption,
        cs.MaxConsumption,
        ps.P75Consumption,
        ps.P95Consumption
    FROM ConsumptionStats cs
    LEFT JOIN PercentileStats ps ON cs.ITEMNMBR = ps.ITEMNMBR
),
ItemBase AS (
    SELECT
        TRIM(i.ITEMNMBR) AS ITEMNMBR,
        TRIM(i.ITEMDESC) AS ITEMDESC,
        TRIM(i.ITMCLSCD) AS ITMCLSCD,
        TRIM(i.UOMSCHDL) AS UOM,
        LEFT(TRIM(i.ITEMNMBR),
             LEN(TRIM(i.ITEMNMBR)) - CHARINDEX('.', REVERSE(TRIM(i.ITEMNMBR)))) AS Base_ITEMNMBR,
        RIGHT(TRIM(i.ITEMNMBR),
              CHARINDEX('.', REVERSE(TRIM(i.ITEMNMBR))) - 1) AS Suffix,
        COALESCE(q.QTYONHND, 0) AS QtyOnHand,
        COALESCE(q.QTYONORD, 0) AS QtyOnOrder,
        COALESCE(q.QTYBKORD, 0) AS QtyBackOrdered,
        COALESCE(v.[Vendor ID], 'UNASSIGNED') AS PRIME_VNDR,
        csp.BatchCount,
        csp.AvgConsumption,
        csp.StdevConsumption,
        csp.MaxConsumption,
        csp.P75Consumption,
        csp.P95Consumption,
        CASE
            WHEN csp.BatchCount IS NULL OR csp.BatchCount < 3 THEN 'NEW'
            WHEN csp.StdevConsumption / NULLIF(csp.AvgConsumption, 0) >= 0.40 THEN 'VOLATILE'
            WHEN csp.StdevConsumption / NULLIF(csp.AvgConsumption, 0) >= 0.15 THEN 'MODERATE'
            ELSE 'STABLE'
        END AS RiskClass,
        CASE
            WHEN csp.BatchCount IS NULL OR csp.BatchCount < 5
                 THEN COALESCE(csp.MaxConsumption, 0) * 1.5
            WHEN csp.StdevConsumption / NULLIF(csp.AvgConsumption, 0) >= 0.40
                THEN COALESCE(csp.P95Consumption, 0)
            ELSE COALESCE(csp.P75Consumption, 0)
        END AS SS_Qty,
        CASE WHEN csp.AvgConsumption > q.QTYONHND * 2.0 THEN 'CRITICAL'
             WHEN csp.AvgConsumption > q.QTYONHND * 1.5 THEN 'WARNING'
             WHEN csp.StdevConsumption / NULLIF(csp.AvgConsumption, 0) > 0.4 THEN 'VOLATILE'
             ELSE 'ADEQUATE' END AS CommercialSignal,
        CAST(GETDATE() AS DATE) AS AsOfDate
    FROM dbo.IV00101 i WITH (NOLOCK)
    LEFT JOIN dbo.IV00102 q WITH (NOLOCK)
        ON TRIM(i.ITEMNMBR) = TRIM(q.ITEMNMBR)
    LEFT JOIN dbo.Prosenthal_Vendor_Items v WITH (NOLOCK)
        ON TRIM(i.ITEMNMBR) = TRIM(v.[Item Number])
    LEFT JOIN ConsumptionStatsWithPercentiles csp
        ON TRIM(i.ITEMNMBR) = csp.ITEMNMBR
     WHERE i.ITEMNMBR NOT LIKE '20%'
       AND i.ITEMNMBR NOT LIKE '15%'
)
SELECT * FROM ItemBase;