# Service Type Database Storage - Clarification

## How Service Types Are Stored

### Database Fields Used:
1. **`errands.service_type`** - TEXT column at root level
2. **`errands.pricing_modifiers`** - JSONB field containing `service_type` key
3. **`errands.vehicle_type`** - TEXT column (for delivery only)

### Current Storage Pattern (After Our Changes):

#### License Discs:
```json
{
  "service_type": "renewal",  // ← At root level
  "pricing_modifiers": {
    "service_type": "renewal",  // ← Also in JSONB
    "service_type_price": 250.00
  }
}
```

#### Document Services:
```json
{
  "service_type": "certification",  // ← At root level
  "pricing_modifiers": {
    "service_type": "certification",  // ← Also in JSONB
    "service_type_price": 150.00
  }
}
```

#### Delivery:
```json
{
  "vehicle_type": "Motorcycle",  // ← Delivery specific
  "service_type": "Motorcycle",  // ← At root level (NEW!)
  "pricing_modifiers": {
    "service_type": "Motorcycle",  // ← Also in JSONB
    "vehicle_type": "Motorcycle",
    "service_type_price": 43.00
  }
}
```

## How Wallet/Accounting Read the Data:

Both pages check BOTH locations:

```dart
// From runner_wallet_page.dart and provider_accounting_page.dart
final serviceType = booking['service_type'] as String?;  // ← Check root first
final pricingModifiers = booking['pricing_modifiers'] as Map?;
final serviceTypeFromModifiers = pricingModifiers?['service_type'] as String?;  // ← Fallback to JSONB
final finalServiceType = serviceType ?? serviceTypeFromModifiers;  // ← Use whichever exists

if (finalServiceType != null) {
  // Show service type badge
}
```

## Data Flow:

### NEW Errands (After Today):
```
User submits form
  ↓
service_type stored at ROOT level ✅
  ↓
service_type stored in pricing_modifiers ✅
  ↓
Wallet reads from either location ✅
  ↓
Service type badge appears ✅
```

### OLD Errands (Before Today):

#### If they have service_type field:
```
Old errand exists
  ↓
Has service_type at root? ✅
  ↓
Wallet reads it ✅
  ↓
Service type badge appears ✅
```

#### If they DON'T have service_type:
```
Very old errand
  ↓
No service_type at root ❌
  ↓
No service_type in pricing_modifiers ❌
  ↓
Wallet can't read it ❌
  ↓
No service type badge ❌
```

## Solution for Old Records:

### Option 1: Do Nothing
- New records will work fine ✅
- Old records just won't show service type badge
- No database changes needed

### Option 2: Backfill Old Records
Run the SQL script `backfill_service_types.sql`:

```bash
# In Supabase SQL Editor, run:
# backfill_service_types.sql
```

This will:
1. Copy `vehicle_type` to `service_type` for old delivery records
2. Add `service_type` to `pricing_modifiers` JSONB for old records
3. Make old records display service types in wallet/accounting

## Testing:

### Test NEW Records:
1. Create a new delivery with Motorcycle ✅
2. Check database - should have:
   - `service_type = 'Motorcycle'` ✅
   - `pricing_modifiers.service_type = 'Motorcycle'` ✅
3. View in runner wallet ✅
4. Service type badge should appear ✅

### Test OLD Records (without backfill):
1. Find old delivery in database
2. Check if `service_type` field exists
3. If yes → badge will appear
4. If no → badge won't appear (but price calculations still work!)

### Test OLD Records (with backfill):
1. Run `backfill_service_types.sql`
2. Check old delivery records
3. Should now have `service_type` populated
4. Badges should appear in wallet/accounting

## Summary:

| Scenario | Root Level `service_type` | JSONB `service_type` | Badge Appears? |
|----------|--------------------------|---------------------|----------------|
| **New License Disc** | ✅ "renewal" | ✅ "renewal" | ✅ YES |
| **New Document Service** | ✅ "certification" | ✅ "certification" | ✅ YES |
| **New Delivery** | ✅ "Motorcycle" | ✅ "Motorcycle" | ✅ YES |
| **Old Delivery (with field)** | ✅ "Motorcycle" | ❌ No | ✅ YES |
| **Old Delivery (without field)** | ❌ No | ❌ No | ❌ NO |
| **After Backfill** | ✅ "Motorcycle" | ✅ "Motorcycle" | ✅ YES |

## Price Calculations Are NOT Affected:

Even for old records without `service_type`, the calculations work because they use `price_amount`:

```dart
// This ALWAYS works, regardless of service_type:
final amount = booking['price_amount'];  // ← Stored in every errand
final commission = amount * 0.3333;
final earnings = amount * 0.6667;
```

So:
- ✅ **Earnings calculations** = Always correct
- ✅ **Commission splits** = Always correct
- ✅ **Total revenue** = Always correct
- ⚠️ **Service type badge** = Only appears if `service_type` exists

## Conclusion:

**Your concern was valid!** Old records might not show service type badges. However:

1. ✅ We've fixed it for NEW records (starting now)
2. ✅ Price calculations always work (not affected)
3. ✅ You can optionally backfill old records if needed
4. ✅ The system gracefully handles missing service types

**Recommended Action:**
- If you have many old delivery records and want them to show vehicle types → Run the backfill script
- If you're okay with only new records showing badges → Do nothing, it will work for all new submissions

