node-eibd-ng
============

A rewrite of the node-eibd package with read support (more to come)

# first install

```
  npm install --save https://github.com/sn0cr/node-eibd-ng/archive/v0.0.3.tar.gz
```
# Then run 

```coffee-script
# to write :smile:
KNXConnection = require 'node-eibd-ng'
eibd = new KNXConnection({ip: '127.0.0.1', port: 6720})
dest = KNXConnection.encodeAddr("1/2/3")
eibd.write dest, [0x00, 0x80 | true], (err) =>
  console.dir err
```
or it could be:

```coffee-script
  # to write :smile:
  KNXConnection = require 'node-eibd-ng'
  eibd = new KNXConnection({ip: '127.0.0.1', port: 6720})
  dest = KNXConnection.encodeAddr("1/2/4")
  eibd.read dest, (err, data) ->
    console.log err
    console.log data.toString() if data?
    eibd.reset => 
      eibd.end()
```
:exclamation: Don't forget these two last lines!


LICENSE
============

The MIT License (MIT)

Copyright (c) 2014 Sn0cr

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
