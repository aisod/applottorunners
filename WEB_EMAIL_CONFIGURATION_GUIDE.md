# Web Email Configuration Guide

This guide explains how to configure your Supabase email templates and URL settings to work with your web app at `https://app.lottoerunners.com/`.

## Overview

Your app is cross-platform and uses different redirect URLs based on the platform:
- **Web**: `https://app.lottoerunners.com/confirm-email` and `https://app.lottoerunners.com/password-reset`
- **Mobile**: `io.supabase.lottorunners://confirm-email` and `io.supabase.lottorunners://reset-password`

The app code automatically detects the platform and sends the appropriate redirect URL. You need to configure Supabase to accept these URLs.

## Step 1: Configure Redirect URLs in Supabase

1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project: `irfbqpruvkkbylwwikwx`
3. Navigate to **Authentication** → **URL Configuration**
4. In the **Redirect URLs** section, add the following URLs (one per line):

```
io.supabase.lottorunners://**
https://app.lottoerunners.com/**
http://localhost:3000/**
```

**Important Notes:**
- **Use the wildcard pattern `https://app.lottoerunners.com/**`** - This allows ALL paths under your domain
- The `**` wildcard allows all paths under that domain/scheme
- `io.supabase.lottorunners://**` covers all mobile deep links (like `io.supabase.lottorunners://confirm-email` and `io.supabase.lottorunners://reset-password`)
- `https://app.lottoerunners.com/**` covers all web app routes (like `/confirm-email`, `/password-reset`, and any future paths)
- `http://localhost:3000/**` is for local development/testing
- **You do NOT need to add specific paths** like `https://app.lottoerunners.com/password-reset` separately - the wildcard covers them all

5. Click **Save** to apply the changes

## Step 2: Configure Email Templates

### 2.1 Confirm Signup Email Template

1. Go to **Authentication** → **Email Templates**
2. Click on **"Confirm Signup"** template
3. Update the template to use the `{{ .RedirectTo }}` variable (which will automatically use the redirect URL sent by your app):

**HTML Template:**
```html
<h2>Confirm Your Signup</h2>

<p>Follow this link to confirm your user:</p>

<p>
  <a href="{{ .SiteURL }}/auth/v1/verify?token={{ .TokenHash }}&type=signup&redirect_to={{ .RedirectTo }}">
    Confirm Your Signup
  </a>
</p>

<p>Or copy and paste this URL into your browser:</p>
<p>{{ .SiteURL }}/auth/v1/verify?token={{ .TokenHash }}&type=signup&redirect_to={{ .RedirectTo }}</p>
```

**Key Points:**
- Use `{{ .RedirectTo }}` instead of hardcoding a URL
- This variable will automatically be set to:
  - `https://app.lottoerunners.com/confirm-email` for web users
  - `io.supabase.lottorunners://confirm-email` for mobile users

4. Click **Save** to apply changes

### 2.2 Reset Password Email Template

1. Go to **Authentication** → **Email Templates**
2. Click on **"Reset Password"** template
3. Update the template to use the `{{ .RedirectTo }}` variable:

**HTML Template:**
```html
<h2>Reset Password</h2>

<p>Follow this link to reset the password for your account:</p>

<p>
  <a href="{{ .SiteURL }}/auth/v1/verify?token={{ .TokenHash }}&type=recovery&redirect_to={{ .RedirectTo }}">
    Reset Password
  </a>
</p>

<p>Or copy and paste this URL into your browser:</p>
<p>{{ .SiteURL }}/auth/v1/verify?token={{ .TokenHash }}&type=recovery&redirect_to={{ .RedirectTo }}</p>
```

**Key Points:**
- Use `{{ .RedirectTo }}` instead of hardcoding a URL
- This variable will automatically be set to:
  - `https://app.lottoerunners.com/password-reset` for web users
  - `io.supabase.lottorunners://reset-password` for mobile users

4. Click **Save** to apply changes

### 2.3 Magic Link Email Template (if used)

If you use magic links, update the **"Magic Link"** template similarly:

```html
<a href="{{ .SiteURL }}/auth/v1/verify?token={{ .TokenHash }}&type=magiclink&redirect_to={{ .RedirectTo }}">
  Sign In
</a>
```

## Step 3: Configure Site URL (Optional but Recommended)

1. Go to **Settings** → **API**
2. Under **Project URL**, ensure your web app URL is configured:
   - **Site URL**: `https://app.lottoerunners.com`

This helps Supabase generate correct links in emails.

## Step 4: Verify SMTP Configuration

Ensure your SMTP settings are configured:

1. Go to **Settings** → **Authentication** → **SMTP Settings**
2. Verify SMTP is enabled and configured correctly
3. For production, consider using custom SMTP (Gmail, SendGrid, etc.) instead of Supabase's default SMTP

**Default SMTP Limitations:**
- Limited sending rate on free tier
- Emails from `noreply@mail.app.supabase.io`
- May hit rate limits in production

**Custom SMTP Example (Gmail):**
```
Host: smtp.gmail.com
Port: 587
Username: your-email@gmail.com
Password: [App Password - not regular password]
Sender Email: your-email@gmail.com
Sender Name: Lotto Runners
```

## Step 5: Test the Configuration

### Test Email Confirmation

1. Sign up with a new account from your web app
2. Check the email you receive
3. Right-click the confirmation link and "Copy link address"
4. Verify the URL contains:
   - For web: `redirect_to=https://app.lottoerunners.com/confirm-email`
   - For mobile: `redirect_to=io.supabase.lottorunners://confirm-email`
5. Click the link and verify it redirects correctly

### Test Password Reset

1. Request a password reset from your web app
2. Check the email you receive
3. Right-click the reset link and "Copy link address"
4. Verify the URL contains:
   - For web: `redirect_to=https://app.lottoerunners.com/password-reset`
   - For mobile: `redirect_to=io.supabase.lottorunners://reset-password`
5. Click the link and verify it redirects correctly

### Test Resend Email

1. If a user hasn't confirmed their email, use the "Resend Confirmation Email" feature
2. Verify the email uses the correct redirect URL based on the platform

## How It Works

1. **App Code Detection**: Your Flutter app uses `kIsWeb` to detect if running on web or mobile
2. **Platform-Specific URLs**: The app sends the appropriate redirect URL:
   - Web: `https://app.lottoerunners.com/confirm-email` or `https://app.lottoerunners.com/password-reset`
   - Mobile: `io.supabase.lottorunners://confirm-email` or `io.supabase.lottorunners://reset-password`
3. **Email Template**: Supabase email templates use `{{ .RedirectTo }}` which automatically uses the URL sent by your app
4. **User Clicks Link**: The link redirects to the appropriate URL based on the platform

## Troubleshooting

### Issue: Email links redirect to wrong URL

**Solution:**
1. Verify the redirect URLs are added in **Authentication** → **URL Configuration**
2. Check that email templates use `{{ .RedirectTo }}` variable
3. Ensure your app code is using the correct URLs (already configured in `supabase_config.dart`)

### Issue: Web users get mobile deep link URLs

**Solution:**
- This shouldn't happen if `kIsWeb` is working correctly
- Verify your Flutter web build is detecting the platform correctly
- Check browser console for any errors

### Issue: Mobile users get web URLs

**Solution:**
- Verify the app is not running in a web view
- Check that `kIsWeb` returns `false` on mobile devices
- Ensure the mobile app is using the native Flutter app, not a web wrapper

### Issue: Redirect URL not allowed error

**Solution:**
1. Go to **Authentication** → **URL Configuration**
2. Verify all redirect URLs are added (use wildcard patterns):
   - `io.supabase.lottorunners://**` (covers all mobile deep links)
   - `https://app.lottoerunners.com/**` (covers all web paths like `/confirm-email`, `/password-reset`, etc.)
   - `http://localhost:3000/**` (for testing)
3. **Important**: Use the wildcard `**` pattern, NOT specific paths. The wildcard allows all paths under that domain
4. Make sure there are no typos in the URLs
5. Save and try again

### Issue: Emails not being sent

**Solution:**
1. Check **Authentication** → **Logs** for email sending errors
2. Verify SMTP configuration in **Settings** → **Authentication** → **SMTP Settings**
3. Check if you've hit email rate limits (free tier has limits)
4. Verify the email address is valid and not blocked

## Code Reference

The redirect URLs are configured in `lib/supabase/supabase_config.dart`:

- **Sign Up**: Uses `https://app.lottoerunners.com/confirm-email` for web
- **Password Reset**: Uses `https://app.lottoerunners.com/password-reset` for web
- **Resend Email**: Uses `https://app.lottoerunners.com/confirm-email` for web
- **Create User/Admin**: Uses `https://app.lottoerunners.com/confirm-email` for web

All methods automatically detect the platform and use the appropriate URL.

## Quick Checklist

- [ ] Added redirect URLs in **Authentication** → **URL Configuration**
- [ ] Updated "Confirm Signup" email template to use `{{ .RedirectTo }}`
- [ ] Updated "Reset Password" email template to use `{{ .RedirectTo }}`
- [ ] Configured Site URL in **Settings** → **API**
- [ ] Verified SMTP settings are configured
- [ ] Tested email confirmation from web app
- [ ] Tested password reset from web app
- [ ] Tested resend email functionality
- [ ] Verified mobile deep links still work

## Additional Resources

- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [Supabase Email Templates Guide](https://supabase.com/docs/guides/auth/auth-email-templates)
- [Supabase URL Configuration](https://supabase.com/docs/guides/auth/auth-redirects)
- [Flutter Platform Detection](https://api.flutter.dev/flutter/foundation/kIsWeb.html)

