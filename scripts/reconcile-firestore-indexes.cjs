#!/usr/bin/env node
const fs = require('node:fs');
const path = require('node:path');

function fail(message) {
  console.error(message);
  process.exit(1);
}

function readJson(file) {
  try {
    return JSON.parse(fs.readFileSync(file, 'utf8'));
  } catch (error) {
    fail(`Could not read JSON from ${file}: ${error.message}`);
  }
}

function stable(value) {
  if (Array.isArray(value)) return value.map(stable);
  if (value && typeof value === 'object') {
    return Object.fromEntries(
      Object.keys(value).sort().map(key => [key, stable(value[key])]),
    );
  }
  return value;
}

function key(value) {
  return JSON.stringify(stable(value));
}

function unique(items) {
  const seen = new Set();
  const result = [];
  for (const item of items) {
    const k = key(item);
    if (seen.has(k)) continue;
    seen.add(k);
    result.push(item);
  }
  return result;
}

function compositeIndexIdentity(index) {
  return key({
    collectionGroup: index?.collectionGroup || '',
    queryScope: index?.queryScope || '',
    apiScope: index?.apiScope || 'ANY_API',
    fields: Array.isArray(index?.fields) ? index.fields : [],
  });
}

function optionalIndexSettingsCompatible(current, required) {
  const optionalKeys = ['density', 'multikey', 'unique'];
  for (const property of optionalKeys) {
    if (!Object.hasOwn(required, property)) continue;
    if (!Object.hasOwn(current, property)) return false;
    if (key(current[property]) !== key(required[property])) return false;
  }
  return true;
}

function mergeCompositeIndexes(currentIndexes, requiredIndexes) {
  const result = [];
  const byIdentity = new Map();

  for (const item of currentIndexes) {
    const identity = compositeIndexIdentity(item);
    if (!byIdentity.has(identity)) {
      byIdentity.set(identity, item);
      result.push(item);
      continue;
    }

    if (!result.some(existing => key(existing) === key(item))) {
      result.push(item);
    }
  }

  for (const required of requiredIndexes) {
    const identity = compositeIndexIdentity(required);
    const current = byIdentity.get(identity);

    if (current && optionalIndexSettingsCompatible(current, required)) {
      continue;
    }

    if (!result.some(existing => key(existing) === key(required))) {
      result.push(required);
    }
  }

  return result;
}

function mergeFieldOverride(current, required) {
  const output = { ...current, ...required };
  if (Object.hasOwn(current, 'ttl') && !Object.hasOwn(required, 'ttl')) {
    output.ttl = current.ttl;
  }
  output.indexes = unique([
    ...(Array.isArray(current.indexes) ? current.indexes : []),
    ...(Array.isArray(required.indexes) ? required.indexes : []),
  ]);
  return output;
}

function reconcile(current, required) {
  const currentIndexes = Array.isArray(current.indexes) ? current.indexes : [];
  const requiredIndexes = Array.isArray(required.indexes) ? required.indexes : [];
  const currentOverrides = Array.isArray(current.fieldOverrides)
    ? current.fieldOverrides
    : [];
  const requiredOverrides = Array.isArray(required.fieldOverrides)
    ? required.fieldOverrides
    : [];

  const overrides = new Map();
  for (const item of currentOverrides) {
    if (!item || typeof item !== 'object') continue;
    const id = `${item.collectionGroup || ''}\u0000${item.fieldPath || ''}`;
    overrides.set(id, item);
  }
  for (const item of requiredOverrides) {
    if (!item || typeof item !== 'object') continue;
    const id = `${item.collectionGroup || ''}\u0000${item.fieldPath || ''}`;
    const existing = overrides.get(id);
    overrides.set(id, existing ? mergeFieldOverride(existing, item) : item);
  }

  return {
    indexes: mergeCompositeIndexes(currentIndexes, requiredIndexes),
    fieldOverrides: [...overrides.values()],
  };
}

if (require.main === module) {
  const [, , currentPath, outputPath = 'firestore.indexes.json',
    requiredPath = 'firestore.indexes.required.json'] = process.argv;

  if (!currentPath) {
    fail(
      'Usage: node scripts/reconcile-firestore-indexes.cjs ' +
      '<firebase-export.json> [output.json] [required.json]',
    );
  }

  const current = readJson(currentPath);
  const required = readJson(requiredPath);
  const merged = reconcile(current, required);

  fs.writeFileSync(
    outputPath,
    JSON.stringify(merged, null, 2) + '\n',
    'utf8',
  );

  console.log(
    `Wrote ${path.resolve(outputPath)} with ` +
    `${merged.indexes.length} composite indexes and ` +
    `${merged.fieldOverrides.length} field overrides.`,
  );
}

module.exports = { reconcile, mergeCompositeIndexes };
