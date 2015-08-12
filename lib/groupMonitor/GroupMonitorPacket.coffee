Tools = require '../tools'
Buffertools = require 'buffertools'

module.exports = class GroupMonitorPacket
  @OPENPACKET: new Buffer [0x00, 0x02, 0x00, 0x26]
  constructor: (@opts, @data) ->
    @hex = @opts.hex
    @log = @opts.log
    @length = @data.readUInt16BE(0) if @data.length >= 2
    @trimDataAndSet(2, @data)

  trimDataAndSet: (start, data) =>
    @log "GroupMonitorPacket#trimDataAndSet"
    @log "Add #{@hex data}"
    if @length > data.length
      @data = data.slice(start, data.length)
    else
      @data = data.slice(start, @length+2) # due to the length attribute
  append: (newData) =>
    @log "GroupMonitorPacket#append"
    @log @hex newData
    newData = Buffer.concat([@data, newData])
    @trimDataAndSet(0, newData)

  source: =>
    if !@isReady() or @length < 4
      @log "has no source"
      return -0xF00
    @data.readUInt16BE 2

  sourceString: =>
    Tools.addr2str @source(), false

  destinationString: =>
    Tools.addr2str @destination(), true

  destination: =>
    if !@isReady() or @length < 6
      @log "has no destination"
      return -0xF00
    @data.readUInt16BE 4

  type: =>
    if !@isReady() or @length < 8
      @log "has no type"
      return -0xF00
    @data.readUInt8 7

  typeString: =>
    if Buffertools.compare(@toPacket(), GroupMonitorPacket.OPENPACKET) == 0
      "OpenPacket"
    switch @type()
      when 64, 65 then 'Response'
      when 128, 129 then 'Write'
      when 0 then 'Read'
      else 'Unknown'
  hasData: => @type() > 0 and @length > 8
  isReady: => @data.length is @length
  payload: =>
    @log "Has data: #{@hasData()} and length: #{@length} and type: #{@type()} #{ @length == 8 and @type() > 0} "
    if @hasData()
      @data.slice 8, @length
    else if @length == 8 and @type() > 0
      (@type() & 0x01) == 1# return the boolean value
    else
      new Buffer([])
  toPacket: =>
    length = new Buffer(2)
    length.writeUInt16BE(@length)
    if @data.length isnt 0
      Buffer.concat([length, @data])
    else
      length
  toString: =>
    additionalInfo = if Buffertools.compare(@toPacket(), GroupMonitorPacket.OPENPACKET) != 0
      "@length='#{@data.length}' @source='#{@sourceString()}' @type='#{@typeString()}' @destination='#{@destinationString()}'"
    else
      "Open Packet"
    payloadData = @payload()
    payload = if typeof payloadData is 'buffer'
      @hex payloadData
    else
      payloadData
    "<#GroupMonitorPacket #{additionalInfo} @payload={#{payload}} @packet={#{@hex @toPacket()}}>"
  ignorable: =>
    Buffertools.compare(@toPacket(), GroupMonitorPacket.OPENPACKET) == 0
