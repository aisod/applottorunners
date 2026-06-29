# Google Play listing images

Google Play Console requires:

| Asset | Size | File |
|-------|------|------|
| **High-res icon** | **512 × 512** PNG | [`app_icon_512x512.png`](app_icon_512x512.png) |
| **Feature graphic** | **1024 × 500** PNG | [`feature_graphic_1024x500.png`](feature_graphic_1024x500.png) |

## Regenerating

From the project root:

```bash
python tools/generate_google_play_assets.py
```

The script uses the first available source icon:

1. `web/icons/logolotto.png` (matches `flutter_launcher_icons` in `pubspec.yaml`)
2. `web/icons/Icon-512.png`
3. `build/flutter_assets/web/icons/Icon-512.png` (after `flutter build web`)

Update your source artwork in `web/icons/`, then rerun the script before each store submission if branding changes.

## Upload in Play Console

1. **Grow** → **Store presence** → **Main store listing** (or **Store settings** → **Theme**).
2. Upload **App icon** and **Feature graphic** from this folder.

## Privacy policy URL (required)

If the app uses the network, sign-in, email, analytics or ads, camera, file storage, location, or backends such as **Supabase** / **Firebase**, Play Console expects a **real, public HTTPS page** (not only in-app text). Google cross-checks this against **App content** and **Data safety**.

**Host the policy** on your own site, [GitHub Pages](https://pages.github.com/), [Vercel](https://vercel.com/), a public Notion page, or similar. Use **one canonical URL** everywhere: Play listing / policy declarations, support or account deletion pages if you link them, and optionally an in-app “Privacy policy” link.

**Upload to your website:** copy [`docs/privacy-policy.html`](../../docs/privacy-policy.html), [`docs/terms-of-service.html`](../../docs/terms-of-service.html), [`docs/delete-account.html`](../../docs/delete-account.html), and [`docs/.htaccess`](../../docs/.htaccess) to your site root. Enable clean URLs per [`docs/HOSTING_LEGAL_PAGES.md`](../../docs/HOSTING_LEGAL_PAGES.md). Public URLs: `https://lottoerunners.com/privacy-policy`, `https://lottoerunners.com/terms-of-service`, and **`https://lottoerunners.com/delete-account`** (Google Play **Delete account URL**).

## Android release build (Mapbox)

Mapbox Navigation SDK is downloaded from `api.mapbox.com` during the Gradle build. If you see SSL or timeout errors, run once:

```powershell
.\tools\build_play_release.ps1
```

Or manually prefetch, then build:

```powershell
cd android
.\gradlew.bat prefetchMapboxDependencies
cd ..
flutter build appbundle --release
```

Upload `build\app\outputs\bundle\release\app-release.aab` to Play Console.

## App access (Play review login)

Lotto Runners requires sign-in. In Play Console choose **All or some functionality is restricted** and paste instructions from [`docs/GOOGLE_PLAY_REVIEW_ACCESS.md`](../../docs/GOOGLE_PLAY_REVIEW_ACCESS.md).

## Permissions (Play review)

Declared permissions are limited to what the App uses: camera, photos, location (while in use on Android), notifications, and Mapbox foreground navigation. Removed: phone call permission, all-files storage, SMS, microphone, contacts, and Android background location. Re-upload `docs/privacy-policy.html` after policy edits.
