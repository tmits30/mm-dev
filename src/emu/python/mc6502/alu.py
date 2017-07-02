class ALU(object):

    def __init__(self):
        self._table = {
            'inc': self._inc, 'dec': self._dec,
            'asl': self._asl, 'lsr': self._lsr,
            'rol': self._rol, 'ror': self._ror,
            'adc': self._adc, 'sbc': self._sbc, 
            'bit': self._bit, 'cmp': self._cmp,
            'and': self._and, 'ora': self._ora,
            'eor': self._eor, 'tha': self._tha,
        }

    def __call__(self, a, b, flag, ctrl):
        ret, flag = self._table[ctrl](a, b, flag)
        ret = ret & 0xff
        return ret, flag

    def _inc(self, a, b, flag):
        """Increment source A"""
        ret = a + 1
        flag['N'] = ret & 0x80
        flag['Z'] = (ret & 0xff) == 0x00
        return ret, flag

    def _dec(self, a, b, flag):
        """Decrement source A"""
        ret = a - 1
        flag['N'] = ret & 0x80
        flag['Z'] = (ret & 0xff) == 0x00
        return ret, flag

    def _asl(self, a, b, flag):
        """Arithmetic shift left source A"""
        ret = a << 1
        flag['N'] = ret & 0x80
        flag['Z'] = (ret & 0xff) == 0x00
        flag['C'] = ret >> 8
        return ret, flag

    def _lsr(self, a, b, flag):
        """Logical shift right source A"""
        ret = a >> 1
        flag['Z'] = (ret & 0xff) == 0x00
        flag['C'] = a & 0x01
        return ret, flag

    def _rol(self, a, b, flag):
        """Rotate left source A"""
        ret = (a << 1) | flag['C']
        flag['N'] = ret & 0x80
        flag['Z'] = (ret & 0xff) == 0x00
        flag['C'] = ret >> 8
        return ret, flag

    def _ror(self, a, b, flag):
        """Rotate right source A"""
        ret = (flag['C'] << 7) | (a >> 1)
        flag['N'] = ret & 0x80
        flag['Z'] = (ret & 0xff) == 0x00
        flag['C'] = a & 0x01
        return ret, flag

    def _adc(self, a, b, flag):
        """Add source A and source B"""
        if flag['D']:
            l = (a & 0x0f) + (b & 0x0f) + flag['C']
            if l >= 0x0a:
                l = ((l + 0x06) & 0x0f) + 0x10
            s = (a & 0xf0) + (b & 0xf0) + l
            t = s
            ret = s + 0x60 if s >= 0xa0 else 0x00
            flag['N'] = ret & 0x80
            flag['V'] = (t < -128) | (t > 127)
            flag['Z'] = (ret & 0xff) == 0x00
            flag['C'] = ret >= 0x100
        else:
            ret = a + b + flag['C']
            a_msb, b_msb = (a & 0x80), (b & 0x80)
            flag['N'] = ret & 0x80
            flag['V'] = (a_msb == b_msb) & ((a_msb ^ (ret & 0x80)) > 0)
            flag['Z'] = (ret & 0xff) == 0x00
            flag['C'] = ret >= 0x100
        return ret, flag

    def _sbc(self, a, b, flag):
        """Subtract source A and source B"""
        borrow = 1 - flag['C']
        if flag['D']:
            l = (a & 0x0f) - (b & 0x0f) - borrow
            s = a - b + flag['C'] - 1
            ret = s - (0x60 if s < 0 else 0) - (0x06 if l < 0 else 0)
            flag['N'] = ret & 0x80
            flag['V'] = ((ret & 0x80) > 0) ^ ((ret & 0x100) != 0)
            flag['Z'] = (ret & 0xff) == 0x00
            flag['C'] = not (s & 0x100)
        else:
            ret = a - b - borrow
            a_msb, b_msb = a & 0x80, b & 0x80
            flag['N'] = ret & 0x80
            flag['V'] = ((ret & 0x80) > 0) ^ ((ret & 0x100) != 0)
            flag['Z'] = (ret & 0xff) == 0x00
            flag['C'] = ret & 0x100
        return ret, flag

    def _bit(self, a, b, flag):
        """Bits 7 and 6 of operand are transfered to bit 7 and 6 of SR (N,V);
        the zeroflag is set to the result of operand AND accumulator."""
        ret = a & b
        flag['N'] = b & 0x80
        flag['V'] = b & 0x40
        flag['Z'] = ret == 0x00
        return a, flag

    def _cmp(self, a, b, flag):
        """Compare source A and source B"""
        ret = a - b
        flag['N'] = ret & 0x80
        flag['Z'] = ret == 0x00
        flag['C'] = ret & 0x100
        return a, flag

    def _and(self, a, b, flag):
        """And source A and source B"""
        ret = a & b
        flag['N'] = ret & 0x80
        flag['Z'] = ret == 0x00
        return ret, flag

    def _ora(self, a, b, flag):
        """OR source A and source B"""
        ret = a | b
        flag['N'] = ret & 0x80
        flag['Z'] = ret == 0x00
        return ret, flag

    def _eor(self, a, b, flag):
        """Exclusive-OR source A and source B"""
        ret = a ^ b
        flag['N'] = ret & 0x80
        flag['Z'] = ret == 0x00
        return ret, flag

    def _tha(self, a, b, flag):
        """Through source A"""
        return a, flag
