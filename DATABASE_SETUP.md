# 🗂️ Lotto Runners Database Setup Guide

## 🚨 Critical Issues Fixed

This setup guide addresses critical database issues that were causing the Flutter app to malfunction:

### Issues That Were Fixed:
1. **Column Name Mismatch**: `profile_image_url` → `avatar_url`
2. **Storage Bucket Mismatch**: `profile-images` → `profiles`  
3. **Missing Payment Policies**: Added RLS policies for payments table
4. **Missing Triggers**: Added `updated_at` triggers to all tables
5. **Missing Indexes**: Added performance indexes

---

## 📋 Setup Instructions

### Option 1: Fresh Database Setup (Recommended)

If you're setting up a new Supabase project:

1. **Create a new Supabase project**
2. **Run the scripts in this order**:
   ```sql
   -- 1. Create tables and basic structure
   -- Copy and paste: lib/supabase/supabase_tables.sql
   
   -- 2. Set up security policies  
   -- Copy and paste: lib/supabase/supabase_policies.sql
   
   -- 3. Add sample data (optional)
   -- Copy and paste: lib/supabase/sample_data.sql
   ```

### Option 2: Fix Existing Database

If you already have a Supabase database with issues:

1. **Run the migration script**:
   ```sql
   -- Copy and paste: lib/supabase/database_migration_fix.sql
   ```

This will safely fix all issues without losing data.

---

## 🔧 Supabase Dashboard Setup

### 1. Storage Buckets

Ensure these buckets exist in **Storage > Buckets**:

- ✅ `errand-images` (Public)
- ✅ `profiles` (Public) 
- ✅ `verification-docs` (Private)

### 2. Authentication Settings

In **Authentication > Settings**:

- ✅ Enable email confirmations
- ✅ Set up email templates
- ✅ Configure redirect URLs for your Flutter app

### 3. API Keys

In **Settings > API**:

- ✅ Copy your **Project URL** 
- ✅ Copy your **anon/public key**
- ✅ Update `lib/supabase/supabase_config.dart`

---

## 🎯 Verification Steps

After setup, verify everything works:

### 1. Database Structure
```sql
-- Check if all tables exist
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';

-- Verify avatar_url column exists
SELECT column_name FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'avatar_url';
```

### 2. Storage Buckets
```sql
-- Check buckets
SELECT id, name, public FROM storage.buckets;
```

### 3. RLS Policies
```sql
-- Check RLS is enabled
SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname = 'public';
```

### 4. Test Flutter App
- ✅ User registration works
- ✅ Profile images upload successfully  
- ✅ Errands can be created and viewed
- ✅ Runner applications work
- ✅ No console errors

---

## 🔍 Troubleshooting

### Common Issues:

**Profile images not uploading?**
- Check if `profiles` bucket exists and is public
- Verify storage policies are correct
- Check Flutter app uses correct bucket name

**User data not saving?**
- Verify `avatar_url` column exists (not `profile_image_url`)
- Check RLS policies allow user operations
- Ensure triggers are working

**Authentication issues?**
- Verify API keys are correct in Flutter app
- Check Supabase URL is correct
- Ensure email confirmations are set up

### Debug Commands:
```sql
-- Check recent errors
SELECT * FROM auth.audit_log_entries ORDER BY created_at DESC LIMIT 10;

-- Check user profiles
SELECT id, email, full_name, avatar_url FROM users;

-- Check bucket policies
SELECT * FROM storage.objects WHERE bucket_id = 'profiles';
```

---

## 🚀 Next Steps

1. **Apply the fixes** using the migration script
2. **Update your Flutter app** configuration if needed
3. **Test all functionality** thoroughly
4. **Deploy to production** with confidence

---

## 📞 Support

If you encounter any issues:
1. Check the console errors in your Flutter app
2. Review Supabase logs in the dashboard
3. Verify all policies and triggers are in place
4. Test with sample data first

**All critical database issues have been identified and fixed!** 🎉 