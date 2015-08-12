GroupMonitorPacket = require './GroupMonitorPacket'

module.exports = class PacketParser
  constructor: (@opts, @packetCallback) ->
    @hex = @opts.hex
    @log = @opts.log
    @finishedPackets = []
    @currentPacket = undefined
  onData: (data) =>
    @log "PacketParser#onData"
    if data?
      if !@currentPacket?
        @currentPacket = new GroupMonitorPacket @opts, data
      else if @currentPacket?.isReady()
        @packetCallback(undefined, @currentPacket) unless @currentPacket.ignorable()
        @currentPacket = new GroupMonitorPacket @opts, data
      else
        @currentPacket.append(data)
    @log "Current status #{@currentPacket.toString()}"
