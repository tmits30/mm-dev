#!/usr/bin/env python

import csv
from collections import OrderedDict
import glob
import os
import string
import sys


class TIAssembler(object):

    _command_table = {
        # Return tuple (addr, r/w)
        # Write
        'VSYNC':  ('w', 0x00), # vertical sync set-clear
        'VBLANK': ('w', 0x01), # vertical blank set-clear
        'WSYNC':  ('w', 0x02), # wait for leading edge of horizontal blank
        'RSYNC':  ('w', 0x03), # reset horizontal sync counter
        'NUSIZ0': ('w', 0x04), # number-size player-missile 0
        'NUSIZ1': ('w', 0x05), # number-size player-missile 1
        'COLUP0': ('w', 0x06), # color-lum player 0
        'COLUP1': ('w', 0x07), # color-lum player 1
        'COLUPF': ('w', 0x08), # color-lum playfield
        'COLUBK': ('w', 0x09), # color-lum background
        'CTRLPF': ('w', 0x0a), # control playfield ball size & collisions
        'REFP0':  ('w', 0x0b), # reflect player 0
        'REFP1':  ('w', 0x0c), # reflect player 1
        'PF0':    ('w', 0x0d), # playfield register byte 0
        'PF1':    ('w', 0x0e), # playfield register byte 1
        'PF2':    ('w', 0x0f), # playfield register byte 2
        'RESP0':  ('w', 0x10), # reset player 0
        'RESP1':  ('w', 0x11), # reset player 1
        'RESM0':  ('w', 0x12), # reset missile 0
        'RESM1':  ('w', 0x13), # reset missile 1
        'RESBL':  ('w', 0x14), # reset ball
        'AUDC0':  ('w', 0x15), # audio control 0
        'AUDC1':  ('w', 0x16), # audio control 1
        'AUDF0':  ('w', 0x17), # audio frequency 0
        'AUDF1':  ('w', 0x18), # audio frequency 1
        'AUDV0':  ('w', 0x19), # audio volume 0
        'AUDV1':  ('w', 0x1a), # audio volume 1
        'GRP0':   ('w', 0x1b), # graphics player 0
        'GRP1':   ('w', 0x1c), # graphics player 1
        'ENAM0':  ('w', 0x1d), # graphics (enable), missile 0
        'ENAM1':  ('w', 0x1e), # graphics (enable), missile 1
        'ENABL':  ('w', 0x1f), # graphics (enable), ball
        'HMP0':   ('w', 0x20), # horizontal motion player 0
        'HMP1':   ('w', 0x21), # horizontal motion player 1
        'HMM0':   ('w', 0x22), # horizontal motion missile 0
        'HMM1':   ('w', 0x23), # horizontal motion missile 1
        'HMBL':   ('w', 0x24), # horizontal motion ball
        'VDELP0': ('w', 0x25), # vertical delay player 0
        'VDELP1': ('w', 0x26), # vertical delay player 1
        'VDELBL': ('w', 0x27), # vertical delay ball
        'RESMP0': ('w', 0x28), # reset missile 0 to player 0
        'RESMP1': ('w', 0x29), # reset missile 1 to player 1
        'HMOVE':  ('w', 0x2a), # apply horizontal motion
        'HMCLR':  ('w', 0x2b), # clear horizontal motion registers
        'CXCLR':  ('w', 0x2c), # clear collision latches
        # Read
        'CXM0P':  ('r', 0x00), # read collision M0-P1), M0-P0 (Bit 7, 6),
        'CXM1P':  ('r', 0x01), # read collision M1-P0), M1-P1
        'CXP0FB': ('r', 0x02), # read collision P0-PF), P0-BL
        'CXP1FB': ('r', 0x03), # read collision P1-PF), P1-BL
        'CXM0FB': ('r', 0x04), # read collision M0-PF), M0-BL
        'CXM1FB': ('r', 0x05), # read collision M1-PF), M1-BL
        'CXBLPF': ('r', 0x06), # read collision BL-PF), unused
        'CXPPMM': ('r', 0x07), # read collision P0-P1), M0-M1
        'INPT0':  ('r', 0x08), # read pot port
        'INPT1':  ('r', 0x09), # read pot port
        'INPT2':  ('r', 0x0a), # read pot port
        'INPT3':  ('r', 0x0b), # read pot port
        'INPT4':  ('r', 0x0c), # read input
        'INPT5':  ('r', 0x0d), # read input
    }

    def __init__(self, filename, width=228, height=262,
                 hblank=68, vsync=3, vblank=37, overscan=30):
        self.filename = filename

        self.width = width
        self.height = height
        self.hblank = hblank
        self.vsync = vsync
        self.vblank = vblank
        self.overscan = overscan

        code, expected = self.read(self.filename)
        self.code = code
        self.expected = expected
        self.asm = self.assemble(self.code)

    def read(self, filename):
        code, expected = [], {}
        with open(filename, 'r') as fh:
            rows = [r.split() for r in fh]
            for i, line in enumerate(rows):
                try:
                    row = line[:['#' in x for x in line].index(True)]
                except:
                    row = line

                if len(row) == 0:
                    continue

                if 'expected' in row[0]:
                    tag = row[1].replace(':', '').lower()
                    key = row[2].replace(':', '').upper()
                    value = eval(row[3])
                    value = value << 6 if 0 < value <= 3 else value
                    expected[key] = (tag, value)
                else:
                    if not len(row) in [4, 5]:
                        raise ValueError(
                            '{}: L{}: "{}" is different format.'.format(
                                filename, i, ' '.join(line)))
                    data = eval(row[4]) if len(row) > 4 else 0
                    code.append([int(x) for x in row[:3]] + [row[3], data])
        code = sorted(code, key=lambda x: self.get_clock(*x[:3]))
        return code, expected

    def get_clock(self, t, y, x):
        return self.height * self.width * t + self.width * y + x

    def assemble(self, code):
        asm = []
        for c in code:
            clock = self.get_clock(*c[:3])
            r_w , addr = self._command_table[c[3]]
            data = c[4] if len(c) > 4 else 0
            asm.append({
                'clock': clock,
                'r_w': r_w,
                'addr': addr,
                'data': data,
            })
        return asm

    def to_yaml(self):
        name = os.path.splitext(os.path.basename(self.filename))[0]
        yml_comment = name
        screen_name = name + '.bin'
        cycle = self.get_clock(self.code[-1][0], self.height, 0)

        # Input commands
        inputs = []
        for a, c in zip(self.asm, self.code):
            in_data = OrderedDict([
                ('DEL', 0),
                ('R_W', a['r_w'] == 'r'),
                ('CS', 1),
                ('A', a['addr']),
                ('I', 0),
                ('D_IN', a['data']),
            ])
            in_data = ', '.join(
                ['%s: 0x%02x' % (k, v) for k, v in in_data.items()])
            comment = ' '.join(str(x) for x in c)
            inputs.append('- clock: %d # %s' % (a['clock'], comment))
            inputs.append('  in: { %s }' % (in_data))
        inputs = ('\n' + ' ' * 8).join(inputs)

        # Expected register
        expected_reg, expected_out = [], []
        if self.expected:
            for key, (tag, value) in self.expected.items():
                if tag == 'reg':
                    expected_reg.append('%s: 0x%02x' % (key, value))
                elif tag == 'out':
                    expected_out.append('%s: 0x%02x' % (key, value))
        expected_reg = '{ ' + ', '.join(expected_reg) + ' }'
        expected_out = '{ ' + ', '.join(expected_out) + ' }'

        # YAML format
        yml_str = string.Template(
"""
- target: Screen
  tests:
    - comment: $comment
      screen_name: $screen_name
      cycle: $cycle
      initial:
        reg: {  }
      inputs:
        $inputs
      expected:
        reg: $expected_reg
        out: $expected_out
"""
        ).substitute(
            comment=yml_comment, screen_name=screen_name,
            cycle=cycle, inputs=inputs,
            expected_reg=expected_reg, expected_out=expected_out)
        return yml_str[1:-1] # remove head and foot new lines


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('usage: {} <tiasm-file>'.format(sys.argv[0]))
        quit()

    path = sys.argv[1]
    if os.path.isdir(path):
        fnames = glob.glob(os.path.join(path, '*.tiasm'))
    elif '.txt' in path:
        dname = os.path.dirname(path)
        with open(path, 'r') as fh:
            fnames = []
            for f in fh:
                if not '.tiasm' in f:
                    continue;
                fnames.append(os.path.join(dname, f.replace('\n', '')))
    else:
        fnames = sys.argv[1:]

    fnames = sorted(fnames)
    for fname in fnames:
        yml_str = TIAssembler(fname).to_yaml()
        print(yml_str)
