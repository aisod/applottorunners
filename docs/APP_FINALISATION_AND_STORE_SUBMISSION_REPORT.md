# Lotto Runners — App Finalisation & Store Submission Report

**Document version:** 1.0  
**Date:** 10 March 2025  
**App:** Lotto Runners (Flutter)  
**Version:** 1.0.0

---

## 1. Executive Summary

This report summarises the current state of the **Lotto Runners** app, remaining finalisation tasks, and the step-by-step process for submitting to **BIPA** (first), **Google Play**, and **Apple App Store**.

---

## 2. App Overview

### 2.1 What the App Does

- **Lotto Runners** is a multi-role service platform that connects:
  - **Customers** — request errands, shopping, transport, bus bookings, document/elderly services, queue sitting, license discs, deliveries, and special orders.
  - **Runners** — accept and fulfil errands; apply to become runners; manage wallet and withdrawals.
  - **Admins** — oversight of errands, transport, buses, payments, withdrawals, feedback, analytics, user/runner verification, and accounting.

### 2.2 Technical Stack

| Component | Technology |
|-----------|------------|
| Framework | Flutter (Dart SDK ≥3.0.0) |
| Backend / Auth / DB | Supabase |
| Maps | Google Maps (Flutter + Geocoding) |
| Payments | PayToday (web flow) |
| Notifications | flutter_local_notifications, background location |
| Platforms | Android, iOS, Web (and Windows/macOS launcher icons configured) |

### 2.3 Current Configuration

- **Package / Bundle:** `com.mycompany.LottoRunners` (Android & iOS)
- **Display name:** Lotto Runners
- **Version:** 1.0.0 (in `pubspec.yaml`)
- **Assets:** Icons from `web/icons/logolotto.png`; launcher icons generated for Android, iOS, web, Windows, macOS
- **Deep links:** `io.supabase.lottorunners` for auth (e.g. password reset)
- **Permissions:** Camera, photos, location (incl. background), storage, phone, notifications, network — with usage strings in iOS `Info.plist` and Android `AndroidManifest.xml`

---

## 3. Finalisation Checklist (Before Any Store Submission)

### 3.1 Must Do

| # | Task | Status / Notes |
|---|------|----------------|
| 1 | **Release signing (Android)** | Replace `signingConfigs.debug` with a release keystore in `android/app/build.gradle`. Create upload key and store credentials securely. |
| 2 | **Apple Developer account & signing (iOS)** | Enroll in Apple Developer Program; configure signing & provisioning in Xcode for release. |
| 3 | **Application ID / Bundle ID** | Decide final ID (e.g. `com.yourcompany.lottorunners`). If changing from `com.mycompany.LottoRunners`, update Android `applicationId`/`namespace` and iOS `PRODUCT_BUNDLE_IDENTIFIER` everywhere. |
| 4 | **Secrets & API keys** | Move Supabase URL/anon key and **Google Maps API key** out of source (e.g. env, CI secrets). **iOS:** `Info.plist` currently has a hardcoded Maps key — use build config / env. |
| 5 | **Privacy Policy URL** | Required by all stores. Host a dedicated page (e.g. your website) and link from app and store listings. |
| 6 | **Terms of Service / Terms and Conditions** | You have in-app terms (individual & runner). Ensure a web URL for “Terms of Service” for store listings and legal. |
| 7 | **Disable debug / verbose logging** | Set `SupabaseConfig` and any `print()`/debug logs to non-verbose in release builds. |
| 8 | **BIPA-specific requirements** | Confirm BIPA’s exact checklist (documents, forms, fees). Treat as “first submit” and complete before Google/Apple. |

### 3.2 Recommended

| # | Task | Notes |
|---|------|--------|
| 9 | **App icons & screenshots** | Icons are generated; prepare store graphics (feature graphic, screenshots per device type) for each store. |
| 10 | **Support URL & contact** | Use consistent support email (e.g. info@lottoerunners.com) and, if possible, a support URL. |
| 11 | **Content rating** | Complete questionnaires for each store (Google Play, Apple, and BIPA if applicable). |
| 12 | **Data safety / privacy labels** | Prepare clear list of data collected (e.g. email, location, photos, payment-related) for Google Play “Data safety” and Apple “Privacy nutrition labels”. |
| 13 | **Test on real devices** | Final QA on physical Android and iOS devices (release builds). |
| 14 | **Version and build numbers** | Use consistent versioning (e.g. `version: 1.0.0+1` in pubspec) and bump build number for each store upload. |

### 3.3 Optional / Later

- Localisation (if targeting multiple languages).
- App Store Optimisation (ASO): keywords, short/long descriptions.
- Beta tracks (Google Play Internal/Closed testing; TestFlight for Apple) before production.

---

## 4. Submission Order and Next Steps

You specified: **first BIPA → then Google Play → then Apple App Store.**

### 4.1 Step 1: Submit to BIPA

- **Purpose:** First formal submission (e.g. local/regional store or regulatory step).
- **Actions:**
  1. Confirm BIPA’s exact process (portal, forms, fees, timeline).
  2. Complete all BIPA-required documents and app build.
  3. Use the same release build preparation as below (signed release, no debug keys in production).
  4. After BIPA submission (and any approval), proceed to Google and Apple with the same or updated build as needed.

*If “BIPA” refers to an internal or beta step (e.g. “first submit to beta”), replace this with your internal checklist and then continue to Step 2 and 3.*

---

### 4.2 Step 2: Submit to Google Play (Android)

1. **Google Play Console**
   - Create a developer account (one-time fee).
   - Create the app (e.g. “Lotto Runners”), set package name to match your final `applicationId`.

2. **Build**
   - Configure release signing (keystore) in `android/app/build.gradle`.
   - Run:  
     `flutter build appbundle --release`  
   - Output: `build/app/outputs/bundle/release/app-release.aab`.

3. **Store listing**
   - Short and full description, screenshots (phone, 7" tablet, 10" tablet if applicable), feature graphic, icon.
   - Privacy Policy URL, optional Terms of Service URL.

4. **Policy and content**
   - Complete “Data safety” form (data collected and how it’s used).
   - Complete content rating questionnaire.
   - Ensure app complies with Play Policy (payments, user data, permissions).

5. **Release**
   - Upload the `.aab` to a release track (e.g. Production or first to Internal testing).
   - Complete rollout.

---

### 4.3 Step 3: Submit to Apple App Store (iOS)

1. **Apple Developer Program**
   - Enroll (annual fee).
   - Create an App ID matching your bundle ID (e.g. `com.mycompany.LottoRunners` or your final ID).

2. **Build**
   - In Xcode: select “Any iOS Device” (or a connected device), set scheme to Release.
   - Archive: Product → Archive.
   - Or from CLI (with proper signing):  
     `flutter build ipa`

3. **App Store Connect**
   - Create the app (name, bundle ID, SKU).
   - Fill in metadata: description, keywords, screenshots per device size, support URL, Privacy Policy URL.
   - Set pricing and availability.
   - Add “App Privacy” details (data collection and usage).

4. **Submit for review**
   - From Xcode/Transporter, upload the `.ipa`.
   - In App Store Connect, attach the build to the version and submit for review.
   - Respond to any review feedback.

---

## 5. Summary Table: Next Steps

| Order | Platform | Main actions |
|-------|----------|--------------|
| 1 | **BIPA** | Confirm process → finalise app (signing, keys, policy URLs) → submit per BIPA requirements. |
| 2 | **Google Play** | Play Console account → release signing → `flutter build appbundle` → listing + Data safety + content rating → upload AAB → release. |
| 3 | **Apple App Store** | Developer account → signing & archive → App Store Connect listing + Privacy → upload IPA → submit for review. |

---

## 6. File Reference (Current Setup)

- **Version:** `pubspec.yaml` → `version: 1.0.0`
- **Android package:** `android/app/build.gradle` → `applicationId` / `namespace`
- **iOS bundle ID:** `ios/Runner.xcodeproj/project.pbxproj` → `PRODUCT_BUNDLE_IDENTIFIER`
- **Android manifest:** `android/app/src/main/AndroidManifest.xml` (permissions, app label)
- **iOS permissions / config:** `ios/Runner/Info.plist` (usage strings, URL scheme, background modes)
- **Supabase:** `lib/supabase/supabase_config.dart` (URL, anon key — move to env for production)
- **Terms / contact:** In-app terms and contact (e.g. info@lottoerunners.com) in `lib/pages/terms_conditions_*.dart` and profile.

---

## 7. Security Reminder

- **Do not** ship with debug signing in production.
- **Do not** leave API keys (Supabase, Google Maps) in source control; use environment or build-time config.
- Ensure **Privacy Policy** and **Terms** are hosted and linked from the app and store listings.

---

*End of report. Update this document as you complete each step and when you change version or store details.*
