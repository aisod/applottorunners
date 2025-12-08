# Service Type Pricing Implementation

## Overview
This document explains how different service types within the same category have different prices, and how this is tracked in the database for accurate runner wallet and admin accounting.

## Service Type Pricing Structure

### License Discs Service Category

#### Service Types & Prices

**Individual Users:**
- `renewal` (License Disc Renewal): **N$250**
- `registration` (Vehicle Registration): **N$1500**

**Business Users:**
- `renewal` (License Disc Renewal): **N$350**
- `registration` (Vehicle Registration): **N$2100**

### Document Services Category

#### Service Types & Prices

**Individual Users:**
- `application_submission` (Application Submission): **N$200**
- `certification` (Document Certification): **N$150**

**Business Users:**
- `application_submission` (Application Submission): **N$280**
- `certification` (Document Certification): **N$210**

## Database Storage

### Errands Table Fields

When an errand is created, the following fields are populated:

```sql
-- Core pricing fields
price_amount: DECIMAL(10,2)      -- The actual service-type-specific price charged
calculated_price: DECIMAL(10,2)  -- Same as price_amount (for consistency)
service_type: TEXT                -- The specific service type (e.g., 'renewal', 'certification')

-- Pricing modifiers JSON field
pricing_modifiers: JSONB {
  "base_price": 0.00,            -- Base category price (from services table)
  "service_type_price": 250.00,  -- The specific service type price charged
  "service_type": "renewal",      -- Service type identifier
  "user_type": "individual",      -- User type (individual/business)
  "service_option": "collect_and_deliver"  -- Optional: delivery option
}
```

### Why This Structure?

1. **price_amount** contains the actual amount charged (service-type-specific)
2. **pricing_modifiers** contains a breakdown for transparency and tracking:
   - `base_price`: The category's base price (reference)
   - `service_type_price`: The actual price based on the service type
   - `service_type`: Which specific service type was selected
   - `user_type`: Whether individual or business pricing was used

## Runner Wallet Integration

The runner wallet calculates earnings based on the `price_amount` field:

```dart
// From runner_earnings_summary view
SELECT 
    e.price_amount AS booking_amount,
    ROUND(e.price_amount * 0.3333, 2) AS company_commission,
    ROUND(e.price_amount * 0.6667, 2) AS runner_earnings
FROM errands e
WHERE e.runner_id = :runner_id
```

**Example:**
- License Disc Renewal (Individual): N$250
- Company Commission (33.3%): N$83.33
- Runner Earnings (66.7%): N$166.67

**Example:**
- Vehicle Registration (Individual): N$1500
- Company Commission (33.3%): N$499.95
- Runner Earnings (66.7%): N$1000.05

## Admin Accounting Integration

The admin accounting page shows:

1. **Total Revenue**: Sum of all `price_amount` values
2. **Company Commission**: 33.3% of total revenue
3. **Runner Earnings**: 66.7% of total revenue

The system can also break down revenue by:
- Service category (e.g., "license_discs", "document_services")
- Service type (e.g., "renewal", "registration")
- User type (individual vs business)

## Implementation Files

### Forms Updated
1. `lib/pages/license_discs_form_page.dart`
   - Added `_getServiceTypePrice()` method
   - Updated price display to use service-type-specific pricing
   - Stores service type details in `pricing_modifiers`

2. `lib/pages/document_services_form_page.dart`
   - Added `_getServiceTypePrice()` method
   - Updated price display to use service-type-specific pricing
   - Stores service type details in `pricing_modifiers`

### Wallet & Accounting Pages
- `lib/pages/runner_wallet_page.dart` - Uses `price_amount` for calculations
- `lib/pages/admin/provider_accounting_page.dart` - Uses `price_amount` for totals

## Future Enhancements

To display service type details in wallet/accounting pages:

```dart
// In wallet page, show breakdown
final pricingModifiers = errand['pricing_modifiers'] as Map?;
final serviceType = pricingModifiers?['service_type'] ?? 'Unknown';
final serviceTypePrice = pricingModifiers?['service_type_price'] ?? 0.0;

// Display: "License Disc - Renewal: N$250"
```

## Testing Checklist

- [ ] License disc renewal shows N$250 for individual users
- [ ] License disc registration shows N$1500 for individual users
- [ ] License disc renewal shows N$350 for business users
- [ ] License disc registration shows N$2100 for business users
- [ ] Document certification shows N$150 for individual users
- [ ] Document application submission shows N$200 for individual users
- [ ] Runner wallet calculates correct commission from service-type price
- [ ] Admin accounting shows correct totals using service-type prices
- [ ] pricing_modifiers JSONB field contains all required data

## Commission Breakdown Examples

### License Disc Renewal (Individual - N$250)
- **Total Amount**: N$250.00
- **Platform Fee (33.3%)**: N$83.33
- **Runner Earnings (66.7%)**: N$166.67

### Vehicle Registration (Individual - N$1500)
- **Total Amount**: N$1500.00
- **Platform Fee (33.3%)**: N$499.95
- **Runner Earnings (66.7%)**: N$1000.05

### Document Certification (Business - N$210)
- **Total Amount**: N$210.00
- **Platform Fee (33.3%)**: N$69.93
- **Runner Earnings (66.7%)**: N$140.07

## Database Query Examples

### Get revenue by service type
```sql
SELECT 
    service_type,
    COUNT(*) as booking_count,
    SUM(price_amount) as total_revenue,
    SUM(price_amount * 0.3333) as company_commission,
    SUM(price_amount * 0.6667) as runner_earnings
FROM errands
WHERE category = 'license_discs'
    AND status = 'completed'
GROUP BY service_type
ORDER BY total_revenue DESC;
```

### Get pricing breakdown for specific errand
```sql
SELECT 
    id,
    title,
    category,
    service_type,
    price_amount,
    pricing_modifiers->>'service_type_price' as service_type_price,
    pricing_modifiers->>'user_type' as user_type,
    pricing_modifiers->>'service_option' as service_option
FROM errands
WHERE id = :errand_id;
```

