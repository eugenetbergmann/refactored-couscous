# Solid Waddle R6

View-native procurement intelligence system for Dynamics GP manufacturing data.

## Overview

Solid Waddle R6 transforms raw GP manufacturing data into deterministic, explainable procurement decisions without materialized state, external computation, or recursive view chains.

**Architecture:** 3 Thin Adapter Views + 1 Decision View + 1 Audit View

**Decisions:** DO_NOTHING | WAIT | INVESTIGATE | CHASE | BUY

## Files

```
solid-waddle-r6/
├── README.md                          # This file
├── PRD.md                             # Product Requirements Document
├── views/
│   ├── 01_sw_vw_source_itemmaster.sql # Adapter: Item attributes
│   ├── 02_sw_vw_source_supply.sql     # Adapter: 4-tier supply
│   ├── 03_sw_vw_source_demand.sql     # Adapter: Filtered demand
│   ├── 04_sw_vw_procurementsignals.sql # Decision: Running PAB
│   └── 05_sw_vw_eventtrace.sql        # Audit: Event decomposition
├── validation/
│   ├── v1_determinism_check.sql
│   ├── v2_tier_priority_check.sql
│   ├── v3_adequate_invariant.sql
│   ├── v4_leakage_check.sql
│   ├── v5_idempotency_test.sql
│   ├── v6_wfq_overdue.sql
│   ├── v7_pastdue_po.sql
│   ├── v8_mpk_noise.sql
│   ├── v9_commercial_distribution.sql
│   └── v10_decision_distribution.sql
├── migration/
│   ├── phase0_permissions.sql
│   ├── phase1_adapter_views.sql
│   ├── phase2_decision_view.sql
│   ├── phase3_parallel_run.sql
│   └── phase4_cutover.sql
└── docs/
    ├── constraint_contract.md
    ├── decision_matrix.md
    ├── exception_handling.md
    └── mpk_expiry_blindspot.md
```

## Quick Start

1. Review PRD.md for full specification
2. Request CREATE VIEW permission (Phase 0)
3. Deploy adapter views in order (Phase 1)
4. Run validation queries V1-V5
5. Deploy decision view (Phase 2)
6. Run structural and phase gate validation

## SQL Server 2016 Compatibility

- Uses PERCENTILE_CONT (supported in 2012+)
- NOLOCK hints required
- Window functions without filtered WHERE clauses
- No STRING_AGG, no CREATE OR ALTER