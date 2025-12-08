# Supabase Password Reset Configuration

## Important: Email Template Configuration

To ensure password reset works on mobile devices, you **MUST** configure the Supabase email templates with the correct redirect URL.

## Configuration Steps

### 1. Access Supabase Dashboard
1. Go to [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Select your project: `irfbqpruvkkbylwwikwx`
3. Navigate to **Authentication** → **Email Templates**

### 2. Configure "Reset Password" Email Template

Find the "Reset Password" template and ensure it contains the correct redirect URL.

#### Required Configuration:
```
Redirect URL: io.supabase.lottorunners://reset-password
```

#### Template Should Look Like:
```html
<h2>Reset Password</h2>

<p>Follow this link to reset the password for your account:</p>

<p>
  <a href="{{ .SiteURL }}/auth/v1/verify?token={{ .TokenHash }}&type=recovery&redirect_to=io.supabase.lottorunners://reset-password">
    Reset Password
  </a>
</p>

<p>Or copy and paste this URL into your browser:</p>
<p>{{ .SiteURL }}/auth/v1/verify?token={{ .TokenHash }}&type=recovery&redirect_to=io.supabase.lottorunners://reset-password</p>
```

### 3. Configure URL Configuration (Optional but Recommended)

Go to **Authentication** → **URL Configuration**

Set **Redirect URLs** to include:
```
io.supabase.lottorunners://**
http://localhost:3000/** (for web testing)
```

This allows Supabase to recognize your custom URL scheme.

### 4. Test Email Sending

In the Supabase dashboard:
1. Go to **Authentication** → **Users**
2. Find a test user
3. Click the "..." menu
4. Select "Send password recovery"
5. Check if the email arrives with the correct redirect URL

## Verification Checklist

- [ ] Email template contains `io.supabase.lottorunners://reset-password`
- [ ] URL Configuration includes the custom scheme
- [ ] Test email is received successfully
- [ ] Email link contains the correct redirect URL
- [ ] SMTP settings are configured (if using custom SMTP)

## Default vs Custom SMTP

### Using Supabase Default SMTP
- Emails will be sent from: `noreply@mail.app.supabase.io`
- Subject: "[Your App Name] Reset Your Password"
- **Limitation**: Limited sending rate (check your plan)

### Using Custom SMTP (Recommended for Production)
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

## Common Issues and Solutions

### Issue: Emails Not Being Sent

**Check:**
1. Supabase email rate limits (free tier has limits)
2. SMTP configuration if using custom SMTP
3. User's email is verified in Supabase dashboard
4. Check Supabase logs: **Authentication** → **Logs**

### Issue: Email Sent but Wrong Redirect URL

**Fix:**
1. Update the email template as shown above
2. Make sure to save the template
3. Test again with a new password reset request

### Issue: Deep Link Not Opening App

**Check:**
1. Android/iOS deep link configuration in `AndroidManifest.xml` / `Info.plist`
2. App is installed on the device
3. Redirect URL exactly matches: `io.supabase.lottorunners://reset-password`

## Testing the Configuration

### Test 1: Check Email Content
1. Request a password reset from the app
2. Open the received email
3. **Right-click** on the "Reset Password" button
4. Select "Copy link address"
5. Paste into a text editor
6. **Verify** the URL contains: `redirect_to=io.supabase.lottorunners://reset-password`

Example correct URL:
```
https://irfbqpruvkkbylwwikwx.supabase.co/auth/v1/verify?token=abc123...&type=recovery&redirect_to=io.supabase.lottorunners://reset-password
```

### Test 2: Test Deep Link Handling
1. On your mobile device, click the password reset link
2. The app should open (not the browser)
3. You should see the password reset form
4. Console should show:
   ```
   🔑 Password recovery event detected!
   🔑 Navigating to password reset page
   ```

## Email Template Variables

Available variables in Supabase email templates:

| Variable | Description | Example |
|----------|-------------|---------|
| `{{ .Email }}` | User's email address | user@example.com |
| `{{ .Token }}` | Magic link token | abc123... |
| `{{ .TokenHash }}` | Hashed token for verification | def456... |
| `{{ .SiteURL }}` | Your Supabase project URL | https://[project].supabase.co |
| `{{ .RedirectTo }}` | Redirect URL | io.supabase.lottorunners://reset-password |

## Email Template Best Practices

1. **Always include both a button AND a plain text link**
   - Some email clients don't render buttons properly
   - Plain text link is a fallback

2. **Use clear, action-oriented text**
   - "Reset Password" is better than "Click Here"

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
    
    <h2 style="color: #333;">Reset Your Password</h2>
    
    <p style="color: #666; line-height: 1.6;">
      Hi there,
    </p>
    
    <p style="color: #666; line-height: 1.6;">
      We received a request to reset your password for your Lotto Runners account ({{ .Email }}).
    </p>
    
    <p style="color: #666; line-height: 1.6;">
      Click the button below to reset your password:
    </p>
    
    <div style="text-align: center; margin: 30px 0;">
      <a href="{{ .SiteURL }}/auth/v1/verify?token={{ .TokenHash }}&type=recovery&redirect_to=io.supabase.lottorunners://reset-password" 
         style="background-color: #2196F3; color: white; padding: 15px 30px; text-decoration: none; border-radius: 5px; display: inline-block; font-weight: bold;">
        Reset Password
      </a>
    </div>
    
    <p style="color: #666; line-height: 1.6; font-size: 14px;">
      Or copy and paste this link into your browser:
    </p>
    
    <p style="color: #2196F3; word-break: break-all; font-size: 12px;">
      {{ .SiteURL }}/auth/v1/verify?token={{ .TokenHash }}&type=recovery&redirect_to=io.supabase.lottorunners://reset-password
    </p>
    
    <hr style="border: none; border-top: 1px solid #eee; margin: 30px 0;">
    
    <p style="color: #999; font-size: 12px; line-height: 1.6;">
      This link will expire in 1 hour for security reasons.
      <br>
      If you didn't request a password reset, you can safely ignore this email.
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
2. **Single Use**: Reset tokens can only be used once
3. **HTTPS Only**: Always use HTTPS for your redirect URLs in production
4. **Rate Limiting**: Supabase automatically rate-limits password reset requests

## Monitoring

### Check Email Logs
1. Go to **Authentication** → **Logs**
2. Filter by "Email sent"
3. Check for failed sends or errors

### Check Auth Events
1. Go to **Authentication** → **Logs**  
2. Filter by event type: "password_recovery"
3. Monitor success/failure rates

## Quick Reference

| Configuration | Value |
|--------------|-------|
| Deep Link Scheme | `io.supabase.lottorunners` |
| Password Reset Path | `reset-password` |
| Full Redirect URL | `io.supabase.lottorunners://reset-password` |
| Token Expiration | 1 hour |
| Email Template | Authentication → Email Templates → Reset Password |

## Next Steps

After configuring:
1. Save all changes in Supabase dashboard
2. Request a password reset from your app
3. Check that the email arrives with correct redirect URL
4. Click the link and verify it opens your app
5. Complete the password reset flow
6. Verify login works with new password

## Need Help?

- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [Supabase Email Templates Guide](https://supabase.com/docs/guides/auth/auth-email-templates)
- [Deep Linking Setup](https://supabase.com/docs/guides/auth/auth-deep-linking)



