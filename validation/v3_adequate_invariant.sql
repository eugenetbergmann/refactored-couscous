-- V3: ADEQUATE items have positive Min_PAB (Deficiency 5 check)
-- MUST return zero rows after deployment
SELECT ITEMNMBR, Min_PAB, ProcurementDecision
FROM SW_vw_ProcurementSignals
WHERE ProcurementDecision = 'DO_NOTHING' AND Min_PAB < 0;