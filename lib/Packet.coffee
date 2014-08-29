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
