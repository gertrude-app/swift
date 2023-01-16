/* eslint-disable */
import { c, log, red } from 'x-chalk';
import exec from 'x-exec';
import { spawnSync } from 'child_process';
import env from '@friends-library/env';

const ENV: 'production' | 'staging' = process.argv.includes(`--production`)
  ? `production`
  : `staging`;

env.load(`../.env.${ENV}`);

const { HOST, MONOREPO_DIR, REPO_URL, PORT_START } = env.require(
  `HOST`,
  `MONOREPO_DIR`,
  `REPO_URL`,
  `PORT_START`,
);

const NGINX_CONFIG = `/etc/nginx/sites-available/default`;
const API_DIR = `${MONOREPO_DIR}/api`;
const BUILD_CMD = ENV === `staging` ? `swift build` : `swift build -c release`;
const BUILD_DIR = ENV === `staging` ? `debug` : `release`;
const VAPOR_RUN = `.build/${BUILD_DIR}/Run`;
const PREV_PORT = getCurrentPort();
const NEXT_PORT = `${PREV_PORT}`.endsWith(`0`) ? PREV_PORT + 1 : PREV_PORT - 1;
const PM2_PREV_NAME = `${ENV}_${PREV_PORT}`;
const PM2_NEXT_NAME = `${ENV}_${NEXT_PORT}`;
const SERVE_CMD = `${VAPOR_RUN} serve --port ${NEXT_PORT} --env ${ENV}`;

exec.exit(`ssh ${HOST} "mkdir -p ${MONOREPO_DIR}"`);

log(c`{green git:} {gray ensuring {cyan monorepo} exists at} {magenta ${MONOREPO_DIR}}`);
inMonorepoDir(`test -d .git || git clone ${REPO_URL} .`);

log(c`{green git:} {gray updating {cyan monorepo} at} {magenta ${MONOREPO_DIR}}`);
inMonorepoDir(`git reset --hard HEAD`);
inMonorepoDir(`git pull origin master`);

log(c`{green env:} {gray copying .env file to} {magenta ${API_DIR}}`);
exec.exit(`scp ./.env.${ENV} ${HOST}:${API_DIR}/.env`);

log(c`{green swift:} {gray building vapor app with command} {magenta ${BUILD_CMD}}`);
inApiDirWithOutput(BUILD_CMD);

log(c`{green vapor:} {gray running migrations}`);
inApiDirWithOutput(`${VAPOR_RUN} migrate --yes`);

// if (ENV === `staging`) {
//   log(c`{green test:} {gray running tests}`);
//   if (!inApiDirWithOutput(`npm run test`)) {
//     red(`Tests failed, halting deploy.\n`);
//     process.exit(1);
//   }
// }

log(c`{green pm2:} {gray setting serve script for pm2} {magenta ${SERVE_CMD}}`);
inApiDir(`echo \\"#!/usr/bin/bash\\" > ./serve.sh`);
inApiDir(`echo \\"${SERVE_CMD}\\" >> ./serve.sh`);

log(c`{green pm2:} {gray starting pm2 app} {magenta ${PM2_NEXT_NAME}}`);
inApiDir(`pm2 start ./serve.sh --name ${PM2_NEXT_NAME}`);

log(c`{green nginx:} {gray changing port in nginx config to} {magenta ${NEXT_PORT}}`);
inApiDir(`sudo sed -E -i 's/:${PORT_START}./:${NEXT_PORT}/' ${NGINX_CONFIG}`);

log(c`{green nginx:} {gray restarting nginx}`);
exec.exit(`ssh ${HOST} "sudo systemctl reload nginx"`);

log(c`{green pm2:} {gray stopping previous pm2 app} {magenta ${PM2_PREV_NAME}}`);
exec(`ssh ${HOST} "pm2 stop ${PM2_PREV_NAME}"`);
exec(`ssh ${HOST} "pm2 delete ${PM2_PREV_NAME}"`);
exec(`ssh ${HOST} "pm2 save"`);
console.log(``);

// // helper functions

function inApiDirWithOutput(cmd: string): boolean {
  console.log(``);
  const result = spawnSync(`ssh`, [HOST, `cd ${API_DIR} && ${cmd}`], {
    stdio: `inherit`,
  });
  console.log(``);
  return result.status === 0;
}

function inApiDir(cmd: string): void {
  exec.exit(`ssh ${HOST} "cd ${API_DIR} && ${cmd}"`);
}

function inMonorepoDir(cmd: string): void {
  exec.exit(`ssh ${HOST} "cd ${MONOREPO_DIR} && ${cmd}"`);
}

function getCurrentPort(): number {
  const port = Number(
    exec
      .exit(`ssh ${HOST} "sudo cat ${NGINX_CONFIG} | grep :${PORT_START} --max-count=1"`)
      .replace(/\n.*/, ``)
      .trim()
      .replace(/.*:/, ``)
      .replace(/;$/, ``),
  );

  if (Number.isNaN(port)) {
    red(`Got NaN trying to resolve current port!\n`);
    process.exit(1);
  }

  return port;
}
