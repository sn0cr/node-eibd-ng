node-eibd-ng
============

A client package for the eibd KNX/EIB-server

# first install

```
  npm install --save https://github.com/sn0cr/node-eibd-ng/archive/v0.0.7.gz
```
# Then run _to write_

```coffee-script
# to write 
KNXConnection = require 'node-eibd-ng'
eibd = new KNXConnection({ip: '127.0.0.1', port: 6720})
dest = KNXConnection.encodeAddr("1/2/3")
eibd.write dest, [0x00, 0x80 | true], (err) =>
  console.dir err
```
# Then run _to read_

```coffee-script
  # to read 
  KNXConnection = require 'node-eibd-ng'
  eibd = new KNXConnection({ip: '127.0.0.1', port: 6720})
  dest = KNXConnection.encodeAddr("1/2/4")
  eibd.read dest, (err, data) ->
    console.log err
    console.log data.toString() if data?
    eibd.reset => 
      eibd.end() # <= Terminate the socket connection
```

# Want to listen on the bus? Here we go:

```coffee-script
  # to read 
  KNXConnection = require 'node-eibd-ng'
  eibd = new KNXConnection({ip: '127.0.0.1', port: 6720})
  eibd.groupMonitor (err, data) ->
    console.log data

  setTimeout(eibd.end, 1000*90)
```



LICENSE
============

The MIT License (MIT)

Copyright (c) 2014-2015 Sn0cr

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
