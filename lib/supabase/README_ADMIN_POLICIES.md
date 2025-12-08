# Admin Policies for Lotto Runners Application

This directory contains SQL files that establish comprehensive admin policies for the Lotto Runners application, allowing admin users to read and write data across all tables in the system.

## Files Overview

### 1. `admin_policies.sql` - Comprehensive Admin Policies
- **Full version** with detailed policies for each table
- **Explicit policies** for SELECT, INSERT, UPDATE, DELETE operations
- **Detailed comments** explaining each policy
- **Suitable for** production environments where you need explicit control

### 2. `admin_policies_simplified.sql` - Simplified Admin Policies
- **Streamlined version** using a helper function
- **Cleaner syntax** with `FOR ALL USING (is_admin())`
- **Easier to maintain** and modify
- **Recommended for** most use cases

## What These Policies Provide

### Core Tables Access
- **Users**: Full CRUD operations on all user accounts
- **Errands**: Complete management of all errand requests
- **Runner Applications**: Full oversight of runner verification process
- **Errand Updates**: Access to all communication and status updates
- **Reviews**: Management of all user feedback and ratings
- **Payments**: Complete financial transaction oversight

### Transportation System Access
- **Service Categories & Subcategories**: Manage service offerings
- **Vehicle Types**: Configure available vehicle options
- **Towns & Routes**: Geographic and routing management
- **Service Providers**: Oversee transportation companies
- **Schedules & Pricing**: Manage service availability and costs
- **Bookings & Reviews**: Full booking oversight and feedback management

### Storage Access
- **Errand Images**: Access to all uploaded errand photos
- **Profile Images**: User profile picture management
- **Verification Documents**: Access to runner verification files

## How to Use

### Option 1: Use the Simplified Version (Recommended)
```sql
-- Run this file in your Supabase SQL editor
\i admin_policies_simplified.sql
```

### Option 2: Use the Comprehensive Version
```sql
-- Run this file in your Supabase SQL editor
\i admin_policies.sql
```

## Prerequisites

1. **Admin User**: Ensure you have at least one user with `user_type = 'admin'`
2. **RLS Enabled**: Row Level Security must be enabled on all tables
3. **Existing Tables**: All referenced tables must exist in your database

## Creating an Admin User

If you don't have an admin user yet, you can create one using:

```sql
-- Insert admin user (replace with actual values)
INSERT INTO users (id, email, full_name, user_type, is_verified)
VALUES (
    'your-uuid-here',
    'admin@lottorunners.com',
    'System Administrator',
    'admin',
    true
);
```

## Verification

After running the policies, you can verify they're working:

```sql
-- Check if admin policies are in place
SELECT 
    tablename,
    policyname,
    cmd
FROM pg_policies 
WHERE policyname LIKE '%admin%' OR policyname LIKE '%Admin%'
ORDER BY tablename, policyname;

-- Test the is_admin function
SELECT is_admin() as is_admin_user;
```

## Security Features

- **Role-Based Access**: Only users with `user_type = 'admin'` can access
- **Function Security**: Helper function uses `SECURITY DEFINER` for proper execution context
- **Comprehensive Coverage**: Covers all tables and storage buckets
- **Audit Trail**: Policies are clearly named for easy tracking

## Troubleshooting

### Common Issues

1. **Policy Already Exists**: If you get "policy already exists" errors, drop existing policies first:
   ```sql
   DROP POLICY IF EXISTS "Policy Name" ON table_name;
   ```

2. **Function Already Exists**: The helper function will be replaced automatically

3. **RLS Not Enabled**: Ensure Row Level Security is enabled on all tables

### Testing Admin Access

```sql
-- Test admin access to users table
SELECT * FROM users LIMIT 5;

-- Test admin access to errands table  
SELECT * FROM errands LIMIT 5;

-- Test admin access to transportation services
SELECT * FROM transportation_services LIMIT 5;
```

## Maintenance

- **Regular Review**: Periodically review admin policies for security
- **User Management**: Ensure only necessary users have admin privileges
- **Policy Updates**: Update policies when adding new tables or changing requirements

## Support

For issues or questions about these admin policies:
1. Check the verification queries for policy status
2. Ensure your user has admin privileges
3. Verify all tables exist and RLS is enabled
4. Check Supabase logs for any policy-related errors
