# Gertrude

## Release notes

- `1.1.0` (1/17/23) pairql/monorepo refactor, no real new features, but ripped out api
  layer, and modules changed
- `1.1.1` (2/8/23) new app icon and menu bar icon only
- `2.0.0` (7/20/23) TCA rewrite
- `2.0.1` (7/24/23)
  - health check screen instructs to reboot computer on filter comm repair fail
  - filter shouldn't cache app descriptors with empty bundle id
- `2.0.2` (7/26/23)
  - attempt to fix post auto-update xpc comm connection
  - fix duplicate keystroke logging
  - fix update being triggered on admin window open
- `2.0.3` (8/3/23)
  - first _stable_ 2.x release
  - @see: https://github.com/gertrude-app/swift/pull/33
  - menu bar returns to initial state after connect fail
  - admin window health check keeps throbbing filter status during communication repair
  - fix webview focus bug
  - remove suspend filter from admin window, add button to suspend filter window
  - rework suspend filter flow, starting with choose duration
- `2.0.4` (8/24/23)
  - health check new default admin screen w/ redesigned "actions" screen
  - disable "view network requests" and "suspend filter" menu bar btns when filter off
  - "view network requests" and "suspend filter" screens warn if filter connection broken
  - remove release channel from app admin window, controlled by parents website
  - add browsers for force quit (including brave and arc)
  - fix flash of light theme when loading app windows in dark mode
  - fixed long blocked urls in catalina
  - fixed app window scrollbars in dark mode
- `2.0.5` (9/6/23)
  - fixed domains resolved from outbound bytes not showing up in blocked requests window
  - fixed double browser quit from computer sleep during filter suspension
- `2.1.0` (10/21/23 as `beta` for new customers)
  - onboarding
  - fixed adminstrate button on request suspension screen filter not connected state
- `2.1.1` (11/1/23)
  - fix parsing of multi-part domains from outbound flow #caf5ded
  - onboading improvements: skip user type if good, allow relaunch on early bail, align
    window right, prevent sys ext install timeout wonkiness
  - fix request suspension double-submit
- `2.1.2` (12/18/23 as `beta` for new customers only)
  - log filter state at beginning of block streaming for debugging/troubleshooting
  - prevent proliferation of sparkle windows
  - stop onboarding early if app launched from wrong dir
  - add onboarding user exemption screen
  - improve user exemption to not include other protected users
  - prevent integer overflow causing json decode in request suspension window
- `2.1.3` (1/16/24 as `beta` for new customers only)
  - multi-stage gifs for onboarding instructions
  - new "how to use gifs" & "don't fall for trick" onboarding screens
- `2.2.0` (released only in canary for testing)
  - app watches and relaunches self on unexpected termination
  - relaunches app if filter gets ahead
  - use updateable api data for browser identification
- `2.3.0` (canary as of 6/13/24)
  - feature: security events
- `2.3.1` (canary as of 6/19/24)
  - refinement, filter suspension security details suspension duration
  - refinement, remove .appUpdateInitiated event, noisy and not useful

## Sparkle Releases

- Increment build numbers in _BOTH_ `Info.plist`s
- create an archive, and notarize it
- export notarized app into `~/gertie/app-updates`
- cd into `/gertie/release`
- run `run release X.Y.Z stable`, setting real semver and channel (stable|beta|canary)
- remember to add it to **Release notes** above ^^^

## Dmg woes...

- runing `run dmg` fouls up the signature somehow, instead:
- after exporting the notarized app, run it through the `DropDMG` app by opening the app
  and choosing `File` -> `New from Folder/File...` and pointing it at the new app
- once it makes the `.dmg` file, double check it by opening the dmg (so the disk is
  _mounted_), and then run:

```sh
spctl -a -t open --context context:primary-signature -v /Volumes/Gertrude/Gertrude.app
```

- probably worth doublechecking by actually installing it as well...

## LaunchAtLogin

- On the machine I'm developing on, Launch at login gets confused and pulls up random old
  builds that are lying around various places on the filesystem, which can be a problem
  for testing, or for using the computer to protect a child. To fix this, figure out where
  all of the copies are by running this command:

```bash
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -dump | grep ".*path.*ertrude"
```

- Then, `sudo rm -rf` all of those to get to a clean slate.

- _Then_, reset the LaunchServices database with:

```
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user
```

- See
  [here for more info](https://www.electrollama.net/blog/2017/4/7/login-items-in-macos-1011-and-newer)

## how to symbolicate a crash report

When investigating a crash of the filter, i was looking at stack trace lines like this:

```
10  com.myorg.app.filter-extension	0x000000010db2c5e3 0x10db02000 + 173539
11  com.myorg.app.filter-extension	0x000000010dbbd708 0x10db02000 + 767752
12  com.myorg.app.filter-extension	0x000000010db073cc 0x10db02000 + 21452
```

1. locate the `.crash` report file by right-clicking crash within Console.app
2. put the `.crash` file into a new folder
3. in Xcode organizer, i clicked "Show in Finder" on the archive of the app version that
   crashed, then, I right-clicked and chose "Show contents" on the `.xcarchive` file so I
   could look inside.

### for crash in FILTER

4. I _copied_ the filter extension executable (the crash was in the filter, not the app),
   which was called `com.netrivet.gertrude.filter-extension.systemextension` (located in
   some subdir), into the empty folder i created in step 2.
5. Next I also _copied_ the `com.netrivet.gertrude.filter-extension.systemextension.dSYM`
   debug symbols into the empty folder. (You have to have "Dwarf + DYSM" enabled in Xcode,
   but it already was, and that shouldn't change)
6. Once I had those three files, I opened a terminal session in the folder and ran this
   basic command for each line (note that the two hex codes are switched, shorter first):

_NB: the `atos` command needs to be run ON the computer (or at least OS + arch???) where
the crash happened, or you will get spurious results_

```sh
atos -o com.netrivet.gertrude.filter-extension.systemextension.dSYM/Contents/Resources/DWARF/com.netrivet.gertrude.filter-extension -l 0x10db02000 0x000000010db073cc
```

### for crash in APP

4. I _copied_ the app executable (if the crash was in the app, not the filter), which was
   called `Gertrude` (located in `Products/Applications/Gertrude.app/Contents/MacOS`--you
   need to expand the inner `Gertrude.app` package contents as wll), into the empty folder
   i created in step 2.
5. Next I also _copied_ the `dSYMs/Gertrude.app.dYSM` debug symbols into the empty folder.
   (You have to have "Dwarf + DYSM" enabled in Xcode, but it already was, and that
   shouldn't change)
6. Once I had those three files, I opened a terminal session in the folder and ran this
   basic command for each line (note that the two hex codes are switched, shorter first):

_NB: the `atos` command needs to be run ON the computer (or at least OS + arch???) where
the crash happened, or you will get spurious results_

```sh
atos -o Gertrude.app.dSYM/Contents/Resources/DWARF/Gertrude -l 0x10db02000 0x000000010db073cc
```
