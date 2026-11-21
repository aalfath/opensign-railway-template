#!/bin/sh
# Small, checked edits to the upstream server. Each one fails the build if upstream code moved.
set -eu
cd /usr/src/app

# 1. Listen on IPv6 and IPv4, so the web service reaches it over Railway's private network.
grep -q "httpServer.listen(port, '0.0.0.0'" index.js
sed -i "s|httpServer.listen(port, '0.0.0.0'|httpServer.listen(port, process.env.HOST \|\| '::'|" index.js

# 2. Only the master key may create the administrator. Upstream lets anyone call `addadmin`
#    at any time; here the first admin comes from the deploy variables (bootstrap-admin.mjs).
grep -q '^export default async function AddAdmin(request) {$' cloud/parsefunction/AddAdmin.js
sed -i 's|^export default async function AddAdmin(request) {$|export default async function AddAdmin(request) {\n  if (!request.master) {\n    throw new Parse.Error(Parse.Error.OPERATION_FORBIDDEN, "The administrator is created from the deploy variables.");\n  }|' cloud/parsefunction/AddAdmin.js
grep -q 'The administrator is created from the deploy variables' cloud/parsefunction/AddAdmin.js
node --check index.js
echo "patches applied"
