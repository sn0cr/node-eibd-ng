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

Buffertools = require('buffertools')
Tools = require './tools'

module.exports = class Packet

  constructor: (@data) ->
    @length = new Buffer(@data.slice(0, 2)).readUInt16BE()
    @trimDataAndSet(2, @data)
    @notNeededData = @data.slice(@length, @data.length)


  append: (newData) =>
    newData = Buffer.concat([@data, newData])
    @trimDataAndSet(0, newData)
    @notNeededData = @data.slice(@length, newData.length)
    # return newData.slice(@length)

  trimDataAndSet: (start, data) =>
    if @length > data.length
      @data = data.slice(start, data.length)
    else
      @data = data.slice(start, @length+2) # due to the length attribute
      @notNeededData = data.slice()

  source: =>
    ((@data[2])<<8)|(@data[3])

  sourceString: =>
    Tools.addr2str(@source())

  type: =>
    payload = @payload()
    switch payload[1]
      when 64, 65 then 'Response'
      when 128, 129 then 'Write'
      when 0 then 'Read'
      else 'Unknown'

  payload: =>
    buf =  @data.slice(4)
    buf.toJSON().data

  payloadArrray: =>
   @payload()

  payloadBuffer: =>
    @data.slice(4)

  toPacket: =>
    length = new Buffer(2)
    length.writeUInt16BE(@length)
    if @data.length isnt 0
      Buffer.concat([length, @data])
    else
      new Buffer(0)

  compareTo: (otherBuffer) =>
    if @isReady() is true
      Buffertools.compare(@toPacket(), otherBuffer) == 0
    else
      false

  isReady: =>
    @data.length is @length

  toString: =>
    "<#Packet @length='#{@data.length}' @source='#{@sourceString()}' @type='#{@type()}' @payloadArray=[#{@payloadArrray().join()}]>"
