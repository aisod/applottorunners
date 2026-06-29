# Google Play — App access for reviewers

Use this when Play Console asks whether reviewers need credentials to access your app.

**Select:** **All or some functionality in my app is restricted**  
**Do not select:** All functionality is available without any access restrictions

Lotto Runners requires sign-in. There is no guest or demo mode.

---

## Copy into Play Console

Paste the block below into **App access → Add instructions**. Replace every `REPLACE_…` value with your real test accounts before submitting.

```
Lotto Runners requires email and password sign-in. There is no guest or demo mode.

TEST ACCOUNT – CUSTOMER (individual)
Email: REPLACE_CUSTOMER_EMAIL
Password: REPLACE_CUSTOMER_PASSWORD

After sign-in, complete onboarding if shown, accept Terms if prompted, then use the home screen to browse and request errands, transport, and related services.

TEST ACCOUNT – RUNNER (optional – driver/runner flows)
Email: REPLACE_RUNNER_EMAIL
Password: REPLACE_RUNNER_PASSWORD

This account is pre-approved for runner verification so reviewers can open the runner dashboard and view job flows.

TEST ACCOUNT – ADMIN (optional – admin panel only; not available via public sign-up)
Email: REPLACE_ADMIN_EMAIL
Password: REPLACE_ADMIN_PASSWORD

Admin and super_admin roles are assigned in our database, not via the public registration screen.

OTHER NOTES FOR REVIEWERS
- Do not create a new account during review; use only the credentials above.
- No 2-step verification on login.
- Test accounts are email-confirmed in our backend (no 6-digit verification code required).
- Payments use PayToday; reviewers may browse booking and payment screens without completing a live charge where the flow allows cancellation.
- Location permission is used for maps and job tracking, not to block access to the app.
- Package name: com.mycompany.LottoRunners
```

---

## Create test accounts (Supabase)

Do this **before** you submit to Play.

### 1. Authentication users

In **Supabase Dashboard → Authentication → Users → Add user**:

| Role | Suggested email | Notes |
|------|-----------------|--------|
| Customer | e.g. `playreview.customer@lottoerunners.com` | Strong password, 12+ characters |
| Runner | e.g. `playreview.runner@lottoerunners.com` | Same |
| Admin (optional) | e.g. `playreview.admin@lottoerunners.com` | Same |

For each user:

- Enable **Auto Confirm User** (or confirm email manually) so reviewers are not blocked by the 6-digit email OTP.

### 2. Profile rows (`users` table)

Ensure each auth user has a matching row in your `users` table (or whatever table stores profiles) with:

| Account | `user_type` | Extra |
|---------|-------------|--------|
| Customer | `individual` or `business` | `terms_accepted: true` if you enforce terms |
| Runner | `runner` | Set runner verification to **approved** if reviewers must accept jobs |
| Admin | `admin` or `super_admin` | Required for admin panel |

If sign-up normally creates the profile automatically, you can instead sign up once in the app with each test email, then fix `user_type` / verification in Supabase SQL or Table Editor.

### 3. Runner verification (if testing runner flows)

Reviewers cannot fully test runner job acceptance if the account is stuck in **pending** verification. In Supabase, set the runner’s verification status to **approved** (or equivalent field your app uses).

### 4. Keep accounts active

- Do not delete these users during review.
- Use passwords you control; rotate after approval if needed.
- Do not enable 2FA on test accounts unless you document the codes for Google (not recommended).

---

## Content rating (IARC / Play questionnaire)

Use these answers for Lotto Runners unless Google’s wording changes. When unsure, answer based on **actual app behaviour**, not worst-case user misuse.

| Question (typical wording) | Answer | Notes |
|----------------------------|--------|--------|
| Ratings-relevant content in the **app package** (sex, violence, language in bundled assets) | **No** | Logos, UI, maps, booking flows only |
| **Public** sharing of nudity | **No** | No public feed, profiles, or gallery; see Terms §5 |
| App is primarily social / communication | **No** | On-demand errands & services marketplace |
| User-generated content (photos, chat) | **Yes** | Private to jobs; prohibited nudity in [Terms](TERMS_OF_SERVICE.md) §4–5 |
| Users interact (chat) | **Yes** | Customer ↔ runner for active bookings only |
| Location | **Yes** | Maps and job tracking |
| Purchases | **Yes** | PayToday for services |

**Policy URL for stores:** https://lottoerunners.com/terms-of-service (section 5 — nudity and user content).

---

## Play Console checklist

- [ ] Selected **restricted access**
- [ ] Added username/password instructions
- [ ] All `REPLACE_…` values filled with real test credentials
- [ ] Test sign-in on a release build (or internal testing track) with each account
- [ ] Privacy policy URL live: https://lottoerunners.com/privacy-policy
- [ ] Delete account URL live: https://lottoerunners.com/delete-account
- [ ] Package name in Console matches app: `com.mycompany.LottoRunners`

---

## Quick test on your phone

```powershell
flutter build apk --release
```

Install the APK, sign in with the **customer** test account, and confirm you reach the home screen without email OTP or verification errors.

---

*Update this file when you change test emails, passwords, or package name.*
