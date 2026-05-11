-- V2: Tier 1 exhausted before Tier 2 (priority check)
-- MUST return zero rows after deployment
-- Verifies deterministic depletion order
SELECT ITEMNMBR
FROM SW_vw_EventTrace
WHERE Tier = 2
  AND EventSequence < (SELECT MIN(EventSequence) FROM SW_vw_EventTrace t2
                       WHERE t2.ITEMNMBR = SW_vw_EventTrace.ITEMNMBR AND t2.Tier = 1);