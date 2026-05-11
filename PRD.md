# OLID WADDLE R6 — VIEW-NATIVE PROCUREMENT INTELLIGENCE SYSTEM

**Product Requirements Document**

**Date:** 2026-05-11  
**Status:** Production-Ready PRD  
**Constraint Profile:** SQL Server 2016, Read-Only GP Access, No CREATE TABLE/PROCEDURE/ALTER, No Query Store, No Materialized State  
**Architecture:** 3 Thin Adapter Views + 1 Decision View + 1 Audit View  
**Max View Depth:** 2 (Decision views read only Adapter views; Adapter views read only GP tables)  
**Philosophy:** Base-Table Isolation, Deterministic CTEs, Zero Recursion, Tufte-Dense Output

## 1. THE CONSTRAINT CONTRACT

| Constraint | Implication | Architectural Response |
|------------|-------------|----------------------|
| No `CREATE TABLE` | No materialized state, no staging, no audit tables | All state is query-time computed; output is the audit trail |
| No `CREATE PROCEDURE` | No parameters, no temp tables, no batch logic | Views only; `GETDATE()` is the implicit parameter; re-execution is the refresh mechanism |
| No `ALTER` / `sp_rename` | Cannot modify existing ETB\_ objects | SW\_ views coexist; cutover is consumer-side (point apps at SW\_ views) |
| No Query Store | No plan stability guarantees | Deterministic logic that does not depend on optimizer whims |
| SQL Server 2016 compat | No `STRING_AGG(DISTINCT)`, no `PERCENTILE_CONT` in all contexts, no `CREATE OR ALTER` | Use `STUFF/FOR XML PATH` for aggregation; use `NTILE` or subquery percentiles; use `ALTER VIEW` only |
| Read-only GP | Cannot fix data at source | Surface data quality gaps as explicit columns; never silently compensate |
| `NOLOCK` required | Dirty reads possible | Acceptable for procurement signals; document risk for financial decisions |

**The single non-negotiable rule:** No SW\_ view may read from an ETB\_ view. All SW\_ views read only GP base tables (via adapter views) or other SW\_ views. This breaks the fossil dependency chain.

## 2. THE ARCHITECTURE: 3 + 1 + 1

```
GP Base Tables (IV00101, IV00102, IV00300, WO010032, PK010033, POP10100, POP10500, SOP10200, MRP1000, MRP1100)
   ↓
3 Thin Adapter Views (normalization only, no window functions, no business logic)
   ├── SW_vw_Source_ItemMaster  →  Item attributes, risk class, SS qty, commercial signals
   ├── SW_vw_Source_Supply      →  4-tier supply with credibility flags
   └── SW_vw_Source_Demand      →  Filtered demand with exclusion reasons
   ↓
1 Decision View (all heavy computation in CTEs, single-pass)
   └── SW_vw_ProcurementSignals  →  Running PAB, tier exhaustion, decision matrix, commercial overlay
   ↓
1 Audit View (query-time traceability reconstruction)
    └── SW_vw_EventTrace          →  Event-level decomposition for investigation
```

**View depth is exactly 2.** Adapter views read GP tables. Decision view reads adapter views. Audit view reads decision view CTEs (or adapter views directly). No view reads another view that reads another view.

## 3. SW_vw_Source_ItemMaster

**Purpose:** Single source of truth for all item attributes. Computes risk class, safety stock, commercial intelligence signals, and base-item/suffix parsing.

**Sources:** `IV00101` (item master), `IV00102` (quantity master), `IV30300` or `PK010033` (consumption history)