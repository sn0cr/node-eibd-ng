# The MIT License (MIT)

# Copyright (c) 2014 Sn0cr

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

EIBConnection = require '../lowLevel'
Packet = require "../Packet"

module.exports = class KNXConnection
  constructor: (@opts) ->
    @eibd = new EIBConnection(opts)
  reset: (cl)=>
    @eibd.reset(cl)
  end: =>
    @eibd.end()
  write: (dest, value, cl) =>
    knxData = [0, 0x80 | value]
    @eibd.open (err) =>
      if err? and cl?
       cl(err)
      @eibd.openTGroup dest, 1, (err, data) =>
        if err? and cl?
          cl(err)
        if data?
          @eibd.sendAPDU knxData, =>
            @eibd.reset =>
              @eibd.end()
  read: (dest, cl) =>
    ingoreBuffers = [
      new Buffer([0x00, 0x06, 0x00, 0x25, 0x00, 0x00, 0x00, 0x00]),
      new Buffer([0x00, 0x06, 0x00, 0x25, 0xFF, 0xFF, 0x00, 0x00])
    ]
    ignorePacket = (buffer) ->
      for ingoreBuffer in ingoreBuffers
        return true if buffer.compareTo(ingoreBuffer)
    @eibd.open (err) =>
     if err? and cl?
       cl(err)
      @eibd.openTGroup dest, 0, (err, data) =>
        if err? and cl?
          cl(err)
        if data?
          @eibd.sendAPDU [0,0],  =>
            onData = (data) =>
              @eibd.log "Got #{@eibd.hex(data)}"
              if @currentPacket?
                additionalPacket = @currentPacket.append(data)
                # handle valid packet
                @eibd.log "@currentPacket: #{@eibd.hex @currentPacket.toPacket()}"
                unless ignorePacket(@currentPacket)
                  @eibd.remove 'data', onData
                  cl(undefined, @currentPacket) if cl?
                @currentPacket = new Packet(additionalPacket) unless additionalPacket.length is 0
              else
                @currentPacket = new Packet(data)
            @eibd.socket.on 'data', onData
