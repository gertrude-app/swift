# Gertrude iOS

## Local dev

Create a `.xcconfig` file at `iosapp/config/Local.xcconfig` with the following content, or
use `just iosconfig` to create it automatically:

```xcconfig
LOCAL_API_URL = https:/$()/REPLACE.ngrok-free.app
```

## Release notes

- `1.4.3` (testflight) (11/20/25)
  - final testflight before 1.5.0 public release
- `1.4.2` (testflight) (9/4/25)
  - fix handling of app launch w/ connected account
- `1.4.1` (testflight) (8/28/25)
  - added more logging to troubleshoot managed settings
- `1.4.0` (testflight) (8/19/25)
  - connect to account
- `1.3.1` (3/14/25)
  - add recovery mode, various failsafes for app deletion
  - fix animation of running screen link
- `1.3.0` (3/6/25)
  - totally revamped/expanded onboarding
  - opt-out groups
  - clear cache after install
- `1.1.0` (10/31/24)
  - fix dark mode
  - clarify 2 steps to auth/install
- `1.0.0` (10/23/24)
  - initial release

## Screenshots for release

Currently, we have just the bare minimum, 2 sizes of screenshots:

- 1290×2796 for iPhone (use simulator iPhone 16 Plus)
- 2048×2732 for iPad (use simulator iPad Air 13 inch M2)
