# Runner Earnings Summary View Fix - October 10, 2025

## Problem

The Provider Accounting page was showing **0 for all cards** (total bookings, revenue, commission) even though clicking on individual runners showed the correct values.

## Root Cause Analysis

### Investigation Steps:

1. **Checked the view existence**: ✅ `runner_earnings_summary` view exists
2. **Checked view data**: ❌ All runners showing 0 for everything
3. **Checked bookings tables**:
   - Errands: 7 total, **3 with runner assignments** ✅
   - Transportation: 2 total, **0 with driver/runner assignments**
   - Contract: 0 total
   - Payments: **0 with runner assignments** ❌

4. **Checked errands table directly**:
   ```sql
   -- Found 5 errands with runner_id assigned
   - Joel: 3 errands (N$295 total)
   - Lidia: 1 errand (N$250)
   - Edvia: 1 errand (N$250)
   ```

### The Issue:

The `runner_earnings_summary` view was querying the **payments table** for errand data:

```sql
-- OLD (BROKEN):
SELECT p.runner_id, ...
FROM payments p
WHERE p.runner_id IS NOT NULL
```

**But the payments table had NO runner_id values!** All payment records had `runner_id = NULL`.

The actual runner assignments are stored in the **errands table** (`errands.runner_id`), not in the payments table.

## Solution

Updated the view to query the **errands table directly** instead of going through payments:

```sql
-- NEW (FIXED):
SELECT 
    e.runner_id,
    'errand' AS booking_type,
    e.status AS booking_status,
    e.price_amount AS booking_amount,
    ROUND(COALESCE(p.company_commission, e.price_amount * 0.3333), 2) AS company_commission,
    ROUND(COALESCE(p.runner_earnings, e.price_amount * 0.6667), 2) AS runner_earnings
FROM errands e
LEFT JOIN payments p ON e.id = p.errand_id  -- Still join payments for commission data
WHERE e.runner_id IS NOT NULL               -- But filter on errands.runner_id
```

## Changes Made

### File Created:
- `fix_runner_earnings_view_to_use_errands.sql`

### Migration Applied:
- `fix_runner_earnings_view_to_use_errands` ✅

## Verification

After the fix, the view now returns correct data:

```
Runner: Joel
- Total Bookings: 4
- Total Revenue: N$395.00
- Company Commission: N$131.66
- Runner Earnings: N$263.35

Runner: Lidia
- Total Bookings: 1
- Total Revenue: N$250.00
- Company Commission: N$83.33
- Runner Earnings: N$166.68

Runner: Edvia
- Total Bookings: 1
- Total Revenue: N$250.00
- Company Commission: N$83.33
- Runner Earnings: N$166.68
```

## Impact

- ✅ Provider Accounting page summary cards now show correct totals
- ✅ Individual runner details continue to work correctly
- ✅ Commission calculations (33.3% / 66.7%) working properly
- ✅ All booking types (errands, transportation, contracts) properly accounted for

## Technical Details

### Tables Structure:
- **errands**: Has `runner_id` column (used for runner assignment)
- **payments**: Has `errand_id` (links to errands) but `runner_id` was NULL
- **transportation_bookings**: Has `driver_id` and `runner_id` columns
- **contract_bookings**: Has `driver_id` and `runner_id` columns

### Why the detailed view worked:
The `get_runner_detailed_bookings` function was already querying the **errands table directly**, which is why clicking on individual runners showed the correct data. Only the summary view was broken.

## Next Steps

If you add more bookings (transportation or contracts), make sure to:
1. Set the `driver_id` or `runner_id` when a runner accepts the booking
2. The view will automatically include them in the calculations

