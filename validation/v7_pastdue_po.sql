-- V7: Past-due PO exception list
-- Query to identify items with open POs past promised date
SELECT ITEMNMBR, PRIME_VNDR, Tier2_InTransit, PastDue_PO_Flag
FROM SW_vw_ProcurementSignals
WHERE PastDue_PO_Flag = 1;