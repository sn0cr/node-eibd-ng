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

tools = require('../tools')
Packet = require('../Packet')
PacketProcessor = require('./PacketProcessor')

net = require('net')
sys = require('sys')

Buffertools = require('buffertools')

module.exports = class EIBConnection
  constructor: (@opts) ->
    @ip = @opts.ip
    @port = @opts.port
    @opts.host = @ip unless @opts.host?
    @debug = @opts.debug if @opts.debug?

  # called when an error occurs
  errorHandler: (error) ->
    console.error "Error occured: #{error}"
    @end()

  userError: (error, secError) ->
    @errorHandler "#{error} EIBConnection##{secError}"

  hex: (data, log) =>
    return unless @debug? and @debug is true
    Hexy = require 'hexy'
    format =
      format: "twos"
      caps: "upper"
    if log is true
      @log Hexy.hexy(data, format).trim()
    else
      format['annotate'] = "none"
      Hexy.hexy(data, format).trim()

  end: =>
    @socket.end() if @socket?
    @ended = true
    delete @socket

  remove: (evnt, cl) =>
    @log "#remove(event: #{evnt}, cl)"
    @socket.removeListener(evnt, cl) if @socket?

  on: (evnt, cl) =>
    @log "#on(event: #{evnt}, cl)"
    if @socket?
      @socket.on(evnt, cl)
    else
      @log "Socket is closed"

  log: (msg) =>
    console.log msg if @debug? and @debug is true

  # open a connection to the eibd server (also known as #socketRemote)
  open: (cl) =>
    unless cl?
      @userError("Please provide an callback to", "open")
    @socket = net.connect(@opts, cl)
    @socket.on('error', cl)
    @socket.on('error', @errorHandler)

  # encode and send data to the bus
  send: (data, cl) =>
    return if @ended
    @log "#send(data: [#{data}])"
    knxData = [((data.length>>8) & 0xff), (data.length & 0xff)].concat(data)
    buffer = tools.packBuffer(knxData)
    @log "Buffer #{@hex(buffer)}"
    @socket.write(buffer, cl)

  # opens a GroupSocket
  openGroupSocket: (writeOnly, cl) =>
    @log "#openGroupSocket"
    data = [0, 38, 0, 0]
    data[4] = if writeOnly isnt 0
      0xff
    else
      0x00

    @send(data)
    cl() if cl?

  # open a connection of type TGroup
  openTGroup: (destination, writeOnly, cl) =>
    @log "#openTGroup(destination: #{destination}, writeOnly: #{writeOnly})"
    knxData = [0, 34, ((destination>>8) & 0xff), (destination & 0xff)]
    knxData[4] = if writeOnly isnt 0
      0xff
    else
      0x00
    receivedPackets = []
    packetProcessor = new PacketProcessor hex: @hex, log: @log

    onData = (data) =>
      @log "#openTGroup#onData"
      @hex data, true
      latestPacket = packetProcessor.onData(data)
      unless (foundPacket = @checkForOpenTGroupPacket(latestPacket))
        while packetProcessor.hasParts()
          @log packetProcessor.telegramParts
          if latestPacket? and @checkForOpenTGroupPacket(latestPacket)
            foundPacket = true
            break
          latestPacket = packetProcessor.onData()
      if foundPacket is true
        @remove 'data', onData
        cl(undefined, latestPacket)


    @socket.on('data', onData);
    @send(knxData)

  checkForOpenTGroupPacket: (packet) =>
    @log "#checkForOpenTGroupPacket #{packet}"
    return false unless packet?
    packet.length is 2 and packet.data[1] is 0x22


  # Send an APDU
  sendAPDU: (data, cl) =>
    @log "#sendAPDU(data: #{data})"
    knxData = [0, 37]
    knxData = knxData.concat data
    if data.length is 3
      knxData[4] = data[2]
    @send knxData, =>
      cl() if cl?


  # reset the connection
  isResetPacket: (data) =>
    return false unless data?
    Buffertools.compare(data?.toPacket(), new Buffer([0x00, 0x02, 0x00, 0x04])) is 0

  reset: (cl)=>
    @log "Reset"
    packetProcessor = new PacketProcessor hex: @hex, log: @log

    onData = (data) =>
      @log "#reset#onData"
      @hex data, true
      latestPacket = packetProcessor.onData(data)
      unless (foundPacket = @isResetPacket(latestPacket))
        while packetProcessor.hasParts()
          if latestPacket? and @isResetPacket(latestPacket)
            foundPacket = true
            break
          latestPacket = packetProcessor.onData()
      if foundPacket is true
        @remove 'data', onData
        cl(latestPacket)

    @on 'data', onData
    @send [0, 4]

