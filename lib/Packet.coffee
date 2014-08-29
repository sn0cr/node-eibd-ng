Buffertools = require('buffertools')
Tools = require './tools'

module.exports = class Packet

  constructor: (@data) ->
    @length = new Buffer(@data.slice(0, 2)).readUInt16BE()
    @notNeededData = @data.slice(@length)
    @data = @data.slice(2, @length)


  append: (newData) =>
    newData = Buffer.concat([@data, newData])
    @data = newData.slice 0, @length
    return newData.slice(@length)

  source: =>
    ((@data[2])<<8)|(@data[3])

  sourceString: =>
    Tools.addr2str(@source())

  payload: =>
    buf =  @data.slice(4)
    {buffer: buf, array: buf.toJSON().data}

  toPacket: =>
    length = new Buffer(2)
    length.writeUInt16BE(@length)
    Buffer.concat([length, @data]) if @data.length isnt 0

  compareTo: (otherBuffer) =>
    if @isReady() is true
      Buffertools.compare(@toPacket(), otherBuffer) == 0
    else
      false

  isReady: =>
    @data.length is @length
