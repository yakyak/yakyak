var fs = require('fs');
var sysPath = require('path');

var f = fs.readFileSync(sysPath.join(__dirname, 'require.js'), 'utf8');

module.exports = function(requireName) {
  requireName = requireName || 'require';
  var r = f.replace('REQUIRENAME', requireName);
  return r;
};
