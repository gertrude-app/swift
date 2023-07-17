# Gertrude

## Release notes

- `1.1.0` (1/17/23) pairql/monorepo refactor, no real new features, but ripped out api
  layer, and modules changed
- `1.1.1` (2/8/23) new app icon and menu bar icon only

## Sparkle Releases

- Increment build numbers in _BOTH_ `Info.plist`s
- create an archive, and notarize it
- export notarized app into `~/gertie/app-updates`
- cd into `/gertie/release`
- run `run release X.Y.Z stable`, setting real semver and channel (stable|beta|canary)
- remember to add it to **Release notes** above ^^^

## Dmg woes...

- runing `run dmg` fouls up the signature somehow, instead:
- after exporting the notarized app, run it through the `DropDMG` app
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
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -dump | grep .*path.*ertrude
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

I was able to find out what those hex codes meant, by following these steps:

1. locate the `.crash` report file by right-clicking crash within Console.app
2. put the `.crash` file into a new folder
3. in Xcode organizer, i clicked "Show in Finder" on the archive of the app version that
   crashed, then, I right-clicked and chose "Show contents" on the `.xcarchive` file so I
   could look inside.
4. I _copied_ the filter extension executable (the crash was in the filter, not the app),
   which was called `com.netrivet.gertrude.filter-extension.systemextension` (located in
   some subdir), into the empty folder i created in step 2.
5. Next I also _copied_ the `com.netrivet.gertrude.filter-extension.systemextension.dSYM`
   debug symbols into the empty folder. (You have to have "Dwarf + DYSM" enabled in Xcode,
   but it already was, and that shouldn't change)
6. Once I had those three files, I opened a terminal session in the folder and ran this
   basic command for each line (note that the two hex codes are switched, shorter first):

```sh
atos -o com.netrivet.gertrude.filter-extension.systemextension.dSYM/Contents/Resources/DWARF/com.netrivet.gertrude.filter-extension -l 0x10db02000 0x000000010db073cc
```