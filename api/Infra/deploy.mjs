/* eslint-disable */
// @ts-check

import { spawnSync } from 'child_process';
import { c, log, red } from 'x-chalk';
import xExec from 'x-exec';
import flpEnv from '@friends-library/env';

// @ts-ignore
const env = flpEnv.default;
// @ts-ignore
const exec = xExec.default;

const ENV = process.argv.includes(`--production`) ? `production` : `staging`;

env.load(`./api/.env.${ENV}`);

const {
  HOST,
  MONOREPO_DIR,
  REPO_URL,
  PORT_START,
  CLOUD_STORAGE_BUCKET,
  CLOUD_STORAGE_ENDPOINT,
} = env.require(
  `HOST`,
  `MONOREPO_DIR`,
  `REPO_URL`,
  `PORT_START`,
  `CLOUD_STORAGE_BUCKET`,
  `CLOUD_STORAGE_ENDPOINT`,
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
const SERVE_CMD = `LOG_LEVEL=info ${VAPOR_RUN} serve --port ${NEXT_PORT} --env ${ENV}`;

exec.exit(`ssh ${HOST} "mkdir -p ${MONOREPO_DIR}"`);

log(c`{green git:} {gray ensuring {cyan monorepo} exists at} {magenta ${MONOREPO_DIR}}`);
inMonorepoDir(`test -d .git || git clone ${REPO_URL} .`);

log(c`{green git:} {gray updating {cyan monorepo} at} {magenta ${MONOREPO_DIR}}`);
inMonorepoDir(`git reset --hard HEAD`);
inMonorepoDir(`git clean --force`);
inMonorepoDir(`git pull --rebase origin master`);

log(c`{green env:} {gray copying .env file to} {magenta ${API_DIR}}`);
exec.exit(`scp ./api/.env.${ENV} ${HOST}:${API_DIR}/.env`);

log(c`{green swift:} {gray building vapor app with command} {magenta ${BUILD_CMD}}`);
inMonorepoDir(`just exclude`);
inApiDirWithOutput(BUILD_CMD);

log(c`{green vapor:} {gray running migrations}`);
inApiDirWithOutput(`${VAPOR_RUN} migrate --yes`);

if (ENV === `staging`) {
  log(c`{green test:} {gray running tests}`);
  if (!inApiDirWithOutput(`SWIFT_DETERMINISTIC_HASHING=1 swift test`)) {
    red(`Tests failed, halting deploy.\n`);
    process.exit(1);
  }
}

log(c`{green pm2:} {gray setting serve script for pm2} {magenta ${SERVE_CMD}}`);
inApiDir(`echo \\"#!/usr/bin/bash\\" > ./serve.sh`);
inApiDir(`echo \\"${SERVE_CMD}\\" >> ./serve.sh`);

log(c`{green pm2:} {gray starting pm2 app} {magenta ${PM2_NEXT_NAME}}`);
inApiDir(`pm2 start ./serve.sh --name ${PM2_NEXT_NAME} --time`);

log(c`{green nginx:} {gray changing port in nginx config to} {magenta ${NEXT_PORT}}`);
inApiDir(`sudo sed -E -i 's/:${PORT_START}./:${NEXT_PORT}/' ${NGINX_CONFIG}`);

log(c`{green nginx:} {gray restarting nginx}`);
exec.exit(`ssh ${HOST} "sudo systemctl reload nginx"`);

log(c`{green pm2:} {gray stopping previous pm2 app} {magenta ${PM2_PREV_NAME}}`);
exec(`ssh ${HOST} "pm2 stop ${PM2_PREV_NAME}"`);
exec(`ssh ${HOST} "pm2 delete ${PM2_PREV_NAME}"`);
exec(`ssh ${HOST} "pm2 save"`);

if (ENV === `production`) {
  log(c`{green s3:} {gray updating s3 expiration policies}`);
  inApiDir(`
    cd Infra && \
    aws s3api put-bucket-lifecycle-configuration \
      --bucket ${CLOUD_STORAGE_BUCKET} \
      --endpoint ${CLOUD_STORAGE_ENDPOINT} \
      --lifecycle-configuration file://s3-expiration-policy.json
  `);
}

console.log(``);

// helpers

/**
 * @param {string} cmd
 * @returns {boolean}
 */
function inApiDirWithOutput(cmd) {
  console.log(``);
  const result = spawnSync(`ssh`, [HOST, `cd ${API_DIR} && ${cmd}`], {
    stdio: `inherit`,
  });
  console.log(``);
  return result.status === 0;
}

/**
 * @param {string} cmd
 */
function inApiDir(cmd) {
  exec.exit(`ssh ${HOST} "cd ${API_DIR} && ${cmd}"`);
}

/**
 * @param {string} cmd
 */
function inMonorepoDir(cmd) {
  exec.exit(`ssh ${HOST} "cd ${MONOREPO_DIR} && ${cmd}"`);
}

/**
 * @returns {number}
 */
function getCurrentPort() {
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
