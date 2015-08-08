# The MIT License (MIT)

# Copyright (c) 2014-2015 Sn0cr

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
tools = require "../tools"
Buffertools = require('buffertools')

module.exports = class KNXConnection

  @encodeAddr: (addr) =>
    tools.str2addr(addr)

  @decodeAddr: (addr, ga) =>
    tools.addr2str(addr, ga)

  constructor: (@opts) ->
    @eibd = new EIBConnection(@opts)
  reset: (cl)=>
    @eibd.reset(cl)
  end: =>
    @eibd.end()
  log: (msg) =>
    @eibd.log(msg)
  hex: (data, log) =>
    @eibd.hex(data, log)

  write: (dest, value, cl) =>
    knxData = value
    @eibd.open (err) =>
      if err? and cl?
       cl(err)
      @eibd.openTGroup dest, 1, (err, data) =>
        if err? and cl?
          cl(err)
        if data?
          @eibd.sendAPDU knxData, =>
            cl() if cl?
            @eibd.reset =>
              @eibd.end()
  read: (dest, cl) =>
    @telegrams = []
    @readingPacket = false
    @packets = []
    @currentLength = -1
    @eibd.open (err) =>
     if err? and cl?
       cl(err)
      @eibd.openTGroup dest, 0, (err, data) =>
        if err? and cl?
          cl(err)
        if data?
          @eibd.sendAPDU [0,0],  =>
            @cl = cl
            @eibd.socket.on 'data', @onReadData


  onReadData: (data) =>
    @log "#onReadData(data: #{@hex data})"

    # store telgram part
    @telegrams.push(data)
    currentTelegram = Buffer.concat @telegrams

    if @readingPacket is false and data.length >= 2
      @readingPacket = true
      @currentLength = data.readUInt16BE(0) + 2 # due to the length attribute
    @log "currentTelegram: #{@hex currentTelegram}"

    if currentTelegram.length >= @currentLength
      @latestPacket = new Packet(currentTelegram.slice(0, @currentLength))
      @packets.push(@latestPacket)
      @log "added packet: #{@latestPacket}"
      # setting back the things (empty the array...)
      @telegrams.length = 0
      @telegrams.push(currentTelegram.slice(@currentLength))
      @readingPacket = false
      @currentLength = -1

      if @latestPacket.type() == "Response"
        @eibd.remove('data', @onReadData)
        if @cl?
          @cl(undefined, @latestPacket)
          delete @cl


