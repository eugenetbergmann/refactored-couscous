-- Phase 3: Parallel Run
-- Weeks 3-4 tasks
--
-- Daily execution:
--  1. Run SW_vw_ProcurementSignals
--  2. Compare decision distributions (V10)
--  3. Investigate deltas > 5%

-- Comparison query template:
SELECT 
    sw.ITEMNMBR,
    sw.Min_PAB AS SW_MinPAB,
    etb.RunBal AS ETB_RunBal,
    ABS(sw.Min_PAB - etb.RunBal) / NULLIF(ABS(etb.RunBal), 0) AS DeltaPct
FROM SW_vw_ProcurementSignals sw
JOIN ETB_SUPPLY_ACTION etb ON sw.ITEMNMBR = etb.Item_Number
WHERE etb.Status NOT IN ('STOCKOUT', 'WFQ_COVERS')
  AND ABS(sw.Min_PAB - etb.RunBal) / NULLIF(ABS(etb.RunBal), 0) > 0.05;

-- Expected: Zero rows (deltas within tolerance)