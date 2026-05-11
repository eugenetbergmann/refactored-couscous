-- Phase 0: Permission Escalation
-- Week 1 tasks for deployment preparation
-- 
-- Request the following permissions from DBA:
--  1. CREATE VIEW permission (minimum to deploy)
--  2. SELECT permission on all GP tables:
--     - IV00101 (Item Master)
--     - IV00102 (Quantity Master)
--     - IV00300 (Quarantine/History)
--     - WO010032 (Manufacturing Orders)
--     - PK010033 (Consumption/Picklist)
--     - POP10100 (Purchase Orders)
--     - POP10500 (PO Receipts)
--     - SOP10200 (Sales Orders)
--     - MRP1000 (MRP Planned Orders)
--     - Prosenthal_Vendor_Items (Vendor mapping)
--  3. Verify NOLOCK hint acceptance

-- Verification query (run after permissions granted)
SELECT 
    COUNT(*) AS TableCount
FROM (
    SELECT 'IV00101' AS TableNmbr UNION ALL
    SELECT 'IV00102' UNION ALL
    SELECT 'IV00300' UNION ALL
    SELECT 'WO010032' UNION ALL
    SELECT 'PK010033' UNION ALL
    SELECT 'POP10100' UNION ALL
    SELECT 'POP10500' UNION ALL
    SELECT 'SOP10200' UNION ALL
    SELECT 'MRP1000'
) t;