-- Phase 1: Adapter Views Deployment
-- Week 1 tasks
--
-- Execution order:
--  1. Deploy SW_vw_Source_ItemMaster
--  2. Deploy SW_vw_Source_Supply
--  3. Deploy SW_vw_Source_Demand
--  4. Run validation queries V1-V5 against each

-- Execute views in order:
-- 1. views/01_sw_vw_source_itemmaster.sql
-- 2. views/02_sw_vw_source_supply.sql
-- 3. views/03_sw_vw_source_demand.sql

-- Post-deployment validation:
-- Run: validation/v1_determinism_check.sql
-- Run: validation/v2_tier_priority_check.sql
-- Run: validation/v3_adequate_invariant.sql
-- Run: validation/v4_leakage_check.sql
-- Run: validation/v5_idempotency_test.sql

-- Expected: All validation queries return zero rows