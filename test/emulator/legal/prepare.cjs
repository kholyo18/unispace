'use strict';
const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');
const {createHash} = require('node:crypto');
const {execFileSync} = require('node:child_process');
const {PROJECT, HOSTS, assertEmulatorOnly} = require('./safety.cjs');
assertEmulatorOnly();
const root = path.resolve(__dirname, '../../..');
// __dirname is <repo>/test/emulator/legal, so three parent levels is the repo.
const output = process.argv[2];
if (!output) throw new Error('Pass a new sandbox directory inside the runner temporary directory.');
const temp = fs.realpathSync(process.env.RUNNER_TEMP || os.tmpdir());
const target = path.resolve(output);
if (!target.startsWith(`${temp}${path.sep}`) || fs.existsSync(target)) throw new Error('Sandbox must be new and inside the temporary directory.');
const sourceFiles = ['consent.js', 'eligibility.js', 'eligibility-consent.js', 'register-eligibility.js'];
const sha = execFileSync('git', ['rev-parse', 'HEAD'], {cwd: root, encoding: 'utf8'}).trim();
if (!/^[a-f0-9]{40}$/.test(sha)) throw new Error('Invalid source commit.');
const before = execFileSync('git', ['status', '--porcelain', '--untracked-files=no'], {cwd: root, encoding: 'utf8'});
if (before.trim()) throw new Error('Tracked source modifications found; use a clean disposable checkout.');
fs.mkdirSync(path.join(target, 'functions/legal'), {recursive: true});
const hashes = {};
function copy(source, destination) {
  const bytes = fs.readFileSync(source);
  fs.copyFileSync(source, destination);
  hashes[path.relative(root, source)] = createHash('sha256').update(bytes).digest('hex');
}
for (const file of sourceFiles) copy(path.join(root, 'functions/legal', file), path.join(target, 'functions/legal', file));
for (const file of ['package.json', 'package-lock.json']) copy(path.join(root, 'functions', file), path.join(target, 'functions', file));
const manifest = JSON.parse(fs.readFileSync(path.join(target, 'functions/package.json')));
if (manifest.main !== 'index.js' || manifest.engines?.node !== '24') throw new Error('Unexpected runtime contract; review rather than rewriting dependencies.');
copy(path.join(__dirname, 'runtime.cjs'), path.join(target, 'functions/index.js'));
// Functions discovery passes a curated environment, not all parent-process variables.
// Publish ONLY these non-secret test flags via the sandbox's emulator-only env file.
// Firebase supplies the project and service emulator endpoints; safety.cjs still
// validates every endpoint before any Admin SDK initialization.
fs.writeFileSync(path.join(target, 'functions/.env.local'),
  `UNISPACE_LEGAL_EMULATOR_TEST=1\nUNISPACE_LEGAL_FUNCTIONS_HOST=${HOSTS.UNISPACE_LEGAL_FUNCTIONS_HOST}\n`);
copy(path.join(root, 'firestore.rules'), path.join(target, 'firestore.rules'));
for (const file of ['safety.cjs', 'legal.test.cjs']) copy(path.join(__dirname, file), path.join(target, file));
const host = key => ({host: '127.0.0.1', port: Number(HOSTS[key].split(':')[1])});
fs.writeFileSync(path.join(target, 'firebase.json'), JSON.stringify({
  functions: [{source: 'functions', codebase: 'legal-emulator-only'}],
  firestore: {rules: 'firestore.rules'},
  emulators: {
    auth: host('FIREBASE_AUTH_EMULATOR_HOST'), firestore: host('FIRESTORE_EMULATOR_HOST'),
    functions: host('UNISPACE_LEGAL_FUNCTIONS_HOST'),
    hub: {host: '127.0.0.1', port: 4489}, logging: {host: '127.0.0.1', port: 4589},
    ui: {enabled: false}, singleProjectMode: true,
  },
}, null, 2));
fs.writeFileSync(path.join(target, 'source-manifest.json'), JSON.stringify({commit: sha, project: PROJECT, hashes}, null, 2));
console.log(`Prepared isolated legal emulator suite at ${target}; source ${sha}`);
