# Flutter App Template — Working Plan

Edit this file freely. Checkboxes and lists are the intended place to change scope.

Status: **implemented in** `/Users/raghavgarg/StudioProjects/flutter-app-template`  
Vokey app: **do not modify** (`/Users/raghavgarg/StudioProjects/vokey`)

---

## Constraints

- [x] Do not change the existing Vokey app
- [x] Analyze Vokey first, then extract a new template repo
- [x] Preserve Vokey architecture, conventions, and coding style
- [x] Do **not** use Riverpod
- [x] Use **BLoC** for state and **GetIt** for DI
- [x] Skip Razorpay / UPI **checkout** until a billing provider is confirmed (Capslock Payments is now wired)
- [x] Do not commit secrets
- [x] Push template to GitHub (`VoiceClub-app/flutter-app-template`, branch `dev`)
- [ ] Enable “Template repository” on GitHub
- [ ] Add payment later, after backend architecture is confirmed

Notes / changes:

```
(add constraint changes here)
```

---

## Source of truth

| Item | Decision | Change to |
| --- | --- | --- |
| Template path | `/Users/raghavgarg/StudioProjects/flutter-app-template` | |
| Dart package name (default) | `app_template` | |
| Android applicationId (default) | `com.example.app_template` | |
| Android Kotlin namespace | keep `com.example.app_template` (do not move MainActivity) | |
| iOS bundle ID (default) | optional — leave `__IOS_BUNDLE_ID__` to skip iOS | |
| Identity file | `project_config.yaml` | |
| Generated Dart identity | `lib/config/app_identity.dart` | |
| Secrets location | gitignored `.env.dev` / `.env.prod` | |

---

## 1. Analyze Vokey (done)

What was inspected:

- Feature-first Clean Architecture, go_router, Dio, fpdart
- Vokey used Riverpod; this template uses **BLoC + GetIt** instead
- Existing flavors: `main_dev.dart` / `main_prod.dart`, `.env.dev` / `.env.prod`, Android `dev`/`prod`
- Hardcoded identity: app name, `com.capslock.vokey`, API URLs, Firebase projects, Mixpanel, legal URLs, notification channels
- Did **not** reuse `app_starter` (different app)

Changes I want to the analysis / what to re-check:

```
(add notes here)
```

---

## 2. Keep vs exclude

### Keep (reusable core)

- [x] `core/analytics` (Firebase + Mixpanel)
- [x] `core/network` (Dio + Retrofit + JWT refresh)
- [x] `core/firebase`
- [x] `core/remote_config`
- [x] `core/crashlytics`
- [x] `core/notifications`
- [x] `core/error`
- [x] `core/router`
- [x] `core/theme`
- [x] `core/config`
- [x] `core/deeplink`
- [x] `core/attribution` (UTM + Play Install Referrer)
- [x] `core/app_update` (Play in-app updates + iOS Upgrader + maintenance)
- [x] `core/logging`
- [x] `core/di` (GetIt composition root; BLoC for presentation state)
- [x] Auth (API Phone/OTP; optional Android Truecaller when `TRUECALLER_CLIENT_ID` is set)
- [x] Notifications feature
- [x] Home shell
- [x] Profile shell (account, terms / privacy / refund, sign-out)
- [x] Paywall plan module (API + which plan to show; no checkout)
- [x] Meta Pixel payment conversions + pending-events drain
- [x] Shared widgets, Poppins, logo placeholder + `./scripts/setup_theme.sh`

Add / remove modules:

```
(add or strike items here)
```

### Exclude (Vokey-specific)

- [x] Voice unlock + native Kotlin overlay / Vosk
- [x] Clap-to-find
- [x] Paywall / Razorpay / Cashfree UPI **checkout** (plan selection is in the template)
- [x] Facebook **deferred** deeplinks (live UTM + Play Install Referrer **are** in the template)
- [x] Payment Cloud Functions

Bring back later:

```
(add items to restore, e.g. paywall)
```

---

## 3. Configuration system

Public identity in `project_config.yaml`:

- [x] App name
- [x] Android package / applicationId
- [x] iOS bundle ID (optional — skip to ship Android-only)
- [x] Dev API URL
- [x] Prod API URL
- [x] Firebase Dev project ID
- [x] Firebase Prod project ID
- [x] Deep-link scheme
- [x] Deep-link host
- [x] Support email
- [x] Terms / privacy / refund URLs
- [x] Theme colors and font family (optional, via `./scripts/setup_theme.sh`)

Secrets **not** in YAML:

- [x] Mixpanel tokens → `.env.*`
- [x] Firebase json / plist → console download
- [x] Signing → `android/key.properties`

Fields I want to add to `project_config.yaml`:

```
(add keys here)
```

---

## 4. Setup generator

Commands: `./scripts/setup_project.sh` and optional `./scripts/setup_theme.sh`

- [x] Prompt for required values
- [x] iOS bundle ID optional (Enter skips iOS native/Firebase checks)
- [x] Targeted replacements only (not global find/replace)
- [x] Idempotent via `.setup_state.json`
- [x] Rollback via `.setup_backup` on failure
- [x] Support `--yes` after editing YAML directly
- [x] `./scripts/setup_theme.sh` — all fields optional (logo, foreground, primary, background, error, font)

Files setup currently updates:

- [x] Gradle `applicationId` + flavor display names
- [x] Android intent filters
- [x] iOS `Flavor.xcconfig` (bundle ID only when iOS is configured)
- [x] `.env.dev` / `.env.prod`
- [x] Firebase placeholder project IDs
- [x] `lib/config/app_identity.dart` (includes refund URL)
- [x] Dart package imports if `app.dart_package` changes

Theme script updates (only fields you fill):

- [x] `assets/logo/logo.png` + adaptive-icon foreground
- [x] Android / iOS launcher icons (`flutter_launcher_icons`)
- [x] Android / iOS splash
- [x] `lib/core/theme/app_colors.dart` + adaptive-icon background color
- [x] `lib/core/theme/app_typography.dart` Google Fonts family

Other files setup should also update:

```
(add paths here)
```

---

## 5. Dev / Prod flavors

```bash
flutter run --flavor dev  -t lib/main_dev.dart
flutter run --flavor prod -t lib/main_prod.dart
```

- [x] Android product flavors + `.dev` applicationId suffix
- [x] iOS `dev` / `prod` schemes + Flavor.xcconfig (iOS identity optional at setup)
- [x] Separate env files, Firebase options, native config per flavor
- [x] `./b.sh` prod AAB; prod `API_BASE_URL` must match `project_config.yaml` (setup Production API URL)
- [x] `./s.sh` flavor APK → Slack (token/channel from env; git user in the upload comment)
- [x] `.github/workflows/auto-release.yml` — tag + GitHub Release from `pubspec.yaml` on merged `dev` → `main`
- [ ] Unique iOS bundle ID per flavor (currently one bundle ID for both iOS flavors)

Flavor changes I want:

```
(add notes here)
```

---

## 6. Firebase

Placeholder files (replace after console setup):

- [x] `android/app/src/dev/google-services.json`
- [x] `android/app/src/prod/google-services.json`
- [x] `ios/config/dev/GoogleService-Info.plist`
- [x] `ios/config/prod/GoogleService-Info.plist`
- [x] `lib/firebase_options_dev.dart`
- [x] `lib/firebase_options_prod.dart`
- [x] Xcode script copies flavor plist into `ios/Runner/`

Manual (cannot automate):

- [ ] Create Firebase Dev project
- [ ] Create Firebase Prod project
- [ ] Register Android apps (`{id}.dev` and `{id}`)
- [ ] Register iOS apps (optional until a bundle ID is set)
- [ ] Add SHA-1 / SHA-256
- [ ] Enable Auth, FCM, Analytics, Crashlytics, Remote Config (`paywall_plan_variant`, `force_update`, `is_app_under_maintenance`, maintenance copy)
- [ ] Run `flutterfire configure` and replace Dart options

Firebase notes:

```
(add notes here)
```

---

## 7. Validation and docs

- [x] `./scripts/validate_config.sh` (skips iOS checks when bundle ID is unset)
- [x] `README.md`
- [x] `STARTUP.md`
- [x] `ARCHITECTURE.md`
- [x] `CODEWALKTHROUGH.md`
- [x] `flutter analyze` clean
- [x] Unit / widget tests passing

Docs or checks I want added:

```
(add here)
```

---

## 8. Remaining / follow-up

- [ ] Enable GitHub **Template repository** on `VoiceClub-app/flutter-app-template`
- [x] Wire paywall CTA to Capslock Payments (Cashfree / PhonePe chosen server-side)
- [x] Profile gating: init / renewal / expire on resume; Payment settings Cancel vs Renew; one-time has no Cancel/Renew
- [ ] Unique iOS bundle IDs per flavor (if needed to install both builds on one device)
- [ ] Real Mixpanel tokens
- [ ] Signing keys / store listings
- [ ] Facebook deferred deeplinks (optional; live links + Play referrer already work)

New-app branding (logo / colors / font) is `./scripts/setup_theme.sh` after clone — not a remaining template task.

Priority order (edit this):

1.
2.
3.

---

## Open decisions

| Question | Current choice | My choice |
| --- | --- | --- |
| Where should the template live? | `StudioProjects/flutter-app-template` | |
| Should Dart package rename during setup? | Only if `app.dart_package` in YAML changes | |
| Should Android Kotlin namespace change? | No — only `applicationId` | |
| Include Facebook analytics? | Yes — Meta Purchase/StartTrial via pending `addBalanceSuccess` drain | |
| Include paywall now? | Plan selection + host UPI checkout + profile `entitlement`/`has_purchased` gating (init / renewal / expire / one-time) | |
| Default OTP backend | API Phone/OTP (`/api/v1/auth/otp/*`); optional `POST /api/v1/auth/truecaller` | |
| State / DI | BLoC + GetIt | |
| iOS at setup? | Optional — skip bundle ID to stay Android-only | |
| Branding | Optional `./scripts/setup_theme.sh` (logo, colors, text font) | |
| Legal URLs | Terms, privacy, **refund** on Profile | |

---

## How to use this file

1. Edit the tables, checkboxes, and fenced note blocks.
2. Tell the agent which section changed (or paste the updated section).
3. Do not treat checked items as locked if you uncheck them — uncheck = revert or redo that part.
