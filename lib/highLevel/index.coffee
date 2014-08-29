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
