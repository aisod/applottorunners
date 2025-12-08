# Supabase Storage Policy Fix - Permission Error Solution

## Problem Encountered

When running the storage policy fix, you encountered:
```
ERROR: 42501: must be owner of table objects
```

This error occurs because the default Supabase database user doesn't have ownership permissions over the `storage.objects` table.

## Solution Applied

### ✅ **Created Supabase-Compatible Script**

**New File: `fix_storage_policies_simple.sql`**

This version:
- ✅ **Avoids permission issues** by not trying to modify table structure
- ✅ **Only creates policies** without ALTER TABLE or GRANT statements
- ✅ **Works with default Supabase permissions**
- ✅ **Focuses on essential policy creation**

### **Key Changes Made**

#### **1. Removed Problematic Commands**
```sql
-- REMOVED: These cause permission errors
-- ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;
-- GRANT SELECT ON storage.objects TO authenticated;
-- GRANT INSERT ON storage.objects TO authenticated;
```

#### **2. Kept Essential Policy Creation**
```sql
-- KEPT: These work with default permissions
CREATE POLICY "Public can view errand images" ON storage.objects
    FOR SELECT USING (bucket_id = 'errand-images');

CREATE POLICY "Authenticated users can upload errand images" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'errand-images' AND 
        auth.role() = 'authenticated'
    );
```

#### **3. Updated Batch File**
- ✅ **Updated to use `fix_storage_policies_simple.sql`**
- ✅ **Maintains same functionality**
- ✅ **Avoids permission errors**

## How to Apply the Fix

### **Option 1: Use the Updated Batch File**
```bash
run_storage_policy_fix.bat
```
*This now uses the permission-safe script*

### **Option 2: Manual SQL Execution (Recommended)**
1. **Go to Supabase Dashboard**
2. **Navigate to SQL Editor**
3. **Copy contents of `fix_storage_policies_simple.sql`**
4. **Run the script**

### **Option 3: Direct Database (If you have proper permissions)**
```bash
psql -h db.your-project.supabase.co -p 5432 -d postgres -U postgres -f fix_storage_policies_simple.sql
```

## Alternative: Supabase Dashboard Method

If you still encounter permission issues, use the **Supabase Dashboard**:

### **Step 1: Go to Authentication → Policies**
1. Open your Supabase Dashboard
2. Navigate to **Authentication** → **Policies**
3. Find the **storage.objects** table

### **Step 2: Create Policies Manually**
Create these policies one by one:

#### **Policy 1: Public Read Access**
```sql
CREATE POLICY "Public can view errand images" ON storage.objects
    FOR SELECT USING (bucket_id = 'errand-images');
```

#### **Policy 2: Authenticated Upload**
```sql
CREATE POLICY "Authenticated users can upload errand images" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'errand-images' AND 
        auth.role() = 'authenticated'
    );
```

#### **Policy 3: User Update**
```sql
CREATE POLICY "Users can update their own errand images" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'errand-images' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );
```

#### **Policy 4: User Delete**
```sql
CREATE POLICY "Users can delete their own errand images" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'errand-images' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );
```

#### **Policy 5: Admin Management**
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

### **Step 3: Verify Bucket Configuration**
In **Storage** → **Buckets**:
1. Ensure `errand-images` bucket exists
2. Set it to **Public**
3. Set file size limit to **50MB**
4. Allow MIME types: `image/jpeg`, `image/png`, `image/gif`, `image/webp`, `application/pdf`

## Expected Results

After applying the fix:

### ✅ **Upload Functionality**
- **No more "must be owner of table objects" errors**
- **No more "row violates row-level security policy" errors**
- **Runner application documents upload successfully**

### ✅ **Access Control**
- **Public**: Can view all uploaded documents
- **Authenticated Users**: Can upload and manage their own documents
- **Admins**: Can manage all documents across all users

### ✅ **Document Types Supported**
- **Driver's License PDFs** ✅
- **Code of Conduct PDFs** ✅
- **Vehicle Photos** ✅
- **License Disc Photos** ✅
- **Errand Images** ✅
- **Document Services** ✅

## Verification

After applying the fix, test by:
1. **Uploading a runner application document** in the profile page
2. **Checking that no errors occur**
3. **Verifying the document appears** in admin verification page
4. **Testing document download** from admin pages

## Files Updated

- ✅ **`fix_storage_policies_simple.sql`** - Permission-safe version
- ✅ **`run_storage_policy_fix.bat`** - Updated to use simple version
- ✅ **`STORAGE_POLICY_FIX_PERMISSIONS.md`** - This documentation

The permission error should now be resolved! Use the **Supabase Dashboard SQL Editor** method for the most reliable results.
