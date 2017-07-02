from mc6502.controller import Controller
from mc6502.datapath import Datapath


class MPU(object):

    def __init__(self):
        self.controller = Controller()
        self.datapath = Datapath()

    @property
    def address(self):
        return self.datapath.ab

    @property
    def r_w(self):
        return self.controller.r_w

    def __call__(self, data, dbe=True, rdy=True,
                 res_n=True, irq_n=True, nmi_n=True):
        flag = self.datapath.flag
        flag['PCC'] = self.datapath.pcadder.carry
        self.controller(self.datapath.ir.data, flag,
                        rdy=rdy, res_n=res_n, irq_n=irq_n, nmi_n=nmi_n)
        data, addr = self.datapath(data, self.controller, dbe=dbe)
        return data, addr
