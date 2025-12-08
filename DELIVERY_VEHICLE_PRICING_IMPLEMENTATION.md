# Delivery Vehicle Pricing Implementation

## Overview
This document explains how different vehicle types in the delivery service have different prices, and how this is tracked in the database for accurate runner wallet and admin accounting calculations.

## Vehicle Type Pricing Structure

### Delivery Service Category

#### Vehicle Types & Prices

**All Users (No business/individual differentiation for vehicles):**
- **Motorcycle**: N$43
- **Sedan**: N$75
- **Mini Truck**: N$171
- **Truck**: N$350

### Vehicle Availability by Delivery Type

1. **Food Delivery**: Motorcycle only
2. **Document Delivery**: Motorcycle only
3. **Package Delivery**: Sedan, Mini Truck, Truck

## Implementation Details

### File Modified: `lib/pages/delivery_form_page.dart`

**Vehicle Price Method** (Lines 109-121):
```dart
double _getVehiclePrice(String vehicleName) {
  final name = vehicleName.toLowerCase();
  if (name.contains('motorcycle')) {
    return 43.0;
  } else if (name.contains('sedan')) {
    return 75.0;
  } else if (name.contains('mini') && name.contains('truck')) {
    return 171.0;
  } else if (name.contains('truck')) {
    return 350.0;
  }
  return 0.0;
}
```

**Pricing Storage in Database**:
```dart
'pricing_modifiers': {
  'base_price': _getBasePrice(),              // Service category base price
  'service_type_price': finalPrice,           // Vehicle-specific price
  'service_type': _vehicleType,               // Vehicle name (e.g., "Motorcycle")
  'vehicle_type': _vehicleType,               // Same as service_type
  'vehicle_price': _getSelectedVehiclePrice(), // Actual vehicle price
  'urgency_surcharge': 0.0,                   // No longer used
  'user_type': 'individual',                  // User type
  'final_price': finalPrice,                  // Total price charged
}
```

## How It Works

### User Flow:
1. **User selects delivery type** (Food, Document, or Package)
2. **Available vehicles are filtered**:
   - Food/Document → Motorcycle only
   - Package → Sedan, Mini Truck, Truck
3. **User selects vehicle** from horizontal scrollable cards
4. **Price updates** based on selected vehicle
5. **Submit button shows** vehicle-specific price
6. **On submission**:
   - Vehicle-specific price stored in `price_amount` and `calculated_price`
   - Vehicle type stored in `vehicle_type` field
   - Detailed breakdown stored in `pricing_modifiers` JSONB
7. **Runner accepts and completes delivery**
8. **Commission calculated** from vehicle price:
   - Company: 33.3% of vehicle price
   - Runner: 66.7% of vehicle price
9. **Runner wallet shows** vehicle type badge
10. **Admin accounting shows** vehicle type in booking details

## Database Storage

### Fields Populated:
```sql
-- Core fields
price_amount: 43.00           -- Vehicle-specific price (e.g., Motorcycle)
calculated_price: 43.00       -- Same as price_amount
vehicle_type: 'Motorcycle'    -- Vehicle name
category: 'delivery'          -- Service category

-- Pricing modifiers JSON
pricing_modifiers: {
  "base_price": 0.00,
  "service_type_price": 43.00,
  "service_type": "Motorcycle",
  "vehicle_type": "Motorcycle",
  "vehicle_price": 43.00,
  "user_type": "individual",
  "final_price": 43.00
}
```

## Commission Breakdown Examples

### Motorcycle Delivery (N$43)
- **Total Amount**: N$43.00
- **Platform Fee (33.3%)**: N$14.32
- **Runner Earnings (66.7%)**: N$28.68

### Sedan Delivery (N$75)
- **Total Amount**: N$75.00
- **Platform Fee (33.3%)**: N$24.98
- **Runner Earnings (66.7%)**: N$50.02

### Mini Truck Delivery (N$171)
- **Total Amount**: N$171.00
- **Platform Fee (33.3%)**: N$56.94
- **Runner Earnings (66.7%)**: N$114.06

### Truck Delivery (N$350)
- **Total Amount**: N$350.00
- **Platform Fee (33.3%)**: N$116.55
- **Runner Earnings (66.7%)**: N$233.45

## Wallet & Accounting Integration

### Runner Wallet Display
When viewing a delivery booking, runners see:
```
Delivery                   [COMPLETED]
[Motorcycle]  ← Vehicle type badge
John Doe
Total: N$43.00
Platform Fee: -N$14.32
Your Earnings: N$28.68
```

### Admin Accounting Display
When viewing booking details:
```
[Delivery] [COMPLETED] [Motorcycle] N$43.00
John Doe
Pickup: 123 Main St
Delivery: 456 Oak Ave
Commission: N$14.32 | Earnings: N$28.68
```

## UI Features

### Vehicle Selection Cards
- **Horizontal scrollable list** of available vehicles
- **Vehicle icon** displayed from Supabase storage
- **Vehicle name** and **price** shown
- **Selected state** with checkmark icon
- **Shimmer animation** for visual appeal
- **Responsive sizing** for mobile/tablet/desktop

### Vehicle Icons (Supabase Storage):
- `motorcycle.png` - For Motorcycle
- `car.png` - For Sedan
- `mini truck.png` - For Mini Truck
- `truck.png` - For Truck

## Code References

### Key Methods:

**Get Vehicle Price**:
```dart
double _getVehiclePrice(String vehicleName) {
  // Returns price based on vehicle name
}
```

**Get Selected Vehicle Price**:
```dart
double _getSelectedVehiclePrice() {
  if (_vehicleType == null) return 0.0;
  return _getVehiclePrice(_vehicleType!);
}
```

**Calculate Final Price**:
```dart
double _calculateFinalPrice() {
  final vehiclePrice = _getSelectedVehiclePrice();
  return vehiclePrice > 0 ? vehiclePrice : _getBasePrice();
}
```

**Filter Vehicles by Delivery Type**:
```dart
List<Map<String, dynamic>> _filterVehicleTypesByDeliveryType() {
  // Returns motorcycles for food/documents
  // Returns sedan/trucks for packages
}
```

## Testing Checklist

### Forms
- [ ] Motorcycle shows N$43 for all users
- [ ] Sedan shows N$75 for all users
- [ ] Mini Truck shows N$171 for all users
- [ ] Truck shows N$350 for all users
- [ ] Food delivery only shows Motorcycle option
- [ ] Document delivery only shows Motorcycle option
- [ ] Package delivery shows Sedan, Mini Truck, Truck options
- [ ] Selected vehicle price appears in submit button
- [ ] Form stores vehicle type in database

### Wallet
- [ ] Vehicle type badge appears on delivery bookings
- [ ] Motorcycle commission: N$14.32, Earnings: N$28.68
- [ ] Sedan commission: N$24.98, Earnings: N$50.02
- [ ] Mini Truck commission: N$56.94, Earnings: N$114.06
- [ ] Truck commission: N$116.55, Earnings: N$233.45

### Admin Accounting
- [ ] Vehicle type chip visible in booking details
- [ ] Revenue totals use vehicle-specific pricing
- [ ] Can identify which vehicle type was used

### Database
- [ ] `price_amount` contains vehicle-specific price
- [ ] `calculated_price` matches `price_amount`
- [ ] `vehicle_type` field contains vehicle name
- [ ] `pricing_modifiers` contains all required fields

## Database Queries

### Revenue by Vehicle Type
```sql
SELECT 
    vehicle_type,
    COUNT(*) as deliveries,
    SUM(price_amount) as total_revenue,
    SUM(price_amount * 0.3333) as company_commission,
    SUM(price_amount * 0.6667) as runner_earnings,
    AVG(price_amount) as avg_delivery_price
FROM errands
WHERE category = 'delivery'
    AND vehicle_type IS NOT NULL
    AND status = 'completed'
GROUP BY vehicle_type
ORDER BY total_revenue DESC;
```

### Example Results:
```
vehicle_type | deliveries | total_revenue | commission | runner_earnings | avg_price
Motorcycle   | 150        | 6450.00       | 2148.64    | 4301.36        | 43.00
Sedan        | 75         | 5625.00       | 1873.69    | 3751.31        | 75.00
Mini Truck   | 30         | 5130.00       | 1708.29    | 3421.71        | 171.00
Truck        | 10         | 3500.00       | 1165.50    | 2334.50        | 350.00
```

### Most Popular Vehicle Type by Delivery Type
```sql
SELECT 
    pricing_modifiers->>'delivery_type' as delivery_type,
    vehicle_type,
    COUNT(*) as count,
    SUM(price_amount) as revenue
FROM errands
WHERE category = 'delivery'
    AND vehicle_type IS NOT NULL
GROUP BY pricing_modifiers->>'delivery_type', vehicle_type
ORDER BY delivery_type, count DESC;
```

## Future Enhancements

### 1. Dynamic Pricing from Database
Fetch vehicle prices from database instead of hardcoding:
```dart
Future<double> _getVehiclePriceFromDB(String vehicleTypeId) async {
  final pricing = await SupabaseConfig.getVehiclePricing(vehicleTypeId);
  return pricing['base_price'] ?? 0.0;
}
```

### 2. Distance-Based Pricing
Add per-kilometer charges:
```dart
final basePrice = 43.0;  // Motorcycle base
final pricePerKm = 2.5;   // N$2.50 per km
final distance = 10.0;    // 10 km
final totalPrice = basePrice + (distance * pricePerKm);  // N$68.00
```

### 3. Peak Hour Multipliers
```dart
final isPeakHour = _isPeakHour(DateTime.now());
final multiplier = isPeakHour ? 1.5 : 1.0;
final adjustedPrice = basePrice * multiplier;
```

### 4. Weight-Based Pricing
For package deliveries, adjust price based on package weight:
```dart
final vehiclePrice = _getVehiclePrice(vehicleName);
final weightSurcharge = weight > 20 ? (weight - 20) * 5 : 0;
final totalPrice = vehiclePrice + weightSurcharge;
```

## Files Modified

1. ✅ `lib/pages/delivery_form_page.dart`
   - Updated `pricing_modifiers` to include `service_type` and `service_type_price`
   - Vehicle type now stored consistently with other service types

2. ✅ `lib/pages/runner_wallet_page.dart`
   - Added vehicle type names to `_getServiceTypeName()` method
   - Wallet now displays vehicle type badges on delivery bookings

3. ✅ `lib/pages/admin/provider_accounting_page.dart`
   - Added vehicle type names to `_getServiceTypeName()` method
   - Admin can now see vehicle types in booking details

## Integration with Other Services

### How Delivery Pricing Differs from License Discs & Documents:

| Feature | License Discs | Documents | Delivery |
|---------|--------------|-----------|----------|
| **Pricing Factor** | Service Type | Service Type | Vehicle Type |
| **Business Pricing** | Yes (+40%) | Yes (+40%) | No |
| **Examples** | Renewal/Registration | Certification/Application | Motorcycle/Truck |
| **Price Range** | N$150-1500 | N$150-280 | N$43-350 |
| **Stored In** | `service_type` | `service_type` | `vehicle_type` + `service_type` |

### Common Pattern:
All three services use the same storage pattern in `pricing_modifiers`:
```json
{
  "service_type": "renewal" | "certification" | "Motorcycle",
  "service_type_price": 250.00,
  "user_type": "individual" | "business"
}
```

This allows the wallet and accounting pages to display pricing details consistently across all service categories.

## Summary

The delivery form now properly stores vehicle-specific pricing in the database using the same pattern as license discs and document services. The runner wallet and admin accounting pages recognize and display vehicle types, ensuring accurate commission calculations and revenue tracking.

**Key Points:**
- ✅ Each vehicle type has its own price
- ✅ Prices stored in `price_amount` and `pricing_modifiers`
- ✅ Vehicle type stored as `service_type` for consistency
- ✅ Wallet shows vehicle type badges
- ✅ Admin accounting shows vehicle type chips
- ✅ Commission (33.3%) calculated correctly from vehicle price
- ✅ Runner earnings (66.7%) calculated correctly from vehicle price

