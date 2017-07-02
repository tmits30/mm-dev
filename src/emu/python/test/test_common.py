import os, sys
sys.path.append(os.path.abspath(
    os.path.join(os.path.dirname(__file__), os.path.pardir)))

from mc6502.memory import Memory
from mc6502.mpu import MPU


def set_mem(instr, mem_dict={}, size=0xffff):
    ret = [0 for _ in range(size + 1)]
    for i, ir in enumerate(instr):
        ret[i] = ir
    for addr, data in mem_dict.items():
        ret[addr] = data
    return ret

def set_reg(pc=0x0000, a=0x00, x=0x00, y=0x00, s=0xff, p=0x00):
    return {'pc': pc, 'a': a, 'x': x, 'y': y, 's': s, 'p': p}

def load_reg(mpu, reg):
    mpu.datapath.pcl.data = reg['pc'] & 0x00ff
    mpu.datapath.pch.data = (reg['pc'] & 0xff00) >> 8
    mpu.datapath.abl.data = mpu.datapath.pcl.data
    mpu.datapath.abh.data = mpu.datapath.pch.data
    mpu.datapath.a.data = reg['a']
    mpu.datapath.x.data = reg['x']
    mpu.datapath.y.data = reg['y']
    mpu.datapath.s.data = reg['s']
    mpu.datapath.p.data = reg['p']

def save_reg(mpu):
    return {
        'pc': mpu.datapath.pc,
        'a': mpu.datapath.a.data,
        'x': mpu.datapath.x.data,
        'y': mpu.datapath.y.data,
        's': mpu.datapath.s.data,
        'p': mpu.datapath.p.data,
    }

def save_mem(mem):
    return mem._data

def test_body(mem, reg, clk):
    mem = Memory(mem)
    mpu = MPU()
    load_reg(mpu, reg)
    for c in range(clk + 1):
        data, addr = mpu(mem(mpu.address))
        mem(addr, data, mpu.r_w == 'w')
    return save_reg(mpu), save_mem(mem)
