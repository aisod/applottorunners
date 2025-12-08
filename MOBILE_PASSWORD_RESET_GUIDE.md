# Mobile Password Reset Testing Guide

## Overview
This guide will help you test the forgot password functionality on mobile apps (Android and iOS).

## What Was Fixed

### 1. **Invalid Email Error Handling** ✅
- Added proper error detection for invalid email addresses
- Shows user-friendly error message: "The email address is invalid. Please enter a valid email address."
- Handles rate limiting and other auth errors gracefully

### 2. **Email Sending Validation** ✅
- Improved success message with reminder to check spam folder
- Better error feedback with both inline messages and snackbars
- Specific error messages based on the error type

### 3. **Mobile Deep Link Configuration** ✅
- Configured Android deep links for `io.supabase.lottorunners://reset-password`
- Configured iOS URL schemes for password reset callbacks
- Added PKCE flow for enhanced security
- Improved auth state change listener to detect password recovery events

## How It Works

### Password Reset Flow:

1. **User Requests Password Reset**
   ```
   User enters email → App sends request to Supabase → Supabase sends email
   ```

2. **User Opens Email Link**
   ```
   User clicks link → Mobile OS opens app with deep link → App captures the link
   ```

3. **App Handles Deep Link**
   ```
   Deep link detected → Auth state changes to 'passwordRecovery' → Navigate to reset page
   ```

4. **User Resets Password**
   ```
   User enters new password → App updates password via Supabase → Success → Redirect to login
   ```

## Testing Instructions

### Prerequisites
- A mobile device (Android or iOS) or emulator
- The app installed on the device
- Access to the email account you're testing with

### Testing Steps

#### Step 1: Test Invalid Email Error
1. Open the app on your mobile device
2. Go to the login screen
3. Tap "Forgot Password?"
4. Enter an invalid email (e.g., `test@invalid`)
5. Tap "Send Reset Email"
6. **Expected Result**: Red error message appears: "The email address is invalid. Please enter a valid email address."

#### Step 2: Test Valid Email
1. Enter a valid email address registered in the system
2. Tap "Send Reset Email"
3. **Expected Result**: 
   - Green success message appears
   - Message says: "Password reset email sent to [email]. Please check your inbox and spam folder."
   - Loading spinner appears briefly

#### Step 3: Check Email
1. Open your email inbox on your mobile device
2. Look for an email from Supabase
3. **Check spam/junk folder if not in inbox**
4. **Expected Result**: Email with subject like "Reset Your Password" or "Password Recovery"

#### Step 4: Test Deep Link (Critical for Mobile)
1. In the password reset email, tap the "Reset Password" button/link
2. **Expected Result**: 
   - The link should open your app automatically
   - App should navigate to the password reset screen
   - You should see the "Reset Your Password" form

#### Step 5: Test Password Reset
1. On the password reset screen, enter a new password (minimum 6 characters)
2. Confirm the new password
3. Tap "Update Password"
4. **Expected Result**:
   - Green success message appears
   - Message says: "Password updated successfully! You can now sign in with your new password."
   - App automatically redirects to login screen after 2 seconds

#### Step 6: Test New Password
1. On the login screen, enter your email
2. Enter your NEW password
3. Tap "Sign In"
4. **Expected Result**: Successfully logged into the app

## Troubleshooting

### Issue: Email Not Received
**Possible Causes:**
- Email is in spam/junk folder
- Invalid email address
- Email service delays (can take 1-2 minutes)
- Supabase email configuration issue

**Solutions:**
1. Check spam/junk folder
2. Wait 2-3 minutes and check again
3. Verify the email is registered in the system
4. Check Supabase dashboard for email logs

### Issue: Deep Link Not Working
**Possible Causes:**
- App not properly installed
- Deep link configuration incorrect
- OS not recognizing the custom URL scheme

**Solutions:**
1. **Android**: Ensure the app is installed and has the correct package name
2. **iOS**: Ensure the app is installed and has the correct bundle identifier
3. Copy the reset link and manually open it in a browser to see if it redirects
4. Check console logs for deep link handling messages

**Console Log Indicators:**
```
✅ Good Signs:
🔗 Checking for initial deep link...
🔐 Auth state changed: passwordRecovery
🔑 Password recovery event detected!
📝 User ID: [user-id]
🔑 Navigating to password reset page

❌ Bad Signs:
❌ Error handling deep link: [error]
❌ Missing tokens in password reset link
```

### Issue: "Invalid Password Reset Link"
**Possible Causes:**
- Link expired (usually expires after 1 hour)
- Link already used
- Link malformed

**Solutions:**
1. Request a new password reset email
2. Use the link within 1 hour
3. Make sure you're clicking the correct link from the latest email

### Issue: Deep Link Opens Browser Instead of App
**Possible Causes:**
- App not set as default handler for the custom URL scheme
- Deep link configuration issue

**Solutions:**
1. **Android**: 
   - Go to Settings → Apps → Your App → Open by default
   - Enable "Open supported links"
2. **iOS**:
   - Make sure app is installed before clicking link
   - Try uninstalling and reinstalling the app

## Deep Link Configuration Files

### Android Configuration
**File**: `android/app/src/main/AndroidManifest.xml`
```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="io.supabase.lottorunners" />
</intent-filter>
```

### iOS Configuration
**File**: `ios/Runner/Info.plist`
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>io.supabase.lottorunners</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>io.supabase.lottorunners</string>
        </array>
    </dict>
</array>
```

## Important Notes

1. **Email Configuration**: Make sure Supabase email templates are configured with the correct redirect URL: `io.supabase.lottorunners://reset-password`

2. **Supabase Dashboard**: Check your Supabase project settings:
   - Go to Authentication → Email Templates
   - Verify "Change Email" and "Reset Password" templates have the correct redirect URL

3. **Testing on Emulator**: 
   - Android emulators work fine for testing deep links
   - iOS simulators also support deep links
   - Physical devices are recommended for final testing

4. **Rate Limiting**: Supabase may rate-limit password reset requests. If you get a rate limit error, wait a few minutes before trying again.

## Error Messages Reference

| Error Message | Meaning | Solution |
|--------------|---------|----------|
| "The email address is invalid. Please enter a valid email address." | Email format is wrong | Check email spelling and format |
| "Too many attempts. Please wait a few minutes and try again." | Rate limited | Wait 5-10 minutes |
| "Failed to send password reset email. Please check your email address and try again." | Generic error | Check network connection and email |
| "Invalid password reset link" | Link expired or invalid | Request a new reset email |
| "Password must be at least 6 characters" | Password too short | Use a longer password |

## Success Indicators

When everything works correctly, you'll see these console logs:

```
📧 Sending password reset email to: user@example.com
✅ Password reset email sent successfully
🔐 Auth state changed: passwordRecovery
🔑 Password recovery event detected!
📝 User ID: [uuid]
📧 User email: user@example.com
🔑 Navigating to password reset page
```

## Additional Resources

- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [Flutter Deep Linking Documentation](https://docs.flutter.dev/development/ui/navigation/deep-linking)
- [Android App Links](https://developer.android.com/training/app-links)
- [iOS Universal Links](https://developer.apple.com/ios/universal-links/)

## Need Help?

If you continue to experience issues:
1. Check the console logs for specific error messages
2. Verify your Supabase email configuration
3. Test with a different email address
4. Ensure your app is running the latest code
5. Try uninstalling and reinstalling the app

## Testing Checklist

- [ ] Invalid email shows proper error message
- [ ] Valid email shows success message
- [ ] Password reset email is received
- [ ] Deep link opens the app (not browser)
- [ ] Password reset page appears
- [ ] New password can be set successfully
- [ ] Login works with new password
- [ ] Error messages are clear and helpful
- [ ] Spam folder reminder is shown



