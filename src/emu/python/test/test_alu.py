#!/usr/bin/env python

import os, sys
sys.path.append(os.path.abspath(
    os.path.join(os.path.dirname(__file__), os.path.pardir)))

from mc6502.alu import ALU
from mc6502.flag import Flag


def get_flag(n=0, v=0, b=0, d=0, i=0, z=0, c=0):
    return \
        ((n & 0x01) << 7) | \
        ((v & 0x01) << 6) | \
        ((b & 0x01) << 4) | \
        ((d & 0x01) << 3) | \
        ((i & 0x01) << 2) | \
        ((z & 0x01) << 1) | \
        ((c & 0x01) << 0)

def test_tha():
    alu = ALU()
    ret, flag = alu(0xff, None, Flag(get_flag(n=1)), 'tha')
    assert ret == 0xff and flag.data == get_flag(n=1)

def test_inc():
    alu = ALU()
    ret, flag = alu(0x64, None, Flag(get_flag()), 'inc')
    assert ret == 0x65 and flag.data == get_flag()
    ret, flag = alu(0xff, None, Flag(get_flag()), 'inc')
    assert ret == 0x00 and flag.data == get_flag(z=1)
    ret, flag = alu(0x7f, None, Flag(get_flag()), 'inc')
    assert ret == 0x80 and flag.data == get_flag(n=1)

def test_dec():
    alu = ALU()
    ret, flag = alu(0x64, None, Flag(get_flag()), 'dec')
    assert ret == 0x63 and flag.data == get_flag()
    ret, flag = alu(0xa4, None, Flag(get_flag()), 'dec')
    assert ret == 0xa3 and flag.data == get_flag(n=1)
    ret, flag = alu(0x01, None, Flag(get_flag()), 'dec')
    assert ret == 0x00 and flag.data == get_flag(z=1)
    ret, flag = alu(0x00, None, Flag(get_flag()), 'dec')
    assert ret == 0xff and flag.data == get_flag(n=1)
    ret, flag = alu(0x80, None, Flag(get_flag()), 'dec')
    assert ret == 0x7f and flag.data == get_flag(n=0)

def test_asl():
    alu = ALU()
    ret, flag = alu(0x33, None, Flag(get_flag()), 'asl')
    assert ret == 0x66 and flag.data == get_flag()
    ret, flag = alu(0x70, None, Flag(get_flag()), 'asl')
    assert ret == 0xe0 and flag.data == get_flag(n=1)
    ret, flag = alu(0x00, None, Flag(get_flag()), 'asl')
    assert ret == 0x00 and flag.data == get_flag(z=1)
    ret, flag = alu(0x80, None, Flag(get_flag()), 'asl')
    assert ret == 0x00 and flag.data == get_flag(z=1, c=1)

def test_lsr():
    alu = ALU()
    ret, flag = alu(0x22, None, Flag(get_flag()), 'lsr')
    assert ret == 0x11 and flag.data == get_flag()
    ret, flag = alu(0x00, None, Flag(get_flag()), 'lsr')
    assert ret == 0x00 and flag.data == get_flag(z=1)
    ret, flag = alu(0x11, None, Flag(get_flag()), 'lsr')
    assert ret == 0x08 and flag.data == get_flag(c=1)
    ret, flag = alu(0x01, None, Flag(get_flag()), 'lsr')
    assert ret == 0x00 and flag.data == get_flag(z=1, c=1)

def test_rol():
    alu = ALU()
    ret, flag = alu(0x33, None, Flag(get_flag()), 'rol')
    assert ret == 0x66 and flag.data == get_flag()
    ret, flag = alu(0x70, None, Flag(get_flag()), 'rol')
    assert ret == 0xe0 and flag.data == get_flag(n=1)
    ret, flag = alu(0x00, None, Flag(get_flag()), 'rol')
    assert ret == 0x00 and flag.data == get_flag(z=1)
    ret, flag = alu(0x80, None, Flag(get_flag()), 'rol')
    assert ret == 0x00 and flag.data == get_flag(z=1, c=1)
    ret, flag = alu(0x80, None, Flag(get_flag(c=1)), 'rol')
    assert ret == 0x01 and flag.data == get_flag(c=1)

def test_ror():
    alu = ALU()
    ret, flag = alu(0x22, None, Flag(get_flag()), 'ror')
    assert ret == 0x11 and flag.data == get_flag()
    ret, flag = alu(0x00, None, Flag(get_flag()), 'ror')
    assert ret == 0x00 and flag.data == get_flag(z=1)
    ret, flag = alu(0x11, None, Flag(get_flag()), 'ror')
    assert ret == 0x08 and flag.data == get_flag(c=1)
    ret, flag = alu(0x01, None, Flag(get_flag(c=1)), 'ror')
    assert ret == 0x80 and flag.data == get_flag(n=1, c=1)

def test_and():
    alu = ALU()
    ret, flag = alu(0x33, 0x55, Flag(get_flag()), 'and')
    assert ret == 0x11 and flag.data == get_flag()
    ret, flag = alu(0x33, 0xcc, Flag(get_flag()), 'and')
    assert ret == 0x00 and flag.data == get_flag(z=1)
    ret, flag = alu(0xff, 0x88, Flag(get_flag()), 'and')
    assert ret == 0x88 and flag.data == get_flag(n=1)

def test_ora():
    alu = ALU()
    ret, flag = alu(0x33, 0x55, Flag(get_flag()), 'ora')
    assert ret == 0x77 and flag.data == get_flag()
    ret, flag = alu(0x33, 0xcc, Flag(get_flag()), 'ora')
    assert ret == 0xff and flag.data == get_flag(n=1)
    ret, flag = alu(0x00, 0x00, Flag(get_flag()), 'ora')
    assert ret == 0x00 and flag.data == get_flag(z=1)

def test_eor():
    alu = ALU()
    ret, flag = alu(0x33, 0x55, Flag(get_flag()), 'eor')
    assert ret == 0x66 and flag.data == get_flag()
    ret, flag = alu(0x33, 0xcc, Flag(get_flag()), 'eor')
    assert ret == 0xff and flag.data == get_flag(n=1)
    ret, flag = alu(0xff, 0xff, Flag(get_flag()), 'eor')
    assert ret == 0x00 and flag.data == get_flag(z=1)

def test_bit():
    alu = ALU()
    ret, flag = alu(0x55, 0x33, Flag(get_flag()), 'bit')
    assert ret == 0x55 and flag.data == get_flag(n=0, v=0, z=0)
    ret, flag = alu(0x55, 0x22, Flag(get_flag()), 'bit')
    assert ret == 0x55 and flag.data == get_flag(n=0, v=0, z=1)
    ret, flag = alu(0x80, 0x80, Flag(get_flag()), 'bit')
    assert ret == 0x80 and flag.data == get_flag(n=1, v=0, z=0)
    ret, flag = alu(0x40, 0x40, Flag(get_flag()), 'bit')
    assert ret == 0x40 and flag.data == get_flag(n=0, v=1, z=0)
    ret, flag = alu(0xc0, 0xc0, Flag(get_flag()), 'bit')
    assert ret == 0xc0 and flag.data == get_flag(n=1, v=1, z=0)

def test_cmp():
    alu = ALU()
    ret, flag = alu(0x55, 0x33, Flag(get_flag()), 'cmp')
    assert ret == 0x55 and flag.data == get_flag(n=0, z=0, c=0)
    ret, flag = alu(0x33, 0x55, Flag(get_flag()), 'cmp')
    assert ret == 0x33 and flag.data == get_flag(n=1, z=0, c=1)
    ret, flag = alu(0x33, 0x33, Flag(get_flag()), 'cmp')
    assert ret == 0x33 and flag.data == get_flag(n=0, z=1, c=0)

def test_adc():
    alu = ALU()
    ret, flag = alu(0x0d, 0xd3, Flag(get_flag(c=1)), 'adc')
    assert ret == 0xe1 and flag.data == get_flag(n=1, v=0, z=0, c=0)
    ret, flag = alu(0xfe, 0x06, Flag(get_flag(c=1)), 'adc')
    assert ret == 0x05 and flag.data == get_flag(n=0, v=0, z=0, c=1)
    ret, flag = alu(0x80, 0x80, Flag(get_flag(c=0)), 'adc')
    assert ret == 0x00 and flag.data == get_flag(n=0, v=1, z=1, c=1)
    ret, flag = alu(0x05, 0x07, Flag(get_flag(c=0)), 'adc')
    assert ret == 0x0c and flag.data == get_flag(n=0, v=0, z=0, c=0)
    ret, flag = alu(0x7f, 0x02, Flag(get_flag(c=0)), 'adc')
    assert ret == 0x81 and flag.data == get_flag(n=1, v=1, z=0, c=0)
    ret, flag = alu(0x05, 0xfd, Flag(get_flag(c=0)), 'adc')
    assert ret == 0x02 and flag.data == get_flag(n=0, v=0, z=0, c=1)
    ret, flag = alu(0x05, 0xf9, Flag(get_flag(c=0)), 'adc')
    assert ret == 0xfe and flag.data == get_flag(n=1, v=0, z=0, c=0)
    ret, flag = alu(0xfb, 0xf9, Flag(get_flag(c=0)), 'adc')
    assert ret == 0xf4 and flag.data == get_flag(n=1, v=0, z=0, c=1)
    ret, flag = alu(0xbe, 0xbf, Flag(get_flag(c=0)), 'adc')
    assert ret == 0x7d and flag.data == get_flag(n=0, v=1, z=0, c=1)

def test_sbc():
    alu = ALU()
    ret, flag = alu(0x05, 0x03, Flag(get_flag()), 'sbc')
    assert ret == 0x02 and flag.data == get_flag(n=0, v=0, z=0, c=1)
    ret, flag = alu(0x05, 0x06, Flag(get_flag()), 'sbc')
    assert ret == 0xff and flag.data == get_flag(n=1, v=0, z=0, c=0)

if __name__ == '__main__':
    test_tha()
    test_inc()
    test_dec()
    test_asl()
    test_lsr()
    test_rol()
    test_ror()
    test_and()
    test_ora()
    test_eor()
    test_bit()
    test_cmp()
    test_adc()
    test_sbc()
