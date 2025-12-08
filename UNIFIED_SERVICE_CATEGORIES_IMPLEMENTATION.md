# Unified Service Categories Implementation

## Overview

This implementation provides a comprehensive unified form structure for the Lotto Runners app that dynamically adapts to different service categories. Each service type has specific required fields while maintaining a consistent user experience.

## ✅ Implemented Features

### 1. **Enhanced Post Errand Form Page**
- **File**: `lib/pages/enhanced_post_errand_form_page.dart`
- **Features**:
  - Dynamic form fields based on service category
  - Category-specific validation
  - Unified pricing calculation
  - Enhanced user experience with clear section organization

### 2. **Service Categories & Required Fields**

#### **Queue Sitting**
- **Fields**:
  - Location (where queue sitting is needed)
  - Time customer will arrive (date + time picker)
  - Service Type: **Now** (+N$30 surcharge) or **Scheduled**
- **Pricing**: Base price + N$30 if "Now" is selected
- **Final Price**: Calculated and displayed only after Submit

#### **License Discs / Vehicle**
- **Fields**:
  - Pickup Location (where to collect documents/vehicle)
  - Drop-off Location (where to deliver license disc)
  - Date of service
- **Requires Vehicle**: True (automatically enforced)

#### **Shopping**
- **Fields**:
  - Pickup Location (where to start shopping)
  - Drop-off Location (where to deliver purchases)
  - Date of errand
  - Stores (1 or more) - dynamic list with add/remove
  - Products (1 or more per store) - dynamic list per store
- **Advanced UI**: Card-based store sections with expandable product lists

#### **Document Services**
- **Fields**:
  - Service Type dropdown: **Certify** / **Copies** / **Other**
  - Pickup Location (where to collect documents)
  - Drop-off Location (where to deliver processed documents)

#### **Elderly Services**
- **Fields**:
  - Description of service (detailed text area)
  - Pickup Location (where to meet elderly person)
  - Drop-off Location (optional - where to accompany/deliver)

#### **Registration**
- **Fields**:
  - Pickup Location (where to collect documents/information)
  - Drop-off Location (where to deliver completed registration)
  - Description (detailed text area)

### 3. **Common Fields (All Services)**
- Special Instructions (optional text field)
- Vehicle Option (Yes/No toggle when required)
- Image attachments (optional)
- Final Price calculation and display

### 4. **Database Schema Updates**
- **File**: `lib/supabase/unified_errand_categories.sql`
- **New Columns Added**:
  ```sql
  - service_type TEXT
  - queue_type TEXT (now/scheduled)
  - customer_arrival_time TIMESTAMP
  - stores JSONB (for shopping category)
  - products JSONB (for shopping category)
  - pricing_modifiers JSONB
  - calculated_price DECIMAL(10,2)
  - location_latitude/longitude DECIMAL
  - pickup_latitude/longitude DECIMAL
  - delivery_latitude/longitude DECIMAL
  ```
- **New Service Categories**:
  - queue_sitting
  - license_discs
  - document_services
  - elderly_services
  - registration

### 5. **Dynamic Pricing System**
- **Base Pricing**: Different rates for individual vs business users
- **Modifiers**: 
  - Queue Sitting "Now" service: +N$30 surcharge
  - Business users: +40% markup
- **Price Display**: Only shown after form submission for transparency
- **Calculation Function**: SQL function for consistent pricing logic

### 6. **Enhanced UX Features**
- **Progressive Disclosure**: Fields appear based on selected service category
- **Smart Validation**: Category-specific validation rules
- **Visual Hierarchy**: Clear section titles and organized layouts
- **Responsive Design**: Works on mobile and desktop
- **Loading States**: Clear feedback during form submission
- **Error Handling**: Specific error messages for different failure scenarios

## 🔧 Implementation Details

### Form Structure
```dart
// Dynamic field generation based on category
List<Widget> _buildCategorySpecificFields(ThemeData theme, bool isMobile) {
  switch (_getServiceCategory()) {
    case 'queue_sitting': return _buildQueueSittingFields(theme, isMobile);
    case 'license_discs': return _buildLicenseDiscsFields(theme, isMobile);
    case 'shopping': return _buildShoppingFields(theme, isMobile);
    // ... other categories
  }
}
```

### Pricing Logic
```dart
double _calculateFinalPrice() {
  double basePrice = _getBaseServicePrice();
  
  // Apply queue sitting "now" surcharge
  if (_getServiceCategory() == 'queue_sitting' && _queueType == 'now') {
    basePrice += 30.0;
  }
  
  return basePrice;
}
```

### Shopping Category Special Features
- **Dynamic Store Management**: Add/remove stores with dedicated controllers
- **Product Lists**: Each store has its own expandable product list
- **Validation**: Ensures at least one store with one product
- **Data Structure**: Stores as JSON array with nested products

```dart
final storesData = _stores.map((store) {
  final storeIndex = _stores.indexOf(store);
  return {
    'name': store['name'],
    'products': _storeProducts[storeIndex.toString()] ?? [],
  };
}).toList();
```

## 📱 User Flow

1. **Service Selection**: User selects service from enhanced service selection page
2. **Dynamic Form**: Form adapts to show category-specific fields
3. **Form Completion**: User fills required fields with smart validation
4. **Price Calculation**: System calculates final price (including modifiers)
5. **Confirmation**: User reviews errand details and final price
6. **Submission**: Errand is created with all category-specific data

## 🚀 Next Steps

### Database Migration Required
1. **Run SQL Script**: Execute `lib/supabase/unified_errand_categories.sql` in Supabase dashboard
2. **Update Service Data**: Add new service categories to your services table
3. **Test Categories**: Verify all service categories work correctly

### Optional Enhancements
1. **Service Templates**: Pre-filled forms for common service types
2. **Price Estimates**: Real-time price updates as user fills form
3. **Location Intelligence**: Suggest nearby stores for shopping category
4. **Recurring Services**: Allow users to create repeating errands

## 🎯 Benefits

1. **User Experience**: Streamlined, category-specific forms reduce confusion
2. **Data Quality**: Structured data collection improves service matching
3. **Pricing Transparency**: Clear pricing rules with modifiers clearly shown
4. **Scalability**: Easy to add new service categories
5. **Maintainability**: Clean, modular code structure
6. **Business Logic**: Proper separation of pricing rules and service logic

## 📊 Technical Specifications

- **Form Validation**: Category-specific validation rules
- **State Management**: Local state with proper cleanup
- **Image Handling**: Multiple image upload with preview
- **Location Services**: Integrated location picker for all location fields
- **Error Handling**: Comprehensive error handling with user feedback
- **Performance**: Optimized rendering with conditional widget building

This implementation provides a robust foundation for handling diverse service categories while maintaining code quality and user experience standards.

