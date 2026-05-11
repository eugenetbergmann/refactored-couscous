-- Phase 4: Cutover
-- Week 5 tasks
--
-- Actions:
--  1. Point buyer dashboards to SW_vw_ProcurementSignals
--  2. Point exception reports to WFQ_Overdue_Flag and PastDue_PO_Flag columns
--  3. Retire ETB_ views (rename to LEGACY_ETB_* when ALTER permission granted)

-- Consumer migration checklist:
-- [ ] Buyer dashboards updated
-- [ ] Exception reports configured
-- [ ] Procurement team training complete
-- [ ] ETB_ view sunset plan documented

-- ALTER VIEW permission required for retirement:
-- ALTER VIEW ETB_vw_Supply_Action RENAME TO LEGACY_ETB_vw_Supply_Action
-- ALTER VIEW ETB_vw_Demand_Risk RENAME TO LEGACY_ETB_vw_Demand_Risk