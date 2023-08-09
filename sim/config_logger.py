#!/usr/bin/env python3
#==============================================================================
# Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
# SPDX-License-Identifier: MIT
#
#==============================================================================

import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger('run_testcase')

def setLoggerLevel(str):
  if(str == 'debug'):
    logging.basicConfig(level=logging.DEBUG)