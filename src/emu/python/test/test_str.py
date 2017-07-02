from test_common import *


def test_STA(mode):
    if mode == 'zpg':
        imem = set_mem([0x85, 0x55])
        tmem = set_mem([0x85, 0x55], {0x0055: 0x77})
        ireg = set_reg(pc=0x0000, a=0x77)
        treg = set_reg(pc=0x0002+1, a=0x77)
        oreg, omem = test_body(imem, ireg, 3)
    elif mode == 'zpgx':
        imem = set_mem([0x95, 0x44])
        tmem = set_mem([0x95, 0x44], {0x0055: 0x77})
        ireg = set_reg(pc=0x0000, a=0x77, x=0x11)
        treg = set_reg(pc=0x0002+1, a=0x77, x=0x11)
        oreg, omem = test_body(imem, ireg, 4)
    elif mode == 'abs':
        imem = set_mem([0x8d, 0x55, 0x22])
        tmem = set_mem([0x8d, 0x55, 0x22], {0x2255: 0x77})
        ireg = set_reg(pc=0x0000, a=0x77)
        treg = set_reg(pc=0x0003+1, a=0x77)
        oreg, omem = test_body(imem, ireg, 4)
    elif mode == 'absx':
        imem = set_mem([0x9d, 0x44, 0x22])
        tmem = set_mem([0x9d, 0x44, 0x22], {0x2255: 0x77})
        ireg = set_reg(pc=0x0000, a=0x77, x=0x11)
        treg = set_reg(pc=0x0003+1, a=0x77, x=0x11)
        oreg, omem = test_body(imem, ireg, 5)
    elif mode == 'absy':
        imem = set_mem([0x99, 0x44, 0x22])
        tmem = set_mem([0x99, 0x44, 0x22], {0x2255: 0x77})
        ireg = set_reg(pc=0x0000, a=0x77, y=0x11)
        treg = set_reg(pc=0x0003+1, a=0x77, y=0x11)
        oreg, omem = test_body(imem, ireg, 5)
    elif mode == 'indx':
        imem = set_mem([0x81, 0x56], {0x0067: 0x55, 0x0068: 0x22})
        tmem = set_mem([0x81, 0x56], {0x0067: 0x55, 0x0068: 0x22, 0x2255: 0x77})
        ireg = set_reg(pc=0x0000, a=0x77, x=0x11)
        treg = set_reg(pc=0x0002+1, a=0x77, x=0x11)
        oreg, omem = test_body(imem, ireg, 6)
    elif mode == 'indy':
        imem = set_mem([0x91, 0x67], {0x0067: 0x44, 0x0068: 0x22})
        tmem = set_mem([0x91, 0x67], {0x0067: 0x44, 0x0068: 0x22, 0x2255: 0x77})
        ireg = set_reg(pc=0x0000, a=0x77, y=0x11)
        treg = set_reg(pc=0x0002+1, a=0x77, y=0x11)
        oreg, omem = test_body(imem, ireg, 6)
    return treg == oreg and tmem == omem

def test_STX(mode):
    if mode == 'zpg':
        imem = set_mem([0x86, 0x55])
        tmem = set_mem([0x86, 0x55], {0x0055: 0x77})
        ireg = set_reg(pc=0x0000, x=0x77)
        treg = set_reg(pc=0x0002+1, x=0x77)
        oreg, omem = test_body(imem, ireg, 3)
    elif mode == 'zpgy':
        imem = set_mem([0x96, 0x44])
        tmem = set_mem([0x96, 0x44], {0x0055: 0x77})
        ireg = set_reg(pc=0x0000, x=0x77, y=0x11)
        treg = set_reg(pc=0x0002+1, x=0x77, y=0x11)
        oreg, omem = test_body(imem, ireg, 4)
    elif mode == 'abs':
        imem = set_mem([0x8e, 0x55, 0x22])
        tmem = set_mem([0x8e, 0x55, 0x22], {0x2255: 0x77})
        ireg = set_reg(pc=0x0000, x=0x77)
        treg = set_reg(pc=0x0003+1, x=0x77)
        oreg, omem = test_body(imem, ireg, 4)
    return treg == oreg and tmem == omem

def test_STY(mode):
    if mode == 'zpg':
        imem = set_mem([0x84, 0x55])
        tmem = set_mem([0x84, 0x55], {0x0055: 0x77})
        ireg = set_reg(pc=0x0000, y=0x77)
        treg = set_reg(pc=0x0002+1, y=0x77)
        oreg, omem = test_body(imem, ireg, 3)
    elif mode == 'zpgx':
        imem = set_mem([0x94, 0x44])
        tmem = set_mem([0x94, 0x44], {0x0055: 0x77})
        ireg = set_reg(pc=0x0000, x=0x11, y=0x77)
        treg = set_reg(pc=0x0002+1, x=0x11, y=0x77)
        oreg, omem = test_body(imem, ireg, 4)
    elif mode == 'abs':
        imem = set_mem([0x8c, 0x55, 0x22])
        tmem = set_mem([0x8c, 0x55, 0x22], {0x2255: 0x77})
        ireg = set_reg(pc=0x0000, y=0x77)
        treg = set_reg(pc=0x0003+1, y=0x77)
        oreg, omem = test_body(imem, ireg, 4)
    return treg == oreg and tmem == omem

def _test_set_STR(mode):
    assert test_STA(mode)
    if not mode in ['zpgx', 'absx', 'absy', 'indx', 'indy']:
        assert test_STX(mode)
    if not mode in ['zpgy', 'absx', 'absy', 'indx', 'indy']:
        assert test_STY(mode)

def test_set_STR():
    _test_set_STR('zpg')
    _test_set_STR('zpgx')
    _test_set_STR('abs')
    _test_set_STR('absx')
    _test_set_STR('absy')
    _test_set_STR('indx')
    _test_set_STR('indy')
