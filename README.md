node-eibd-ng
============

A rewrite of the node-eibd package with read support (more to come)

```
  # first install
  npm install --save https://github.com/sn0cr/node-eibd-ng/archive/v0.0.1.tar.gz
```
# Then run :+1:

```coffee-script
KNXConnection = require 'node-eibd-ng'
eibd = new KNXConnection({ip: '127.0.0.1', port: 6720})
dest = KNXConnection.encodeAddr("1/2/3")
eibd.write dest, [0x00, 0x80 | true], (err) =>
  console.dir err
```
