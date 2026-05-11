# Decision Matrix

## Procurement Decisions (5 Values)

| Condition | Decision | Meaning |
|-----------|----------|---------|
| Min_PAB >= SS_Qty | DO_NOTHING | Safe, no action |
| Min_PAB >= 0, Tier <= 2, no MPK, BatchCount >= 5 | WAIT | No shortage, no conditional dependency |
| Min_PAB >= 0, Tier <= 2, but data issues | INVESTIGATE | Decision may be wrong; verify data |
| Min_PAB >= 0, Tier >= 3 | CHASE | Relying on conditional supply (quarantine or cross-suffix) |
| Min_PAB < 0 | BUY | Physical shortage |

## Signal Confidence

| Condition | Confidence |
|-----------|------------|
| BatchCount < 5 | LOW |
| Max_Tier_Used >= 3 | LOW |
| MPK_Noise_Flag = 1 | LOW |
| PastDue_PO_Flag = 1 | LOW |
| Otherwise | HIGH |