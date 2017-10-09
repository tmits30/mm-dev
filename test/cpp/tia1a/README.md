# Test for TIA-1A


## Run test

Run all test patterns.

```shell-session
$ make
```


## YAML test format

```yaml
- target: VSYNC
  tests:
    - comment: VSYNC
      cycle: 3
      initial:
        reg: {
          VSYNC: 0x0, VBLANK: 0x0, NUSIZ0: 0x0, NUSIZ1: 0x0,
          COLUP0: 0x0, COLUP1: 0x0, COLUPF: 0x0, COLUBK: 0x0, CTRLPF: 0x0,
          REFP0: 0x0, REFP1: 0x0, PF0: 0x0, PF1: 0x0, PF2: 0x0,
          GRP0: 0x0, GRP1: 0x0, GRP0D: 0x0, GRP1D: 0x0,
          ENAM0: 0x0, ENAM1: 0x0, ENABL: 0x0, ENABLD: 0x0,
          HMP0: 0x0, HMP1: 0x0, HMM0: 0x0, HMM1: 0x0, HMBL: 0x0,
          POSP0: 0x0, POSP1: 0x0, POSM0: 0x0, POSM1: 0x0, POSBL: 0x0,
          VDELP0: 0x0, VDELP1: 0x0, VDELBL: 0x0,
          RESMP0: 0x0, RESMP1: 0x0, CXCLR: 0x0, CXR: 0x0
        }
      inputs:
        - clock: 0
          in: { DEL: 0x0, R_W: 0x0, CS: 0x1, A: 0x0, I: 0x0, D_IN: 0x2 }
      expected:
        reg: {
          VSYNC: 0x0, VBLANK: 0x0, NUSIZ0: 0x0, NUSIZ1: 0x0,
          COLUP0: 0x0, COLUP1: 0x0, COLUPF: 0x0, COLUBK: 0x0, CTRLPF: 0x0,
          REFP0: 0x0, REFP1: 0x0, PF0: 0x0, PF1: 0x0, PF2: 0x0,
          GRP0: 0x0, GRP1: 0x0, GRP0D: 0x0, GRP1D: 0x0,
          ENAM0: 0x0, ENAM1: 0x0, ENABL: 0x0, ENABLD: 0x0,
          HMP0: 0x0, HMP1: 0x0, HMM0: 0x0, HMM1: 0x0, HMBL: 0x0,
          POSP0: 0x0, POSP1: 0x0, POSM0: 0x0, POSM1: 0x0, POSBL: 0x0,
          VDELP0: 0x0, VDELP1: 0x0, VDELBL: 0x0,
          RESMP0: 0x0, RESMP1: 0x0, CXCLR: 0x0, CXR: 0x0
        }
        out: {
          RDY: 0x1, HSYNC: 0x0, HBLANK: 0x1, VSYNC: 0x1, VBLANK: 0x0,
          LUM: 0x0, COL: 0x0, AUD: 0x0, D_OUT: 0x0
        }
```


## TIAsm

TIAsm is test description language for mm-dev TIA-1A module.
We can write TIA commands in suitable timing by screen coordinate and number screens like the following code.

```
# test.tiasm
#   t    y    x    command   value
    0    0    0    COLUBK    0x90 # background is dark blue
    0    0    3    COLUP1    0x4e # player1 color is pink
    0    0    6    NUSIZ1    0x05 # player1 charactor is double size (16x16)
    0    0    148  RESP1          # player1 charactor appears center of screen
    0    0    151  VSYNC          # reset input command for test description...

    # draw a player1 fighter between 80 and 96 scanlines
    # first 40 scanlines of each frame are vertical sync and vertical blank
    0    80   0    GRP1      0b00011000
    0    82   0    GRP1      0b00011000
    0    84   0    GRP1      0b10011001
    0    86   0    GRP1      0b10111101
    0    88   0    GRP1      0b10111101
    0    90   0    GRP1      0b11111111
    0    92   0    GRP1      0b11111111
    0    94   0    GRP1      0b10100101
    0    96   0    GRP1      0b00000000
```

TIAsm file is converted to YAML test format by `tiasm.py`.

```shell-session
$ python ./tiasm.py test.tiasm > sim_tiasm.yml
```

Run the test with Verilator program `obj_dir/Vtia1a`.
This test program outputs the screen binary file for converted TIAsm.

```shell-session
$ ./obj_dir/Vtia1a
$ ls test.bin
test.bin
```

Screen binary file are converted to PNG image by `bin2img.py`.

```shell-session
$ python ./bin2img.py test.bin
$ display test_0.png
```

![test_0.png](https://raw.githubusercontent.com/tmits30/mm-dev/tia/test/cpp/tia1a/test_0.png)
