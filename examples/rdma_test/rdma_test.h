//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================

#include <getopt.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#define DEVICE_NAME_DEFAULT "/dev/reconic-mm"

#define TCP_PORT 11111

#define LISTENQ 8

#define QP_LOCATION_DEFAULT HOST_MEM

// Hardcoded some of the configurations
#define P_KEY 0x1234
#define R_KEY 0x0008

// Total number of hugepages allocated: preallocated_hugepages * per_hugepage_size
//    -- 256 * 2MB = 512MB
#define preallocated_hugepages 256

static struct option const long_opts[] = {
	{"device"        , required_argument, NULL, 'd'},
	{"pcie_resource" , required_argument, NULL, 'p'},
	{"src_ip"        , required_argument, NULL, 'r'},
	{"dst_ip"        , required_argument, NULL, 'i'},
	{"udp_sport"     , required_argument, NULL, 'u'},
	{"tcp_sport"     , required_argument, NULL, 't'},
	{"dst_qp"        , required_argument, NULL, 'q'},
	{"payload_size"  , required_argument, NULL, 'z'},
	{"batch_size"    , required_argument, NULL, 'b'},
	{"qp_location"   , required_argument, NULL, 'l'},
	{"server"        , no_argument      , NULL, 's'},
	{"client"        , no_argument      , NULL, 'c'},
  {"debug"         , no_argument      , NULL, 'g'},
	{"help"          , no_argument      , NULL, 'h'},
	{0               , 0                , 0   ,  0 }
};
static void usage(const char *name)
{
	int i = 0;

	fprintf(stdout, "usage: %s [OPTIONS]\n\n", name);

	fprintf(stdout, "  -%c (--%s) character device name (defaults to %s)\n",
		long_opts[i].val, long_opts[i].name, DEVICE_NAME_DEFAULT);
	i++;
	fprintf(stdout, "  -%c (--%s) PCIe resource \n",
		long_opts[i].val, long_opts[i].name);
	i++;
	fprintf(stdout, "  -%c (--%s) Source IP address \n",
		long_opts[i].val, long_opts[i].name);
	i++;
	fprintf(stdout, "  -%c (--%s) Destination IP address \n",
		long_opts[i].val, long_opts[i].name);
	i++;
	fprintf(stdout, "  -%c (--%s) UDP source port \n",
		long_opts[i].val, long_opts[i].name);
	i++;
	fprintf(stdout, "  -%c (--%s) TCP source port \n",
		long_opts[i].val, long_opts[i].name);
	i++;
	fprintf(stdout, "  -%c (--%s) Destination QP number \n",
		long_opts[i].val, long_opts[i].name);
	i++;
	fprintf(stdout, "  -%c (--%s) Payload size in bytes \n",
		long_opts[i].val, long_opts[i].name);
	i++;
	fprintf(stdout, "  -%c (--%s) Batch size, number of WQEs per QP \n",
		long_opts[i].val, long_opts[i].name);
	i++;
	fprintf(stdout, "  -%c (--%s) QP/mem-registered buffers' location: [host_mem | dev_mem] \n",
		long_opts[i].val, long_opts[i].name);
	i++;
	fprintf(stdout, "  -%c (--%s) Server node \n",
		long_opts[i].val, long_opts[i].name);
	i++;
	fprintf(stdout, "  -%c (--%s) Client node \n",
		long_opts[i].val, long_opts[i].name);
	i++;
	fprintf(stdout, "  -%c (--%s) Debug mode \n",
		long_opts[i].val, long_opts[i].name);
	i++;
	fprintf(stdout, "  -%c (--%s) print usage help and exit\n",
		long_opts[i].val, long_opts[i].name);
}