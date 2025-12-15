# SMTP Setup Guide for Supabase

## Quick Setup Steps

### 1. Access SMTP Settings
1. Go to **Supabase Dashboard**: https://supabase.com/dashboard
2. Select your project: `irfbqpruvkkbylwwikwx`
3. Navigate to **Settings** → **Authentication** → **SMTP Settings**

### 2. Enable SMTP
1. Toggle **"Enable Custom SMTP"** to ON
2. Fill in your SMTP provider details (see examples below)
3. Click **"Save"**

## SMTP Provider Examples

### Gmail SMTP Configuration

**Settings:**
```
Host: smtp.gmail.com
Port: 587
Username: your-email@gmail.com
Password: [App Password - see below]
Sender Email: your-email@gmail.com
Sender Name: Lotto Runners
```

**Important - Gmail App Password:**
1. Go to https://myaccount.google.com/apppasswords
2. Sign in with your Google account
3. Select "Mail" and "Other (Custom name)"
4. Enter "Lotto Runners" as the name
5. Click "Generate"
6. Copy the 16-character password (no spaces)
7. Use this password in SMTP settings (NOT your regular Gmail password)

**Note**: You need 2-Step Verification enabled on your Google account to generate app passwords.

### SendGrid SMTP Configuration

**Settings:**
```
Host: smtp.sendgrid.net
Port: 587
Username: apikey
Password: [Your SendGrid API Key]
Sender Email: your-verified-email@yourdomain.com
Sender Name: Lotto Runners
```

**Getting SendGrid API Key:**
1. Sign up at https://sendgrid.com
2. Go to Settings → API Keys
3. Create a new API key with "Mail Send" permissions
4. Copy the API key (you'll only see it once!)

### Outlook/Hotmail SMTP Configuration

**Settings:**
```
Host: smtp-mail.outlook.com
Port: 587
Username: your-email@outlook.com (or @hotmail.com)
Password: [Your Outlook password]
Sender Email: your-email@outlook.com
Sender Name: Lotto Runners
```

### Mailgun SMTP Configuration

**Settings:**
```
Host: smtp.mailgun.org
Port: 587
Username: postmaster@yourdomain.mailgun.org
Password: [Your Mailgun SMTP password]
Sender Email: noreply@yourdomain.com
Sender Name: Lotto Runners
```

## Testing Your SMTP Configuration

### Test 1: Send Test Email from Dashboard
1. After saving SMTP settings, look for a "Send Test Email" button
2. Enter your email address
3. Click "Send"
4. Check your inbox (and spam folder)

### Test 2: Test from Your App
1. Try signing up with a new account
2. Check if the confirmation email arrives
3. Check Supabase logs: **Authentication** → **Logs**

### Test 3: Check SMTP Logs
1. Go to **Authentication** → **Logs**
2. Filter by "Email sent"
3. Look for any errors or failures

## Common SMTP Issues & Solutions

### Issue: "Authentication failed"

**Causes:**
- Wrong username/password
- Using regular password instead of app password (Gmail)
- Account security settings blocking access

**Solutions:**
- Double-check credentials
- For Gmail: Use App Password, not regular password
- Check if "Less secure app access" needs to be enabled (older accounts)
- Verify 2-Step Verification is enabled (Gmail)

### Issue: "Connection timeout"

**Causes:**
- Wrong SMTP host or port
- Firewall blocking connection
- Network issues

**Solutions:**
- Verify host and port are correct
- Try port 465 with SSL instead of 587 with TLS
- Check firewall settings
- Test from different network

### Issue: "Sender email not verified"

**Causes:**
- Email address not verified with SMTP provider
- Domain not verified (for custom domains)

**Solutions:**
- Verify sender email in SMTP provider dashboard
- For SendGrid: Verify sender in Sender Authentication
- For Mailgun: Verify domain in Domain Settings

### Issue: Emails going to spam

**Causes:**
- SPF/DKIM records not configured
- Sender reputation issues
- Email content triggers spam filters

**Solutions:**
- Configure SPF and DKIM records for your domain
- Use a verified domain instead of free email
- Avoid spam trigger words in email templates
- Warm up your sending domain gradually

## SMTP Settings Checklist

Before going live, verify:

- [ ] SMTP is enabled in Supabase dashboard
- [ ] All credentials are correct
- [ ] Test email was received successfully
- [ ] Sender email is verified with SMTP provider
- [ ] Email templates are configured correctly
- [ ] Redirect URLs are set correctly
- [ ] Test sign-up flow works end-to-end

## Benefits of Using SMTP

✅ **No rate limits** (or much higher limits than default service)
✅ **Send to any email address** (not just team members)
✅ **More reliable delivery**
✅ **Better for production** applications
✅ **Custom sender address** and branding
✅ **Better deliverability** with proper SPF/DKIM

## After SMTP Setup

Once SMTP is configured:

1. **Update Email Templates** (if needed):
   - Go to **Authentication** → **Email Templates**
   - Verify redirect URLs are correct
   - Customize email content if desired

2. **Test Everything**:
   - Sign up with new account
   - Request password reset
   - Resend confirmation email
   - Verify all emails arrive correctly

3. **Monitor**:
   - Check email logs regularly
   - Monitor bounce rates
   - Watch for delivery issues

## Security Best Practices

1. **Never commit SMTP credentials to code**
   - They're stored securely in Supabase dashboard
   - Use environment variables if needed elsewhere

2. **Use App Passwords** (Gmail):
   - More secure than regular passwords
   - Can be revoked individually
   - Required for 2-Step Verification accounts

3. **Rotate credentials periodically**:
   - Change passwords/API keys regularly
   - Revoke old credentials when updating

4. **Monitor for unauthorized access**:
   - Check SMTP provider logs
   - Watch for unusual sending patterns

## Troubleshooting

### Still Not Working?

1. **Check Supabase Logs**:
   - Go to **Authentication** → **Logs**
   - Look for SMTP-related errors
   - Check error messages for clues

2. **Test SMTP Directly**:
   - Use a tool like https://www.smtper.net/
   - Test your SMTP credentials independently
   - Verify they work outside of Supabase

3. **Verify Provider Settings**:
   - Check SMTP provider documentation
   - Ensure account is not suspended
   - Verify sending limits haven't been exceeded

4. **Contact Support**:
   - Supabase support if it's a Supabase issue
   - SMTP provider support if credentials work elsewhere

## Quick Reference

| Provider | Host | Port | Username | Password |
|----------|------|------|----------|----------|
| Gmail | smtp.gmail.com | 587 | Your email | App Password |
| SendGrid | smtp.sendgrid.net | 587 | apikey | API Key |
| Outlook | smtp-mail.outlook.com | 587 | Your email | Your password |
| Mailgun | smtp.mailgun.org | 587 | postmaster@domain | SMTP password |

## Next Steps

1. ✅ Configure SMTP in Supabase dashboard
2. ✅ Send test email to verify
3. ✅ Test sign-up flow in your app
4. ✅ Monitor email delivery
5. ✅ Customize email templates if needed

Your email confirmation should now work reliably! 🎉

