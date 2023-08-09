# ==============================================================================
#  Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
#  SPDX-License-Identifier: MIT
# 
# ==============================================================================
#
# build_tcl.py
# -- The script is used to generate a build file with all required source files
#    including *.v, *.vp, *.sv, *.vhdl and *.xci
#
# ==============================================================================
#!/usr/bin/env python3

import os
import sys
import shutil
import logging
import argparse

# file type
VERILOG_EXT     = [".v", ".vp", ".sv",".xci"]
VHDL_EXT        = [".vhdl"]

skip_file_list_open_nic = []
skip_file_list_rdma_opennic = ["packet_matcher.sv"]
skip_file_list_hpce_nic = ["app_sub_system_wrapper.sv"]

root_dir = '.'
base_nic = ''

def collect_files(cwd, exts):
    result = []
    for path, subdir, files in os.walk(cwd):
        for f in files:
            if os.path.splitext(f)[1] in exts:
                if(base_nic == 'open-nic'):
                    if(not (f in skip_file_list_open_nic)):
                        result.append(os.path.join(path, f))
                elif (base_nic == 'hpce-nic'):
                    if(not (f in skip_file_list_hpce_nic)):
                        result.append(os.path.join(path, f))
                elif (base_nic == 'rdma-opennic'):
                    if(not (f in skip_file_list_rdma_opennic)):
                        result.append(os.path.join(path, f))
                else:
                    result.append(os.path.join(path, f))
    return result

def create_tcl(src_dir, tcl_path):

    verilog_files = collect_files(src_dir, VERILOG_EXT)
    vhdl_files = collect_files(src_dir, VHDL_EXT)

    if tcl_path:
        if os.path.exists(tcl_path):
            print("Regenerate the file: " + tcl_path)
            os.remove(tcl_path)
            #raise RuntimeError("outfile already exists")

        with open(tcl_path, "w+") as fout:
            fout.write("# This is a generated file. Do not modify by hand\n")
            fout.write("# cmd: ")
            fout.write(" ".join(sys.argv))
            fout.write("\n\n")
            '''
            # Add specific files below if needed
            if(base_nic == 'open-nic'):
                fout.write("add_files ./your-hdl-file.v \n")
            '''

            #  add rtl files
            for f in verilog_files:
                fout.write("add_files {}\n".format(f))
                #fout.write("import_files {}\n".format(f))
            for f in vhdl_files:
                RuntimeError("not handling VHDL files")
            fout.write("\n")

    else:
        # print to stdout
        for f in verilog_files:
            logging.info(f'verilog: {f}')
        for f in vhdl_files:
            logging.info(f'   vhdl: {f}')

def find_elem_in_lst(key, lst):
  idx = 0
  for item in lst:
    if item in key:
      return idx
    else:
      idx = idx + 1
  return -1

def print_help():
    logging.info('Usage:')
    logging.info('  python build_tcl.py -nic [open-nic] [-o output_filename]')
    logging.info('Note: default output_filename is \'build.tcl\'')

if __name__ == "__main__":
    argv_len = len(sys.argv)
    logging.getLogger().setLevel(logging.INFO)

    if (argv_len < 2):
        print_help()
        exit()

    output_filename = 'build.tcl'

    idx_nic = find_elem_in_lst('-nic', sys.argv)
    idx_filename = find_elem_in_lst('-o', sys.argv)

    if(idx_nic != -1):
        base_nic = sys.argv[idx_nic+1]
    
    if(idx_filename != -1):
        output_filename = sys.argv[idx_filename+1]

    tcl_path = os.path.join(root_dir, output_filename)
    src_dir  = os.path.join(root_dir, '')
    create_tcl(src_dir, tcl_path)