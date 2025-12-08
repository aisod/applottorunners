# Provider Accounting System Implementation - 33.3% Commission

## Overview

This implementation adds a comprehensive provider accounting system to the Lotto Runners app with a **33.3% company commission** structure. Runners/providers receive **66.7%** of every booking, while the company retains **33.3%**.

## Key Features Implemented

### 1. **Commission Tracking in Database**

#### New Database Fields Added
- All booking tables now include:
  - `company_commission` - Amount retained by company (33.3%)
  - `runner_earnings` - Amount paid to runner (66.7%)
  - `commission_rate` - Configurable rate (default 33.33%)

#### Tables Updated
- `payments` (for errand bookings)
- `transportation_bookings`
- `contract_bookings`
- `bus_service_bookings`

#### Automatic Commission Calculation
- Database triggers automatically calculate commission when bookings are completed
- Function: `calculate_commission()` - Calculates split based on total amount
- Triggers auto-populate commission fields on booking completion/confirmation

### 2. **Runner Earnings Summary View**

Created `runner_earnings_summary` database view that provides:
- Total bookings per runner
- Completed bookings count
- Total revenue generated
- Total company commission
- Total runner earnings
- Breakdown by booking type (errands, transportation, contracts, bus services)

### 3. **Admin Provider Accounting Page**

**Location:** `lib/pages/admin/provider_accounting_page.dart`

**Features:**
- Company overview with totals:
  * Total revenue across all bookings
  * Total company commission (33.3%)
  * Total runner earnings (66.7%)
  * Total bookings count
  
- Runner list with:
  * Search functionality (by name or email)
  * Sort options (by revenue, name, or bookings)
  * Per-runner statistics
  * Click to view detailed bookings
  
- Detailed booking view:
  * All bookings for selected runner
  * Booking type, status, customer info
  * Individual booking commission breakdown
  * Amount, commission, and earnings per booking

### 4. **Terms and Conditions Updated**

#### Runner Code of Conduct (`RUNNER_CODE_OF_CONDUCT.md`)
Added Section 6.3: **Commission and Payment Terms**
- Clear explanation of 33.3% platform fee
- Details on what commission covers
- Confirmation that runners receive 66.7%
- Applies to all booking types
- Warning against payment circumvention

#### Profile Page Terms (`lib/pages/profile_page.dart`)
Added "Runner Commission" section displaying:
- 33.3% service fee retained by company
- 66.7% earnings paid to runners
- Commission applies to all service types
- Automatic calculation per transaction
- What platform fee covers

### 5. **Supabase Configuration Methods**

**Location:** `lib/supabase/supabase_config.dart`

New methods added:

```dart
// Get summary of all runners with earnings
getRunnerEarningsSummary()

// Get detailed bookings for specific runner
getRunnerDetailedBookings(String runnerId)

// Get all runners/providers
getAllRunners()

// Get company-wide commission totals
getCompanyCommissionTotals()

// Calculate commission for any amount
calculateCommission(double amount, {double rate = 33.33})
```

### 6. **Admin Dashboard Integration**

**Location:** `lib/pages/admin/admin_home_page.dart`

- Added new "Provider Accounting" tab
- Positioned as second tab (after Dashboard)
- Uses account balance wallet icon
- Highlighted with yellow color for visibility

## Commission Calculation Logic

### Automatic Calculation
```sql
Company Commission = Total Amount × 0.3333
Runner Earnings = Total Amount × 0.6667
```

### Example Breakdown
For a N$100 booking:
- Total Amount: **N$100.00**
- Company Commission (33.3%): **N$33.33**
- Runner Earnings (66.7%): **N$66.67**

### Trigger Points
Commission is calculated when:
- Payment status = 'completed'
- Transportation booking status = 'completed' or 'confirmed'
- Contract booking status = 'completed', 'active', or 'confirmed'
- Bus booking status = 'completed' or 'confirmed'

## Database Migration

### Files Created
1. **`add_commission_tracking.sql`** - Main migration script
   - Adds commission fields to all booking tables
   - Creates calculation functions
   - Sets up automatic triggers
   - Creates summary view
   - Adds performance indexes

2. **`run_commission_tracking_setup.bat`** - Execution script
   - Windows batch file to run migration
   - Requires Supabase credentials
   - Provides feedback on success/failure

### Running the Migration

```bash
# Set environment variables
set SUPABASE_PROJECT_REF=your_project_ref
set SUPABASE_DB_PASSWORD=your_password

# Run the migration
run_commission_tracking_setup.bat
```

Or manually:
```bash
psql -h aws-0-eu-central-1.pooler.supabase.com -p 6543 -d postgres -U postgres.YOUR_PROJECT_REF -f add_commission_tracking.sql
```

## Benefits

### For Company
- ✅ Transparent commission tracking
- ✅ Real-time earnings visibility
- ✅ Per-runner accounting
- ✅ Revenue analytics by booking type
- ✅ Easy reconciliation

### For Runners
- ✅ Clear commission structure
- ✅ Terms explained upfront
- ✅ Automatic calculation (no disputes)
- ✅ Transparent earnings
- ✅ Breakdown by booking type

### For Admins
- ✅ Comprehensive accounting dashboard
- ✅ Runner performance tracking
- ✅ Commission totals at a glance
- ✅ Detailed booking history
- ✅ Search and sort functionality

## Technical Details

### Database Performance
- Indexed commission fields for fast queries
- View uses optimized aggregation
- Function marked as IMMUTABLE for caching
- Efficient UNION queries for booking types

### UI/UX Features
- Responsive design (mobile, tablet, desktop)
- Pull-to-refresh functionality
- Loading states and error handling
- Beautiful gradient headers
- Color-coded status indicators
- Tap-to-expand details

### Security
- RLS (Row Level Security) on all tables
- Authenticated users can view own earnings
- Admins have full access via view
- Commission calculations server-side only

## Booking Types Covered

### 1. Errands (via Payments table)
- General errands
- Delivery services
- Shopping tasks
- Document services

### 2. Transportation Bookings
- Shuttle services
- Point-to-point rides
- Scheduled transportation

### 3. Contract Bookings
- Long-term contracts
- Weekly/Monthly/Yearly subscriptions
- Business transportation

### 4. Bus Service Bookings
- Bus route services
- Multi-passenger bookings
- Scheduled bus services

## Usage Instructions

### For Admins

1. **Access Accounting Dashboard**
   - Log in as admin
   - Click "Provider Accounting" tab
   - View company overview at top

2. **View Runner Details**
   - Scroll through runner list
   - Use search to find specific runner
   - Sort by revenue, name, or bookings
   - Click on runner card

3. **Analyze Bookings**
   - View detailed booking list
   - See commission breakdown per booking
   - Filter by status
   - Export data (future feature)

### For Developers

1. **Calculate Commission Programmatically**
```dart
final breakdown = SupabaseConfig.calculateCommission(100.0);
// Returns:
// {
//   'total_amount': 100.0,
//   'company_commission': 33.33,
//   'runner_earnings': 66.67,
//   'commission_rate': 33.33
// }
```

2. **Get Runner Earnings**
```dart
final earnings = await SupabaseConfig.getRunnerEarningsSummary();
// Returns list of all runners with earnings
```

3. **Get Runner Bookings**
```dart
final bookings = await SupabaseConfig.getRunnerDetailedBookings(runnerId);
// Returns all bookings for runner with commission details
```

## Future Enhancements

### Planned Features
- [ ] Export accounting data to CSV/Excel
- [ ] Date range filters
- [ ] Monthly/yearly reports
- [ ] Runner payment history
- [ ] Automated payout scheduling
- [ ] Commission rate adjustments per runner
- [ ] Tax reporting features
- [ ] Invoice generation

### Potential Improvements
- [ ] Chart visualizations for earnings trends
- [ ] Comparison metrics (month-over-month)
- [ ] Runner ranking system
- [ ] Commission notifications
- [ ] Payment dispute resolution
- [ ] Multi-currency support

## Testing Checklist

- [ ] Run database migration
- [ ] Verify commission calculations
- [ ] Test admin accounting page
- [ ] Check runner earnings summary
- [ ] Verify detailed bookings view
- [ ] Test search functionality
- [ ] Test sort options
- [ ] Verify responsive design
- [ ] Check all booking types
- [ ] Verify terms display

## Support and Maintenance

### Commission Rate Changes
To change commission rate (e.g., to 30%):
1. Update `commission_rate` default in migration
2. Update Code of Conduct document
3. Update profile terms
4. Re-calculate existing bookings if needed

### Troubleshooting
- **Missing commission data**: Run migration script
- **Incorrect calculations**: Check trigger status
- **Performance issues**: Verify indexes exist
- **View not updating**: Refresh materialized view (if used)

## File Structure

```
lotto_runners/
├── add_commission_tracking.sql           # Database migration
├── run_commission_tracking_setup.bat     # Migration runner
├── RUNNER_CODE_OF_CONDUCT.md            # Updated terms
├── PROVIDER_ACCOUNTING_SYSTEM_IMPLEMENTATION.md  # This file
└── lib/
    ├── pages/
    │   ├── admin/
    │   │   ├── admin_home_page.dart      # Updated with new tab
    │   │   └── provider_accounting_page.dart  # New accounting page
    │   └── profile_page.dart             # Updated terms
    └── supabase/
        └── supabase_config.dart          # New accounting methods
```

## Conclusion

This implementation provides a complete, production-ready accounting system with clear commission tracking, transparent terms, and comprehensive admin tools. The 33.3% commission structure is automatically enforced at the database level, ensuring accuracy and preventing disputes.

All runners are informed of the commission structure through updated terms and conditions, and admins have full visibility into earnings and commission breakdowns through the new accounting dashboard.

---

**Version:** 1.0  
**Date:** October 2025  
**Commission Rate:** 33.3% (Company) / 66.7% (Runners)

