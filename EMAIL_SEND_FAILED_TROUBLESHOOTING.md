# Email Send Failed - Troubleshooting Guide

## Error Message
```
AuthRetryableFetchException: {"code":"unexpected_failure","message":"Error sending confirmation email"}
Status Code: 500
```

## What This Means

This error indicates that Supabase is unable to send the confirmation email. This is a **server-side issue** in your Supabase project configuration, not a code issue.

## Common Causes & Solutions

### 1. SMTP Not Configured (Most Common)

**Problem**: Supabase default SMTP might be disabled or not working.

**Solution**:
1. Go to **Supabase Dashboard** → **Settings** → **Authentication** → **SMTP Settings**
2. Check if SMTP is enabled
3. If using default SMTP, verify it's working
4. **Recommended**: Configure custom SMTP (Gmail, SendGrid, etc.)

**How to Configure Custom SMTP (Gmail Example)**:
```
Host: smtp.gmail.com
Port: 587
Username: your-email@gmail.com
Password: [App Password - NOT your regular password]
Sender Email: your-email@gmail.com
Sender Name: Lotto Runners
```

**Important**: For Gmail, you need an "App Password":
1. Go to https://myaccount.google.com/apppasswords
2. Generate a new app password
3. Use that password (not your regular Gmail password)

### 2. Email Rate Limits Exceeded

**Problem**: Free tier Supabase projects have strict email sending limits.

**Solution**:
1. Go to **Supabase Dashboard** → **Settings** → **Billing**
2. Check your email quota usage
3. Wait for the rate limit to reset (usually hourly)
4. Consider upgrading your plan if you need more emails

**Free Tier Limits**:
- Limited emails per hour
- Limited emails per day
- Check your dashboard for exact limits

### 3. Email Template Configuration Issue

**Problem**: The email template might have invalid redirect URLs or syntax errors.

**Solution**:
1. Go to **Supabase Dashboard** → **Authentication** → **Email Templates**
2. Check the "Confirm Signup" template
3. Verify the redirect URL is correct: `io.supabase.lottorunners://confirm-email`
4. Make sure the template syntax is valid HTML
5. Save the template

**Correct Template Format**:
```html
<a href="{{ .SiteURL }}/auth/v1/verify?token={{ .TokenHash }}&type=signup&redirect_to=io.supabase.lottorunners://confirm-email">
  Confirm Your Signup
</a>
```

### 4. Invalid Redirect URL in Supabase Settings

**Problem**: The redirect URL might not be whitelisted in Supabase.

**Solution**:
1. Go to **Supabase Dashboard** → **Authentication** → **URL Configuration**
2. Under "Redirect URLs", add:
   ```
   io.supabase.lottorunners://**
   http://localhost:3000/** (for web testing)
   ```
3. Save the configuration

### 5. Email Address Issues

**Problem**: The email address might be invalid, blocked, or in a format Supabase doesn't accept.

**Solution**:
- Verify the email address is valid
- Try a different email address
- Check if the email domain is blocked
- Some email providers block automated emails

### 6. Supabase Service Issues

**Problem**: Supabase might be experiencing temporary service issues.

**Solution**:
1. Check [Supabase Status Page](https://status.supabase.com/)
2. Wait a few minutes and try again
3. Check Supabase dashboard for any service alerts

## Step-by-Step Diagnostic Process

### Step 1: Check SMTP Configuration
```
✅ Go to: Settings → Authentication → SMTP Settings
✅ Verify SMTP is enabled
✅ If using custom SMTP, test the credentials
```

### Step 2: Check Email Logs
```
✅ Go to: Authentication → Logs
✅ Filter by "Email sent" or "signup"
✅ Look for error messages
✅ Check if emails are being attempted
```

### Step 3: Check Rate Limits
```
✅ Go to: Settings → Billing
✅ Check email quota usage
✅ Verify you haven't exceeded limits
```

### Step 4: Test Email Template
```
✅ Go to: Authentication → Email Templates
✅ Open "Confirm Signup" template
✅ Verify redirect URL is correct
✅ Check template syntax
```

### Step 5: Test with Different Email
```
✅ Try signing up with a different email address
✅ Use a different email provider (Gmail, Outlook, etc.)
✅ Check if the issue is email-specific
```

## Quick Fix Checklist

- [ ] SMTP is configured and enabled
- [ ] Email rate limits not exceeded
- [ ] Email template has correct redirect URL
- [ ] Redirect URLs are whitelisted in Supabase
- [ ] Email address is valid
- [ ] No Supabase service outages
- [ ] Tried with different email address

## Testing After Fix

1. **Sign up with a new account**
2. **Check Supabase logs** for email sending status
3. **Check your email** (and spam folder)
4. **Verify the confirmation link works**

## If Still Not Working

1. **Check Supabase Dashboard Logs**:
   - Go to **Authentication** → **Logs**
   - Look for detailed error messages
   - Check for any additional context

2. **Contact Supabase Support**:
   - If SMTP is configured correctly
   - If rate limits aren't exceeded
   - If email template is correct
   - They can check server-side logs

3. **Temporary Workaround**:
   - Manually verify users in Supabase dashboard
   - Go to **Authentication** → **Users**
   - Click on user → **Send confirmation email** (if available)
   - Or manually set `email_confirmed_at` in database

## Code Changes Made

The code has been updated to:
1. ✅ Catch `AuthRetryableFetchException` specifically
2. ✅ Provide detailed error messages
3. ✅ Guide users on what to check
4. ✅ Handle email sending failures gracefully

## Prevention

To prevent this issue in the future:
1. **Configure custom SMTP** (more reliable than default)
2. **Monitor email quota** usage
3. **Set up email alerts** for rate limits
4. **Test email templates** after changes
5. **Keep redirect URLs** updated in Supabase settings

## Related Documentation

- [Supabase SMTP Configuration](https://supabase.com/docs/guides/auth/auth-smtp)
- [Supabase Email Templates](https://supabase.com/docs/guides/auth/auth-email-templates)
- [Supabase Rate Limits](https://supabase.com/docs/guides/platform/rate-limits)

