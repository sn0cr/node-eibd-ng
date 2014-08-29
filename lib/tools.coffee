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
