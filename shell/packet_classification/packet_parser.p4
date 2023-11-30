//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================

#include <core.p4>
#include <xsa.p4>

const bit<16> ETH_VLAN = 0x8100;
const bit<16> ETH_IPV4 = 0x0800;
const bit<16> ETH_IPV6 = 0x86DD;

const bit<8> IPPROTO_TCP = 0x06;
const bit<8> IPPROTO_UDP = 0x11;

// Operations that contain RETH header
const bit<5> WRITE_FIRST    = 0x06;
const bit<5> WRITE_ONLY     = 0x0a;
const bit<5> WRITE_ONLY_IMM = 0x0b;
const bit<5> READ_REQ       = 0x0c;

// Operations that contain AETH header
const bit<5> READ_RSP_FIRST = 0x0d;
const bit<5> READ_RSP_LAST  = 0x0f;
const bit<5> READ_RSP_ONLY  = 0x10;
const bit<5> ACK            = 0x11;

// Operations that contain IETH header
const bit<5> SEND_LAST_INV  = 0x16;
const bit<5> SEND_ONLY_INV  = 0x17;

// Operations that contain ImmDt header
const bit<5> SEND_LAST_IMM  = 0x03;
const bit<5> SEND_ONLY_IMM  = 0x05;
const bit<5> WRITE_LAST_IMM = 0x09;
//const bit<5> WRITE_ONLY_IMM = 0x0b;

/* RoCEv2 Base Transport Header (BTH) - 12B
 * - connType : 3-bit, only consider reliable connection (RC) Opcode[7:5] = 000;
 * - op       : 5-bit, opcode used to specify rdma operation, Opcode[4:0] Opcode[7:0] = {connType, op}
 * - SE       : 1-bit,  solicited event to ask the responder to invoke the CQ event handler
 * - MigReg   : 1-bit,  used to communicate migration state. If set to 1, indicates the connection or EE
 *                      context has been migrated. Otherwise, no change in the current migration state
 * - Padding  : 2-bit,  pading count indicates the number of pad bytes (0 - 3) that are appended to the 
 *                      packet payload. Packet payloads are sent as a multiple of 4-byte quantities
 * - TVer     : 4-bit,  transport header version, used to specify the version of the IBA (InfiniBand 
 *                      Architecture) Transport used for this packet
 * - P_Key    : 16-bit, partition key used to identify the partition that the destination QP (RC, UC, 
 *                      UD) or EE context (RD) is a member
 * - Resv1    : 8-bit,  reserved field, transmitted as 0, ignored on receive. This field is not  
 *                      included in the invariant CRC
 * - DestQP   : 24-bit, destination QP indentifier
 * - AckReq   : 1-bit,  used to request responder to schedule an acknowledgement on the associated QP
 * - Resv2    : 7-bit,  reserved field, transmitted as 0 ignored on receive. This field is included  
 *                      in the invariant CRC
 * - PSN      : 24-bit, packet sequence number, used to identify the position of a packet within a  
 *                      sequence of packets
 */
header bth_h {
  bit<3>  connType;
  bit<5>  op;
  bit<1>  se;
  bit<1>  migEeq;
  bit<2>  padding;
  bit<4>  tver;
  bit<16> p_key;
  bit<8>  resv1;
  bit<24> destqp;
  bit<1>  ackreq;
  bit<7>  resv2;
  bit<24> psn;
}

/* RoCEv2 RDMA Extended Transport Header (RETH) - 16B
 * - virtual high address - 32-bit, high address [63:32]
 * - virtual low address  - 32-bit, low address  [31: 0]
 * - r_key                - 32-bit, remote key used to authorize access for the RDMA operation
 * - dma_length           - 32-bit, length in bytes of the DMA operation
 */
header reth_h {
  bit<32> vir_high_addr;
  bit<32> vir_low_addr;
  bit<32> r_key;
  bit<32> dma_length;
}

/* RoCEv2 ACK Extended Transport Header (AETH) - 4B
 * - Syndrome : 8-bit,  used to identify an ACK or NAK packet + additional information about the ACK 
 *                      or NAK. Syndrome[6:5] - 00 : ACK opcode
 * - MSN      : 24-bit, message sequence number, the sequence number of the last mesage completed at
 *                      the responder
 */
header aeth_h {
  bit<8>  syndrome;
  bit<24> msn;
}

/* RoCEv2 Immediate Data Extended Transport Header (ImmDt) - 4B
 * - Immediate data : 32-bit, data defined by a user
 */
header immdt_h {
  bit<32> imm_data;
}

/* RoCEv2 Invalidate Extended Transport Header (IETH) - 4B
 * - R_Key : 32-bit, remote key used by the responder to invalidate a memory region or memory window
 * [Note] Invalidate packet is not supported in the current version
 */
header ieth_h {
  bit<32> r_key;
}

/* Ethernet header */
header eth_h {
  bit<48> dst_mac;
  bit<48> src_mac;
  bit<16> type;
}

/* Vlan header */
header vlan_h {
    bit<3>  pcp;  // Priority code point
    bit<1>  cfi;  // Drop eligible indicator
    bit<12> vid;  // VLAN identifier
    bit<16> tpid; // Tag protocol identifier
}

/* ipv4 header */
header ipv4_h {
  bit<4>  version;
  bit<4>  ihl;
  bit<6>  dscp;
  bit<2>  ecn;
  bit<16> len; // length includes header and data
  bit<16> id;
  bit<3>  flags;
  bit<13> frag;
  bit<8>  ttl;
  bit<8>  proto;
  bit<16> chksum;
  bit<32> src;
  bit<32> dst;
}

/* ipv6 header */
header ipv6_h {
    bit<4>   version;    // Version = 6
    bit<8>   priority;   // Traffic class
    bit<20>  flow_label; // Flow label
    bit<16>  length;     // Payload length
    bit<8>   protocol;   // Next protocol
    bit<8>   hop_limit;  // Hop limit
    bit<128> src;        // Source address
    bit<128> dst;        // Destination address
}

/* IPv4 options - length = (ipv4.ihl - 5)*32 */
header ipv4_opt_t {
  varbit<320> options;
}

/* UDP header */
header udp_h {
  bit<16> sport;
  bit<16> dport;
  bit<16> len; // length includes UDP header and its payload data
  bit<16> chksum;
}

/* Headers of interest */
struct headers_t {
  eth_h      eth;
  vlan_h[2]  vlan;
  ipv4_h     ipv4;
  ipv4_opt_t ipv4_opt;
  ipv6_h     ipv6;
  udp_h      udp;
  bth_h      bth;
  reth_h     reth;
  aeth_h     aeth;
  immdt_h    immdt;
  ieth_h     ieth;
}

/* 
 * Metadata contains debug information and control data
 * Total size   : 263 bits
 * @index       : 32-bit, index of an incoming packet, used for 
 *                        debug purpose
 * @ip_src      : 32-bit, IP source address
 * @ip_dst      : 32-bit, IP destination address
 * @udp_sport   : 16-bit, UDP source port
 * @udp_dport   : 16-bit, UDP destination port
 * @opcode      : 5-bit, opcode
 * @pktlen      : 16-bit, packet length
 * @dma_length  : 32-bit, length in bytes of the DMA operation
 * @r_key       : 32-bit, remote key
 * @se          : 1-bit, solicited event
 * @psn         : 24-bit, packet sequence number
 * @msn         : 24-bit, message sequence number
 * @is_rdma     : 1-bit, indicates that this packet is a rdma packet
 */
struct pc_metadata_t {
  bit<32> index;
  bit<32> ip_src;
  bit<32> ip_dst;
  bit<16> udp_sport;
  bit<16> udp_dport;
  bit<5>  opcode;
  bit<16> pktlen;
  bit<32> dma_length;
  bit<32> r_key;
  bit<1>  se;
  bit<24> psn;
  bit<24> msn;
  bit<1>  is_rdma;
}

error {
  InvalidIPpacket
}

/*
 * parser
 * - Only accept UDP/IPv4 packets in the current implementation
 */
parser parser_inst(packet_in pkt, 
                   out headers_t hdr, 
                   inout pc_metadata_t pc_meta, 
                   inout standard_metadata_t smeta)
{
  state start {
    pkt.extract<eth_h>(hdr.eth);

    transition select(hdr.eth.type) {
      ETH_VLAN: parse_vlan;
      ETH_IPV4: parse_ipv4;
      ETH_IPV6: parse_ipv6;
      default : accept;
    }
  }

  state parse_vlan {
    pkt.extract(hdr.vlan.next);
    transition select(hdr.vlan.last.tpid) {
      ETH_VLAN : parse_vlan;
      ETH_IPV4 : parse_ipv4;
      ETH_IPV6 : parse_ipv6;
      default  : accept;
    }
  }

  state parse_ipv4 {
    pkt.extract<ipv4_h>(hdr.ipv4);
    verify(hdr.ipv4.version == 4 && hdr.ipv4.len >= 5, error.InvalidIPpacket);
    
    transition select (hdr.ipv4.ihl) {
      5: dispatch_on_protocol;
      _: parse_ipv4_options;
    }
  }

  state parse_ipv4_options {
    pkt.extract(hdr.ipv4_opt,(((bit<32>)hdr.ipv4.ihl-5) * 32));
    transition dispatch_on_protocol;
  }

  state dispatch_on_protocol {
    transition select(hdr.ipv4.proto) {
      IPPROTO_UDP : parse_udp;
      default     : accept;
    }
  }

  state parse_ipv6 {
    pkt.extract(hdr.ipv6);
    verify(hdr.ipv6.version == 6, error.InvalidIPpacket);
    transition select(hdr.ipv6.protocol) {
      IPPROTO_UDP : parse_udp;
      default     : accept; 
    }
  }

  state parse_udp {
    pkt.extract<udp_h>(hdr.udp);
    pkt.extract<bth_h>(hdr.bth);

    transition select(hdr.bth.op) {
      WRITE_FIRST   : parse_reth;
      WRITE_ONLY    : parse_reth;
      WRITE_ONLY_IMM: parse_reth;
      READ_REQ      : parse_reth;
      READ_RSP_FIRST: parse_aeth;
      READ_RSP_LAST : parse_aeth;
      READ_RSP_ONLY : parse_aeth;
      ACK           : parse_aeth;
      SEND_LAST_INV : parse_ieth;
      SEND_ONLY_INV : parse_ieth;
      SEND_LAST_IMM : parse_immdt;
      SEND_ONLY_IMM : parse_immdt;
      WRITE_LAST_IMM: parse_immdt;
      default: accept;
    }
  }

  state parse_reth {
    pkt.extract<reth_h>(hdr.reth);
    
    transition select(hdr.bth.op) {
      WRITE_ONLY_IMM: parse_immdt;
      default: accept;
    }
  }

  state parse_aeth {
    pkt.extract<aeth_h>(hdr.aeth);
    transition accept;
  }

  state parse_ieth {
    pkt.extract<ieth_h>(hdr.ieth);
    transition accept;
  }

  state parse_immdt {
    pkt.extract<immdt_h>(hdr.immdt);
    transition accept;
  }
}

/*
 * RDMA atomic operations are not supported
 */
control forward_inst(inout headers_t hdr,
                     inout pc_metadata_t pc_meta,
                     inout standard_metadata_t smeta)
{

  bit<32> index;
  bit<32> ip_src;
  bit<32> ip_dst;
  bit<16> udp_sport;
  bit<16> udp_dport;
  bit<5>  opcode;
  bit<16> pktlen;
  bit<32> dma_length;
  bit<32> r_key;
  bit<1>  se;
  bit<24> psn;
  bit<24> msn;
  bit<1>  is_rdma;

  apply {
    // Initialize variables
    ip_src    = (bit<32>) 0;
    ip_dst    = (bit<32>) 0;
    udp_sport = (bit<16>) 0;
    udp_dport = (bit<16>) 0;
    opcode    = (bit<5>) 0;
    dma_length= (bit<32>) 0;
    r_key     = (bit<32>) 0;
    se        = (bit<1>) 0;
    psn       = (bit<24>) 0;
    msn       = (bit<24>) 0;
    is_rdma   = (bit<1>) 0;

    index   = pc_meta.index;
    pktlen  = pc_meta.pktlen;

    if (hdr.udp.isValid()) {
      if (hdr.ipv6.isValid()){
        ip_src = (bit<32>) 6;
        ip_dst = (bit<32>) 6;
      } else {
        ip_src = hdr.ipv4.src;
        ip_dst = hdr.ipv4.dst;
      }
      
      udp_sport = hdr.udp.sport;
      udp_dport = hdr.udp.dport;

      if(hdr.reth.isValid()) {
        r_key      = hdr.reth.r_key;
        dma_length = hdr.reth.dma_length;
        is_rdma    = (bit<1>) 1;
      }

      if(hdr.aeth.isValid()) {
        msn     = hdr.aeth.msn;
        is_rdma = (bit<1>) 1;
      }

      if(hdr.ieth.isValid()) {
        r_key   = hdr.ieth.r_key;
        is_rdma = (bit<1>) 1;
      }

      if(hdr.bth.isValid()) {
        opcode = hdr.bth.op;
        se     = hdr.bth.se;
        psn    = hdr.bth.psn;
        
        if(hdr.bth.connType != ((bit<3>) 0)) {
          is_rdma = (bit<1>) 0;
        } else {
          // Only consider reliable connection RDMA operations
          is_rdma = (bit<1>) 1;
        }
      }
    }

    pc_meta.ip_src     = ip_src;
    pc_meta.ip_dst     = ip_dst;
    pc_meta.udp_sport  = udp_sport;
    pc_meta.udp_dport  = udp_dport;
    pc_meta.opcode     = opcode;
    pc_meta.dma_length = dma_length;
    pc_meta.r_key      = r_key;
    pc_meta.se         = se;
    pc_meta.psn        = psn;
    pc_meta.msn        = msn;
    pc_meta.is_rdma    = is_rdma;
  }
}

control deparser_inst(packet_out pkt,
                      in headers_t hdr,
                      inout pc_metadata_t pc_meta,
                      inout standard_metadata_t smeta)
{
  apply {
    pkt.emit(hdr.eth);
    pkt.emit(hdr.vlan);
    pkt.emit(hdr.ipv4);
    pkt.emit(hdr.ipv4_opt);
    pkt.emit(hdr.ipv6);
    pkt.emit(hdr.udp);
    pkt.emit(hdr.bth);
    pkt.emit(hdr.reth);
    pkt.emit(hdr.aeth);
    pkt.emit(hdr.immdt);
    pkt.emit(hdr.ieth);
  }
}

XilinxPipeline(
  parser_inst(),
  forward_inst(),
  deparser_inst()
) main;
