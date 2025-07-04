# Profile Image Upload Setup Guide

Follow these steps **in order** to set up profile image uploads in your Lotto Runners app.

## Step 1: Create Storage Bucket in Supabase Dashboard

1. **Go to your Supabase Dashboard**: https://supabase.com/dashboard
2. **Select your Lotto Runners project**
3. **Navigate to Storage** (in the left sidebar)
4. **Create a new bucket**:
   - Click "**New bucket**"
   - **Bucket name**: `profiles`
   - **Public bucket**: ✅ **Enable this checkbox** (important!)
   - Click "**Create bucket**"

## Step 2: Run SQL Setup Script

1. **Go to SQL Editor** in your Supabase dashboard
2. **Create a new query**
3. **Copy and paste** the entire content from `lib/supabase/storage_setup.sql`
4. **Run the query**
5. **Verify** you see "Storage setup completed successfully!" message

## Step 3: Verify Setup

1. **Go to Storage > profiles bucket**
2. **Check Policies tab** - you should see 4 policies created:
   - "Users can upload own profile images"
   - "Public can view profile images" 
   - "Users can update own profile images"
   - "Users can delete own profile images"

## Step 4: Test the App

1. **Restart your Flutter app** completely (stop and start again)
2. **Navigate to Profile page**
3. **Click the camera icon** on your profile picture
4. **Try uploading an image** from gallery or camera
5. **Check home page** - your profile image should appear there too!

## Troubleshooting

### If you still get "Bucket not found" error:
- Double-check the bucket name is exactly `profiles` (lowercase)
- Make sure the bucket is marked as **Public**
- Try refreshing your Supabase dashboard

### If upload fails with permission error:
- Re-run the SQL setup script
- Check that all 4 storage policies are present
- Verify the bucket is public

### If image doesn't appear:
- Check browser developer tools for any network errors
- Verify the image URL is accessible by opening it in a new tab
- Try a hot restart in Flutter (`r` key when app is running)

## How It Works

1. **User uploads image** → Stored in `profiles/{user_id}/profile_timestamp.jpg`
2. **Old images are automatically removed** to save storage space
3. **Avatar URL is saved** in users table `avatar_url` column
4. **Home page displays** the image from `avatar_url`
5. **Images are publicly accessible** but organized by user folders

## File Structure in Storage

```
profiles/
├── user-uuid-1/
│   └── profile_1234567890.jpg
├── user-uuid-2/
│   └── profile_1234567891.jpg
└── ...
```

The app is now ready for profile image uploads! 🎉 