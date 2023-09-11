#!/usr/bin/env python3
#==============================================================================
# Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
# SPDX-License-Identifier: MIT
#
#==============================================================================

## This file descripes control registers used in ERNIC

# Global Control Status Register (CSR) offset
XRNICCONF       = 0x00020000
XRNICADCONF     = 0x00020004
MACXADDLSB      = 0x00020010
MACXADDMSB      = 0x00020014
IPv6XADD1       = 0x00020020
IPv6XADD2       = 0x00020024
IPv6XADD3       = 0x00020028
IPv6XADD4       = 0x0002002C
IPv4XADD        = 0x00020070
ERRBUFBA        = 0x00020060
ERRBUFBAMSB     = 0x00020064
ERRBUFSZ        = 0x00020068
IPKTERRQBA      = 0x00020088
IPKTERRQBAMSB   = 0x0002008C
IPKTERRQSZ      = 0x00020090
DATBUFBA        = 0x000200A0
DATBUFBAMSB     = 0x000200A4
DATBUFSZ        = 0x000200A8
RESPERRPKTBA    = 0x000200B0
RESPERRPKTBAMSB = 0x000200B4
RESPERRSZ       = 0x000200B8
RESPERRSZMSB    = 0x000200BC
INTEN           = 0x00020180
STATCURSQPTRi   = 0x0002028C
STATMSN         = 0x00020284

# Global status register (GSR) offset, Read-only
ERRBUFWPTR      = 0x0002006C
IPKTERRQWPTR    = 0x00020094
INSRRPKTCNT     = 0x00020100  
INAMPKTCNT      = 0x00020104
OUTIOPKTCNT     = 0x00020108
OUTAMPKTCNT     = 0x0002010C
LSTINPKT        = 0x00020110
LSTOUTPKT       = 0x00020114
ININVDUPCNT     = 0x00020118
INNCKPKTSTS     = 0x0002011C
OUTRNRPKTSTS    = 0x00020120
WQEPROCSTS      = 0x00020124
QPMSTS          = 0x0002012C
INALLDRPPKTCNT  = 0x00020130
INNAKPKTCNT     = 0x00020134
OUTNAKPKTCNT    = 0x00020138
RESPHNDSTS      = 0x0002013C
RETRYCNTSTS     = 0x00020140
INCNPPKTCNT     = 0x00020174
OUTCNPPKTCNT    = 0x00020178
OUTRDRSPPKTCNT  = 0x0002017C
INTSTS          = 0x00020184
RQINTSTS1       = 0x00020190
RQINTSTS2       = 0x00020194
RQINTSTS3       = 0x00020198
RQINTSTS4       = 0x0002019C
RQINTSTS5       = 0x000201A0
RQINTSTS6       = 0x000201A4
RQINTSTS7       = 0x000201A8
RQINTSTS8       = 0x000201AC
CQINTSTS1       = 0X000201B0
CQINTSTS2       = 0x000201B4
CQINTSTS3       = 0X000201B8
CQINTSTS4       = 0x000201BC
CQINTSTS5       = 0X000201C0
CQINTSTS6       = 0x000201C4
CQINTSTS7       = 0X000201C8
CQINTSTS8       = 0x000201CC
CNPSCHDSTS1REG  = 0X000201D0
CNPSCHDSTS2REG  = 0X000201D4
CNPSCHDSTS3REG  = 0X000201D8
CNPSCHDSTS4REG  = 0X000201DC
CNPSCHDSTS5REG  = 0X000201E0
CNPSCHDSTS6REG  = 0X000201E4
CNPSCHDSTS7REG  = 0X000201E8
CNPSCHDSTS8REG  = 0X000201EC

# Protection domain table (PDT) register offset
PDPDNUM         = 0x00000000
VIRTADDRLSB     = 0x00000004
VIRTADDRMSB     = 0x00000008
BUFBASEADDRLSB  = 0x0000000C
BUFBASEADDRMSB  = 0x00000010
BUFRKEY         = 0x00000014
WRRDBUFLEN      = 0x00000018
ACCESSDESC      = 0x0000001C

# Per-queue CSR offset
QPCONFi         = 0x00020200
QPADVCONFi      = 0x00020204
RQBAi           = 0x00020208
RQBAMSBi        = 0x000202C0
SQBAi           = 0x00020210
SQBAMSBi        = 0x000202C8
CQBAi           = 0x00020218
CQBAMSBi        = 0x000202D0
RQWPTRDBADDi    = 0x00020220
RQWPTRDBADDMSBi = 0x00020224
CQDBADDi        = 0x00020228
CQDBADDMSBi     = 0x0002022C
RQCIi           = 0x00020234
SQPIi           = 0x00020238
QDEPTHi         = 0x0002023C
SQPSNi          = 0x00020240
LSTRQREQi       = 0x00020244
DESTQPCONFi     = 0x00020248
MACDESADDLSBi   = 0x00020250
MACDESADDMSBi   = 0x00020254
IPDESADDR1i     = 0x00020260
IPDESADDR2i     = 0x00020264
IPDESADDR3i     = 0x00020268
IPDESADDR4i     = 0x0002026C
PDi             = 0x000202B0

# Per-queue CSR Read-Only register offset
CQHEADi         = 0x00020230
STATSSNi        = 0x00020280
STATMSNi        = 0x00020284
STATQPi         = 0x00020288
STATCURSQPTRi   = 0x0002028C
STATRESPSNi     = 0x00020290
STATRQBUFCAi    = 0x00020294
STATRQBUFCAMSBi = 0x000202D8
STATWQEi        = 0x00020298
STATRQPIDBi     = 0x0002029C


# WQE opcodes: 8 bits
OP_WRITE     		= 0
OP_WRITE_IMMDT	= 1
OP_SEND		    	= 2
OP_SEND_IMMDT	  = 3
OP_READ		    	= 4
OP_SEND_INV	  	= 12

opcode_lst = ['write', 'write_immdt', 'send', 'send_immdt', 'read', 'send_inv']
location_lst = ['dev_mem','sys_mem']
dev_offset = 0xa350000000000000
