from collections import OrderedDict


class Flag(object):

    def __init__(self, data):
        self.flag = OrderedDict()
        for i, k in enumerate(['C', 'Z', 'I', 'D', 'B', '-', 'V', 'N']):
            self.flag[k] = (data >> i) & 0x01

    def __getitem__(self, key):
        return self.flag[key]

    def __setitem__(self, key, value):
        self.flag[key] = value != 0

    def __str__(self):
        return ' '.join(['{}={:d}'.format(k, v)
                         for k, v in reversed(self.flag.items())])

    @property
    def data(self):
        ret = [(v & 0x01) << i for i, v in enumerate(self.flag.values())]
        return reduce(lambda x, y: x | y, ret)
