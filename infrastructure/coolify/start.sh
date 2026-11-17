#!/bin/sh
set -e

mkdir -p "$UPLOAD_LOCATION"

# The server connects to Redis at localhost:6379 (hardcoded), so forward that port to the redis service
node -e "const n=require('net');n.createServer(c=>{const r=n.connect(6379,'redis');c.pipe(r).pipe(c);c.on('error',()=>r.destroy());r.on('error',()=>c.destroy())}).listen(6379,'127.0.0.1')" &

yarn typeorm migration:run -d data-source.ts

exec yarn concurrently -k -n proxy,server,app \
  "node infrastructure/dev/devProxy.js" \
  "yarn workspace @koh/server prod:start" \
  "yarn workspace @koh/app prod:start"
