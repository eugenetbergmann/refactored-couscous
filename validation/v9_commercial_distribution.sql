-- V9: Commercial signal distribution
-- Query to analyze commercial signal categories
SELECT CommercialSignal, COUNT(*) AS ItemCount
FROM SW_vw_ProcurementSignals
GROUP BY CommercialSignal;