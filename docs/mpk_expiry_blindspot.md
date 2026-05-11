# MPK Expiry Blindspot

## Problem

MRP planned orders (MPK) create demand signals without corresponding firm manufacturing orders. These signals may expire without execution, creating false shortage indicators.

## Detection

The system flags MPK noise in `SW_vw_Source_Demand.FilterReason = 'MPK_NOISE'` when:
- MRP demand exists in MRP1000
- No corresponding firm MO exists in WO010032

## Impact on Decision Matrix

| MPK_Noise_Flag | Decision Impact |
|----------------|-----------------|
| 0 | Normal decision path |
| 1 | SignalConfidence = LOW, WAIT becomes INVESTIGATE |

## Mitigation

1. Regular reconciliation of MRP planned orders to firm MOs
2. Adjust MPK planning parameters to reduce noise
3. Implement expiry horizon validation

## Query for Investigation

```sql
SELECT ITEMNMBR, DueDate, DemandQty
FROM SW_vw_Source_Demand
WHERE FilterReason = 'MPK_NOISE';
```