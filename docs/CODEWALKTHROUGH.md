# Code walkthrough — how this app is placed and how it runs

This is a runtime map of the template. For layer rules and how to add a
feature, see `ARCHITECTURE.md`. For clone-and-configure steps, see `STARTUP.md`.
For plan fetch → checkout → profile entitlement → cancel / renew, see `PAYMENTS.md`.
For OTP + Truecaller login, see `ARCHITECTURE.md` (Auth) and section 4 below.

Run:

```bash
flutter run --flavor dev  -t lib/main_dev.dart
flutter run --flavor prod -t lib/main_prod.dart
```

---

## 1. Where code lives

```
lib/
  main_dev.dart / main_prod.dart   Flavor entry — load .env, then shared main
  main.dart                        Firebase, DI, runApp
  app.dart                         MaterialApp.router + session side effects
  config/                          Compile-time identity (AppIdentity) + flavors
  core/                            Infrastructure (no product screens)
    di/injection.dart              GetIt composition root
    router/                        go_router, auth redirect, PendingRoute
    network/                       Dio + Retrofit, JWT store, refresh, API paths
    deeplink/                      App Links, short-link resolve, payment → paywall
    payments/                      Capslock CheckoutClient adapter + status mapping
                                   (host owns PaywallCheckout UI + UpiService)
    app_update/                    Play in-app updates, iOS store alert, maintenance
    attribution/                   UTM + Play Install Referrer persistence
    analytics/                     Mixpanel + Firebase + Facebook
  features/                        Vertical slices
    auth/  notifications/  paywall/  home/  profile/  analytics/
  shared/widgets/                  Reusable UI
```

Dependency rule: **features → core → SDKs**. Features do not import other
features. Screens read BLoC via `context.read` / `BlocBuilder` and services via
`getIt<T>()`.

Identity vs secrets:

| Kind | Source | Ends up in |
| --- | --- | --- |
| App name, scheme, host, Android package | `project_config.yaml` → `./scripts/setup_project.sh` | `lib/config/app_identity.dart`, Android native files (iOS and App Links only if those values are set) |
| `API_BASE_URL`, Mixpanel token, `PAYMENTS_*`, `AUTH_*`, `TRUECALLER_CLIENT_ID` | `.env.dev` / `.env.prod` | `AppConfig` at process start; Truecaller also flavor `truecaller.xml` |

---

## 2. Process start (cold launch)

```
main_dev.dart / main_prod.dart
        │
        ├─ WidgetsFlutterBinding.ensureInitialized()
        ├─ AppConfig.initialize(Environment.dev|prod)     // dotenv
        │
        └─ main.dart
              ├─ FirebaseInitializer.initialize()         // flavor options
              ├─ Crashlytics + Remote Config + FCM bg handler  (if Firebase up)
              ├─ configureDependencies()                  // GetIt graph
              │     ├─ register every singleton
              │     ├─ eagerly create AuthCubit + GoRouter
              │     └─ PushNotificationService.start()
              ├─ GrowthBookService.initialize()           // unawaited; 6s cap
              └─ runApp(App)
                    ├─ MultiBlocProvider (cubits already in GetIt)
                    ├─ BlocListener<AuthCubit>  → analytics user + GB attrs + EntitlementCubit.apply
                    ├─ PushNotificationListener
                    ├─ _PendingEventsLifecycle  → profile refresh + drain on resume
                    ├─ _DeeplinkLifecycle       → DeeplinkController.start()
                    └─ _AppUpdateLifecycle      → config status + Play/App Store
                          └─ MaterialApp.router + MaintenanceGate
```

GoRouter’s first location is `/loading`. `AuthCubit` is already listening to
the session stream, so the splash is not waiting on DI.

---

## 3. How GetIt is wired

`configureDependencies()` in `lib/core/di/injection.dart` is the only place
that constructs the graph. Order matters: tokens and Dio first, then
repositories, then cubits, then router, then `DeeplinkController` (it needs
the router).

Eager create at the bottom:

```dart
getIt<AuthCubit>();                          // start watching session
getIt<GoRouter>();                           // attach redirect + refresh
getIt<PushNotificationService>().start();    // FCM, not navigation
```

`DeeplinkController.start()` is **not** here. It runs from `App` after the
widget tree exists so `router.go` has a navigator.

| Registered type | Implementation | Used for |
| --- | --- | --- |
| `AuthTokenStore` / `RestSession` | disk tokens + in-memory user | session |
| `AppApiClient` | Dio + refresh interceptor | shared HTTP client for Retrofit |
| `AuthApiService` / `EventsApiService` / … | Retrofit | auth uses `authDio` (`AUTH_*` or `API_BASE_URL`); others use app Dio |
| `CheckoutClient` | Capslock SDK + `CapslockHttpSender` | plans, checkout, billing cancel |
| `AuthRepository` | `AuthRemoteDataSourceImpl` | OTP + optional Truecaller |
| `TruecallerOAuthClient` | `TruecallerOAuthClientImpl` | Android Truecaller PKCE |
| `AnalyticsService` | Mixpanel + Firebase + Facebook | events |
| `PurchaseSuccessReporter` | pending purchase cache | `firstAddBalanceSuccess` + once-only `addBalanceSuccess` |
| `AttributionStore` | SharedPreferences | UTM |
| `GrowthBookService` | `growthbook_sdk_flutter` | experiments, force-update, attribution attrs |
| `DeeplinkResolver` | `POST /api/v1/deeplinks/resolve` | short links |
| `PlanRepository` | Capslock `getPlan` / `listPlans` | paywall catalog |
| `SubscriptionRepository` | Capslock `getUserSubscription` / `cancelSubscription` | Payment settings dates / cancel (not access) |
| `AuthCubit` | session `AsyncValue<User?>` + `refreshProfile` | router redirect |
| `EntitlementCubit` | profile + Capslock `validity_end_at` | access overlay + analytics |
| `PhoneAuthBloc` | OTP UI + Truecaller CTA | auth screen |
| `GoRouter` | `createAppRouter` | navigation |
| `DeeplinkController` | app_links + Play referrer | incoming URLs + GB attribution |
| `AppUpdateService` | RC + config API + GrowthBook `forceUpdate` + Play Core | store update / maintenance |

---

## 4. Auth and the splash gate

`AuthCubit` subscribes to `WatchAuthStateUseCase` → `AuthRemoteDataSourceImpl.authStateChanges()`.

That stream **must emit quickly** or the app stays on `/loading`:

1. Load JWT + cached user JSON from disk (`AuthTokenStore.load`).
2. Emit cached user or `null` immediately (`RestSession.restore`).
3. Refresh `GET /public/tenants/{tenant}/users/{userId}` (else `.../profile?phone=`) in the background.
4. If nothing arrives in 8 seconds, `AuthCubit` emits `AsyncData(null)`.

`GoRouterRefreshStream` listens to `AuthCubit.stream` and
`EntitlementCubit.stream` and re-runs `appRedirect`.

`appRedirect` (`lib/core/router/app_router.dart`):

```
auth still loading
  paywall/payment URI  → stash + stay on /loading   (do not fetch plans yet)
  other in-app route   → leave it
  else                 → /loading

not signed in
  stash payment/paywall deeplink if it has a plan, offer, or /payment
  → /auth

signed in
  entitlement still loading (first Capslock fetch)
    already inside app or on /paywall → stay
    else → /loading
  already on /paywall
    premium + source=init → /
    premium + source=renewal → /
    premium + source=renew → stay (cancelled Autopay re-checkout)
    else → stay (deeplink / Profile Plans)
  on /auth or /loading → PendingRoute.take()
                         ?? /paywall?source=init     (free, never purchased)
                         ?? /paywall?source=renewal  (free + has_purchased
                            or Capslock validity_end_at in the past)
                         ?? /
  other in-app route, not premium, not /payment-settings
                         → same gated paywall as above
```

Phone OTP is the default sign-in path: `AuthScreen` → `PhoneAuthBloc` →
`POST /public/tenants/{tenant}/otp/send` then `/otp/verify`. Tokens land in
`AuthTokenStore`; `RestSession` emits the user; `EntitlementCubit.refreshFor`
overlays Capslock; the router leaves `/auth` / `/loading` for Home or a gated
paywall.

### Truecaller (optional, Android)

Shown and auto-launched when `TRUECALLER_CLIENT_ID` is set **and** the platform is Android,
on the phone step (not OTP). Empty env → no button, no SDK, no auto-launch.
SDK unavailability / cancel is silent; the outlined CTA remains as a retry.

```
AuthScreen (phone step)
  → auto-launch once per visit (TruecallerAutoLaunchGuard)
      → PhoneAuthTruecallerRequested
          → TruecallerOAuthClient.authorize
               initializeSDK(OPTION_VERIFY_ONLY_TC_USERS)
               isOAuthFlowUsable?  else stay on OTP form (no banner)
               PKCE + getAuthorizationCode
               streamCallbackData success (state must match AppIdentity)
          → POST /public/tenants/{tenant}/truecaller/verify
               { authorization_code, code_verifier }
          → same persist path as OTP verify
          → AuthCubit → /home, /paywall?source=init, or stashed paywall
```

`TruecallerOAuthClientImpl` lives under `features/auth/data/`. Cancel the
OAuth stream when the bloc closes or the user hits Change number.

Analytics: `truecallerInitiated` → `truecallerProceed` → `otpVerified`, or
`truecallerFailed` (SDK not usable, user cancel, or API error).

---

## 5. Navigation (absolute paths only)

Routes in `createAppRouter`:

| Path | Screen |
| --- | --- |
| `/loading` | Splash |
| `/auth` | Phone OTP (+ Truecaller if configured) |
| `/` | Home |
| `/profile` | Profile |
| `/paywall` and `/paywall/:planId` | Paywall (`source=init` / `renewal` / deeplink) |
| `/payment-settings` | Cancel Autopay / Renew / one-time plan details |
| `/payment` | Redirects to `/paywall?…` |

Helpers: `RoutePaths.absolute`, `IncomingDeeplink.toAppLocation`. Relative
strings like `paywall` are rewritten to `/paywall` so go_router cannot nest
them under the current route (`/paywall/paywall`).

Flutter’s built-in deep linking is **off** (`flutter_deeplinking_enabled` /
`FlutterDeepLinkingEnabled`). Incoming URLs go through `app_links` →
`DeeplinkController`, not through GoRouter’s platform parser.

---

## 6. Deeplink + UTM + Play Install Referrer

Started from `_DeeplinkLifecycle.initState` → `DeeplinkController.start()`:

1. Hydrate `AttributionStore` from SharedPreferences.
2. **Play Install Referrer** (Android, first launch only): parse
   `utm_source`, `utm_medium`, `short_id`. If `short_id` exists,
   `POST /api/v1/deeplinks/resolve` then open the resolved URL.
3. Cold-start link: `app_links.getInitialLink()`.
4. Warm links: `uriLinkStream`.

Every handled URI:

1. Log `receivedDeeplink`.
2. Save UTM (`utm_source` / `utmSource`, `utm_medium` / `utmMedium`) and the
   full URL as the onboarding deeplink.
3. If the host is not this app’s scheme/host (HTTPS shortener), resolve to
   `original_url`.
4. Map to an in-app location and `router.go` it.

Payment mapping (`IncomingDeeplink`):

| Incoming | Becomes |
| --- | --- |
| `/payment?plan_price_id=yearly&offer_type=DISCOUNT` | `/paywall?planId=yearly&source=DEEPLINK&offerType=DISCOUNT` |
| `/payment` (no plan) | `/paywall?source=DEEPLINK` |
| `/paywall?planId=yearly` | same, plus `source=DEEPLINK` if stashed |
| `lbaType=…` | UTM saved, paywall **not** opened |

If the user is not logged in, `PendingRoute` holds that absolute `/paywall?…`
across `/auth`. After sign-in (OTP or Truecaller), `appRedirect` restores it.

On first authenticated session, `App`’s `BlocListener` calls
`AttributionStore.applyToAnalytics` (Mixpanel set-once for `utmSource` /
`utmMedium` / `onboardingDeeplink`), then `GrowthBookService.applyAttribution`
(`utmSource`, `utmMedium`, `ref`, `gclid`, `gbraid` as targeting attributes)
and `trackEnabledGrowthBookFeatures` (`isInit: true`).

---

## 7. Paywall plan selection and checkout

Home / Profile `push('/paywall')` or a restored deeplink builds
`PaywallScreen.fromRoute` → `PaywallPlanCubit.load`.

`ResolvePaywallPlanUseCase` picks **one** plan (not a picker):

1. Deeplink `planId` / `plan_price_id` if Capslock `getPlan` exists.
2. Else GrowthBook `paywall_plan_variant` when that feature is on.
3. Else Remote Config `paywall_plan_variant` (default `monthly`).
4. Else control `monthly`.
5. Else first catalog plan.

Load times out at 8 seconds. Close is hidden on gated `/paywall?source=init`
(first purchase) and expire `/paywall?source=renewal`; a Renew tap from
Payment settings (cancelled Autopay, still premium) pushes
`/paywall?source=renew` with the cancelled Capslock plan forced (no trial,
**Renew Now**) and can pop back. Premium users stay on that renew route to
checkout. Resume refreshes the auth profile and the router sends a lapsed
user (`free` + `has_purchased`) to `/paywall?source=renewal`.

On Android with `PAYMENTS_*` set and a signed-in user with a phone,
`PaywallCheckout` (host UI) lists UPI apps, calls `initiatePayment`, then
opens the app or a non-dismissible QR sheet. There is no Reset — Cancel
payment closes the sheet so the user can tap Continue again. After UPI
return a processing sheet stays open while the host listens to
`watchCheckoutStatus` (3s poll, 5 min timeout). Recurring success =
subscription `ACTIVE`; one-time = payment
`SUCCESS` / `COMPLETED`. Then `PaywallCheckoutCubit` flushes
`firstAddBalanceSuccess` (first checkout) + `addBalanceSuccess`
(`PurchaseSuccessReporter`), logs `checkoutVerified`,
flips the sheet to success, and only then refreshes the **auth profile**
(`User.entitlement`, `has_purchased`) and drains leftover backend rows.

Access is that profile payload overlaid with Capslock `validity_end_at`, not
Remote Config. After login the router waits for entitlement: premium → Home;
`free` + never purchased → `/paywall?source=init`;
`free` + `has_purchased` → `/paywall?source=renewal`.

Profile → Payment settings (`/payment-settings`) loads Capslock
`getUserSubscription` for dates. Recurring + still premium + Autopay on →
Cancel. Cancelled Autopay + still premium → Renew (`source=renew`, same
plan, full price, **Renew Now**). One-time has no Cancel / Renew; a missing
Capslock row must not drop access if the profile is still premium.

`offer_type=DISCOUNT|BONUS` is display + analytics only. Full sequence:
`PAYMENTS.md`.

---

## 8. App update and maintenance

`AppUpdateService` (GetIt) merges **Remote Config first**, then
`GET /api/v1/config/status` if that call succeeds, then GrowthBook
`forceUpdate` if that feature is on. Booleans are ORed: any source can set
`force_update`.

Remote Config keys (create in the Firebase console; see `STARTUP.md`):

| Key | Type | Default |
| --- | --- | --- |
| `force_update` | Boolean | `false` |
| `is_app_under_maintenance` | Boolean | `false` |
| `maintenance_title` | String | empty |
| `maintenance_message` | String | empty |

GrowthBook `forceUpdate` is a separate dashboard flag (same as Vokey). Empty
`GROWTHBOOK_API_KEY` disables GrowthBook; RC / API flags still apply.

The fetch is not on the splash critical path. Resume re-fetches Remote Config
(subject to the 1h production interval) and re-reads GrowthBook.

| Platform | Launch | Force (`force_update` **or** GB `forceUpdate`) |
| --- | --- | --- |
| Android | Play `in_app_update` only when force is on (immediate if allowed, else flexible). Deny retries a few times | Same prompt on resume |
| iOS | `UpgradeAlert` on home (App Store listing vs `pubspec` version) | `showLater` is hidden; `showIgnore` is always off |

Country for the App Store lookup is the device locale, not a hardcoded
storefront. Immediate Play success calls `exit(0)`.

`is_app_under_maintenance` replaces the navigator with `MaintenanceScreen`.

---

## 9. Analytics drain (Meta Purchase)

Do **not** fire Facebook Purchase from `checkoutVerified`. First checkout
also logs `firstAddBalanceSuccess` (Meta StartTrial / GA `start_trial`).
`addBalanceSuccess` is sent once by `PurchaseSuccessReporter` on stream success
(or premium resume). If the client never flushed, the backend queue is drained:

- on login (`App` listener)
- on resume (`_PendingEventsLifecycle`)
- after the success sheet (`PendingEventsService.onPaymentSucceeded()`)

A drain row whose `subscription_id` was already reported is marked done
without tracking again. Facebook maps `addBalanceSuccess` to Purchase and
`firstAddBalanceSuccess` to StartTrial.

Renewal events (`subscriptionRenewed`, `subscriptionRenewalFailed`,
`subscriptionRenewalNotified`) are queued by the backend on charge /
webhook. The app only tracks them here — never from checkout. Drain
`subscriptionRenewed` maps to Meta Subscribe / GA `renew_subscription`.

---

## 10. Notifications

`PushNotificationService.start()` (from DI) requests permission, syncs the
FCM token, and listens for taps. `PushNotificationListener` in `App` shows
foreground banners. Tap routing uses `RoutePaths.absolute` then `router.go`
so a payload of `paywall` becomes `/paywall`, not `/current/paywall`.

---

## 11. Feature slice shape (paywall as the example)

```
features/paywall/
  domain/     Plan, Entitlement, Subscription, repositories, use cases
  data/       Capslock PlanRemoteDataSourceImpl, SubscriptionRemoteDataSourceImpl
  presentation/
    bloc/paywall_plan_cubit.dart, paywall_checkout_cubit.dart, entitlement_cubit.dart
    screens/paywall_screen.dart, paywall_view.dart, payment_settings_screen.dart
    widgets/  one widget class per file (PaywallCheckout, PaywallCta, …)

features/auth/
  domain/     User, AuthRepository, TruecallerOAuthClient, use cases
  data/       AuthRemoteDataSourceImpl, TruecallerOAuthClientImpl, AuthApiService
  presentation/
    bloc/auth_cubit.dart, phone_auth_bloc.dart, sign_out_cubit.dart
    screens/auth_screen.dart
    widgets/  one widget class per file (AuthPhoneView, AuthOtpView, …)
```

Screen → Cubit → Use case → Repository → Capslock `CheckoutClient` (plans /
checkout) or Retrofit `ApiRoutes` (auth, events, deeplink, config). Failures
are `Either<Failure, T>` at the domain boundary.

To add a feature: domain + Freezed DTOs + Retrofit service + cubit, register
in `injection.dart`, add a `GoRoute` and a `RoutePaths` constant. Do not import
the new feature from `core/`.

---

## 12. First-run checklist vs “stuck” screens

| You see | Usual cause |
| --- | --- |
| `/loading` forever | Auth stream never emitted (fixed: disk hydrate + 8s timeout) |
| Spinner on paywall | Capslock plans unreachable or `PAYMENTS_*` empty; after 8s you get retry + Close |
| Bounce back to paywall after login | Real `/payment` or `planId` deeplink was stashed (intended) |
| OTP fails | `.env` `AUTH_BASE_URL` / `AUTH_TENANT_ID` still empty or a placeholder |
| No Truecaller button | Empty `TRUECALLER_CLIENT_ID`, not Android, or already on the OTP step |

Checkout, unique store IDs, and real Mixpanel / Facebook / Firebase /
Capslock tenant values are still project setup — not this runtime graph.
