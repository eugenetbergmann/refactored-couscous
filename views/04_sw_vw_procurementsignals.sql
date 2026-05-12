-- SW_vw_ProcurementSignals
-- Decision View: Running PAB, tier exhaustion, decision matrix, commercial overlay
-- SQL Server 2016 compatible, NOLOCK required, single-pass computation

CREATE VIEW dbo.SW_vw_ProcurementSignals
AS
WITH Config AS (
    SELECT
        CAST(GETDATE() AS DATE) AS Today,
        DATEADD(DAY, -7, CAST(GETDATE() AS DATE)) AS StaleThreshold
),
SupplyAgg AS (
    SELECT
        ITEMNMBR,
        SUM(CASE WHEN Tier = 1 THEN SupplyQty ELSE 0 END) AS Tier1_Total,
        SUM(CASE WHEN Tier = 2 AND IsCreditable = 1 THEN SupplyQty ELSE 0 END) AS Tier2_Creditable,
        SUM(CASE WHEN Tier = 3 AND IsCreditable = 1 THEN SupplyQty ELSE 0 END) AS Tier3_Creditable,
        SUM(CASE WHEN Tier = 4 THEN SupplyQty ELSE 0 END) AS Tier4_Total,
        MAX(CASE WHEN Tier = 3 AND EstimatedReleaseDate < (SELECT Today FROM Config)
            THEN 1 ELSE 0 END) AS WFQ_Overdue_Flag,
        MAX(CASE WHEN Tier = 2 AND ExpectedDate < (SELECT Today FROM Config) AND IsCreditable = 0
            THEN 1 ELSE 0 END) AS PastDue_PO_Flag,
        MAX(CASE WHEN Tier = 4 THEN 1 ELSE 0 END) AS CrossSuffix_Available
    FROM dbo.SW_vw_Source_Supply
    GROUP BY ITEMNMBR
),
DemandAgg AS (
    SELECT
        ITEMNMBR,
        SUM(CASE WHEN FinalFilterReason IS NULL THEN DemandQty ELSE 0 END) AS ActiveDemand,
        SUM(CASE WHEN FinalFilterReason = 'STALE' THEN DemandQty ELSE 0 END) AS StaleDemand,
        SUM(CASE WHEN FinalFilterReason = 'MPK_NOISE' THEN DemandQty ELSE 0 END) AS MPK_Demand,
        MAX(CASE WHEN FinalFilterReason = 'MPK_NOISE' THEN 1 ELSE 0 END) AS MPK_Noise_Flag
    FROM dbo.SW_vw_Source_Demand
    GROUP BY ITEMNMBR
),
Events AS (
    SELECT
        ITEMNMBR,
        ExpectedDate AS EventDate,
        SupplyQty AS EventQty,
        1 AS EventPriority,
        Tier,
        SupplyType,
        StateConfidence
    FROM dbo.SW_vw_Source_Supply
     WHERE IsCreditable = 1
    UNION ALL
    SELECT
        ITEMNMBR,
        DueDate AS EventDate,
        -DemandQty AS EventQty,
        2 AS EventPriority,
        99 AS Tier,
        'DEMAND' AS SupplyType,
        'HIGH' AS StateConfidence
    FROM dbo.SW_vw_Source_Demand
     WHERE FinalFilterReason IS NULL
),
RunningBalance AS (
    SELECT
        ITEMNMBR,
        EventDate,
        EventQty,
        EventPriority,
        Tier,
        SupplyType,
        StateConfidence,
        SUM(EventQty) OVER (
            PARTITION BY ITEMNMBR
            ORDER BY EventDate, EventPriority, SupplyType
            ROWS UNBOUNDED PRECEDING
        ) AS RunningPAB,
        ROW_NUMBER() OVER (
            PARTITION BY ITEMNMBR
            ORDER BY EventDate, EventPriority, SupplyType
        ) AS EventSequence
    FROM Events
),
MinPAB AS (
    SELECT
        ITEMNMBR,
        MIN(RunningPAB) AS Min_PAB,
        MAX(CASE WHEN RunningPAB < 0 THEN EventDate END) AS FirstStockoutDate,
        MAX(Tier) AS Max_Tier_Used
    FROM RunningBalance
    GROUP BY ITEMNMBR
),
Decision AS (
    SELECT
        i.ITEMNMBR,
        i.ITEMDESC,
        i.Base_ITEMNMBR,
        i.Suffix,
        i.RiskClass,
        i.SS_Qty,
        i.CommercialSignal,
        i.BatchCount,
        i.PRIME_VNDR,
        COALESCE(s.Tier1_Total, 0) AS Tier1_OnHand,
        COALESCE(s.Tier2_Creditable, 0) AS Tier2_InTransit,
        COALESCE(s.Tier3_Creditable, 0) AS Tier3_WFQ,
        COALESCE(s.Tier4_Total, 0) AS Tier4_CrossSuffix,
        COALESCE(d.ActiveDemand, 0) AS ActiveDemand,
        COALESCE(d.StaleDemand, 0) AS StaleDemand,
        COALESCE(d.MPK_Demand, 0) AS MPK_Demand,
        COALESCE(m.Min_PAB, 0) AS Min_PAB,
        m.FirstStockoutDate,
        COALESCE(m.Max_Tier_Used, 1) AS Max_Tier_Used,
        s.WFQ_Overdue_Flag,
        s.PastDue_PO_Flag,
        s.CrossSuffix_Available,
        d.MPK_Noise_Flag,
        CASE WHEN COALESCE(m.Min_PAB, 0) < 0 THEN 1 ELSE 0 END AS PhysicalShortage,
        CASE WHEN COALESCE(m.Min_PAB, 0) < i.SS_Qty THEN 1 ELSE 0 END AS SS_Breach,
        CASE
            WHEN COALESCE(m.Min_PAB, 0) >= i.SS_Qty THEN 'DO_NOTHING'
            WHEN COALESCE(m.Min_PAB, 0) >= 0 AND COALESCE(m.Max_Tier_Used, 1) <= 2
                 AND d.MPK_Noise_Flag = 0 AND i.BatchCount >= 5 THEN 'WAIT'
            WHEN COALESCE(m.Min_PAB, 0) >= 0 AND COALESCE(m.Max_Tier_Used, 1) <= 2 THEN 'INVESTIGATE'
            WHEN COALESCE(m.Min_PAB, 0) >= 0 AND COALESCE(m.Max_Tier_Used, 1) >= 3 THEN 'CHASE'
            ELSE 'BUY'
        END AS ProcurementDecision,
        CASE
            WHEN i.BatchCount < 5 THEN 'LOW'
            WHEN COALESCE(m.Max_Tier_Used, 1) >= 3 THEN 'LOW'
            WHEN d.MPK_Noise_Flag = 1 THEN 'LOW'
            WHEN s.PastDue_PO_Flag = 1 THEN 'LOW'
            ELSE 'HIGH'
        END AS SignalConfidence,
        CASE WHEN m.FirstStockoutDate IS NOT NULL
            THEN DATEDIFF(DAY, m.FirstStockoutDate, (SELECT Today FROM Config))
            ELSE NULL
        END AS DeficitAgeDays,
        'MinPAB=' + CAST(CAST(COALESCE(m.Min_PAB, 0) AS INT) AS VARCHAR)
            + ';SS=' + CAST(CAST(i.SS_Qty AS INT) AS VARCHAR)
            + ';Tier=' + CAST(COALESCE(m.Max_Tier_Used, 1) AS VARCHAR)
            + ';Hist=' + CAST(COALESCE(i.BatchCount, 0) AS VARCHAR)
            + ';MPK=' + CAST(COALESCE(d.MPK_Noise_Flag, 0) AS VARCHAR) AS DecisionRationale,
        (SELECT Today FROM Config) AS AsOfDate
    FROM dbo.ETB_ItemMaster i
    LEFT JOIN SupplyAgg s ON i.ITEMNMBR = s.ITEMNMBR
    LEFT JOIN DemandAgg d ON i.ITEMNMBR = d.ITEMNMBR
    LEFT JOIN MinPAB m ON i.ITEMNMBR = m.ITEMNMBR
)
SELECT * FROM Decision;