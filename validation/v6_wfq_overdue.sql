-- V6: WFQ overdue exception list
-- Query to identify items with quarantine past estimated release date
SELECT ITEMNMBR, PRIME_VNDR, DeficitAgeDays, DecisionRationale
FROM SW_vw_ProcurementSignals
WHERE WFQ_Overdue_Flag = 1;