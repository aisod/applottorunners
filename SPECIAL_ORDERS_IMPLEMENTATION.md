# Special Orders Management System - Implementation Summary

## Overview
This implementation adds a complete special orders management system where:
1. Customers submit special order requests without seeing prices
2. Admin reviews requests and sets custom prices
3. Customers receive price quotes and must approve
4. Approved orders become available to runners

## Changes Made

### 1. Service Selection Page (`lib/pages/service_selection_page.dart`)
- **Price Display**: Special orders now show "Varies" instead of a fixed price
- Updated both discounted and regular price displays to handle special_orders category

### 2. Enhanced Post Errand Form (`lib/pages/enhanced_post_errand_form_page.dart`)
- **Removed Price Banner**: Price header is hidden for special orders
- **Updated Submit Button**: Shows "Submit Special Order Request" without price
- **Status Handling**: Special orders are created with status `'pending_price'`
- **Success Message**: Shows custom message informing user admin will contact them

### 3. Admin Special Orders Management Page (`lib/pages/admin/special_orders_management_page.dart`)
**NEW FILE** - Complete admin interface for managing special orders:

**Features**:
- Two tabs: "Pending" and "Quoted"
- View all special order details
- Set custom prices for orders
- Add admin notes for customers
- Send price quotes to customers

**Workflow**:
1. Admin sees pending special orders
2. Admin clicks "Set Price" button
3. Admin enters price and optional notes
4. System sends quote to customer
5. Order moves to "Quoted" tab
6. Customer approves/rejects quote
7. Approved orders become available to runners

## Database Schema Requirements

### Errands Table Updates
The errands table needs these fields:
- `status` VARCHAR - Add 'pending_price' and 'price_quoted' statuses
- `quoted_price` DECIMAL(10,2) - The admin's price quote
- `admin_notes` TEXT - Notes from admin to customer

### Status Flow
```
Special Order Statuses:
1. pending_price   → Initial state when customer submits
2. price_quoted    → Admin has set a price
3. pending         → Customer approved, available to runners
4. rejected        → Customer rejected the quote
```

## Required SupabaseConfig Methods

Add these methods to `lib/supabase/supabase_config.dart`:

```dart
// Get all special orders for admin
static Future<List<Map<String, dynamic>>> getSpecialOrdersForAdmin() async {
  try {
    final response = await supabase
        .from('errands')
        .select('''
          *,
          customer:users!errands_customer_id_fkey(id, full_name, phone, email)
        ''')
        .eq('category', 'special_orders')
        .inFilter('status', ['pending_price', 'price_quoted'])
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    print('Error getting special orders for admin: $e');
    rethrow;
  }
}

// Set price for special order
static Future<void> setSpecialOrderPrice(
  String errandId,
  double price,
  String adminNotes,
) async {
  try {
    await supabase.from('errands').update({
      'quoted_price': price,
      'price_amount': price,
      'calculated_price': price,
      'admin_notes': adminNotes,
      'status': 'price_quoted',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', errandId);
    
    // TODO: Send notification to customer about price quote
    
  } catch (e) {
    print('Error setting special order price: $e');
    rethrow;
  }
}

// Customer approves price quote
static Future<void> approveSpecialOrderPrice(String errandId) async {
  try {
    await supabase.from('errands').update({
      'status': 'pending', // Now available to runners
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', errandId);
  } catch (e) {
    print('Error approving special order: $e');
    rethrow;
  }
}

// Customer rejects price quote
static Future<void> rejectSpecialOrderPrice(String errandId) async {
  try {
    await supabase.from('errands').update({
      'status': 'rejected',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', errandId);
  } catch (e) {
    print('Error rejecting special order: $e');
    rethrow;
  }
}
```

## Database Migration SQL

⚠️ **IMPORTANT**: Run this SQL migration file first: `add_special_orders_category.sql`

This adds `special_orders` to the allowed categories in the errands table constraint.

Then run this SQL to update the errands table:

```sql
-- Add new columns if they don't exist
ALTER TABLE errands 
ADD COLUMN IF NOT EXISTS quoted_price DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS admin_notes TEXT;

-- Add comment for status field to document new statuses
COMMENT ON COLUMN errands.status IS 
'Status values: posted, pending, pending_price (special orders awaiting price), price_quoted (quote sent to customer), accepted, in_progress, completed, cancelled, rejected (quote rejected)';

-- Create index for admin queries
CREATE INDEX IF NOT EXISTS idx_errands_special_orders_admin 
ON errands(category, status) 
WHERE category = 'special_orders';
```

### Error Fix
If you see this error:
```
PostgrestException(message: new row for relation "errands" violates check constraint "errands_category_check", code: 23514)
```

It means the category constraint hasn't been updated yet. Run `add_special_orders_category.sql` immediately.

## Admin Dashboard Integration

Add button to admin dashboard to access special orders management:

```dart
// In admin dashboard, add navigation button:
ElevatedButton.icon(
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const SpecialOrdersManagementPage(),
    ),
  ),
  icon: const Icon(Icons.shopping_bag),
  label: const Text('Special Orders'),
)
```

## Customer Order View

### For Orders with Status 'price_quoted'
Show in customer's orders with:
- Special badge: "Price Quote Received"
- Display quoted price
- Show admin notes if any
- Buttons: "Approve" and "Reject"

### UI Example
```dart
if (order['status'] == 'price_quoted') {
  return Card(
    child: Column(
      children: [
        Text('Price Quote: N\$${order['quoted_price']}'),
        if (order['admin_notes'] != null)
          Text(order['admin_notes']),
        Row(
          children: [
            ElevatedButton(
              onPressed: () => approveQuote(order['id']),
              child: Text('Approve'),
            ),
            OutlinedButton(
              onPressed: () => rejectQuote(order['id']),
              child: Text('Reject'),
            ),
          ],
        ),
      ],
    ),
  );
}
```

## Testing Checklist

### Customer Side:
- [ ] Special orders show "Varies" price in service selection
- [ ] Form doesn't show price banner for special orders
- [ ] Submit button says "Submit Special Order Request"
- [ ] Success message mentions admin contact
- [ ] Order appears in customer's orders with correct status

### Admin Side:
- [ ] Special orders appear in pending tab
- [ ] Can view full order details
- [ ] Can set price and add notes
- [ ] Quote is sent to customer
- [ ] Order moves to quoted tab after pricing

### Approval Flow:
- [ ] Customer receives notification of quote
- [ ] Customer can view quote in their orders
- [ ] Customer can approve quote
- [ ] Approved order appears in available errands for runners
- [ ] Customer can reject quote
- [ ] Rejected order is marked appropriately

## Next Steps

1. **Add SupabaseConfig methods** - Implement the methods listed above
2. **Run database migration** - Execute the SQL to add new columns
3. **Add admin button** - Integrate special orders button in admin dashboard
4. **Customer order view** - Add UI for customers to view and approve quotes
5. **Notifications** - Implement notification system for quote alerts
6. **Testing** - Test complete workflow end-to-end

## Notes

- Special orders never show prices until admin sets them
- Orders stay in pending_price until admin reviews
- Customers must approve before order goes to runners
- Admin can add helpful notes about pricing decisions
- System prevents special orders from appearing in available errands prematurely


