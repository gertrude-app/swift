# Gertrude

## Release notes

- `1.1.0` (1/17/23) pairql/monorepo refactor, no real new features, but ripped out api
  layer, and modules changed

## Sparkle Releases

- Increment build numbers in _BOTH_ `Info.plist`s
- create an archive, and notarize it
- export notarized app into `~/gertie/app-updates`
- cd into `/gertie/release`
- run `run release X.Y.Z stable`, setting real semver and channel (stable|beta|canary)

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
