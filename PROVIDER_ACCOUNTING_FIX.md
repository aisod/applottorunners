# Provider Accounting Fix - Showing 0 Bookings Issue

## Problem
The provider accounting page is showing 0 bookings even though bookings exist in the database.

## Diagnosis
Based on the terminal output, the system shows:
- ✅ Loaded 2 transportation bookings and 5 bus bookings
- ✅ Loaded earnings for 18 runners

However, the accounting page displays 0 bookings. This suggests the `runner_earnings_summary` view is not properly aggregating booking data.

## Possible Causes

### 1. **Status Filtering Issue**
The view might only be counting bookings with status 'completed' or 'confirmed', but your bookings might have different statuses like:
- 'pending'
- 'accepted'
- 'active'
- 'in_progress'

### 2. **Missing runner_id or driver_id**
Bookings might not have the runner_id or driver_id fields properly set, so they're not being associated with any runner.

### 3. **User Type Filtering**
The view only includes users where `user_type = 'runner'` OR `is_verified = true`. If your users don't match these criteria, they won't appear.

## Debugging Steps

### Step 1: Check Console Output
I've added detailed debug logging to both:
1. `lib/pages/admin/provider_accounting_page.dart`
2. `lib/supabase/supabase_config.dart`

**To see the debug output:**
1. Run your Flutter app
2. Navigate to Admin Dashboard
3. Click on "Provider Accounting"
4. Check the console/terminal output

You should see output like:
```
💰 Getting runner earnings summary
✅ Loaded earnings for 18 runners
   📊 First 3 runners from DB:
      1. John Doe: 0 bookings, N$0
      2. Jane Smith: 5 bookings, N$500
      ...
   Runners with bookings > 0: X

🔍 DEBUG: Provider Accounting Data
   Runners loaded: 18
   Total bookings (from totals): 0
   Total revenue: 0
   ...
```

This will tell us:
- How many runners have bookings > 0
- What the actual booking counts are
- What the revenue values are

### Step 2: Fix the Database View

If the debug output shows that `total_bookings` is 0 for all runners, we need to fix the database view.

**Option A: Using Supabase Dashboard (RECOMMENDED)**

1. Go to your Supabase dashboard: https://supabase.com/dashboard
2. Select your project
3. Go to SQL Editor
4. Copy and paste the contents of `fix_accounting_view.sql` (I created this file)
5. Click "Run"

**Option B: Using Supabase CLI**

If you have Supabase CLI installed:
```bash
supabase db push
# Or
supabase db reset
```

**Option C: Manual Fix**

Copy this SQL and run it in Supabase SQL Editor:

```sql
-- Fix the runner_earnings_summary view
DROP VIEW IF EXISTS runner_earnings_summary CASCADE;

CREATE OR REPLACE VIEW runner_earnings_summary AS
SELECT 
    u.id AS runner_id,
    u.full_name AS runner_name,
    u.email AS runner_email,
    u.phone AS runner_phone,
    COALESCE(earnings_data.total_bookings, 0) AS total_bookings,
    COALESCE(earnings_data.completed_bookings, 0) AS completed_bookings,
    COALESCE(earnings_data.total_revenue, 0) AS total_revenue,
    COALESCE(earnings_data.total_company_commission, 0) AS total_company_commission,
    COALESCE(earnings_data.total_runner_earnings, 0) AS total_runner_earnings,
    COALESCE(earnings_data.errand_count, 0) AS errand_count,
    COALESCE(earnings_data.errand_revenue, 0) AS errand_revenue,
    COALESCE(earnings_data.errand_earnings, 0) AS errand_earnings,
    COALESCE(earnings_data.transportation_count, 0) AS transportation_count,
    COALESCE(earnings_data.transportation_revenue, 0) AS transportation_revenue,
    COALESCE(earnings_data.transportation_earnings, 0) AS transportation_earnings,
    COALESCE(earnings_data.contract_count, 0) AS contract_count,
    COALESCE(earnings_data.contract_revenue, 0) AS contract_revenue,
    COALESCE(earnings_data.contract_earnings, 0) AS contract_earnings,
    COALESCE(earnings_data.bus_count, 0) AS bus_count,
    COALESCE(earnings_data.bus_revenue, 0) AS bus_revenue,
    COALESCE(earnings_data.bus_earnings, 0) AS bus_earnings
FROM users u
LEFT JOIN (
    SELECT 
        runner_id,
        COUNT(*) AS total_bookings,
        -- Include more statuses
        SUM(CASE WHEN booking_status IN ('completed', 'confirmed', 'active', 'in_progress', 'accepted') THEN 1 ELSE 0 END) AS completed_bookings,
        SUM(booking_amount) AS total_revenue,
        SUM(company_commission) AS total_company_commission,
        SUM(runner_earnings) AS total_runner_earnings,
        SUM(CASE WHEN booking_type = 'errand' THEN 1 ELSE 0 END) AS errand_count,
        SUM(CASE WHEN booking_type = 'errand' THEN booking_amount ELSE 0 END) AS errand_revenue,
        SUM(CASE WHEN booking_type = 'errand' THEN runner_earnings ELSE 0 END) AS errand_earnings,
        SUM(CASE WHEN booking_type = 'transportation' THEN 1 ELSE 0 END) AS transportation_count,
        SUM(CASE WHEN booking_type = 'transportation' THEN booking_amount ELSE 0 END) AS transportation_revenue,
        SUM(CASE WHEN booking_type = 'transportation' THEN runner_earnings ELSE 0 END) AS transportation_earnings,
        SUM(CASE WHEN booking_type = 'contract' THEN 1 ELSE 0 END) AS contract_count,
        SUM(CASE WHEN booking_type = 'contract' THEN booking_amount ELSE 0 END) AS contract_revenue,
        SUM(CASE WHEN booking_type = 'contract' THEN runner_earnings ELSE 0 END) AS contract_earnings,
        SUM(CASE WHEN booking_type = 'bus' THEN 1 ELSE 0 END) AS bus_count,
        SUM(CASE WHEN booking_type = 'bus' THEN booking_amount ELSE 0 END) AS bus_revenue,
        SUM(CASE WHEN booking_type = 'bus' THEN runner_earnings ELSE 0 END) AS bus_earnings
    FROM (
        -- Errands via payments
        SELECT 
            p.runner_id,
            'errand' AS booking_type,
            p.status AS booking_status,
            p.amount AS booking_amount,
            COALESCE(p.company_commission, p.amount * 0.3333) AS company_commission,
            COALESCE(p.runner_earnings, p.amount * 0.6667) AS runner_earnings
        FROM payments p
        WHERE p.runner_id IS NOT NULL
        
        UNION ALL
        
        -- Transportation bookings
        SELECT 
            COALESCE(tb.driver_id, tb.runner_id) AS runner_id,
            'transportation' AS booking_type,
            tb.status AS booking_status,
            COALESCE(tb.final_price, tb.estimated_price, 0) AS booking_amount,
            COALESCE(tb.company_commission, COALESCE(tb.final_price, tb.estimated_price, 0) * 0.3333) AS company_commission,
            COALESCE(tb.runner_earnings, COALESCE(tb.final_price, tb.estimated_price, 0) * 0.6667) AS runner_earnings
        FROM transportation_bookings tb
        WHERE COALESCE(tb.driver_id, tb.runner_id) IS NOT NULL
        
        UNION ALL
        
        -- Contract bookings
        SELECT 
            COALESCE(cb.runner_id, cb.driver_id) AS runner_id,
            'contract' AS booking_type,
            cb.status AS booking_status,
            COALESCE(cb.final_price, cb.estimated_price, 0) AS booking_amount,
            COALESCE(cb.company_commission, COALESCE(cb.final_price, cb.estimated_price, 0) * 0.3333) AS company_commission,
            COALESCE(cb.runner_earnings, COALESCE(cb.final_price, cb.estimated_price, 0) * 0.6667) AS runner_earnings
        FROM contract_bookings cb
        WHERE COALESCE(cb.runner_id, cb.driver_id) IS NOT NULL
        
        UNION ALL
        
        -- Bus service bookings
        SELECT 
            bsb.runner_id,
            'bus' AS booking_type,
            bsb.status AS booking_status,
            COALESCE(bsb.final_price, bsb.estimated_price, 0) AS booking_amount,
            COALESCE(bsb.company_commission, COALESCE(bsb.final_price, bsb.estimated_price, 0) * 0.3333) AS company_commission,
            COALESCE(bsb.runner_earnings, COALESCE(bsb.final_price, bsb.estimated_price, 0) * 0.6667) AS runner_earnings
        FROM bus_service_bookings bsb
        WHERE bsb.runner_id IS NOT NULL
    ) all_bookings
    GROUP BY runner_id
) earnings_data ON u.id = earnings_data.runner_id
-- Changed: Include any user who has bookings
WHERE earnings_data.runner_id IS NOT NULL OR u.user_type = 'runner' OR u.is_verified = true;

-- Grant permissions
GRANT SELECT ON runner_earnings_summary TO authenticated;
```

### Step 3: Verify the Fix

After running the SQL:

1. Restart your Flutter app
2. Navigate to Provider Accounting
3. Pull to refresh
4. Check if bookings now show up

## Key Changes Made

1. **Extended Status Filtering**: Now includes 'active', 'in_progress', 'accepted' in addition to 'completed' and 'confirmed'

2. **Improved User Filtering**: Changed from only showing runners with `user_type = 'runner'` to also showing any user who has bookings

3. **Better COALESCE Usage**: Added COALESCE to handle cases where final_price or estimated_price might be NULL

4. **Debug Logging**: Added comprehensive logging to track data flow

## Files Modified

1. `lib/pages/admin/provider_accounting_page.dart` - Added debug logging
2. `lib/supabase/supabase_config.dart` - Added debug logging to getRunnerEarningsSummary()
3. `fix_accounting_view.sql` - New file with the corrected SQL view
4. `fix_accounting_view.dart` - Alternative fix using Dart (may not work without custom RPC)

## Next Steps

1. **Run the app** and check the console output when you visit Provider Accounting
2. **Share the debug output** with me so I can see exactly what data is being returned
3. **Run the SQL fix** in Supabase dashboard if needed
4. **Test the accounting page** after the fix

## Common Issues & Solutions

### Issue: "No runners found"
**Solution**: Check if users have `user_type = 'runner'` set or `is_verified = true`

### Issue: "Runners shown but 0 bookings"
**Solution**: Run the SQL fix to update the view to include more statuses

### Issue: "runner_id is NULL in bookings"
**Solution**: Need to update bookings to assign runners/drivers properly

### Issue: "Permission denied on runner_earnings_summary"
**Solution**: Run `GRANT SELECT ON runner_earnings_summary TO authenticated;`

## Support

If the issue persists after following these steps, please provide:
1. The console debug output
2. A screenshot of the accounting page
3. Sample data from your database (number of bookings, their statuses)


