tools = require('../tools')
Packet = require('../Packet')

net = require('net')
sys = require('sys')
Hexy = require 'hexy'
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

  remove: (evnt, cl) =>
    @log "#remove(event: #{evnt}, cl)"
    @socket.removeListener(evnt, cl)

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

    onData = (data) =>
      @log "#openTGroup#onData"
      @hex data, true
      if @waitForBytes? and @waitForData? and data.length is @waitForBytes
        data = Buffer.concat([@waitForData, data])
        delete @waitForBytes
        delete @waitForData

      if data[1] is 2
        if ((data[2]<<8 | data[3]) == 34)
          @remove('data', onData)
          cl(null, data)
        else
          @waitForBytes = 2
          @waitForData = data
      else
        @remove('data', onData)
        cl(new Error('invalid buffer length received'))
    @socket.on('data', onData);
    @send(knxData)

  # Send an APDU
  sendAPDU: (data, cl) =>
    @log "#sendAPDU(data: #{data})"
    knxData = [0, 37]
    knxData = knxData.concat data
    if data.length is 3
      knxData[4] = data[2]
    @send knxData, =>
      cl() if cl?

  isResetPacket: (data, onDataClObject, cl) =>
    if Buffertools.compare(data, new Buffer([0x00, 0x02])) == 0
      @partData = data
    if @partData? and Buffertools.compare(data, new Buffer([0x00, 0x04])) is 0
      data = Buffer.concat([@partData, data])
    if Buffertools.compare(data, new Buffer([0x00, 0x02, 0x00, 0x04])) is 0
      @log "#isResetPacket: #{@hex data}"
      @remove 'data', onDataClObject
      @log "Resetted successfully (got #{@hex(data)})"
      cl(data) if cl?

  # reset the connection
  reset: (cl)=>
    @log "Reset"
    onData = (data) =>
      @log "#reset#onData"
      @hex data, true
      @isResetPacket(data, onData, cl)
      if @currentPacket?
        additionalPacket = @currentPacket.append(data)
        unless additionalPacket.length is 0
          @currentPacket = new Packet(additionalPacket)
      else if data.length isnt 2 or data.length isnt 4
        @currentPacket = new Packet(data)
        if @currentPacket.notNeededData.length isnt 0
          data = @currentPacket.notNeededData
      @isResetPacket(data, onData, cl)

    @socket.on 'data', onData
    @send [0, 4]

