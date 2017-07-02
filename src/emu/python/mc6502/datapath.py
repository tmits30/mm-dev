from mc6502.alu import ALU
from mc6502.flag import Flag


class Register(object):

    def __init__(self, data=0x00):
        self.data = data

    def __call__(self, data, we=True):
        assert 0x00 <= data <= 0xff, \
            'out of range byte data %s' % hex(data)
        if we:
            self.data = data

    def __str__(self):
        return 'Register {}'.format(hex(self.data))


class PCAdder(object):

    def __init__(self):
        self.carry = 0

    def __call__(self, pcl, pch, src, control='nop'):
        if control == 'inc':
            if pcl == 0xff:
                pcl = 0x00
                if pch == 0xff:
                    pch = 0x00
                else:
                    pch += 0x01
            else:
                pcl += 0x01
        elif control == 'add':
            dst = pcl + 1 + src
            pcl = dst & 0xff
            self.carry = int(dst > 0xff)
        elif control == 'cadd':
            pch += self.carry
            self.carry = 0
        return pcl, pch


class Datapath(object):

    def __init__(self):
        # Address Bus
        self.abl = Register()
        self.abh = Register()

        # Data buffer
        self.db = Register()  # Data Bus Buffer
        self.dl = Register()  # Input Data Latch

        # Instruction Register
        self.ir = Register()

        # Program Counter
        self.pcl = Register()
        self.pch = Register()

        # Registers
        self.a = Register(0x77) # Accumulator
        self.x = Register(0x77) # Index X Register
        self.y = Register(0x77) # Index Y Register
        self.s = Register(0xff) # Stack Point Register
        self.t = Register(0x77) # Temporary Register, Not show in manual
        self.p = Register(0x00) # Processor Status Registe

        # ALU
        self.alu = ALU()
        self._alu_out = 0 # for debug

        # Adder for PC
        self.pcadder = PCAdder()

    @property
    def ab(self):
        return (self.abh.data << 8) | self.abl.data

    @property
    def pc(self):
        return (self.pch.data << 8) | self.pcl.data

    @property
    def flag(self):
        return Flag(self.p.data)

    def __str__(self):
        fmt = [
            'PC=0x{:04x}'.format(self.pc),
            'AB=0x{:04x}'.format(self.ab),
            'DB=0x{:02x}'.format(self.db.data),
            'A=0x{:02x}'.format(self.a.data),
            'X=0x{:02x}'.format(self.x.data),
            'Y=0x{:02x}'.format(self.y.data),
            'S=0x{:02x}'.format(self.s.data),
            'P=0x{:02x}'.format(self.p.data),
            'T=0x{:02x}'.format(self.t.data),
            'ALUOut=0x{:02x}'.format(self._alu_out),
        ]
        return ' '.join(fmt)

    def __call__(self, data, controller, dbe=True):
        # Data Bus
        db_src = {
            'm': data,
            'a': self.a.data,
            'x': self.x.data,
            'y': self.y.data,
            't': self.t.data,
            'p': self.p.data,
            'pcl': self.pcl.data,
            'pch': self.pch.data,
        }.get(controller.db_src, None)
        if dbe:
            self.db(db_src)
        self.dl(self.db.data, controller.dl_we)

        # Instruction Register
        self.ir(data, controller.ir_we)

        # Program Counter Increment/Add
        pcl_add, pch_add = self.pcadder(
            self.pcl.data, self.pch.data, data, controller.pcadder_ctrl)

        # Program Counter
        pcl_src = {
            'm': self.dl.data,
            't': self.t.data,
            'padr': pcl_add,
        }.get(controller.pcl_src, None)
        self.pcl(pcl_src, controller.pcl_we)

        pch_src = {
            'm': self.dl.data,
            'padr': pch_add,
        }.get(controller.pch_src, None)
        self.pch(pch_src, controller.pch_we)

        # ALU
        alu_src_a = {
            'a': self.a.data,
            'x': self.x.data,
            'y': self.y.data,
            's': self.s.data,
            't': self.t.data,
        }.get(controller.alu_src_a, 0x00)

        alu_src_b = {
            'm': self.dl.data,
            't': self.t.data,
        }.get(controller.alu_src_b, 0x00)

        alu_out, flag_alu = self.alu(
            alu_src_a, alu_src_b, Flag(self.p.data), controller.alu_ctrl)
        self._alu_out = alu_out # for debug

        # Registers
        reg_src = {
            'm': self.dl.data,
            'alu': alu_out,
        }.get(controller.reg_src, None)
        self.a(reg_src, controller.a_we) # Accumulator
        self.x(reg_src, controller.x_we) # Index X Register
        self.y(reg_src, controller.y_we) # Index Y Register
        self.s(reg_src, controller.s_we) # Stack Point Register
        self.t(reg_src, controller.t_we) # Temporary Register

        # Processor Status Register
        p_src = {
            'm': self.dl.data,
            'set': self.p.data | controller.p_mask,
            'clr': self.p.data & ~controller.p_mask,
            'alu': flag_alu.data,
        }.get(controller.p_src, self.p.data)
        self.p(p_src, True)

        # Address Bus
        str_ab = self.ab

        abl_src = {
            'm': self.dl.data,
            's': self.s.data,
            't': self.t.data,
            'pcl': self.pcl.data,
            'alu': alu_out,
            'fe': 0xfe,
            'ff': 0xff,
        }.get(controller.abl_src, None)
        self.abl(abl_src, controller.abl_we)

        abh_src = {
            'm': self.dl.data,
            'pch': self.pch.data,
            'alu': alu_out,
            '0': 0x00,
            '1': 0x01,
            'ff': 0xff,
        }.get(controller.abh_src, None)
        self.abh(abh_src, controller.abh_we)

        return self.db.data, str_ab if controller.r_w == 'w' else self.ab
