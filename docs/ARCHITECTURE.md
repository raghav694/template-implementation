# Architecture

This template follows the production Flutter architecture used in Vokey, with
intentional changes: **BLoC** for state and **GetIt** for DI (no Riverpod, no Provider).

- Feature-first **Clean Architecture**
- **flutter_bloc** (Bloc / Cubit) for presentation state
- **GetIt** for dependency injection
- **go_router** for navigation and auth redirects
- **Dio** + **Retrofit** REST client with token refresh
- **Capslock Payments SDK** for catalog, UPI Autopay / one-time, and billing status (not access)
- **truecaller_sdk** for optional Android Truecaller login (gated on `TRUECALLER_CLIENT_ID`)
- **growthbook_sdk_flutter** for experiments, force-update, and attribution targeting
- **fpdart** `Either<Failure, T>` at the domain boundary
- **Freezed** + `json_serializable` for API DTOs

Paywall **plan selection and checkout** use Capslock Payments. Cashfree /
PhonePe are chosen on the Capslock server; the app never selects a gateway.
See `PAYMENTS.md` for fetch → pay → poll → **profile entitlement** → cancel / renew. Access is `GET /public/tenants/{tenant}/users/{userId}` (else `.../profile?phone=`) (`entitlement`, `has_purchased`), overlayed with Capslock `validity_end_at` so a past paid period shows the paywall even if profile has not flipped.

## Layers

```
lib/
  config/          App identity, Environment, flavor metadata
  core/            Reusable infrastructure (no product features)
    di/            GetIt composition root (`injection.dart`)
  features/        Vertical slices (auth, notifications, home, profile, paywall)
  shared/          Reusable widgets
  main_dev.dart    Dev flavor entry
  main_prod.dart   Prod flavor entry
  main.dart        Shared bootstrap
  app.dart         MaterialApp.router
```

Dependency flow:

```
features → core → Flutter / third-party SDKs
features must not import other features except through core contracts
```

`lib/core/di/injection.dart` is the composition root (`configureDependencies()`).
It registers network, auth, analytics, notifications, and the router in GetIt.
Screens use `BlocBuilder` / `context.read` for BLoC state and `getIt<T>()` for
services.

## Configuration system

`project_config.yaml` is the source of truth for **public identity**:

- App name, Dart package, Android applicationId
- iOS bundle ID (**optional** — leave `__IOS_BUNDLE_ID__` to skip iOS)
- API base URLs
- Firebase project IDs (**required** — create new or reuse existing)
- Deep-link scheme and host (**optional** — leave `__APP_SCHEME__` / `__DEEPLINK_HOST__` to skip App Links)
- Support email and legal URLs (terms, privacy, refund)

`./scripts/setup_project.sh` writes those values into:

- `lib/config/app_identity.dart`
- Android applicationId / flavor suffixes
- Android intent filters
- `ios/Flutter/Flavor.xcconfig` (display name, URL scheme, and bundle ID only when iOS is configured)
- `.env.dev` / `.env.prod` (API URLs only — tokens stay in env files)
- Firebase project IDs (`setup_firebase.sh` creates them only when `firebase.create_if_missing` is true)

`./scripts/setup_firebase.sh` registers Android (and iOS when configured) apps using the Dev/Prod IDs from YAML. If you chose to create projects during setup, missing IDs are created; otherwise they must already exist in the Firebase account. A rerun after a GCP-only create calls `projects:addfirebase` and retries `projects:list` / `flutterfire configure` until the project is visible. Writes flavor `google-services.json`, `GoogleService-Info.plist`, and `lib/firebase_options_*.dart`. Requires the Firebase CLI. Login uses `firebase login --reauth` (bare `login` is a no-op on a stale session).

`./b.sh prod` builds a Play App Bundle. Before compiling, it requires `.env.prod` `API_BASE_URL` to equal `environment.prod.api_base_url` from `project_config.yaml` (the Production API URL entered in setup). The check is not a hardcoded host.

`./s.sh` builds a flavor APK and uploads it to Slack. Credentials are `SLACK_API_TOKEN` and `SLACK_CHANNEL_ID` in the matching flavor `.env.dev` / `.env.prod` (same keys as Vokey), then `.slack.env`. The APK filename uses `app.name` from `project_config.yaml`, not a hardcoded product string. The Slack comment and file title always include `git config user.name`. Prod APKs use the same API URL safety check as `./b.sh`.

`.github/workflows/auto-release.yml` creates `v{version}` (from `pubspec.yaml`) and a GitHub Release when a same-repo `dev` PR is merged into `main`.

`./scripts/validate_config.sh` skips iOS bundle ID, `GoogleService-Info.plist`, and Xcode flavor schemes when iOS is not configured. It also skips deep-link scheme/host checks when those placeholders remain.

### Optional branding

`./scripts/setup_theme.sh` — every field is skippable (Enter or omit the flag):

| Field | Applied to |
| --- | --- |
| Logo path | `assets/logo/logo.png`, launcher icons, Android splash, iOS `LaunchImage` |
| Adaptive-icon foreground | `assets/logo/foreground.png` (defaults to the logo) |
| Primary | `AppColors` accent / gradient / glow + Android adaptive-icon background |
| Background | `AppColors` canvas + splash background |
| Error | Destructive / error token |
| Text theme font | `AppTypography.fontFamily` via Google Fonts (e.g. Inter) |

Colors and font family are stored under `theme:` in `project_config.yaml` when set. The in-app logo widget is `shared/widgets/app_logo.dart`.

The Android `namespace` and `MainActivity` Kotlin package stay
`com.example.app_template`. Play / Firebase identity is `applicationId`, which
setup **does** change.

Secrets never belong in YAML:

- Mixpanel tokens → `.env.dev` / `.env.prod`
- Capslock Payments origin + tenant → `.env.dev` / `.env.prod` (`PAYMENTS_BASE_URL`, `PAYMENTS_TENANT_ID`)
- Auth origin + tenant → `.env.dev` / `.env.prod` (`AUTH_BASE_URL`, `AUTH_TENANT_ID`; both required for OTP / refresh / profile)
- Truecaller client id → `.env.dev` / `.env.prod` (`TRUECALLER_CLIENT_ID`; also flavor `truecaller.xml`)
- Signing keys → `android/key.properties` (gitignored)
- Firebase plist / json → `./scripts/setup_firebase.sh` (not secrets, but machine-generated)



## Environment strategy


| Layer                    | Dev                         | Prod                         |
| ------------------------ | --------------------------- | ---------------------------- |
| Dart entry               | `lib/main_dev.dart`         | `lib/main_prod.dart`         |
| Env file                 | `.env.dev`                  | `.env.prod`                  |
| Android flavor           | `--flavor dev`              | `--flavor prod`              |
| Android applicationId    | `{id}.dev`                  | `{id}`                       |
| iOS scheme               | `dev` (optional identity)   | `prod` (optional identity)   |
| Firebase options         | `firebase_options_dev.dart` | `firebase_options_prod.dart` |
| google-services.json     | `android/app/src/dev/`      | `android/app/src/prod/`      |
| GoogleService-Info.plist | `ios/config/dev/` (if iOS)  | `ios/config/prod/` (if iOS)  |


Business logic reads `AppConfig` / Remote Config. It must not hardcode URLs, tokens, or project IDs.

## Reusable core modules


| Module               | Role                                                            |
| -------------------- | --------------------------------------------------------------- |
| `core/analytics`     | Mixpanel + Firebase + Meta standard events (see below) |
| `core/auth` wiring   | Token store lives in `core/network`; feature is `features/auth` |
| `core/network`       | Dio + Retrofit; app origin vs auth origin (`AUTH_*`); refresh interceptor |
| `core/notifications` | FCM background handler                                          |
| `core/remote_config` | Typed keys + defaults; `force_update` is ORed with GrowthBook / config API |
| `core/growthbook`    | GetIt `GrowthBookService`; experiments + attribution attributes |
| `core/di`            | GetIt (`configureDependencies`)                                 |
| `core/crashlytics`   | Global error hooks                                              |
| `core/deeplink`      | App Links, short-link resolve, payment → paywall |
| `core/payments`      | Capslock `CheckoutClient` Dio adapter + status mapping |
| `core/app_update`    | Merges RC + config API + GrowthBook `forceUpdate`; Play `in_app_update`; iOS `UpgradeAlert`; maintenance gate |
| `core/attribution`   | UTM source/medium + Play Install Referrer; Mixpanel set-once + GrowthBook attrs |
| `core/logging`       | Debug logger                                                    |
| `core/error`         | Failures / exceptions                                           |
| `core/state`         | `AsyncValue` for loading / data / error in controllers          |
| `core/firebase`      | Init, options resolver                                          |
| `core/router`        | go_router + auth + profile-entitlement redirect                 |
| `core/theme`         | Colors, type, spacing; branded via `setup_theme.sh`             |
| `core/config`        | `.env` loading                                                  |




## Generic features kept

- **auth** — API Phone/OTP, plus optional Android Truecaller when `TRUECALLER_CLIENT_ID` is set
- **notifications** — FCM permission, token sync, tap routing
- **paywall** — Capslock catalog + which plan to show (deeplink, else GrowthBook, else Remote Config) + UPI checkout + cancel / renew / expire / one-time. Access is Heimdall `User.entitlement` + `hasPurchased`, not Capslock.
- **analytics drain** — `GET /api/v1/events/pending` → track → `POST /events/{id}/done`
- **home** — placeholder shell
- **profile** — account, **Privacy / Terms / Refund Policy**, Help & Support, sign-out, plans entry, payment settings

Profile legal rows open `PolicyWebViewScreen` with `AppIdentity.privacyUrl`, `termsUrl`, and `refundUrl`.

### Auth: Phone OTP and Truecaller

Phone OTP is always on the auth screen
(`POST /public/tenants/{tenant}/otp/send` with `{ phone_no }`, then
`/otp/verify` with `{ phone_no, otp }`). Truecaller is an extra Android CTA
on the **phone** step only.

**Continue with Truecaller** auto-launches on Android when
`AppConfig.hasTruecaller` (`TRUECALLER_CLIENT_ID` non-empty). The outlined
CTA stays as a retry. The sheet is launched once per visit
(`TruecallerAutoLaunchGuard`). SDK unavailability / cancel is silent; OTP
stays available. Backend verify failures still show a banner.

Empty client id → no auto-launch, no button, and no `truecaller_sdk` init.

Native SDK reads the same id from the Android manifest
(`com.truecaller.android.sdk.ClientId` → `@string/truecaller_client_id`).
Flavor files `android/app/src/{dev,prod}/res/values/truecaller.xml` hold the
value; `./scripts/setup_project.sh` copies each `.env` `TRUECALLER_CLIENT_ID`
into the matching flavor file.

Tap flow:

1. `AuthScreen` auto-launches (or the user taps the CTA) → `PhoneAuthTruecallerRequested`.
2. `PhoneAuthBloc` → `TruecallerOAuthClient.authorize()` (`OPTION_VERIFY_ONLY_TC_USERS`, PKCE, `streamCallbackData`). `truecallerInitiated` fires when the consent sheet is requested.
3. OAuth state is `AppIdentity.androidPackage` (else deeplink host), not a VoiceClub string.
4. If Truecaller is not usable on the device, OTP stays available with no error banner.
5. `POST /public/tenants/{tenant}/truecaller/verify` with `{ authorization_code, code_verifier }`.
6. Response is parsed as the same `VerifyOtpResponse` as OTP; tokens and user go through `AuthTokenStore` + `RestSession`.
7. `AuthCubit` sees the user; `appRedirect` leaves `/auth`.

Do not send VoiceClub `app_secret_key` or call `/un/secure/true_caller/verify`.
The client does not pick a Truecaller partner key; the dashboard client id is
enough. iOS / web never show the CTA.

Analytics: `truecallerInitiated` / `truecallerProceed` / `truecallerFailed`.
Successful login also logs `otpVerified` (full `number` + `loginType`) and
`onboardingCompleted` once per install (Meta CompleteRegistration / GA `login`).

### Payment events and Meta Pixel

Meta Purchase / StartTrial are **not** fired from `checkoutVerified`.
`firstAddBalanceSuccess` (StartTrial) and `addBalanceSuccess` (Purchase) are
sent from `PurchaseSuccessReporter` on stream success (or premium resume).
The Heimdall pending drain sends `addBalanceSuccess` if the client never
flushed, and skips a row already reported.

1. Client flush or `GET /api/v1/events/pending`
2. `AnalyticsService.logEvent` (Mixpanel + Firebase + Facebook)
3. Facebook maps: `onboardingCompleted` → CompleteRegistration,
   `paymentScreen` → AddToCart, `addBalanceInitiated` → InitiateCheckout,
   `firstAddBalanceSuccess` → StartTrial, `addBalanceSuccess` → Purchase.
   `subscriptionRenewed` → Subscribe only when the **backend drain** delivers
   a queued renewal (checkout never logs it).
4. Google maps the same checkout rows to `login`, `add_to_cart`,
   `begin_checkout`, `start_trial`, `purchase`. Drain-only
   `subscriptionRenewed` → custom `renew_subscription`. `firstAppOpen`
   is sent as GA `first_visit`.
5. `POST /api/v1/events/{id}/done` only if the drain tracked successfully

### Which plan the paywall shows

The paywall renders **one** plan, not a picker. Autopay and subscription are
the same **recurring** category; the other category is a **one-time** payment.
That category comes from the plan payload — there is no Remote Config flag
for Autopay.

Incoming links (`app_links` + Play Install Referrer) are handled by
`DeeplinkController`: UTM source/medium are persisted, HTTPS short links are
expanded via `POST /api/v1/deeplinks/resolve`, and `/payment` / `/paywall`
open the paywall.

1. Deeplink plan id, if present (`/paywall?planId=yearly`,
   `/payment?plan_price_id=yearly`, or `/paywall/yearly`) and that plan exists
2. Else GrowthBook `paywall_plan_variant` when that feature is on
3. Else Remote Config `paywall_plan_variant` (default `monthly`)
4. Else the control plan `monthly`
5. Else Capslock `listPlans` and take the first plan

`offer_type=DISCOUNT|BONUS` is shown on the paywall and passed through on the
CTA; it does not change which plan is loaded.

If the app has no deeplink plan id, step 1 is skipped. A missing deeplink plan
falls through rather than blanking the paywall.

### Checkout, status, and cancel

The CTA is host-owned `PaywallCheckout` (Android). It lists UPI apps via
`UpiService`, calls Capslock `initiatePayment` (no `payment_method` /
`provider` — Capslock picks the gateway), opens the selected app or a
non-dismissible QR sheet (Cancel to retry; no Reset), then listens to
`watchCheckoutStatus`. After UPI return a
processing sheet stays up until success or failure. `initiatePayment`
creates a Cashfree or PhonePe session on the server. Recurring success is
subscription `ACTIVE`; one-time success is payment `SUCCESS` / `COMPLETED`.
Capslock `PENDING` maps to app `initiated` and is **not** entitled.

After the success sheet closes the app refreshes the auth profile
(`entitlement` / `has_purchased`) and drains pending payment events.
Capslock `getUserSubscription` is Payment settings only (dates, cancel).
`addBalanceSuccess` is flushed once from `PurchaseSuccessReporter` (stream
success or later premium resume), not from `checkoutVerified`. First checkout
also sends `firstAddBalanceSuccess` (Meta StartTrial). Recurring
`subscriptionRenewed` / `subscriptionRenewalFailed` /
`subscriptionRenewalNotified` are backend-queued and only tracked on drain.
Cancel from Payment settings logs `subscriptionCancel`.

Profile gating (no Remote Config flag): `entitlement` premium → Home;
`free` + never purchased → `/paywall?source=init` (non-dismissible);
`free` + `has_purchased` → `/paywall?source=renewal`. After login the router
holds `/loading` until Capslock entitlement resolves. App resume refreshes
the profile so expiry is picked up without an HTTP 410 interceptor.
Settings: Cancel while Autopay is on; Renew when Autopay is cancelled but
access remains until `validity_end_at` (forced Capslock plan, **Renew Now**);
no cancel / renew on one-time (missing Capslock row does not drop access if
profile is still premium). Renewal checkout uses the full plan price, not a
trial. Premium users stay on `/paywall?source=renew` so that checkout can
complete.

Empty `PAYMENTS_BASE_URL` / `PAYMENTS_TENANT_ID` disables the CTA with a hint.
Details: `PAYMENTS.md`.

### Store updates and maintenance

Force-update is on when **any** of these is true: Firebase Remote Config
`force_update`, `GET /api/v1/config/status` `force_update`, or GrowthBook
`forceUpdate`. Maintenance is still RC / API only.

1. Firebase Remote Config (`force_update`, `is_app_under_maintenance`,
   optional `maintenance_title` / `maintenance_message`).
2. If `GET /api/v1/config/status` succeeds, its booleans are **ORed** in and
   non-empty `title` / `message` replace the Remote Config copy.
3. If GrowthBook `forceUpdate` is on, `AppUpdateService.status.forceUpdate`
   is turned on (iOS `UpgradeAlert` reads that notifier).

Empty `GROWTHBOOK_API_KEY` disables GrowthBook; RC / API flags still apply.
Create the RC keys in both Firebase projects from `remoteconfig.template.json`
— see `STARTUP.md`. Create matching GrowthBook features (`forceUpdate`,
`paywall_plan_variant`) in the dashboard.

- **Android** — `in_app_update`. Launch and resume both prompt only when force
  is on (immediate if allowed, else flexible). Deny retries a few times.
  Immediate success calls `exit(0)`.
- **iOS** — `UpgradeAlert` on the home shell. `showLater` is off when force
  is on. Store country is the device locale.
- **Maintenance** — `MaintenanceGate` overlays the whole navigator.

Play Console must have in-app updates enabled for the Android flow. iOS
needs a live App Store listing whose bundle ID matches the build.



## How to add a generic core module

1. Put infrastructure under `lib/core/<name>/` with a small interface.
2. Register it in `configureDependencies()` (`lib/core/di/injection.dart`). Feature code depends on the interface, not the SDK.
3. Read environment values from `AppConfig`, Remote Config, or `GrowthBookService`.
4. Document required secrets in `STARTUP.md` and the runtime path in `CODEWALKTHROUGH.md`.
5. Add a validate-config check if a file or key is required (skip iOS-only checks unless `app.ios_bundle_id` is set).



## How to add an app-specific feature

1. Create `lib/features/<name>/{data,domain,presentation}`.
2. Domain: entities, repository interface, use cases returning `Either<Failure, T>`.
3. Data: Freezed DTOs + Retrofit `*ApiService` + datasource + repository impl.
   Add paths to `ApiRoutes`. Register the Retrofit service with `AppApiClient.dio`.
   Datasources call `_client.run(() => _api....)` — do not call Dio/`AppApiClient.get` directly.
4. Presentation: Cubit/Bloc + screens (`BlocBuilder` / `context.read`).
5. Register routes in `core/router/app_router.dart` and paths in `core/constants/route_paths.dart`.
6. Do not import this feature from `core/`.
7. If the change is architectural (new core module, new RC key, new API, new gated SDK), update `ARCHITECTURE.md`, `STARTUP.md`, and `CODEWALKTHROUGH.md`.

