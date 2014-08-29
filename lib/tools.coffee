module.exports =
    packBuffer: (data) ->
      buf = new Buffer(data.length)
      for entry, i in data
        buf.writeUInt8(entry, i)
      buf
    str2addr: (addr) ->
      m = addr.match(/(\d*)\/(\d*)\/(\d*)/)
      a = 0
      b = 0
      c = 0
      result = -1

      if m and m.length > 0
        a = (m[1] & 0x01f) << 11
        b = (m[2] & 0x07) << 8
        c = m[3] & 0xff
        result = a | b | c
      if result > -1
        return result
      else
        return new Error("Could not parse address")

    addr2str: (addr, ga) ->
      if ga is true
        a = (addr>>11)&0xf
        b = (addr>>8)&0x7
        c = (addr & 0xff)
        "#{a}/#{b}/#{c}"
      else
        a = (addr>>12)&0xf
        b = (addr>>8)&0xf
        c = addr&0xff
        "#{a}.#{b}.#{c}"
