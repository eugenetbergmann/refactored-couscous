# Exception Handling

## Operational Exceptions

| Exception | Column | Condition |
|-----------|--------|-----------|
| WFQ Overdue | WFQ_Overdue_Flag | Tier = 3 AND EstimatedReleaseDate < Today |
| Past-due PO | PastDue_PO_Flag | Tier = 2 AND ExpectedDate < Today AND IsCreditable = 0 |
| MPK Noise | MPK_Noise_Flag | MRP demand detected with no firm MO |
| Cross-Suffix | CrossSuffix_Available | Alternative suffix supply exists |

## Resolution Actions

1. **WFQ Overdue**: Contact QA for lot release status
2. **Past-due PO**: Contact vendor for updated ETA
3. **MPK Noise**: Verify MRP planned orders against firm MOs
4. **Cross-Suffix**: Evaluate regulatory eligibility for substitution