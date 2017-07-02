class Memory(object):

    def __init__(self, data=None, filename=None, size=0xffff):
        self._data = [0 for _ in range(size + 1)]
        if data:
            for i, d in enumerate(data):
                self._data[i] = d
        if filename:
            with open(filename, 'r') as f:
                pc = 0
                for row in f:
                    if row[0] == '#':
                        continue
                    row = row.replace('\n', '').split(' ')
                    for byte in row:
                        assert pc < size
                        self._data[pc] = int(byte, 16)
                        pc += 1

    def __call__(self, address, data=None, we=False):
        if data and we:
            assert 0x00 <= data < 0x100, \
                'data: 0x{:x} address: 0x{:x}'.format(data, address)
            self._data[address] = data
        return self._data[address]
