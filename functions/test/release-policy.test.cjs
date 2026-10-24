const test = require('node:test');
const assert = require('node:assert/strict');
const { createReleasePolicyReader, createReleaseVersionGuard } = require('../security/release-policy');
function fixture(policy, buildNumber) {
  const sid = 'a'.repeat(64), paths = [], request = { data: {}, auth: { uid: 'viewer', token: { sid } } };
  const db = { doc: path => ({ get: async () => {
    paths.push(path);
    const data = path === 'releasePolicy/android' ? policy : { buildNumber };
    return { exists: data !== undefined, data: () => data };
  } }) };
  let calls = 0;
  return { paths, request, read: createReleasePolicyReader({ db }),
    call: createReleaseVersionGuard({ db })(async () => { calls++; return 'allowed'; }), count: () => calls };
}
test('absent policy defaults disabled and fixed Play URL; public reader requires empty input', async () => {
  const f = fixture();
  assert.deepEqual(await f.read({ data: {} }), { enabled: false, minimumBuild: 1,
    storeUrl: 'https://play.google.com/store/apps/details?id=dz.fachub.fachub' });
  assert.equal(await f.call(f.request), 'allowed');
  assert.ok(f.paths.every(path => path === 'releasePolicy/android'));
  for (const data of [undefined, [], { minimumBuild: 1 }, '']) {
    await assert.rejects(f.read({ data }), { code: 'invalid-argument' });
  }
});
test('malformed stored policy fails closed, including disabled malformed policy', async () => {
  for (const policy of [{}, { enabled: 'false', minimumBuild: 1 }, { enabled: false, minimumBuild: 0 },
    { enabled: true, minimumBuild: 1.5 }, { enabled: true, minimumBuild: '2' }]) {
    const f = fixture(policy, '999');
    await assert.rejects(f.read({ data: {} }), { code: 'failed-precondition' });
    await assert.rejects(f.call(f.request), { code: 'failed-precondition' });
    assert.equal(f.count(), 0);
  }
});
test('enabled gate accepts matching/new builds from signed session row, never caller version', async () => {
  for (const build of ['2', '3', '002']) {
    const f = fixture({ enabled: true, minimumBuild: 2 }, build);
    assert.equal(await f.call(f.request), 'allowed');
    assert.ok(f.paths.includes(`users/viewer/sessions/${'a'.repeat(64)}`));
  }
  for (const build of [undefined, '1', 3, '2.0', '-2', 'Infinity', '9007199254740992', ' 2 ']) {
    const f = fixture({ enabled: true, minimumBuild: 2 }, build);
    await assert.rejects(f.call({ ...f.request, data: { buildNumber: '999', sid: 'b'.repeat(64) } }), error =>
      error.code === 'failed-precondition' && error.details.reason === 'app-update-required' && error.details.minimumBuild === 2);
    assert.equal(f.count(), 0);
  }
});
test('missing signed session cannot bypass enabled gate and store URL is not configurable', async () => {
  const f = fixture({ enabled: true, minimumBuild: 2, storeUrl: 'https://evil.invalid' }, '3');
  await assert.rejects(f.call({ data: {}, auth: { uid: 'viewer', token: {} } }), { code: 'failed-precondition' });
  assert.match((await f.read({ data: {} })).storeUrl, /^https:\/\/play.google.com\//);
});
