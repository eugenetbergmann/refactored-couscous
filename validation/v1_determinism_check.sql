-- V1: Zero duplicate event sequences (determinism check)
-- MUST return zero rows after deployment
SELECT ITEMNMBR, EventSequence, COUNT(*)
FROM SW_vw_EventTrace
GROUP BY ITEMNMBR, EventSequence
HAVING COUNT(*) > 1;