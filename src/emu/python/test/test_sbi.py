from test_common import *


def test_NOP(mode):
    ret = None
    if mode == 'impl':
        imem = [0xea]
        ireg = set_reg(pc=0x0000)
        treg = set_reg(pc=0x0001+1)
        oreg, _ = test_body(imem, ireg, 2)
    return treg == oreg

def test_SEC(mode):
    ret = None
    if mode == 'impl':
        imem = [0x38]
        ireg = set_reg(pc=0x0000)
        treg = set_reg(pc=0x0001+1, p=0x01)
        oreg, _ = test_body(imem, ireg, 2)
    return treg == oreg

def test_SED(mode):
    ret = None
    if mode == 'impl':
        imem = [0xf8]
        ireg = set_reg(pc=0x0000)
        treg = set_reg(pc=0x0001+1, p=0x08)
        oreg, _ = test_body(imem, ireg, 2)
    return treg == oreg

def test_SEI(mode):
    ret = None
    if mode == 'impl':
        imem = [0x78]
        ireg = set_reg(pc=0x0000)
        treg = set_reg(pc=0x0001+1, p=0x04)
        oreg, _ = test_body(imem, ireg, 2)
    return treg == oreg

def test_CLC(mode):
    ret = None
    if mode == 'impl':
        imem = [0x18]
        ireg = set_reg(pc=0x0000, p=0x01)
        treg = set_reg(pc=0x0001+1, p=0x00)
        oreg, _ = test_body(imem, ireg, 2)
    return treg == oreg

def test_CLD(mode):
    ret = None
    if mode == 'impl':
        imem = [0xd8]
        ireg = set_reg(pc=0x0000, p=0x08)
        treg = set_reg(pc=0x0001+1, p=0x00)
        oreg, _ = test_body(imem, ireg, 2)
    return treg == oreg

def test_CLI(mode):
    ret = None
    if mode == 'impl':
        imem = [0x58]
        ireg = set_reg(pc=0x0000, p=0x04)
        treg = set_reg(pc=0x0001+1, p=0x00)
        oreg, _ = test_body(imem, ireg, 2)
    return treg == oreg

def test_CLV(mode):
    ret = None
    if mode == 'impl':
        imem = [0xb8]
        ireg = set_reg(pc=0x0000, p=0x40)
        treg = set_reg(pc=0x0001+1, p=0x00)
        oreg, _ = test_body(imem, ireg, 2)
    return treg == oreg

def test_TAX(mode):
    ret = None
    if mode == 'impl':
        imem = [0xaa]
        ireg = set_reg(pc=0x0000, a=0x77)
        treg = set_reg(pc=0x0001+1, a=0x77, x=0x77)
        oreg, _ = test_body(imem, ireg, 2)
    return treg == oreg

def test_TAY(mode):
    ret = None
    if mode == 'impl':
        imem = [0xa8]
        ireg = set_reg(pc=0x0000, a=0x77)
        treg = set_reg(pc=0x0001+1, a=0x77, y=0x77)
        oreg, _ = test_body(imem, ireg, 2)
    return treg == oreg

def test_TSX(mode):
    ret = None
    if mode == 'impl':
        imem = [0xba]
        ireg = set_reg(pc=0x0000, s=0x77)
        treg = set_reg(pc=0x0001+1, s=0x77, x=0x77)
        oreg, _ = test_body(imem, ireg, 2)
    return treg == oreg

def test_TXA(mode):
    ret = None
    if mode == 'impl':
        imem = [0x8a]
        ireg = set_reg(pc=0x0000, x=0x77)
        treg = set_reg(pc=0x0001+1, x=0x77, a=0x77)
        oreg, _ = test_body(imem, ireg, 2)
    return treg == oreg

def test_TXS(mode):
    ret = None
    if mode == 'impl':
        imem = [0x9a]
        ireg = set_reg(pc=0x0000, x=0x77)
        treg = set_reg(pc=0x0001+1, x=0x77, s=0x77)
        oreg, _ = test_body(imem, ireg, 2)
    return treg == oreg

def test_TYA(mode):
    ret = None
    if mode == 'impl':
        imem = [0x98]
        ireg = set_reg(pc=0x0000, y=0x77)
        treg = set_reg(pc=0x0001+1, y=0x77, a=0x77)
        oreg, _ = test_body(imem, ireg, 2)
    return treg == oreg

def test_DEX(mode):
    ret = None
    if mode == 'impl':
        imem = [0xca]
        ireg = set_reg(pc=0x0000, x=0x77)
        treg = set_reg(pc=0x0001+1, x=0x76)
        oreg, _ = test_body(imem, ireg, 2)
    return treg == oreg

def test_DEY(mode):
    ret = None
    if mode == 'impl':
        imem = [0x88]
        ireg = set_reg(pc=0x0000, y=0x77)
        treg = set_reg(pc=0x0001+1, y=0x76)
        oreg, _ = test_body(imem, ireg, 2)
    return treg == oreg

def test_INX(mode):
    ret = None
    if mode == 'impl':
        imem = [0xe8]
        ireg = set_reg(pc=0x0000, x=0x77)
        treg = set_reg(pc=0x0001+1, x=0x78)
        oreg, _ = test_body(imem, ireg, 2)
    return treg == oreg

def test_INY(mode):
    ret = None
    if mode == 'impl':
        imem = [0xc8]
        ireg = set_reg(pc=0x0000, y=0x77)
        treg = set_reg(pc=0x0001+1, y=0x78)
        oreg, _ = test_body(imem, ireg, 2)
    return treg == oreg

def test_set_SBI():
    assert test_NOP('impl')
    assert test_SEC('impl')
    assert test_SED('impl')
    assert test_SEI('impl')
    assert test_CLC('impl')
    assert test_CLD('impl')
    assert test_CLI('impl')
    assert test_CLV('impl')
    assert test_TAX('impl')
    assert test_TAY('impl')
    assert test_TSX('impl')
    assert test_TXA('impl')
    assert test_TXS('impl')
    assert test_TYA('impl')
    assert test_DEX('impl')
    assert test_DEY('impl')
    assert test_INX('impl')
    assert test_INY('impl')
