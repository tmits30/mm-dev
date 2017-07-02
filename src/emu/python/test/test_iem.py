from test_common import *


def test_LDA(mode):
    if mode == 'imm':
        imem = set_mem([0xa9, 0x77])
        ireg = set_reg(pc=0x0000)
        treg = set_reg(pc=0x0002+1, a=0x77)
        oreg, _ = test_body(imem, ireg, 2)
    elif mode == 'zpg':
        imem = set_mem([0xa5, 0x55], {0x0055: 0x77})
        ireg = set_reg(pc=0x0000)
        treg = set_reg(pc=0x0002+1, a=0x77)
        oreg, _ = test_body(imem, ireg, 3)
    elif mode == 'zpgx':
        imem = set_mem([0xb5, 0x44], {0x0055: 0x77})
        ireg = set_reg(pc=0x0000, x=0x11)
        treg = set_reg(pc=0x0002+1, a=0x77, x=0x11)
        oreg, _ = test_body(imem, ireg, 4)
    elif mode == 'abs':
        imem = set_mem([0xad, 0x55, 0x22], {0x2255: 0x77})
        ireg = set_reg(pc=0x0000)
        treg = set_reg(pc=0x0003+1, a=0x77)
        oreg, _ = test_body(imem, ireg, 4)
    elif mode == 'absx':
        imem = set_mem([0xbd, 0x44, 0x22], {0x2255: 0x77})
        ireg = set_reg(pc=0x0000, x=0x11)
        treg = set_reg(pc=0x0003+1, a=0x77, x=0x11)
        oreg, _ = test_body(imem, ireg, 4)
    elif mode == 'absx*':
        imem = set_mem([0xbd, 0xf0, 0x21], {0x2255: 0x77})
        ireg = set_reg(pc=0x0000, x=0x65)
        treg = set_reg(pc=0x0003+1, a=0x77, x=0x65)
        oreg, _ = test_body(imem, ireg, 5)
    elif mode == 'absy':
        imem = set_mem([0xb9, 0x44, 0x22], {0x2255: 0x77})
        ireg = set_reg(pc=0x0000, y=0x11)
        treg = set_reg(pc=0x0003+1, a=0x77, y=0x11)
        oreg, _ = test_body(imem, ireg, 4)
    elif mode == 'absy*':
        imem = set_mem([0xb9, 0xf0, 0x21], {0x2255: 0x77})
        ireg = set_reg(pc=0x0000, y=0x65)
        treg = set_reg(pc=0x0003+1, a=0x77, y=0x65)
        oreg, _ = test_body(imem, ireg, 5)
    elif mode == 'indx':
        imem = set_mem([0xa1, 0x56], {0x0067: 0x55, 0x0068: 0x22, 0x2255: 0x77})
        ireg = set_reg(pc=0x0000, x=0x11)
        treg = set_reg(pc=0x0002+1, a=0x77, x=0x11)
        oreg, _ = test_body(imem, ireg, 6)
    elif mode == 'indy':
        imem = set_mem([0xb1, 0x67], {0x0067: 0x44, 0x0068: 0x22, 0x2255: 0x77})
        ireg = set_reg(pc=0x0000, y=0x11)
        treg = set_reg(pc=0x0002+1, a=0x77, y=0x11)
        oreg, _ = test_body(imem, ireg, 5)
    elif mode == 'indy*':
        imem = set_mem([0xb1, 0x67], {0x0067: 0xf0, 0x0068: 0x21, 0x2255: 0x77})
        ireg = set_reg(pc=0x0000, y=0x65)
        treg = set_reg(pc=0x0002+1, a=0x77, y=0x65)
        oreg, _ = test_body(imem, ireg, 6)
    return treg == oreg

def test_LDX(mode):
    if mode == 'imm':
        imem = set_mem([0xa2, 0x77])
        ireg = set_reg(pc=0x0000)
        treg = set_reg(pc=0x0002+1, x=0x77)
        oreg, _ = test_body(imem, ireg, 2)
    elif mode == 'zpg':
        imem = set_mem([0xa6, 0x55], {0x0055: 0x77})
        ireg = set_reg(pc=0x0000)
        treg = set_reg(pc=0x0002+1, x=0x77)
        oreg, _ = test_body(imem, ireg, 3)
    elif mode == 'zpgy':
        imem = set_mem([0xb6, 0x44], {0x0055: 0x77})
        ireg = set_reg(pc=0x0000, y=0x11)
        treg = set_reg(pc=0x0002+1, x=0x77, y=0x11)
        oreg, _ = test_body(imem, ireg, 4)
    elif mode == 'abs':
        imem = set_mem([0xae, 0x55, 0x22], {0x2255: 0x77})
        ireg = set_reg(pc=0x0000)
        treg = set_reg(pc=0x0003+1, x=0x77)
        oreg, _ = test_body(imem, ireg, 4)
    elif mode == 'absy':
        imem = set_mem([0xbe, 0x44, 0x22], {0x2255: 0x77})
        ireg = set_reg(pc=0x0000, y=0x11)
        treg = set_reg(pc=0x0003+1, x=0x77, y=0x11)
        oreg, _ = test_body(imem, ireg, 4)
    elif mode == 'absy*':
        imem = set_mem([0xbe, 0xf0, 0x21], {0x2255: 0x77})
        ireg = set_reg(pc=0x0000, y=0x65)
        treg = set_reg(pc=0x0003+1, x=0x77, y=0x65)
        oreg, _ = test_body(imem, ireg, 5)
    return treg == oreg

def test_LDY(mode):
    if mode == 'imm':
        imem = set_mem([0xa0, 0x77])
        ireg = set_reg(pc=0x0000)
        treg = set_reg(pc=0x0002+1, y=0x77)
        oreg, _ = test_body(imem, ireg, 2)
    elif mode == 'zpg':
        imem = set_mem([0xa4, 0x55], {0x0055: 0x77})
        ireg = set_reg(pc=0x0000)
        treg = set_reg(pc=0x0002+1, y=0x77)
        oreg, _ = test_body(imem, ireg, 3)
    elif mode == 'zpgx':
        imem = set_mem([0xb4, 0x44], {0x0055: 0x77})
        ireg = set_reg(pc=0x0000, x=0x11)
        treg = set_reg(pc=0x0002+1, x=0x11, y=0x77)
        oreg, _ = test_body(imem, ireg, 4)
    elif mode == 'abs':
        imem = set_mem([0xac, 0x55, 0x22], {0x2255: 0x77})
        ireg = set_reg(pc=0x0000)
        treg = set_reg(pc=0x0003+1, y=0x77)
        oreg, _ = test_body(imem, ireg, 4)
    elif mode == 'absx':
        imem = set_mem([0xbc, 0x44, 0x22], {0x2255: 0x77})
        ireg = set_reg(pc=0x0000, x=0x11)
        treg = set_reg(pc=0x0003+1, x=0x11, y=0x77)
        oreg, _ = test_body(imem, ireg, 4)
    elif mode == 'absx*':
        imem = set_mem([0xbc, 0xf0, 0x21], {0x2255: 0x77})
        ireg = set_reg(pc=0x0000, x=0x65)
        treg = set_reg(pc=0x0003+1, x=0x65, y=0x77)
        oreg, _ = test_body(imem, ireg, 5)
    return treg == oreg

def test_ADC(mode):
    if mode == 'imm':
        imem = set_mem([0x69, 0x77])
        ireg = set_reg(pc=0x0000, a=0x11)
        treg = set_reg(pc=0x0002+1, a=0x88)
        oreg, _ = test_body(imem, ireg, 2)
    elif mode == 'zpg':
        imem = set_mem([0x65, 0x55], {0x0055: 0x77})
        ireg = set_reg(pc=0x0000, a=0x11)
        treg = set_reg(pc=0x0002+1, a=0x88)
        oreg, _ = test_body(imem, ireg, 3)
    elif mode == 'zpgx':
        imem = set_mem([0x75, 0x44], {0x0055: 0x77})
        ireg = set_reg(pc=0x0000, a=0x11, x=0x11)
        treg = set_reg(pc=0x0002+1, x=0x11, a=0x88)
        oreg, _ = test_body(imem, ireg, 4)
    elif mode == 'abs':
        imem = set_mem([0x6d, 0x55, 0x22], {0x2255: 0x77})
        ireg = set_reg(pc=0x0000, a=0x11)
        treg = set_reg(pc=0x0003+1, a=0x88)
        oreg, _ = test_body(imem, ireg, 4)
    elif mode == 'absx':
        imem = set_mem([0x7d, 0x44, 0x22], {0x2255: 0x77})
        ireg = set_reg(pc=0x0000, a=0x11, x=0x11)
        treg = set_reg(pc=0x0003+1, a=0x88, x=0x11)
        oreg, _ = test_body(imem, ireg, 4)
    elif mode == 'absx*':
        imem = set_mem([0x7d, 0xf0, 0x21], {0x2255: 0x77})
        ireg = set_reg(pc=0x0000, a=0x11, x=0x65)
        treg = set_reg(pc=0x0003+1, a=0x88, x=0x65)
        oreg, _ = test_body(imem, ireg, 5)
    elif mode == 'absy':
        imem = set_mem([0x79, 0x44, 0x22], {0x2255: 0x77})
        ireg = set_reg(pc=0x0000, a=0x11, y=0x11)
        treg = set_reg(pc=0x0003+1, a=0x88, y=0x11)
        oreg, _ = test_body(imem, ireg, 4)
    elif mode == 'absy*':
        imem = set_mem([0x79, 0xf0, 0x21], {0x2255: 0x77})
        ireg = set_reg(pc=0x0000, a=0x11, y=0x65)
        treg = set_reg(pc=0x0003+1, a=0x88, y=0x65)
        oreg, _ = test_body(imem, ireg, 5)
    elif mode == 'indx':
        imem = set_mem([0x61, 0x56], {0x0067: 0x55, 0x0068: 0x22, 0x2255: 0x77})
        ireg = set_reg(pc=0x0000, a=0x11, x=0x11)
        treg = set_reg(pc=0x0002+1, a=0x88, x=0x11)
        oreg, _ = test_body(imem, ireg, 6)
    elif mode == 'indy':
        imem = set_mem([0x71, 0x67], {0x0067: 0x44, 0x0068: 0x22, 0x2255: 0x77})
        ireg = set_reg(pc=0x0000, a=0x11, y=0x11)
        treg = set_reg(pc=0x0002+1, a=0x88, y=0x11)
        oreg, _ = test_body(imem, ireg, 5)
    elif mode == 'indy*':
        imem = set_mem([0x71, 0x67], {0x0067: 0xf0, 0x0068: 0x21, 0x2255: 0x77})
        ireg = set_reg(pc=0x0000, a=0x11, y=0x65)
        treg = set_reg(pc=0x0002+1, a=0x88, y=0x65)
        oreg, _ = test_body(imem, ireg, 6)
    return treg == oreg

def test_AND(mode):
    if mode == 'imm':
        imem = set_mem([0x29, 0x77])
        ireg = set_reg(pc=0x0000, a=0x18)
        treg = set_reg(pc=0x0002+1, a=0x10)
        oreg, _ = test_body(imem, ireg, 2)
    elif mode == 'zpg':
        imem = set_mem([0x25, 0x55], {0x0055: 0x77})
        ireg = set_reg(pc=0x0000, a=0x18)
        treg = set_reg(pc=0x0002+1, a=0x10)
        oreg, _ = test_body(imem, ireg, 3)
    elif mode == 'zpgx':
        imem = set_mem([0x35, 0x44], {0x0055: 0x77})
        ireg = set_reg(pc=0x0000, a=0x18, x=0x11)
        treg = set_reg(pc=0x0002+1, a=0x10, x=0x11)
        oreg, _ = test_body(imem, ireg, 4)
    elif mode == 'abs':
        imem = set_mem([0x2d, 0x55, 0x22], {0x2255: 0x77})
        ireg = set_reg(pc=0x0000, a=0x18)
        treg = set_reg(pc=0x0003+1, a=0x10)
        oreg, _ = test_body(imem, ireg, 4)
    elif mode == 'absx':
        imem = set_mem([0x3d, 0x44, 0x22], {0x2255: 0x77})
        ireg = set_reg(pc=0x0000, a=0x18, x=0x11)
        treg = set_reg(pc=0x0003+1, a=0x10, x=0x11)
        oreg, _ = test_body(imem, ireg, 4)
    elif mode == 'absx*':
        imem = set_mem([0x3d, 0xf0, 0x21], {0x2255: 0x77})
        ireg = set_reg(pc=0x0000, a=0x18, x=0x65)
        treg = set_reg(pc=0x0003+1, a=0x10, x=0x65)
        oreg, _ = test_body(imem, ireg, 5)
    elif mode == 'absy':
        imem = set_mem([0x39, 0x44, 0x22], {0x2255: 0x77})
        ireg = set_reg(pc=0x0000, a=0x18, y=0x11)
        treg = set_reg(pc=0x0003+1, a=0x10, y=0x11)
        oreg, _ = test_body(imem, ireg, 4)
    elif mode == 'absy*':
        imem = set_mem([0x39, 0xf0, 0x21], {0x2255: 0x77})
        ireg = set_reg(pc=0x0000, a=0x18, y=0x65)
        treg = set_reg(pc=0x0003+1, a=0x10, y=0x65)
        oreg, _ = test_body(imem, ireg, 5)
    elif mode == 'indx':
        imem = set_mem([0x21, 0x56], {0x0067: 0x55, 0x0068: 0x22, 0x2255: 0x77})
        ireg = set_reg(pc=0x0000, a=0x18, x=0x11)
        treg = set_reg(pc=0x0002+1, a=0x10, x=0x11)
        oreg, _ = test_body(imem, ireg, 6)
    elif mode == 'indy':
        imem = set_mem([0x31, 0x67], {0x0067: 0x44, 0x0068: 0x22, 0x2255: 0x77})
        ireg = set_reg(pc=0x0000, a=0x18, y=0x11)
        treg = set_reg(pc=0x0002+1, a=0x10, y=0x11)
        oreg, _ = test_body(imem, ireg, 5)
    elif mode == 'indy*':
        imem = set_mem([0x31, 0x67], {0x0067: 0xf0, 0x0068: 0x21, 0x2255: 0x77})
        ireg = set_reg(pc=0x0000, a=0x18, y=0x65)
        treg = set_reg(pc=0x0002+1, a=0x10, y=0x65)
        oreg, _ = test_body(imem, ireg, 6)
    return treg == oreg

def _test_set_IEM(mode):
    assert test_LDA(mode)
    if not mode in ['zpgx', 'absx', 'absx*', 'indx', 'indy', 'indy*']:
        assert test_LDX(mode)
    if not mode in ['zpgy', 'absy', 'absy*', 'indx', 'indy', 'indy*']:
        assert test_LDY(mode)
    # assert test_ADC(mode)
    assert test_AND(mode)

def test_set_IEM():
    _test_set_IEM('imm')
    _test_set_IEM('zpg')
    _test_set_IEM('zpgx')
    _test_set_IEM('abs')
    _test_set_IEM('absx')
    _test_set_IEM('absx*')
    _test_set_IEM('absy')
    _test_set_IEM('absy*')
    _test_set_IEM('indx')
    _test_set_IEM('indy')
    _test_set_IEM('indy*')
