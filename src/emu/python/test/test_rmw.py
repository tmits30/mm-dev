from test_common import *


def test_DEC(mode):
    if mode == 'zpg':
        imem = set_mem([0xc6, 0x55], {0x0055: 0x77})
        tmem = set_mem([0xc6, 0x55], {0x0055: 0x76})
        ireg = set_reg(pc=0x0000)
        treg = set_reg(pc=0x0002+1)
        oreg, omem = test_body(imem, ireg, 5)
    elif mode == 'zpgx':
        imem = set_mem([0xd6, 0x44], {0x0055: 0x77})
        tmem = set_mem([0xd6, 0x44], {0x0055: 0x76})
        ireg = set_reg(pc=0x0000, x=0x11)
        treg = set_reg(pc=0x0002+1, x=0x11)
        oreg, omem = test_body(imem, ireg, 6)
    elif mode == 'abs':
        imem = set_mem([0xce, 0x55, 0x22], {0x2255: 0x77})
        tmem = set_mem([0xce, 0x55, 0x22], {0x2255: 0x76})
        ireg = set_reg(pc=0x0000)
        treg = set_reg(pc=0x0003+1)
        oreg, omem = test_body(imem, ireg, 6)
    elif mode == 'absx':
        imem = set_mem([0xde, 0x44, 0x22], {0x2255: 0x77})
        tmem = set_mem([0xde, 0x44, 0x22], {0x2255: 0x76})
        ireg = set_reg(pc=0x0000, x=0x11)
        treg = set_reg(pc=0x0003+1, x=0x11)
        oreg, omem = test_body(imem, ireg, 7)
    return treg == oreg and tmem == omem

def test_INC(mode):
    if mode == 'zpg':
        imem = set_mem([0xe6, 0x55], {0x0055: 0x77})
        tmem = set_mem([0xe6, 0x55], {0x0055: 0x78})
        ireg = set_reg(pc=0x0000)
        treg = set_reg(pc=0x0002+1)
        oreg, omem = test_body(imem, ireg, 5)
    elif mode == 'zpgx':
        imem = set_mem([0xf6, 0x44], {0x0055: 0x77})
        tmem = set_mem([0xf6, 0x44], {0x0055: 0x78})
        ireg = set_reg(pc=0x0000, x=0x11)
        treg = set_reg(pc=0x0002+1, x=0x11)
        oreg, omem = test_body(imem, ireg, 6)
    elif mode == 'abs':
        imem = set_mem([0xee, 0x55, 0x22], {0x2255: 0x77})
        tmem = set_mem([0xee, 0x55, 0x22], {0x2255: 0x78})
        ireg = set_reg(pc=0x0000)
        treg = set_reg(pc=0x0003+1)
        oreg, omem = test_body(imem, ireg, 6)
    elif mode == 'absx':
        imem = set_mem([0xfe, 0x44, 0x22], {0x2255: 0x77})
        tmem = set_mem([0xfe, 0x44, 0x22], {0x2255: 0x78})
        ireg = set_reg(pc=0x0000, x=0x11)
        treg = set_reg(pc=0x0003+1, x=0x11)
        oreg, omem = test_body(imem, ireg, 7)
    return treg == oreg and tmem == omem

def _test_set_RMW(mode):
    assert test_DEC(mode)
    assert test_INC(mode)

def test_set_RMW():
    _test_set_RMW('zpg')
    _test_set_RMW('zpgx')
    _test_set_RMW('abs')
    _test_set_RMW('absx')
