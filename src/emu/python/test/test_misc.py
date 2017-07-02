from test_common import *


def test_PHA(mode):
    if mode == 'impl':
        imem = set_mem([0x48])
        tmem = set_mem([0x48], {0x01ff: 0x77})
        ireg = set_reg(pc=0x0000, a=0x77, s=0xff)
        treg = set_reg(pc=0x0001+1, a=0x77, s=0xfe)
        oreg, omem = test_body(imem, ireg, 3)
    return treg == oreg and tmem == omem

def test_PHP(mode):
    if mode == 'impl':
        imem = set_mem([0x08])
        tmem = set_mem([0x08], {0x01ff: 0x77})
        ireg = set_reg(pc=0x0000, p=0x77, s=0xff)
        treg = set_reg(pc=0x0001+1, p=0x77, s=0xfe)
        oreg, omem = test_body(imem, ireg, 3)
    return treg == oreg and tmem == omem

def test_PLA(mode):
    if mode == 'impl':
        imem = set_mem([0x68], {0x01ff: 0x77})
        tmem = set_mem([0x68], {0x01ff: 0x77})
        ireg = set_reg(pc=0x0000, s=0xfe)
        treg = set_reg(pc=0x0001+1, a=0x77, s=0xff)
        oreg, omem = test_body(imem, ireg, 4)
    return treg == oreg and tmem == omem

def test_PLP(mode):
    if mode == 'impl':
        imem = set_mem([0x28], {0x01ff: 0x77})
        tmem = set_mem([0x28], {0x01ff: 0x77})
        ireg = set_reg(pc=0x0000, s=0xfe)
        treg = set_reg(pc=0x0001+1, p=0x77, s=0xff)
        oreg, omem = test_body(imem, ireg, 4)
    return treg == oreg and tmem == omem

def test_JSR(mode):
    if mode == 'impl':
        imem = set_mem([], {0x3366: 0x20, 0x3367: 0x55, 0x3368: 0x22,
                            0x2255: 0xea})
        tmem = set_mem([], {0x3366: 0x20, 0x3367: 0x55, 0x3368: 0x22,
                            0x2255: 0xea, 0x01ff: 0x33, 0x01fe: 0x68})
        ireg = set_reg(pc=0x3366, s=0xff)
        treg = set_reg(pc=0x2255+1, s=0xfd)
        oreg, omem = test_body(imem, ireg, 6)
    return treg == oreg and tmem == omem

def test_BRK(mode):
    if mode == 'impl':
        imem = set_mem([], {0x3366: 0x00, 0xfffe: 0x55, 0xffff: 0x22,
                            0x2255: 0xea})
        tmem = set_mem([], {0x3366: 0x00, 0xfffe: 0x55, 0xffff: 0x22,
                            0x2255: 0xea, 0x01ff: 0x33, 0x01fe: 0x67, 0x01fd: 0x80})
        ireg = set_reg(pc=0x3366, p=0x80, s=0xff)
        treg = set_reg(pc=0x2255+1, p=0x80, s=0xfc)
        oreg, omem = test_body(imem, ireg, 7)
    return treg == oreg and tmem == omem

def test_RTI(mode):
    if mode == 'impl':
        imem = set_mem([0x40], {0x01ff: 0x22, 0x01fe: 0x55, 0x01fd: 0x80, 0x2255: 0xea})
        tmem = set_mem([0x40], {0x01ff: 0x22, 0x01fe: 0x55, 0x01fd: 0x80, 0x2255: 0xea})
        ireg = set_reg(pc=0x0000, s=0xfc)
        treg = set_reg(pc=0x2255+1, p=0x80, s=0xff)
        oreg, omem = test_body(imem, ireg, 6)
    return treg == oreg and tmem == omem

def test_RTS(mode):
    if mode == 'impl':
        imem = set_mem([0x60], {0x01ff: 0x22, 0x01fe: 0x54, 0x2255: 0xea})
        tmem = set_mem([0x60], {0x01ff: 0x22, 0x01fe: 0x54, 0x2255: 0xea})
        ireg = set_reg(pc=0x0000, s=0xfd)
        treg = set_reg(pc=0x2255+1, s=0xff)
        oreg, omem = test_body(imem, ireg, 6)
    return treg == oreg and tmem == omem

def test_JMP(mode):
    if mode == 'abs':
        imem = set_mem([0x4c, 0x55, 0x22], {0x2255: 0xea})
        tmem = set_mem([0x4c, 0x55, 0x22], {0x2255: 0xea})
        ireg = set_reg(pc=0x0000)
        treg = set_reg(pc=0x2255+1)
        oreg, omem = test_body(imem, ireg, 3)
    elif mode == 'ind':
        imem = set_mem([0x6c, 0x44, 0x11], {0x1144: 0x55, 0x1145: 0x22, 0x2255: 0xea})
        tmem = set_mem([0x6c, 0x44, 0x11], {0x1144: 0x55, 0x1145: 0x22, 0x2255: 0xea})
        ireg = set_reg(pc=0x0000)
        treg = set_reg(pc=0x2255+1)
        oreg, omem = test_body(imem, ireg, 5)
    return treg == oreg and tmem == omem

def _test_branch(mode, opcode, flag_t, flag_f):
    if mode == 't1':
        imem = set_mem([opcode, 0x53], {0x0055: 0xea})
        tmem = set_mem([opcode, 0x53], {0x0055: 0xea})
        ireg = set_reg(pc=0x0000, p=flag_f)
        treg = set_reg(pc=0x0002+1, p=flag_f)
        oreg, omem = test_body(imem, ireg, 2)
    if mode == 't2':
        imem = set_mem([opcode, 0x53], {0x0055: 0xea})
        tmem = set_mem([opcode, 0x53], {0x0055: 0xea})
        ireg = set_reg(pc=0x0000, p=flag_t)
        treg = set_reg(pc=0x0055+1, p=flag_t)
        oreg, omem = test_body(imem, ireg, 3)
    if mode == 't3':
        imem = set_mem([], {0x0040: opcode, 0x0041: 0xe0, 0x0122: 0xea})
        tmem = set_mem([], {0x0040: opcode, 0x0041: 0xe0, 0x0122: 0xea})
        ireg = set_reg(pc=0x0040, p=flag_t)
        treg = set_reg(pc=0x0122+1, p=flag_t)
        oreg, omem = test_body(imem, ireg, 4)
    return treg == oreg and tmem == omem

def _test_set_branch(mode):
    assert _test_branch(mode, 0x90, 0x00, 0x01)
    assert _test_branch(mode, 0xb0, 0x01, 0x00)
    assert _test_branch(mode, 0xd0, 0x00, 0x02)
    assert _test_branch(mode, 0xf0, 0x02, 0x00)
    assert _test_branch(mode, 0x50, 0x00, 0x40)
    assert _test_branch(mode, 0x70, 0x40, 0x00)
    assert _test_branch(mode, 0x10, 0x00, 0x80)
    assert _test_branch(mode, 0x30, 0x80, 0x00)

def _test_set_MISC(mode):
    assert test_PHA(mode)
    assert test_PHP(mode)
    assert test_PLA(mode)
    assert test_PLP(mode)
    assert test_JSR(mode)
    assert test_BRK(mode)
    assert test_RTI(mode)
    assert test_RTS(mode)

def test_set_MISC():
    _test_set_MISC('impl')
    assert test_JMP('abs')
    assert test_JMP('ind')
    _test_set_branch('t1')
    _test_set_branch('t2')
    _test_set_branch('t3')
