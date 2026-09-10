# Payments

Capslock Payments owns the catalog, checkout, Autopay, one-time charges, and
**billing** status (dates, cancel). The app never talks to Cashfree or PhonePe
directly; the tenant on the Capslock server chooses the gateway. The client
only shows `provider` after the fact (payment settings).

**Access (are they Pro?) is not Capslock and not Remote Config.** It is the
auth user payload: `GET /public/tenants/{tenant}/users/{userId}` (else
`.../profile?phone=`) and OTP / Truecaller verify `entitlement` plus
`has_purchased`. Same split as Shanti Club
(`is_subscribed` / `has_purchased` on `/auth/me`).

Do **not** change `StudioProjects/vokey` or `StudioProjects/capslock-payments`.
This template depends on the Flutter SDK as a path package:

```yaml
capslock_payments_sdk:
  path: ../capslock-payments/sdks/flutter
```

UPI checkout in this template is **Android-only**. Empty
`PAYMENTS_BASE_URL` / `PAYMENTS_TENANT_ID` leaves the paywall visible with a
disabled CTA.

The full flow is also summarized in `ARCHITECTURE.md` and `CODEWALKTHROUGH.md`.

## Environment

Gitignored `.env.dev` / `.env.prod` (see `.env.*.example`):

| Key | Role |
| --- | --- |
| `PAYMENTS_BASE_URL` | Capslock origin only (no path, trailing slash stripped) |
| `PAYMENTS_TENANT_ID` | Tenant id on every Capslock call |

`AppConfig.hasPaymentsConfig` is true only when **both** are non-empty.
`./scripts/setup_project.sh` rewrites `.env.*` for API / Mixpanel / region but
**keeps** existing `PAYMENTS_*` values.

Capslock HTTP does **not** send the app JWT. `CapslockHttpSender` is a separate
Dio instance from `AppApiClient`.

## Layers

```
PaywallScreen / PaymentSettingsScreen
  → PaywallCheckout (UPI picker + QR) / PaywallPlanCubit / …
      → ResolvePaywallPlanUseCase / GetSubscription / Cancel
          → Auth profile `entitlement` (access) + PlanRepository / SubscriptionRepository
              → PlanRemoteDataSourceImpl / SubscriptionRemoteDataSourceImpl
                  → CheckoutClient (Capslock SDK)
                      → HttpCheckoutTransport + CapslockHttpSender
                          → GET/POST /v1/tenants/{tenant}/…
                      → UpiService.getAvailablePaymentsAppsInfo / openUpiApp
```

`PaywallCheckout` (host UI) is the only widget that calls `initiatePayment`.
Capslock SDK supplies `UpiService`, checkout links, and
`watchCheckoutStatus` — it no longer ships a `PaymentWidget`.

## End-to-end flow

```
Deeplink /payment|/paywall  or  Profile → Plans
        │
        ▼
PaywallScreen.fromRoute
        │
        ▼
PaywallPlanCubit.load(deeplinkPlanId, source)
        │
        ▼
ResolvePaywallPlanUseCase  (deeplink id ?? GrowthBook ?? RC variant)
  1. Deeplink plan id → CheckoutClient.getPlan
       GET /v1/tenants/{tenant}/plans/{planId}
  2. Else GrowthBook `paywall_plan_variant` when that feature is on → getPlan
  3. Else Remote Config paywall_plan_variant → getPlan
  4. Else control plan `monthly` → getPlan
  5. Else listPlans, first catalog row
        │
        ▼
PlanPricingCard + PaywallCheckout  (Android, signed-in, phone present)
        │
        ▼
User picks a UPI app (or QR if none installed) and taps Continue
  PaywallCheckoutCubit.onPayStarted
    analytics: paywallCtaTapped, addBalanceInitiated
      properties: trialAmount, subscriptionAmount, mediaURL, planFrequency,
                  paymentApps, paymentMethod (`link` / `qrcode`),
                  selectedPackageName (intent only)
        │
        ▼
PaywallCheckout → CheckoutClient.initiatePayment
  POST /v1/tenants/{tenant}/payments
  Body includes customer.externalId = auth user id, planId, deviceOs
  Do not send payment_method or provider — Capslock picks the gateway
  Response.type  RECURRING | ONE_TIME  (from the plan, not the app)
        │
        ├─ UPI app installed → UpiService.openUpiApp (PhonePe / GPay / Paytm / BHIM)
        │                      processing sheet, then host watchCheckoutStatus
        └─ none installed    → non-dismissible QR sheet from UpiService.qrPayload
        │                      Cancel payment closes the sheet (no Reset)
        │                      widget watches status until success / expiry
        │
        ▼
CheckoutClient.watchCheckoutStatus  (poll every 3s, 5 min timeout)
  Recurring: GET /v1/tenants/{tenant}/subscriptions/{subscriptionId}
             success = ACTIVE
  One-time:  GET /v1/tenants/{tenant}/payments/{paymentId}
             success = SUCCESS | COMPLETED
  PENDING events are ignored (not entitled)
        │
        ├─ success → PaywallCheckoutCubit.onPaySuccess
        │              PurchaseSuccessReporter.flushOnStreamSuccess
        │                addBalanceSuccess once (paymentId fallback chain)
        │              analytics: checkoutVerified
        │              processing sheet → success
        │              then refresh auth profile (entitlement / has_purchased)
        │              then pending drain
        │              then router.go(home)
        │
        └─ failure / timeout → PaymentFailure sheet; widget remounts
```

Heimdall `GET /api/v1/plans` is **not** used. `PlanApiService` remains in the
tree unused.

`toDomainPlan` maps Capslock `Plan.type` (`RECURRING` / `ONE_TIME`) plus
interval, trial (`hasTrial`, `trialDuration`, `authorizationAmountMinor`),
and metadata (`label`, `original_price_inr`, `video_url`) onto the domain
`Plan`. The paywall prices the trial amount when present.

### Status vocabulary (Capslock billing row)

Capslock statuses are mapped in `PaymentsConfig` for **Payment settings**
(plan dates, cancel vs renew). They do **not** grant access.

| Capslock | App | Meaning on settings |
| --- | --- | --- |
| `ACTIVE` | `active` | Autopay on; show Cancel |
| `PAST_DUE` | `past_due` | Mandate retrying; still show Cancel |
| `PENDING` | `initiated` | Mandate not confirmed |
| `CANCELED` / `CANCELLED` | `canceled` | Autopay off; show Renew if profile is no longer premium |

If the user backs out of GPay, Capslock often stays `PENDING` until timeout.
The mandate can still activate later via webhook. Access updates when
the auth profile returns the new `entitlement`.

## Entitlement (access) — profile + Capslock validity end

| Concern | Source | Not |
| --- | --- | --- |
| Are they Pro? | Auth profile `entitlement`, then Capslock `validity_end_at` (`Subscription.isActive`) | Remote Config |
| Paid before? | Profile `has_purchased`, or any Capslock billing row | Inferring from UI |
| Which plan to sell? | Deeplink plan id, else GrowthBook `paywall_plan_variant`, else Remote Config | Access |
| Cancel / valid-until / gateway | Capslock `getUserSubscription` | Access grant |

`User.entitlement` is parsed on OTP / Truecaller / profile. Non-`free` means
entitled unless `validity_end_at` / `expires_at` is in the past. After login,
checkout, and resume, `EntitlementCubit.refreshFor` waits for Capslock
`validity_end_at` (same cutoff as Vokey) before leaving `/loading`. A past
end date sends the user to `/paywall?source=renewal` even if profile still
says `premium`. Cancelled Autopay with a future end stays premium. If
payments are not configured or the Capslock call fails / has no row, profile
access is kept.

### After login (profile gating)

| Profile | Where they go |
| --- | --- |
| `entitlement` is premium | Home |
| `free` and `has_purchased` is false | `/paywall?source=init` (non-dismissible) |
| `free` and `has_purchased` is true | `/paywall?source=renewal` |

No Remote Config flag for this. Free-to-play products keep sending
`entitlement: premium` (or drop the redirect). There is no Voice Club HTTP
410 interceptor; `_PendingEventsLifecycle` on resume calls
`AuthCubit.refreshProfile` and `appRedirect` sends a lapsed user to
`/paywall?source=renewal`. `source=init` cannot dismiss; expire/renewal from
the router cannot either. Renew from Payment settings uses `push` so it can
pop.

`appRedirect` is the shared guard (`User.isPremium` / `hasPurchased`), not
Capslock and not a per-feature widget.

`addBalanceSuccess` is sent **once**. The client caches a pending purchase on
Continue, attaches checkout ids on `initiatePayment`, and flushes on stream
success (`firstAddBalanceSuccess` then `addBalanceSuccess` when the cached
entitlement was free). If the app dies during UPI and the webhook finishes first, login /
resume (after profile is premium) call `flushOnPremiumResume`. The Heimdall
pending drain skips a row whose `subscription_id` was already reported so
Meta Purchase is not double-counted.

Profile is refreshed **after** the success sheet closes so the confirmation
stays on screen. Back is blocked while checkout is in flight; returning from
UPI without a callback unlocks the screen.

## Cancel, silent renew, expire, one-time

### Cancel Autopay

Profile → **Payment settings** (`/payment-settings`):

1. Profile `entitlement` for the access badge
2. `GetSubscriptionUseCase` → Capslock `getUserSubscription` for dates / status
3. Recurring + still premium + Autopay on → **Cancel subscription** confirm sheet
4. `CancelSubscriptionUseCase` → `POST …/subscriptions/{id}/cancel`
5. Log `subscriptionCancel` (plan amounts, `subscriptionCount`, `source`)
6. Refresh profile (backend may keep `entitlement: premium` until period end)
7. Stay on settings and reload — do not jump to Home
8. Status `canceled` + still premium → **Renew subscription**

Copy: Autopay stops; access lasts until Capslock `validity_end_at`.

### Silent Autopay renewal

No client renewal RPC. Capslock / the gateway charge the mandate. The app
notices on the next auth profile refresh (`entitlement` stays `premium`,
`valid until` moves).

Manual **Renew subscription** (Payment settings) is Vokey’s cancelled-but-still-
premium path: Autopay is off, `validity_end_at` is still in the future. It
opens `/paywall?source=renew` with that Capslock plan forced (full price,
no trial), CTA **Renew Now**. Premium users stay on that route to checkout.

### Expired

Backend flips profile `entitlement` to `free` and keeps `has_purchased: true`.
Resume / next API-driven profile refresh sends them to
`/paywall?source=renewal` (**Unlock** / first-purchase-style paywall, not the
settings Renew button). Do not listen for HTTP 410 unless Heimdall
documents it.

### One-time / lifetime

Same host checkout. `watchCheckoutStatus` polls the payment. After success,
refresh profile (`entitlement: premium`, `has_purchased: true`). Capslock may
have no subscription row — that must not drop access if profile is premium.
Settings: no Cancel / Renew for one-time.

## What the host must not do

- Pick Cashfree vs PhonePe in Dart (`provider` is informational)
- Send `payment_method` on initiate unless a product explicitly overrides it
- Call Dio against Capslock except through `CapslockHttpSender`
- Poll `getSubscriptionStatus` / `getPaymentStatus` outside the SDK watch
- Use checkout UI on iOS / web (CTA shows a hint instead)
- Derive access from Remote Config or from Capslock `CANCELED` + `nextBillingAt`
- Skip the auth profile refresh after checkout / cancel / resume and trust Capslock for Pro
- Add a Remote Config `require_subscription` (or similar) kill switch for access
- Depend on SDK `PaymentWidget` — that widget was removed; the host owns picker + QR

The SDK README currently recommends Autopay over PhonePe **one-time** (PhonePe
one-time may return only an HTTPS redirect). This template still maps
`one_time` / `lifetime` intervals onto `PlanCategory.oneTime` and uses the
same host checkout UI.

## Android UPI visibility

`android/app/src/main/AndroidManifest.xml` `<queries>` includes `upi` plus
PhonePe, GPay, Paytm, and BHIM package names so the SDK can list installed
apps. The Flutter plugin also merges queries; keeping them in the app
manifest matches the Vokey host setup.
