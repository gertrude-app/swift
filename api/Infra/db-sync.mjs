/* eslint-disable */
// @ts-check

import { gray, green, magenta, red } from 'x-chalk';
import xExec from 'x-exec';

// @ts-ignore
const exec = xExec.default;

if (!exec.success(`ls /Users/$USER`)) {
  red(`ERROR! db:sync may only be run from local dev machine!\n`);
  process.exit(1);
}

magenta(`\nStarting db sync process\n`);
exec.exit(`rm -f ./sync.sql.gz ./sync.sql`);
gray(`  • Dumping remote database...`);
// -Z 9 enables maximum compression for pg_dump
exec.exit(`ssh gapi "pg_dump gertrude --file sync.sql.gz -Z 9"`);
gray(`  • Downloading gzipped dump...`);
exec.exit(`scp gapi:~/sync.sql.gz .`);
gray(`  • Deleting remote dump file...`);
exec.exit(`ssh gapi "rm sync.sql.gz"`);
gray(`  • Unzipping local dump file...`);
exec.exit(`gunzip ./sync.sql.gz`);
gray(`  • Killing any running instances of Postico...`);
exec(`killall Postico`);
gray(`  • Dropping and re-creating local gertrude_sync database...`);
exec.exit(`dropdb gertrude_sync`);
exec.exit(`createdb gertrude_sync`);
gray(`  • Importing records...`);
exec.exit(`psql -d gertrude_sync -f ./sync.sql`);
gray(`  • Cleaning up...`);
exec.exit(`rm -f ./sync.sql.gz ./sync.sql`);
green(`\nSync complete!\n`);
