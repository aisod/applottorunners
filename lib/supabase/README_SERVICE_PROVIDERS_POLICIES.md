# Service Providers Policies for Lotto Runners

This directory contains SQL files that establish comprehensive Row Level Security (RLS) policies for the `service_providers` table and other transportation-related tables.

## Files Overview

### 1. `service_providers_policies.sql` - Service Providers Only
- **Focused policies** specifically for the `service_providers` table
- **Basic setup** with public read access and admin full access
- **Suitable for** when you only need to fix service providers policies

### 2. `transportation_policies_complete.sql` - Complete Transportation System
- **Comprehensive policies** for all transportation tables
- **Full RLS setup** including bookings, reviews, and all service tables
- **Recommended for** complete transportation system setup

## What These Policies Provide

### Service Providers Table Access
- **Public Read**: Anyone can view active service providers
- **Admin Full Access**: Admins can create, read, update, and delete all providers
- **RLS Enabled**: Row Level Security is properly configured

### Key Features
- **Active Providers Only**: Public users only see providers with `is_active = true`
- **Admin Override**: Admins can see and manage all providers regardless of status
- **Secure Access**: Uses the `is_admin()` helper function for admin checks

## How to Use

### Option 1: Quick Fix for Service Providers Only
```sql
-- Run this file in your Supabase SQL editor
\i lib/supabase/service_providers_policies.sql
```

### Option 2: Complete Transportation System Setup
```sql
-- Run this file in your Supabase SQL editor
\i lib/supabase/transportation_policies_complete.sql
```

## Prerequisites

1. **Admin User**: Ensure you have at least one user with `user_type = 'admin'`
2. **Tables Exist**: The `service_providers` table must exist in your database
3. **Users Table**: The `users` table must exist with `user_type` field

## Creating an Admin User

If you don't have an admin user yet, create one using:

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

## Policy Details

### Public Access Policy
```sql
CREATE POLICY "Public can view active providers" ON service_providers 
FOR SELECT USING (is_active = true);
```
- **Purpose**: Allows public users to browse available service providers
- **Restriction**: Only shows active providers
- **Use Case**: Transportation page, service selection

### Admin Access Policy
```sql
CREATE POLICY "Admins can manage all providers" ON service_providers 
FOR ALL USING (is_admin());
```
- **Purpose**: Gives admins full CRUD access to all providers
- **Restriction**: Only users with `user_type = 'admin'`
- **Use Case**: Admin transportation management page

## Testing the Policies

After running the policies, test them with:

```sql
-- Test public access (should only see active providers)
SELECT * FROM service_providers WHERE is_active = true;

-- Test admin access (should see all providers)
SELECT * FROM service_providers;

-- Test admin insert
INSERT INTO service_providers (name, description, contact_phone, contact_email, rating, is_active) 
VALUES ('Test Provider', 'Test Description', '+1234567890', 'test@example.com', 4.5, true);

-- Test admin update
UPDATE service_providers SET rating = 5.0 WHERE name = 'Test Provider';

-- Test admin delete
DELETE FROM service_providers WHERE name = 'Test Provider';
```

## Verification

Check if policies are working:

```sql
-- Check if policies are in place
SELECT 
    tablename,
    policyname,
    cmd
FROM pg_policies 
WHERE tablename = 'service_providers'
ORDER BY policyname;

-- Test the is_admin function
SELECT is_admin() as is_admin_user;
```

## Troubleshooting

### Common Issues

1. **"Policy already exists" errors**: The policies will automatically drop existing ones
2. **"Function is_admin() doesn't exist"**: The file creates this function automatically
3. **"Table doesn't exist"**: Make sure to run the transportation system setup first

### If Policies Still Don't Work

1. **Check RLS**: Ensure RLS is enabled on the table
2. **Verify Admin User**: Make sure you have a user with `user_type = 'admin'`
3. **Check Permissions**: Ensure your Supabase user has the right permissions

## Security Features

- **Role-Based Access**: Only admin users can manage providers
- **Function Security**: Helper function uses `SECURITY DEFINER` for proper execution context
- **Public Read-Only**: Public users can only view active providers
- **Admin Full Access**: Admins have complete control over all provider data

## Next Steps

After setting up the policies:

1. **Test the admin interface** in your Flutter app
2. **Verify public access** works correctly
3. **Check that inactive providers** are hidden from public view
4. **Ensure admin operations** work properly

The policies will ensure that your service providers table is properly secured while maintaining the functionality needed for your transportation system.
