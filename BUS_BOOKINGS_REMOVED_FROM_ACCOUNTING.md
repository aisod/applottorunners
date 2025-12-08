# Bus Bookings Removed from Provider Accounting

## Change Summary

**Date:** October 10, 2025  
**Change:** Removed bus service bookings from provider accounting calculations  
**Reason:** Per user request - bus bookings should not count towards provider/runner earnings

## What Was Changed

### 1. Database View: `runner_earnings_summary`
- Bus booking data is now **excluded** from all revenue calculations
- Bus count, revenue, and earnings fields still exist but always return **0**
- Only counts: **Errands, Transportation, and Contract bookings**

### 2. Database Function: `get_runner_detailed_bookings()`
- Bus service bookings are **no longer included** in detailed booking lists
- When clicking on a runner, you won't see their bus bookings
- Only shows: **Errands, Transportation, and Contract bookings**

### 3. Files Updated

#### ✅ `fix_runner_linking.sql`
- Removed bus bookings UNION ALL clause from view
- Removed bus bookings from detailed bookings function
- Bus fields return 0
- Added comments explaining exclusion

#### ✅ `fix_accounting_view.sql`
- Removed bus bookings UNION ALL clause from view
- Removed bus bookings from detailed bookings function
- Bus fields return 0
- Added comments explaining exclusion

## Impact

### What's Still Included in Accounting:
✅ **Errands** - via payments table  
✅ **Transportation Bookings** - Point-to-point rides  
✅ **Contract Bookings** - Long-term contracts  

### What's Now Excluded:
❌ **Bus Service Bookings** - Scheduled bus routes

## Provider Accounting Display

After running the updated SQL:

### Company Overview Section
```
Total Revenue:           N$XXX.XX  (Errands + Transportation + Contracts only)
Company Commission:      N$XXX.XX  (33.3% of above)
Runner Earnings:         N$XXX.XX  (66.7% of above)
Total Bookings:          XX        (Count of Errands + Transportation + Contracts)
```

### Runner Cards
Each runner will show:
- **Bookings:** Count of non-bus bookings only
- **Revenue:** From non-bus bookings only
- **Errand Count:** Still shown
- **Transportation Count:** Still shown
- **Contract Count:** Still shown
- **Bus Count:** Always shows **0**

### Detailed Bookings (when clicking runner)
Will show:
- ✅ Errand bookings
- ✅ Transportation bookings
- ✅ Contract bookings
- ❌ Bus service bookings (won't appear)

## Technical Details

### Database Structure

**Before (Old):**
```sql
FROM (
    SELECT ... FROM payments              -- Errands
    UNION ALL
    SELECT ... FROM transportation_bookings  -- Transportation
    UNION ALL
    SELECT ... FROM contract_bookings     -- Contracts
    UNION ALL
    SELECT ... FROM bus_service_bookings  -- Buses (NOW REMOVED)
) all_bookings
```

**After (New):**
```sql
FROM (
    SELECT ... FROM payments              -- Errands
    UNION ALL
    SELECT ... FROM transportation_bookings  -- Transportation
    UNION ALL
    SELECT ... FROM contract_bookings     -- Contracts
    -- Note: Bus service bookings are excluded from provider accounting
) all_bookings
```

### Fields That Changed

```sql
-- Old values (calculated from bus bookings)
bus_count           -- Was: COUNT of bus bookings
bus_revenue         -- Was: SUM of bus booking amounts
bus_earnings        -- Was: 66.7% of bus revenue

-- New values (hardcoded to 0)
bus_count           -- Now: 0
bus_revenue         -- Now: 0.00
bus_earnings        -- Now: 0.00
```

## Running the Update

### Step 1: Run Updated SQL
Either file will work - they both have the same changes:

**Option A:** Use `fix_runner_linking.sql` (includes provider linking)
**Option B:** Use `fix_accounting_view.sql` (simpler version)

```bash
1. Open Supabase Dashboard → SQL Editor
2. Copy contents of fix_runner_linking.sql OR fix_accounting_view.sql
3. Paste and Run
4. Wait for "Success"
```

### Step 2: Restart App
```bash
1. Close Flutter app
2. Run: flutter run
3. Go to Provider Accounting
4. Pull down to refresh
```

### Step 3: Verify
Check that:
- ✅ Bus count shows 0 for all runners
- ✅ Total bookings only counts non-bus bookings
- ✅ Revenue only includes non-bus bookings
- ✅ Clicking a runner doesn't show bus bookings

## Why Keep Bus Fields?

The fields `bus_count`, `bus_revenue`, and `bus_earnings` are kept in the view (returning 0) to:

1. **Prevent Breaking Changes** - Flutter code expects these fields
2. **Easy Reversal** - Can easily re-enable by running old SQL
3. **Clear Intent** - Shows bus bookings are intentionally excluded (not forgotten)

## Reverting the Change

If you need to **include bus bookings again** in the future:

1. Find the old versions of these files (in git history)
2. Or manually add back the UNION ALL clauses:

```sql
UNION ALL

-- Bus service bookings
SELECT 
    bsb.runner_id,
    'bus' AS booking_type,
    bsb.status AS booking_status,
    COALESCE(bsb.final_price, bsb.estimated_price, 0) AS booking_amount,
    COALESCE(bsb.company_commission, ...) AS company_commission,
    COALESCE(bsb.runner_earnings, ...) AS runner_earnings
FROM bus_service_bookings bsb
WHERE bsb.runner_id IS NOT NULL
```

And change the SELECT fields from:
```sql
0 AS bus_count,
0 AS bus_revenue,
0 AS bus_earnings
```

Back to:
```sql
COALESCE(earnings_data.bus_count, 0) AS bus_count,
COALESCE(earnings_data.bus_revenue, 0) AS bus_revenue,
COALESCE(earnings_data.bus_earnings, 0) AS bus_earnings
```

## Notes

- **Bus bookings still exist** in the database - they're just not counted in accounting
- **Bus management pages** are unaffected - admins can still manage bus bookings
- **Users can still book buses** - this only affects provider accounting calculations
- **No data loss** - bus booking data remains intact

## Migration Checklist

- [x] Updated `fix_runner_linking.sql`
- [x] Updated `fix_accounting_view.sql`
- [x] Added comments explaining exclusion
- [x] Documented the change
- [ ] **USER ACTION: Run updated SQL in Supabase**
- [ ] **USER ACTION: Test Provider Accounting page**
- [ ] **USER ACTION: Verify bus bookings don't appear**

---

**Status:** Files updated ✅ | SQL needs to be run ⚠️  
**Action Required:** Run either SQL file in Supabase Dashboard  
**Breaking:** No - existing fields maintained (return 0)  
**Reversible:** Yes - can restore bus bookings easily

