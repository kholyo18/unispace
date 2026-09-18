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
    indexes: unique([...currentIndexes, ...requiredIndexes]),
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

module.exports = { reconcile };
