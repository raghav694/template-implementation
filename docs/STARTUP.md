# New project startup checklist

Work top to bottom. Optional steps are marked; skip them and the app still runs.

```bash
chmod +x scripts/*.sh
```

## 1. Clone and identity

- [ ] Create a repository from the GitHub template
- [ ] Clone it
- [ ] Run setup (edits `project_config.yaml` interactively, or edit the file first)

```bash
./scripts/setup_project.sh
```

The script asks for app name, Android package, **required** Firebase project IDs (create new or reuse existing), API URLs, optional deep-link scheme/host, support email, and **Terms / Privacy / Refund** URLs (Profile webviews; auth still shows terms + privacy).

| Prompt | Required? |
| --- | --- |
| iOS bundle identifier | No — Enter skips iOS. Native files stay `com.example.appTemplate` |
| Deep-link scheme / host | No — Enter keeps `__APP_SCHEME__` / `__DEEPLINK_HOST__`. App Links stay off |
| Create new Firebase projects? | Yes — `Y` creates missing IDs later; `n` requires existing Dev + Prod IDs |
| Firebase Dev / Prod project IDs | Yes — never skipped |

Setup writes those IDs into `project_config.yaml`. `./scripts/setup_firebase.sh` uses them (it does not invent new IDs). If you chose to create, missing projects are created; if you said no, only existing projects are used.

- [ ] Confirm Android `applicationId` in `android/app/build.gradle.kts`
- [ ] If you set an iOS bundle ID, confirm `ios/Flutter/Flavor.xcconfig`
- [ ] Confirm `.env.dev` / `.env.prod` exist (`API_BASE_URL` should already be filled)

Setup writes identity into Android, Dart, and env files. Secrets (Mixpanel, Slack, Capslock Payments, Auth tenant, Truecaller, GrowthBook) never go in YAML. Re-running setup keeps existing `PAYMENTS_*`, `AUTH_*`, `TRUECALLER_CLIENT_ID`, and `GROWTHBOOK_*` in `.env`.

## 2. Branding (optional)

Every field in `./scripts/setup_theme.sh` is skippable (Enter, or omit the flag).

| Prompt | What it changes |
| --- | --- |
| App logo path | In-app `AppLogo`, `assets/logo/logo.png`, launcher icons, Android/iOS splash |
| Adaptive icon foreground | Android adaptive icon (`assets/logo/foreground.png`); defaults to the logo |
| Primary color | Accent, gradient, glow, Android adaptive-icon background |
| Background color | App canvas + splash background |
| Error color | Destructive / error token |
| Text theme font | Google Fonts family for `AppTypography` (default Poppins) |

```bash
./scripts/setup_theme.sh
# or:
./scripts/setup_theme.sh --logo ./brand/logo.png --primary '#1E88E5' --font Inter
```

JPG/WebP logos become PNG on macOS via `sips` (or ImageMagick). Launcher icons need `fvm` or `dart` on PATH (`dart run flutter_launcher_icons`). The font must be a [Google Fonts](https://fonts.google.com) family; the app loads it through `google_fonts`. Bundled `assets/fonts/Poppins-*.ttf` stay as a fallback until you replace those files. If the logo is not already on a transparent square, you may need to pad the adaptive icon by hand.

## 3. Firebase

Needs the [Firebase CLI](https://firebase.google.com/docs/cli) and a Google login. The script installs `flutterfire_cli` if it is missing. Setup already asked for Dev and Prod project IDs.

```bash
npm install -g firebase-tools   # once
firebase login --reauth         # browser; use --reauth so a stale token is refreshed
./scripts/setup_firebase.sh
```

`setup_firebase.sh` runs `firebase login --reauth` itself if `projects:list` fails or the token is expired. Bare `firebase login` is a no-op when the CLI still thinks you are logged in. In CI / non-TTY, run `firebase login --reauth` first.

`setup_project.sh` can run this for you at the end. It:

- Reuses the project IDs from `project_config.yaml`
- Creates those projects only if you answered yes to “Create new Firebase projects…”
- If an ID already exists as a **GCP-only** project (create succeeded, Firebase attach did not), a rerun calls `projects:addfirebase` instead of treating the ID as taken globally
- Waits for a new project to show up in `projects:list`, then retries `flutterfire configure` if Firebase has not listed it yet
- Registers flavor apps and writes:
  - `android/app/src/dev/google-services.json` and `android/app/src/prod/google-services.json`
  - `lib/firebase_options_dev.dart` and `lib/firebase_options_prod.dart`
  - `ios/config/dev/GoogleService-Info.plist` and `ios/config/prod/GoogleService-Info.plist` (only if iOS is configured)

If YAML has no IDs (you skipped `setup_project.sh`), it asks for them: existing IDs if you are not creating, or new IDs if you are.

| Flavor | Android applicationId | iOS bundle ID |
| --- | --- | --- |
| Dev | `{android_package}.dev` | `{ios_bundle_id}.dev` |
| Prod | `{android_package}` | `{ios_bundle_id}` |

`--existing` only registers apps (same as answering no during setup). `--dev` / `--prod` run one flavor. If a chosen ID is taken globally, the script tries `projects:addfirebase` first. It asks for a different ID only if attach fails and the ID is still not in this account’s Firebase list.

Then in the **Firebase console** (repeat for Dev **and** Prod):

- [ ] Enable Analytics
- [ ] Enable Crashlytics
- [ ] Enable Cloud Messaging
- [ ] Enable Remote Config and publish the keys below
- [ ] Add SHA-1 / SHA-256 from the upload keystore (Android)

### Remote Config keys

Canonical list: `remoteconfig.template.json`. The app has in-app defaults, but unpublished console keys mean you cannot flip force-update or maintenance without a new build.

| Key | Type | Default | What it does |
| --- | --- | --- | --- |
| `paywall_plan_variant` | String | `monthly` | Plan id on the paywall when there is no deeplink plan id and GrowthBook has not assigned one. **Not** access / entitlement. |
| `force_update` | Boolean | `false` | Mandatory store update. Android: Play in-app update on launch and resume. iOS: App Store dialog hides Later |
| `is_app_under_maintenance` | Boolean | `false` | Full-screen maintenance gate over the whole app |
| `maintenance_title` | String | *(empty)* | Headline on that maintenance screen |
| `maintenance_message` | String | *(empty)* | Body copy on that maintenance screen |

Firebase Boolean parameters must be type **Boolean**, not a string `"false"`.

- [ ] Dev: create all five keys, leave defaults, **Publish**
- [ ] Prod: same keys, **Publish**

### GrowthBook features

Create these in the GrowthBook dashboard (same names as `GrowthBookKeys`). Empty
`GROWTHBOOK_API_KEY` skips the SDK; the app uses the in-app defaults below.

| Key | Type | Default | What it does |
| --- | --- | --- | --- |
| `paywall_plan_variant` | String | *(off → Remote Config)* | Plan id when the feature is on. Loses to a deeplink plan id. |
| `forceUpdate` | Boolean | `false` | Mandatory store update, ORed with RC / config API |

UTM from deeplinks / Play Install Referrer is also sent as GrowthBook
attributes (`utmSource`, `utmMedium`, `ref`, `gclid`, `gbraid`) for targeting.
Mixpanel still gets set-once UTM at login.

To force an update later: set `force_update` = `true` (Firebase and/or
GrowthBook `forceUpdate`), publish, wait for the client fetch (debug: immediate;
prod RC: up to 1 hour).

`GET /api/v1/config/status` is optional. When it succeeds, its `force_update` / `is_app_under_maintenance` flags are **ORed** with Remote Config (either source can turn them on). GrowthBook `forceUpdate` is ORed on top of that for store prompts.

## 4. Tokens (optional until you need the product)

Setup already wrote `API_BASE_URL`. Fill the rest only when you use that product.

- [ ] Mixpanel → `.env.dev` / `.env.prod` `MIXPANEL_TOKEN` (empty = no-op)
- [ ] Capslock Payments → `.env.dev` / `.env.prod` `PAYMENTS_BASE_URL` + `PAYMENTS_TENANT_ID` (empty = paywall CTA disabled)
- [ ] Auth (OTP / refresh / profile) → `.env.dev` / `.env.prod` `AUTH_BASE_URL` + `AUTH_TENANT_ID` (both required; tenant is in the path)
- [ ] Truecaller → `.env.dev` / `.env.prod` `TRUECALLER_CLIENT_ID` (empty = button hidden). Re-run setup or copy the same id into `android/app/src/{dev,prod}/res/values/truecaller.xml`. Android only.
- [ ] GrowthBook → `.env.dev` / `.env.prod` `GROWTHBOOK_API_KEY` (empty = flags use in-app defaults). Optional `GROWTHBOOK_HOST_URL` (default `https://cdn.growthbook.io/`).
- [ ] Meta / Facebook App ID + Client Token → `android/.../strings.xml`, `ios/Runner/Info.plist` (placeholders = no-op)
- [ ] Slack (`./s.sh`) → `SLACK_API_TOKEN` + `SLACK_CHANNEL_ID` in `.env.dev` / `.env.prod` (optional `.slack.env`)

Checkout is Capslock Payments (UPI Autopay + one-time on Android). A `/payment`
or `/paywall` deeplink still opens the paywall; without `PAYMENTS_*` the CTA
is a hint. Full flow: [PAYMENTS.md](PAYMENTS.md).

Truecaller is optional. Put the dashboard client id in `.env.dev` / `.env.prod`
`TRUECALLER_CLIENT_ID`. Setup copies it into
`android/app/src/{dev,prod}/res/values/truecaller.xml` (the Android SDK reads
that via the manifest). Empty → **Continue with Truecaller** is hidden and the
sheet is not auto-launched. When set on Android, the sheet auto-launches once
per login visit; OTP always remains. iOS / web never show the CTA. Runtime
flow: `ARCHITECTURE.md` (Auth) and `CODEWALKTHROUGH.md` §4.

| Service | Required values | Where | How to disable |
| --- | --- | --- | --- |
| Mixpanel | project token | `.env.*` `MIXPANEL_TOKEN` | Leave empty |
| Meta Pixel / App Events | Facebook App ID + Client Token | `android/.../strings.xml`, `ios/Runner/Info.plist` | Leave placeholders |
| Firebase Analytics | Firebase project | native config + FlutterFire options | Remove `FirebaseAnalyticsService` from `analytics_factory.dart` |
| Crashlytics | Firebase project | Gradle plugin + `CrashlyticsService` | Collection is off in debug |
| Remote Config | parameters in console (section 3) | `remoteconfig.template.json` | In-app defaults if a key is missing |
| GrowthBook | SDK client key | `.env.*` `GROWTHBOOK_API_KEY` (+ optional host URL) | Leave empty — in-app defaults |
| App update / force update | RC `force_update` **or** GB `forceUpdate` + store listing | Firebase console + GrowthBook dashboard; optional `GET /api/v1/config/status` | Leave both force flags false |
| FCM | Firebase project + iOS key | native config files | Listener no-ops if Firebase did not init |
| Phone OTP | `AUTH_BASE_URL` + `AUTH_TENANT_ID` + `/public/tenants/{tenant}/otp/*` | `.env.*` | Auth screen is the default sign-in path |
| Truecaller | `TRUECALLER_CLIENT_ID` + `POST /public/tenants/{tenant}/truecaller/verify` | `.env.*` and flavor `truecaller.xml` | Leave empty — CTA hidden, no auto-launch |
| Plans / paywall | `PAYMENTS_BASE_URL` + `PAYMENTS_TENANT_ID` + Capslock `/v1/tenants/{tenant}/plans` | `.env.*` + optional deeplink `planId` + GB / RC `paywall_plan_variant` | Empty payments env: plan load errors, CTA hint |
| Checkout / Autopay | same Capslock origin; host `PaywallCheckout` + `UpiService` | Android UPI; see `PAYMENTS.md` | Empty env or non-Android: CTA disabled |
| Entitlement (access) | Auth profile `entitlement` / `has_purchased`, overlayed with Capslock `validity_end_at` | OTP / Truecaller / resume `EntitlementCubit.refreshFor` | Not Remote Config |
| Cancel / renew / dates | Capslock `getUserSubscription` / `cancelSubscription` | Profile → Payment settings | Cancel Autopay; Renew when free + has purchased; none on one-time |
| Expire / first paywall | same profile fields | `appRedirect` → `source=init` or `source=renewal` | Free-to-play: keep sending `entitlement: premium` |
| Pending payment events | `/api/v1/events/pending`, `/api/v1/events/{id}/done` | `.env.*` | Drain no-ops if the API is unreachable |
| Deep links | scheme + host | `project_config.yaml` | Enter skips; runtime no-ops until both are set |
| Legal pages | terms / privacy / refund URLs | `project_config.yaml` → Profile | Placeholders still show the rows |
| Short-link resolve | `POST /api/v1/deeplinks/resolve` | Backend | UTM is still saved from the raw URL |
| Play Install Referrer | Play campaign UTM + `short_id` | Android, first launch | No-ops on iOS / if Play returns nothing |

## 5. Validate and first run

```bash
./scripts/validate_config.sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter run --flavor dev -t lib/main_dev.dart
```

- [ ] `./scripts/validate_config.sh`
- [ ] Dev run (`--flavor dev -t lib/main_dev.dart`)
- [ ] Prod run (`--flavor prod -t lib/main_prod.dart`)
- [ ] Firebase connectivity (Analytics DebugView)
- [ ] Phone OTP via API
- [ ] Truecaller on Android (only if `TRUECALLER_CLIENT_ID` is set)
- [ ] First-time user lands on `/paywall?source=init` (cannot dismiss)
- [ ] Lapsed user (`free` + `has_purchased`) lands on `/paywall?source=renewal`
- [ ] Profile → Payment settings: Cancel Autopay; Renew after cancel while still in the paid period; no Cancel/Renew on one-time
- [ ] Profile → Privacy, Terms, Refund Policy
- [ ] Logo on splash, home, and launcher (if you ran `setup_theme.sh`)
- [ ] Analytics events
- [ ] Notifications (foreground + tap)
- [ ] Remote Config keys exist in Dev and Prod
- [ ] GrowthBook features exist if `GROWTHBOOK_API_KEY` is set

## 6. Ship

Prod AAB builds require `.env.prod` `API_BASE_URL` to equal `environment.prod.api_base_url` from setup. There is no hardcoded host.

```bash
./b.sh prod                 # app-<name>-PROD-<version>.aab
./b.sh dev
./b.sh prod my-custom-bundle
```

- [ ] Signing keys in `android/key.properties` (gitignored)
- [ ] `./b.sh prod`

Slack APK (comment includes `git config user.name`; prod uses the same API URL check):

```bash
./s.sh dev
./s.sh prod
```

- [ ] `./s.sh dev` (optional)

Bump `pubspec.yaml` `version:` before merging **dev → main**. That merge creates tag `v{version}` and a GitHub Release (`.github/workflows/auto-release.yml`).

Play Console / App Store listings stay manual.

## iOS later (optional)

Skipped bundle ID is fine. `./scripts/validate_config.sh` then skips iOS bundle ID, `GoogleService-Info.plist`, and Xcode flavor schemes.

When you need iOS:

1. Set `app.ios_bundle_id` (or re-run `./scripts/setup_project.sh`)
2. `./scripts/setup_firebase.sh` to register iOS apps
3. Apple Developer team, push key, and associated domains

The Xcode build phase `Select Firebase Plist` copies the flavor plist into `ios/Runner/GoogleService-Info.plist` at build time.

## Deep links later (optional)

Skipped scheme/host is fine. `./scripts/validate_config.sh` then skips those checks, and `DeeplinkConfig.isConfigured` keeps App Links off.

When you need custom scheme / App Links:

1. Set `deeplink.scheme` and `deeplink.host` (or re-run `./scripts/setup_project.sh`)
2. Confirm `AndroidManifest.xml` intent filters picked up the real values (setup does not write empty `android:scheme=""`)
