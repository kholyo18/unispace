const fs = require('node:fs');
const path = require('node:path');
// Include same-library parts so source contracts still inspect the full implementation.
module.exports = function readDartLibrary(file) {
  const source = fs.readFileSync(file, 'utf8');
  return source + [...source.matchAll(/^part ['"]([^'"]+)['"];\r?$/gm)]
    .map((match) => '\n' + fs.readFileSync(path.resolve(path.dirname(file), match[1]), 'utf8')).join('');
};
