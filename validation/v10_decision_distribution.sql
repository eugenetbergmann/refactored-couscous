-- V10: Decision distribution
-- Query to analyze procurement decision breakdown
SELECT ProcurementDecision, SignalConfidence, COUNT(*) AS ItemCount
FROM SW_vw_ProcurementSignals
GROUP BY ProcurementDecision, SignalConfidence;