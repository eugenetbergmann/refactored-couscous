-- V4: 20-series leakage check
-- MUST return zero rows after deployment
-- Verifies FG items are excluded from processing
SELECT ITEMNMBR FROM SW_vw_ProcurementSignals WHERE ITEMNMBR LIKE '20%';