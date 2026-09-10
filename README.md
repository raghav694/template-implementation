# Flutter App Template

Reusable Flutter application foundation extracted from production architecture (Clean Architecture, BLoC, GetIt, go_router, Dio + Retrofit, Firebase, Mixpanel).

Create a GitHub repository from this template, run setup, then `./scripts/setup_firebase.sh`.

Payment checkout uses Capslock Payments (UPI Autopay and one-time on Android). Access (`entitlement`, `has_purchased`) comes from the auth profile, not Remote Config. See [PAYMENTS.md](PAYMENTS.md). Auth is Phone OTP, plus optional Android Truecaller when `TRUECALLER_CLIENT_ID` is set.

## Create a project from this template

1. On GitHub: **Use this template** → create a new repository.
2. Clone the new repository.
3. Run setup:

```bash
./scripts/setup_project.sh
```

The script asks for app name, Android package, API URLs, and **required** Firebase project IDs, then writes them into Android, Dart, and `.env` files from `project_config.yaml`. iOS bundle ID and deep-link scheme/host are optional — press Enter to skip (same as leaving `__IOS_BUNDLE_ID__` / `__APP_SCHEME__` / `__DEEPLINK_HOST__`).

You can create new Firebase projects or point at existing ones. `./scripts/setup_firebase.sh` uses those IDs (and creates the projects if you asked it to).

Optional branding (logo, colors, text font — every field is skippable):

```bash
./scripts/setup_theme.sh
```

Create the Dev and Prod Firebase apps and write `google-services.json` / `firebase_options_*.dart` (needs `firebase login --reauth` if the token is stale). Uses the project IDs from setup; creates them only if you chose that. A rerun after a partial create attaches the existing GCP project instead of demanding a new ID:

```bash
./scripts/setup_firebase.sh
```

4. Validate:

```bash
./scripts/validate_config.sh
```

## Run Dev and Prod

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs

flutter run --flavor dev -t lib/main_dev.dart
flutter run --flavor prod -t lib/main_prod.dart
```

VS Code / Cursor launch configs are in `.vscode/launch.json`.

## Build a Play Store bundle

Prod builds refuse to ship unless `.env.prod` `API_BASE_URL` matches the Production API URL from `./scripts/setup_project.sh` (`project_config.yaml` → `environment.prod.api_base_url`).

```bash
./b.sh prod
./b.sh dev
./b.sh prod my-custom-bundle
```

## Slack APK

Builds a flavor APK and uploads it. Token and channel come from `SLACK_API_TOKEN` + `SLACK_CHANNEL_ID` in `.env.dev` / `.env.prod` (same keys as Vokey), then `.slack.env`, then the shell. The APK filename uses `app.name` from `project_config.yaml` (`{slug}-DEV-{version}.apk`), not a hardcoded product name. The Slack comment and file title always include `git config user.name`.

```bash
# fill SLACK_API_TOKEN + SLACK_CHANNEL_ID in .env.dev / .env.prod
./s.sh dev
./s.sh prod
./s.sh dev "QA please smoke this"
```

Merging a **`dev` → `main`** PR creates a GitHub Release tagged `v{version}` from `pubspec.yaml` (see `.github/workflows/auto-release.yml`). Bump `version:` before that merge. Same-repo `dev` only — fork PRs do not release.

## Project structure

```
project_config.yaml          # App identity (not secrets)
lib/
  config/                    # Identity + environment + flavor metadata
  core/                      # Reusable infrastructure (deeplink, app update, analytics)
  features/                  # Auth, notifications, paywall plans, home, profile
  shared/                    # Shared widgets
  main_dev.dart / main_prod.dart
scripts/                     # setup_project.sh, setup_theme.sh, setup_firebase.sh, validate_config.sh
b.sh                         # flavor AAB; prod URL must match setup
s.sh                         # flavor APK → Slack (git user in the message)
android/app/src/dev|prod/    # Flavor google-services.json
ios/config/dev|prod/         # Flavor GoogleService-Info.plist
```

Secrets (Mixpanel tokens, Capslock Payments, Truecaller client id) live in gitignored `.env.dev` / `.env.prod`.

## Docs

- [STARTUP.md](STARTUP.md) — new-project checklist (Firebase required; iOS, deep links, and branding optional)
- [PAYMENTS.md](PAYMENTS.md) — Capslock checkout + billing; profile `entitlement` for access; cancel / renew / expire / one-time
- [ARCHITECTURE.md](ARCHITECTURE.md) — architecture, modules, how to extend (includes OTP + Truecaller)
- [CODEWALKTHROUGH.md](CODEWALKTHROUGH.md) — runtime map (splash, auth, paywall, deeplinks)
- [PLAN.md](PLAN.md) — working plan / remaining follow-ups
