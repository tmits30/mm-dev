#!/usr/bin/env python

import test_sbi
import test_iem
import test_str
import test_rmw
import test_misc


if __name__ == '__main__':
    test_sbi.test_set_SBI()
    test_iem.test_set_IEM()
    test_str.test_set_STR()
    test_rmw.test_set_RMW()
    test_misc.test_set_MISC()
