-- V8: MPK noise exposure
-- Query to identify items with MRP demand but no firm MO
SELECT ITEMNMBR, MPK_Demand, MPK_Noise_Flag, ProcurementDecision
FROM SW_vw_ProcurementSignals
WHERE MPK_Noise_Flag = 1;