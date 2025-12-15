# Supabase Email Confirmation Configuration

## Important: Email Template Configuration

To ensure email confirmation works correctly, you **MUST** configure the Supabase email templates with the correct redirect URL. This is critical for the confirmation emails to work properly.

## The Problem

If you're seeing "confirmation email sent successfully" but not receiving emails, it's likely because:
1. The email template in Supabase dashboard doesn't have the correct redirect URL
2. The redirect URL isn't configured in Supabase URL settings
3. SMTP settings aren't configured (if using custom SMTP)

## Configuration Steps

### 1. Access Supabase Dashboard
1. Go to [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Select your project: `irfbqpruvkkbylwwikwx`
3. Navigate to **Authentication** → **Email Templates**

### 2. Configure "Confirm Signup" Email Template

Find the "Confirm Signup" template and ensure it contains the correct redirect URL.

#### Required Configuration:
```
Redirect URL: io.supabase.lottorunners://confirm-email
```

#### Template Should Look Like:
```html
<h2>Confirm Your Signup</h2>

<p>Follow this link to confirm your user:</p>

<p>
  <a href="{{ .SiteURL }}/auth/v1/verify?token={{ .TokenHash }}&type=signup&redirect_to=io.supabase.lottorunners://confirm-email">
    Confirm Your Signup
  </a>
</p>

<p>Or copy and paste this URL into your browser:</p>
<p>{{ .SiteURL }}/auth/v1/verify?token={{ .TokenHash }}&type=signup&redirect_to=io.supabase.lottorunners://confirm-email</p>
```

### 3. Configure URL Configuration

Go to **Authentication** → **URL Configuration**

Set **Redirect URLs** to include:
```
io.supabase.lottorunners://**
http://localhost:3000/** (for web testing)
```

This allows Supabase to recognize your custom URL scheme.

### 4. Check SMTP Settings

#### Using Supabase Default SMTP
- Emails will be sent from: `noreply@mail.app.supabase.io`
- Subject: "[Your App Name] Confirm Your Signup"
- **Limitation**: Limited sending rate (check your plan)
- **Important**: Free tier has strict rate limits

#### Using Custom SMTP (Recommended for Production)
If you want to use your own email service (Gmail, SendGrid, etc.):

1. Go to **Settings** → **Authentication** → **SMTP Settings**
2. Configure your SMTP provider:
   - **Host**: Your SMTP server
   - **Port**: Usually 587 or 465
   - **Username**: Your SMTP username
   - **Password**: Your SMTP password
   - **Sender email**: Your verified sender email
   - **Sender name**: Your app name

### Example: Gmail SMTP Configuration
```
Host: smtp.gmail.com
Port: 587
Username: your-email@gmail.com
Password: [App Password - not your regular password]
Sender Email: your-email@gmail.com
Sender Name: Lotto Runners
```

**Note**: For Gmail, you need to use an "App Password", not your regular password. Generate one at: https://myaccount.google.com/apppasswords

## Verification Checklist

- [ ] Email template contains `io.supabase.lottorunners://confirm-email`
- [ ] URL Configuration includes the custom scheme
- [ ] SMTP settings are configured (default or custom)
- [ ] Test email is received successfully
- [ ] Email link contains the correct redirect URL
- [ ] Deep link opens the app correctly

## Common Issues and Solutions

### Issue: Emails Not Being Sent

**Check:**
1. **Supabase email rate limits** - Free tier has strict limits
2. **SMTP configuration** - If using custom SMTP, verify settings
3. **Email address** - Check if email is valid and not blocked
4. **Supabase logs** - Go to **Authentication** → **Logs** to see email sending status
5. **Spam folder** - Check user's spam/junk folder

**Fix:**
- If rate limited, wait before trying again
- Verify SMTP credentials are correct
- Check Supabase project status
- Review authentication logs for errors

### Issue: Email Sent but Wrong Redirect URL

**Fix:**
1. Update the email template as shown above
2. Make sure to save the template
3. Test again with a new sign-up request
4. Verify the redirect URL in the email link

### Issue: Deep Link Not Opening App

**Check:**
1. Android/iOS deep link configuration in `AndroidManifest.xml` / `Info.plist`
2. App is installed on the device
3. Redirect URL exactly matches: `io.supabase.lottorunners://confirm-email`
4. Deep link service is properly configured

### Issue: "Email sent successfully" but no email received

**This is the most common issue!** It usually means:

1. **Rate limiting** - Supabase free tier limits emails per hour
   - Solution: Wait and try again, or upgrade plan

2. **SMTP not configured** - Default SMTP might be disabled
   - Solution: Configure SMTP settings in dashboard

3. **Email template missing redirect URL** - Email is sent but link is broken
   - Solution: Update email template with correct redirect URL

4. **Email in spam folder** - User should check spam/junk
   - Solution: Ask user to check spam folder

5. **Invalid email address** - Email might be rejected
   - Solution: Verify email address is valid

## Testing the Configuration

### Test 1: Check Email Content
1. Sign up with a new account
2. Open the received email
3. **Right-click** on the "Confirm Your Signup" button
4. Select "Copy link address"
5. Paste into a text editor
6. **Verify** the URL contains: `redirect_to=io.supabase.lottorunners://confirm-email`

Example correct URL:
```
https://irfbqpruvkkbylwwikwx.supabase.co/auth/v1/verify?token=abc123...&type=signup&redirect_to=io.supabase.lottorunners://confirm-email
```

### Test 2: Test Deep Link Handling
1. On your mobile device, click the confirmation link
2. The app should open (not the browser)
3. You should see a success message
4. Console should show:
   ```
   📧 Handling email confirmation
   ✅ Email confirmation successful
   ```

### Test 3: Check Supabase Logs
1. Go to **Authentication** → **Logs**
2. Filter by "Email sent" or "signup"
3. Check for any errors or failures
4. Verify email was actually sent

## Email Template Variables

Available variables in Supabase email templates:

| Variable | Description | Example |
|----------|-------------|---------|
| `{{ .Email }}` | User's email address | user@example.com |
| `{{ .Token }}` | Magic link token | abc123... |
| `{{ .TokenHash }}` | Hashed token for verification | def456... |
| `{{ .SiteURL }}` | Your Supabase project URL | https://[project].supabase.co |
| `{{ .RedirectTo }}` | Redirect URL | io.supabase.lottorunners://confirm-email |

## Email Template Best Practices

1. **Always include both a button AND a plain text link**
   - Some email clients don't render buttons properly
   - Plain text link is a fallback

2. **Use clear, action-oriented text**
   - "Confirm Your Signup" is better than "Click Here"

3. **Include expiration information**
   - Let users know the link expires (default: 1 hour)

4. **Add branding**
   - Include your app logo
   - Use your brand colors

5. **Test across email clients**
   - Gmail, Outlook, Apple Mail, etc.
   - Mobile and desktop views

## Sample Complete Email Template

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="background-color: #f4f4f4; padding: 20px; font-family: Arial, sans-serif;">
  <div style="max-width: 600px; margin: 0 auto; background-color: white; padding: 30px; border-radius: 10px;">
    <div style="text-align: center; margin-bottom: 30px;">
      <h1 style="color: #2196F3; margin: 0;">Lotto Runners</h1>
    </div>
    
    <h2 style="color: #333;">Confirm Your Signup</h2>
    
    <p style="color: #666; line-height: 1.6;">
      Hi there,
    </p>
    
    <p style="color: #666; line-height: 1.6;">
      Thank you for signing up for Lotto Runners! Please confirm your email address ({{ .Email }}) by clicking the button below:
    </p>
    
    <div style="text-align: center; margin: 30px 0;">
      <a href="{{ .SiteURL }}/auth/v1/verify?token={{ .TokenHash }}&type=signup&redirect_to=io.supabase.lottorunners://confirm-email" 
         style="background-color: #2196F3; color: white; padding: 15px 30px; text-decoration: none; border-radius: 5px; display: inline-block; font-weight: bold;">
        Confirm Your Signup
      </a>
    </div>
    
    <p style="color: #666; line-height: 1.6; font-size: 14px;">
      Or copy and paste this link into your browser:
    </p>
    
    <p style="color: #2196F3; word-break: break-all; font-size: 12px;">
      {{ .SiteURL }}/auth/v1/verify?token={{ .TokenHash }}&type=signup&redirect_to=io.supabase.lottorunners://confirm-email
    </p>
    
    <hr style="border: none; border-top: 1px solid #eee; margin: 30px 0;">
    
    <p style="color: #999; font-size: 12px; line-height: 1.6;">
      This link will expire in 1 hour for security reasons.
      <br>
      If you didn't sign up for Lotto Runners, you can safely ignore this email.
    </p>
    
    <p style="color: #999; font-size: 12px; line-height: 1.6;">
      Thanks,
      <br>
      The Lotto Runners Team
    </p>
  </div>
</body>
</html>
```

## Security Considerations

1. **Token Expiration**: Default is 1 hour - appropriate for most use cases
2. **Single Use**: Confirmation tokens can only be used once
3. **HTTPS Only**: Always use HTTPS for your redirect URLs in production
4. **Rate Limiting**: Supabase automatically rate-limits sign-up requests

## Monitoring

### Check Email Logs
1. Go to **Authentication** → **Logs**
2. Filter by "Email sent"
3. Check for failed sends or errors

### Check Auth Events
1. Go to **Authentication** → **Logs**  
2. Filter by event type: "signup"
3. Monitor success/failure rates

### Check Rate Limits
1. Go to **Settings** → **Billing**
2. Check your email sending quota
3. Monitor usage to avoid hitting limits

## Quick Reference

| Configuration | Value |
|--------------|-------|
| Deep Link Scheme | `io.supabase.lottorunners` |
| Email Confirmation Path | `confirm-email` |
| Full Redirect URL | `io.supabase.lottorunners://confirm-email` |
| Token Expiration | 1 hour |
| Email Template | Authentication → Email Templates → Confirm Signup |

## Code Changes Made

The following code changes have been made to fix the email confirmation issue:

1. **Updated `signUpWithEmail` method** - Now includes `emailRedirectTo` parameter
2. **Updated `resendEmailConfirmation` method** - Improved error handling and platform-specific redirect URLs
3. **Updated `createAdminUser` method** - Now includes `emailRedirectTo` parameter
4. **Updated `createUser` method** - Now includes `emailRedirectTo` parameter

All methods now use platform-specific redirect URLs:
- **Web**: `http://localhost:3000/confirm-email`
- **Mobile**: `io.supabase.lottorunners://confirm-email`

## Next Steps

After configuring:
1. Save all changes in Supabase dashboard
2. Sign up with a new account from your app
3. Check that the email arrives with correct redirect URL
4. Click the link and verify it opens your app
5. Complete the email confirmation flow
6. Verify login works after confirmation

## Need Help?

- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [Supabase Email Templates Guide](https://supabase.com/docs/guides/auth/auth-email-templates)
- [Deep Linking Setup](https://supabase.com/docs/guides/auth/auth-deep-linking)
- [SMTP Configuration](https://supabase.com/docs/guides/auth/auth-smtp)

