# Gertrude iOS

## Local dev

Create a `.xcconfig` file at `iosapp/config/Local.xcconfig` with the following content:

```xcconfig
LOCAL_API_URL = https:/$()/maybe-your-ngrok-url.com
```

## Release notes

- `1.0.0` (10/23/24)
  - initial release
- `1.1.0` (10/31/24)
  - fix dark mode
  - clarify 2 steps to auth/install
- `1.3.0` (3/6/25)
  - totally revamped/expanded onboarding
  - opt-out groups
  - clear cache after install
- `1.3.1` (3/14/25)
  - add recovery mode, various failsafes for app deletion
  - fix animation of running screen link

## Screenshots for release

Currently, we have just the bare minimum, 2 sizes of screenshots:

- 1290×2796 for iPhone (use simulator iPhone 16 Plus)
- 2048×2732 for iPad (use simulator iPad Air 13 inch M2)
