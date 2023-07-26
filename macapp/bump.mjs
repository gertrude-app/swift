/* eslint-disable */
// @ts-check
import fs from 'node:fs';
import semver from 'semver';
import { c, log } from 'x-chalk';

const plistPaths = [
  `macapp/Xcode/Gertrude/Info.plist`,
  `macapp/Xcode/GertrudeFilterExtension/Info.plist`,
];

const plistContents = plistPaths.map((path) => fs.readFileSync(path, 'utf8'));

const current = plistContents[0].match(
  /CFBundleVersion<\/key>\n\s*<string>(.*?)<\/string>/,
)[1];

if (!semver.valid(current)) {
  abort(`Invalid current version: ${current}`);
}

const nextVersion = next(current);
if (!semver.valid(nextVersion)) {
  abort(`Invalid next version: ${nextVersion}`);
}

// replace current with next for both paths
plistContents.forEach((content, i) => {
  const nextContent = content.replace(
    /(CFBundleVersion|CFBundleShortVersionString)<\/key>\n\s*<string>.*?<\/string>/g,
    `$1</key>\n    <string>${nextVersion}</string>`,
  );
  fs.writeFileSync(plistPaths[i], nextContent);
});

log(c`\nSet {cyan Info.plist} versions to {green.bold ${nextVersion}}.\n`);

function next(current) {
  const input = process.argv[2];
  let nextVersion = '';
  if (
    [
      'major',
      'minor',
      'patch',
      'premajor',
      'preminor',
      'prepatch',
      'prerelease',
    ].includes(input)
  ) {
    return semver.inc(current, /** @type {any} */ (input));
  } else {
    return input;
  }
}

function abort(message) {
  log(c`\n{red.bold ${message}}\n`);
  process.exit(1);
}
