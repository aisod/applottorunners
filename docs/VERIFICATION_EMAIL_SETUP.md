# Supabase email templates

Paste the bodies below into **Authentication → Email Templates** in the Supabase Dashboard. Use the **Body** (HTML) field for each template.

---

## 1. Confirm signup

The app uses a **6-digit code** (no link). The user enters the code in the app.

**Subject (optional):** `Verify your email – Lotto Runners`

**Body:**

```html
<h2>Verify your email</h2>
<p>Thanks for signing up for Lotto Runners.</p>
<p>Your verification code is:</p>
<p style="font-size: 24px; font-weight: bold; letter-spacing: 4px;">{{ .Token }}</p>
<p>Enter this 6-digit code in the app to verify your email. The code expires in 1 hour.</p>
<p>If you didn't create an account, you can ignore this email.</p>
<p>— Lotto Runners</p>
```

---

## 2. Reset password

The user clicks a link to open your app and set a new password.

**Subject (optional):** `Reset your password – Lotto Runners`

**Body:**

```html
<h2>Reset your password</h2>
<p>We received a request to reset the password for {{ .Email }}.</p>
<p>Click the link below to choose a new password:</p>
<p><a href="{{ .ConfirmationURL }}">Reset password</a></p>
<p>If you didn't request this, you can ignore this email. The link will expire in 1 hour.</p>
<p>— Lotto Runners</p>
```

---

## 3. Magic link

The user clicks a link to sign in without a password.

**Subject (optional):** `Sign in to Lotto Runners`

**Body:**

```html
<h2>Sign in to Lotto Runners</h2>
<p>Click the link below to sign in to your account:</p>
<p><a href="{{ .ConfirmationURL }}">Sign in</a></p>
<p>If you didn't request this, you can ignore this email. The link will expire in 1 hour.</p>
<p>— Lotto Runners</p>
```

---

## Template variables reference

| Variable | Description |
|----------|-------------|
| `{{ .Token }}` | 6-digit OTP (use in Confirm signup for code-based verification). |
| `{{ .ConfirmationURL }}` | Full confirmation/sign-in link (use in Reset password and Magic link). |
| `{{ .Email }}` | User's email address. |
| `{{ .SiteURL }}` | Your app's site URL from Auth settings. |
| `{{ .RedirectTo }}` | Redirect URL passed when the auth method was called. |

---

## If emails are not received

- Add test addresses to your Supabase organization **Team** (Auth only sends to team emails when custom SMTP is not set).
- For production, set a custom email provider under **Authentication** so emails can be sent to any address.
