-- V5: Idempotency test (run twice, compare)
-- MUST return zero rows after deployment (ignoring AsOfDate if different)
SELECT * FROM SW_vw_ProcurementSignals
EXCEPT
SELECT * FROM SW_vw_ProcurementSignals;