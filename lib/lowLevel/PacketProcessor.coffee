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


Packet = require '../Packet'
module.exports = class PacketProcessor
  constructor: (opts) ->
    @log = opts.log
    @hex = opts.hex

    @telegramParts = []
    @readingPacket = false
    @currentLength = -1

  hasParts: =>
    Buffer.concat(@telegramParts).length isnt 0 and @readingPacket is false
  # This method is called when a new chunk of data arrives
  onData: (data) =>
    @log "PacketProcessor#onData"
    if data
      @hex data, true
      @telegramParts.push data
    currentTelegram = Buffer.concat(@telegramParts)
    unless data?
      data = currentTelegram


    if @readingPacket is false and data.length >= 2
      @readingPacket = true
      @currentLength = data.readUInt16BE(0) + 2 # + 2 due to the length attribute

    @log "currentTelegram: #{@hex currentTelegram}"

    if currentTelegram.length >= @currentLength
      @latestPacket = new Packet(currentTelegram.slice(0, @currentLength))
      @log "added packet: #{@latestPacket}"
      @log "added packet: #{@hex @latestPacket.data}"

      # setting back the things (empty the array...)
      @telegramParts.length = 0
      @telegramParts.push(currentTelegram.slice(@currentLength))
      @readingPacket = false
      @currentLength = -1
      return @latestPacket
