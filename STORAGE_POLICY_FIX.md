# Storage Policy Fix for Runner Application Documents

## Problem Identified

The error message shows:
```
Exception: Failed to upload image: StorageException 
(message: new row violates row-level security policy, statusCode: 403, error: Unauthorized)
```

This occurs when trying to upload runner application documents (driver's license, code of conduct, vehicle photos, license disc photos) to the Supabase storage bucket.

## Root Cause

The `errand-images` storage bucket has Row Level Security (RLS) policies that are either:
1. **Missing** - No policies allowing authenticated users to upload
2. **Conflicting** - Multiple policies with different rules
3. **Incorrectly configured** - Policies don't match the expected user permissions

## Solution Applied

### 1. Comprehensive Policy Setup

The fix creates a complete set of RLS policies for the `errand-images` bucket:

#### **Public Read Access**
```sql
CREATE POLICY "Public can view errand images" ON storage.objects
    FOR SELECT USING (bucket_id = 'errand-images');
```

#### **Authenticated Upload Access**
```sql
CREATE POLICY "Authenticated users can upload errand images" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'errand-images' AND 
        auth.role() = 'authenticated'
    );
```

#### **User-Specific Management**
```sql
CREATE POLICY "Users can update their own errand images" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'errand-images' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Users can delete their own errand images" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'errand-images' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );
```

#### **Admin Full Access**
```sql
CREATE POLICY "Admins can manage all errand images" ON storage.objects
    FOR ALL USING (
        bucket_id = 'errand-images' AND
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.user_type = 'admin'
        )
    );
```

### 2. Bucket Configuration

Ensures the `errand-images` bucket is properly configured:

```sql
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'errand-images', 
    'errand-images', 
    true, 
    52428800, -- 50MB limit
    ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'application/pdf']
)
ON CONFLICT (id) DO UPDATE SET
    public = true,
    file_size_limit = 52428800,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'application/pdf'];
```

### 3. Permission Grants

Grants necessary permissions to authenticated and anonymous users:

```sql
-- Authenticated users can perform all operations
GRANT SELECT ON storage.objects TO authenticated;
GRANT INSERT ON storage.objects TO authenticated;
GRANT UPDATE ON storage.objects TO authenticated;
GRANT DELETE ON storage.objects TO authenticated;

-- Anonymous users can read public content
GRANT SELECT ON storage.objects TO anon;
```

## Files Created

1. **`fix_storage_policies.sql`** - Complete SQL script to fix storage policies
2. **`run_storage_policy_fix.bat`** - Batch file to execute the SQL script
3. **`STORAGE_POLICY_FIX.md`** - This documentation file

## How to Apply the Fix

### Option 1: Using the Batch File
```bash
run_storage_policy_fix.bat
```

### Option 2: Manual Execution
1. Go to your Supabase Dashboard
2. Navigate to SQL Editor
3. Copy and paste the contents of `fix_storage_policies.sql`
4. Run the script

### Option 3: Direct Database Connection
```bash
psql -h db.your-project.supabase.co -p 5432 -d postgres -U postgres -f fix_storage_policies.sql
```

## Expected Results

After applying the fix:

### ✅ **Upload Functionality**
- Runner application documents can be uploaded successfully
- No more "row violates row-level security policy" errors
- Proper file size limits (50MB) and MIME type restrictions

### ✅ **Access Control**
- **Public**: Can view all uploaded documents
- **Authenticated Users**: Can upload and manage their own documents
- **Admins**: Can manage all documents across all users

### ✅ **File Management**
- Users can update their own uploaded documents
- Users can delete their own uploaded documents
- Admins can manage any user's documents

## Verification

The script includes verification queries to confirm the fix:

```sql
-- Verify policies are in place
SELECT policyname, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'objects' 
AND schemaname = 'storage'
AND policyname LIKE '%errand%';

-- Verify bucket configuration
SELECT id, name, public, file_size_limit, allowed_mime_types
FROM storage.buckets 
WHERE id = 'errand-images';

-- Test current user permissions
SELECT auth.uid() as current_user_id, auth.role() as current_role
FROM users u 
WHERE u.id = auth.uid();
```

## Impact

This fix resolves the storage upload issues for:
- **Driver's License PDFs** - Runner applications
- **Code of Conduct PDFs** - Runner applications  
- **Vehicle Photos** - Multiple images per runner
- **License Disc Photos** - Multiple images per runner
- **Errand Images** - Customer uploaded images
- **Document Services** - Customer uploaded files

All document upload functionality should now work correctly across the entire application.
