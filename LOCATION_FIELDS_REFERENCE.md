# Location Fields Reference Guide

Quick reference for all service forms and their location field structures.

## Database Field Mapping

| Service Category | Form File | Location Fields Used | Display Format |
|-----------------|-----------|---------------------|----------------|
| **shopping** | `enhanced_shopping_form_page.dart` | • `location_address` (stores)<br>• `delivery_address` (customer) | "Deliver to: [delivery_address]" |
| **delivery** | `delivery_form_page.dart` | • `location_address` (pickup)<br>• `pickup_address` (pickup)<br>• `delivery_address` (destination) | "[pickup] → [delivery]" |
| **license_discs** | `license_discs_form_page.dart` | • `location_address` (varies)<br>• `pickup_address` (optional)<br>• `dropoff_address` (optional) | "[pickup] → [dropoff]" or single location |
| **document_services** | `document_services_form_page.dart` | • `location_address` (primary)<br>• `pickup_location` (if collect & deliver) | "[pickup] → [location]" or single location |
| **elderly_services** | `elderly_services_form_page.dart` | • `location_address` (service location) | "[location_address]" |
| **queue_sitting** | `queue_sitting_form_page.dart` | • `location_address` (queue location) | "[location_address]" |

## Form Controllers to Database Fields

### Shopping Form
```dart
_deliveryLocationController → delivery_address
_stores (array) → location_address (combined string)
```

### Delivery Form
```dart
_pickupLocationController → pickup_address & location_address
_deliveryLocationController → delivery_address
```

### License Discs Form
```dart
_pickupLocationController → pickup_address
_dropoffLocationController → dropoff_address
// One of them also goes to location_address based on service_option
```

### Document Services Form
```dart
_locationController → location_address
_pickupLocationController → pickup_location
```

### Elderly Services Form
```dart
_locationController → location_address
```

### Queue Sitting Form
```dart
_locationController → location_address
```

## Implementation Details

### Helper Method Location
- **ErrandCard Widget:** `lib/widgets/errand_card.dart` - method: `_getDisplayLocation()`
- **Runner Dashboard:** `lib/pages/runner_dashboard_page.dart` - method: `_getDisplayLocation(errand)`

### Display Priority
1. Check category first
2. For route services: Show pickup → destination
3. For single location: Show primary location_address
4. Truncate long addresses (>20 chars)
5. Fall back to "Location TBD" if no location found

## Example Outputs

| Category | Scenario | Display Output |
|----------|----------|----------------|
| Shopping | Store: "Shoprite", Delivery: "123 Main St" | "Deliver to: 123 Main St" |
| Delivery | Pickup: "Office Building A", Delivery: "Residential Complex B" | "Office Building A → Residential Complex..." |
| License Discs | Collect & Deliver | "Home Address → Motor Vehicle Dept" |
| Document Services | Drop off only | "Government Office" |
| Elderly Services | Service at home | "123 Oak Street, Windhoek" |
| Queue Sitting | Hospital queue | "Katutura Hospital" |

## Coordinate Fields

All location fields also store coordinates:
- `location_latitude` / `location_longitude`
- `pickup_latitude` / `pickup_longitude`
- `delivery_latitude` / `delivery_longitude`
- `dropoff_latitude` / `dropoff_longitude`

These can be used for:
- Distance calculations
- Map displays
- Route optimization
- Proximity matching

## Notes
- The `location_address` field is always present in the database
- Some forms duplicate data (e.g., delivery form saves pickup to both `pickup_address` and `location_address`)
- The helper method checks multiple field variations (e.g., `pickup_location` vs `pickup_address`)
- Empty/null values are handled gracefully with fallbacks

