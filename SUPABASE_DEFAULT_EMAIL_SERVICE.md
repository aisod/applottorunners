# Supabase Default Email Service (No SMTP)

## Important: Default Email Service Limitations

Since you're **not using SMTP**, you're relying on Supabase's default email service. This service has **significant limitations** that may cause email sending failures.

## Default Email Service Limitations

### 1. **Authorized Recipients Only**
- **Emails can ONLY be sent to addresses associated with your project's team members**
- If the email address is not in your Supabase project team, emails will fail
- This is the most common cause of "email sent successfully" but no email received

### 2. **Very Low Rate Limits**
- **2 emails per hour** (very restrictive!)
- If you've sent 2 emails in the last hour, you must wait
- This applies to ALL email types (signup, password reset, etc.)

### 3. **No SLA Guarantee**
- The default service doesn't guarantee delivery
- Emails may be delayed or not delivered
- Not suitable for production applications

## Why You're Getting Errors

The error `"Error sending confirmation email"` with status 500 typically means:

1. **Rate Limit Exceeded**: You've sent 2+ emails in the last hour
2. **Unauthorized Email**: The email address is not in your Supabase project team
3. **Service Issue**: The default email service is experiencing problems

## Solutions

### Option 1: Add Email to Supabase Team (Quick Fix)

1. Go to **Supabase Dashboard** → **Settings** → **Team**
2. Click **"Invite Team Member"**
3. Add the email address you're trying to send to
4. The user will receive an invitation email
5. Once added, emails should work (within rate limits)

**Note**: This only works for testing. For production, you need Option 2.

### Option 2: Configure Custom SMTP (Recommended for Production)

Even if you don't want to use SMTP now, it's **highly recommended** for production:

1. Go to **Supabase Dashboard** → **Settings** → **Authentication** → **SMTP Settings**
2. Configure your SMTP provider (Gmail, SendGrid, etc.)
3. This removes the rate limits and authorization restrictions

**Benefits of Custom SMTP**:
- ✅ No rate limits (or much higher limits)
- ✅ Send to any email address
- ✅ More reliable delivery
- ✅ Better for production use

### Option 3: Wait and Retry

If you've hit the rate limit:
1. Wait 1 hour
2. Try again
3. Make sure the email is authorized in your team

## Checking Your Current Status

### Check Rate Limits
1. Go to **Supabase Dashboard** → **Settings** → **Billing**
2. Check your email quota usage
3. See if you've exceeded the 2 emails/hour limit

### Check Authorized Emails
1. Go to **Supabase Dashboard** → **Settings** → **Team**
2. View all team members
3. Verify the email you're sending to is listed

### Check Email Logs
1. Go to **Supabase Dashboard** → **Authentication** → **Logs**
2. Filter by "Email sent" or "signup"
3. Look for error messages or failures

## Common Error Messages

### "Error sending confirmation email" (500)
- **Cause**: Rate limit exceeded OR unauthorized email
- **Solution**: Wait 1 hour OR add email to team

### "Email sent successfully" but no email received
- **Cause**: Email not authorized OR rate limit hit
- **Solution**: Add email to team OR wait and retry

### "unexpected_failure"
- **Cause**: Default email service issue
- **Solution**: Wait and retry, or configure SMTP

## Testing

### Test 1: Check if Email is Authorized
1. Go to **Settings** → **Team**
2. Verify your test email is listed
3. If not, add it as a team member

### Test 2: Check Rate Limits
1. Count how many emails you've sent in the last hour
2. If 2 or more, wait until the hour resets
3. Try again

### Test 3: Check Email Logs
1. Go to **Authentication** → **Logs**
2. Look for your email sending attempts
3. Check for error messages

## Best Practices

### For Development/Testing
- ✅ Add test emails to your Supabase team
- ✅ Be aware of the 2 emails/hour limit
- ✅ Wait between tests if needed

### For Production
- ⚠️ **Do NOT rely on default email service**
- ✅ **Configure custom SMTP** (Gmail, SendGrid, etc.)
- ✅ This ensures reliable email delivery
- ✅ Removes rate limits and authorization restrictions

## Quick Reference

| Issue | Cause | Solution |
|-------|-------|----------|
| Email not received | Not in team | Add to Supabase team |
| Email not received | Rate limit | Wait 1 hour |
| 500 error | Rate limit or unauthorized | Check team + wait |
| "Email sent" but nothing | Unauthorized email | Add to team |

## Code Changes Made

The error messages have been updated to reflect that you're using the default email service (not SMTP). The messages now mention:
- Rate limits (2 emails/hour)
- Authorization requirements (team members only)
- Guidance on what to check

## Next Steps

1. **For Testing**: Add your test email to Supabase team
2. **For Production**: Configure custom SMTP
3. **Monitor**: Check email logs regularly
4. **Wait**: If rate limited, wait 1 hour before retrying

## Need Help?

- [Supabase Default Email Service Docs](https://supabase.com/docs/guides/auth/auth-smtp)
- [Supabase Team Management](https://supabase.com/docs/guides/platform/team-management)
- [Supabase Rate Limits](https://supabase.com/docs/guides/platform/rate-limits)

