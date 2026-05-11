-- SW_vw_EventTrace
-- Audit View: Event-level decomposition for investigation
-- SQL Server 2016 compatible, NOLOCK required

CREATE VIEW dbo.SW_vw_EventTrace
AS
WITH Config AS (
    SELECT CAST(GETDATE() AS DATE) AS Today
),
Events AS (
    SELECT
        ITEMNMBR,
        ExpectedDate AS EventDate,
        SupplyQty AS EventQty,
        1 AS EventPriority,
        Tier,
        SupplyType,
        StateConfidence,
        IsCreditable
    FROM dbo.SW_vw_Source_Supply
    UNION ALL
    SELECT
        ITEMNMBR,
        DueDate AS EventDate,
        -DemandQty AS EventQty,
        2 AS EventPriority,
        99 AS Tier,
        'DEMAND' AS SupplyType,
        'HIGH' AS StateConfidence,
        1 AS IsCreditable
    FROM dbo.SW_vw_Source_Demand
    WHERE FinalFilterReason IS NULL
)
SELECT
    ITEMNMBR,
    EventDate,
    EventQty,
    EventPriority,
    Tier,
    SupplyType,
    StateConfidence,
    IsCreditable,
    SUM(EventQty) OVER (
        PARTITION BY ITEMNMBR
        ORDER BY EventDate, EventPriority, SupplyType
        ROWS UNBOUNDED PRECEDING
    ) AS RunningPAB,
    ROW_NUMBER() OVER (
        PARTITION BY ITEMNMBR
        ORDER BY EventDate, EventPriority, SupplyType
    ) AS EventSequence
FROM Events;