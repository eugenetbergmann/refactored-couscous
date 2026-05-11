-- Phase 2: Decision View Deployment
-- Week 2 tasks
--
-- Execution order:
--  1. Deploy SW_vw_ProcurementSignals
--  2. Deploy SW_vw_EventTrace
--  3. Run structural validation (V1-V5)
--  4. Run phase gate validation (P2-G2a, P2-G2b)

-- Execute views:
-- 1. views/04_sw_vw_procurementsignals.sql
-- 2. views/05_sw_vw_eventtrace.sql

-- Post-deployment validation:
-- Run structural validation (V1-V5)
-- Run phase gate validation:
--   - validation/v6_wfq_overdue.sql
--   - validation/v7_pastdue_po.sql
--   - validation/v8_mpk_noise.sql
--   - validation/v9_commercial_distribution.sql
--   - validation/v10_decision_distribution.sql

-- Phase Gate Validation (migration from ETB_):
-- P2-G2a: Non-STOCKOUT items delta < 5% on Min_PAB
-- P2-G2b: STOCKOUT items exact match (hard blocker)