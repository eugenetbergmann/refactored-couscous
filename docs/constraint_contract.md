# Constraint Contract

## The Non-Negotiable Rule

**No SW_ view may read from an ETB_ view.** All SW_ views read only GP base tables (via adapter views) or other SW_ views.

This breaks the fossil dependency chain.

## Constraints Summary

| Constraint | Response |
|------------|----------|
| No CREATE TABLE | All state computed query-time |
| No CREATE PROCEDURE | Views only; GETDATE() is implicit parameter |
| No ALTER / sp_rename | SW_ views coexist; consumer-side cutover |
| No Query Store | Deterministic logic independent of optimizer |
| SQL Server 2016 | Use STUFF/FOR XML PATH for aggregation |
| Read-only GP | Surface data quality gaps explicitly |
| NOLOCK required | Document risk for financial decisions |