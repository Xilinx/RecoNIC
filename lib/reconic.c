//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================

/** @file reconic.c
 *  @brief The RecoNIC user-space API library.
 *
 */

#include "reconic.h"

int debug = 0;

char* device = "";

int fpga_fd = -1;

uint64_t get_win_size() {
  //return AXI_BAR_SIZE>>3;
  return AXI_BAR_SIZE;
}

uint32_t convert_ip_addr_to_uint(char* ip_addr){
  unsigned char ip_char[4] = {0};
  uint32_t ip;
  sscanf(ip_addr, "%hhu.%hhu.%hhu.%hhu", &ip_char[0],&ip_char[1],&ip_char[2],&ip_char[3]);
  //fprintf(stderr, "ip = %u.%u.%u.%u\n", ip_char[0], ip_char[1], ip_char[2], ip_char[3]);
  ip = (ip_char[0]<<24) | (ip_char[1]<<16) | (ip_char[2]<<8) | ip_char[3];
  return ip;
}

struct mac_addr_t convert_mac_addr_str_to_uint(char* mac_addr_str) {
    struct mac_addr_t mac_addr_inst;
    uint32_t mac_addr_lsb;
    uint32_t mac_addr_msb;
    uint32_t mac_addr_array[6] = {0};
    sscanf(mac_addr_str, "%x:%x:%x:%x:%x:%x", &mac_addr_array[0],&mac_addr_array[1],&mac_addr_array[2],&mac_addr_array[3],&mac_addr_array[4],&mac_addr_array[5]);

    fprintf(stderr, "Info: mac_addr_t = %02x:%02x:%02x:%02x:%02x:%02x\n", mac_addr_array[0], mac_addr_array[1], mac_addr_array[2], mac_addr_array[3], mac_addr_array[4], mac_addr_array[5]);

    mac_addr_msb = ((mac_addr_array[0]<<8) | mac_addr_array[1]) & 0x0000ffff;
    mac_addr_lsb = ((mac_addr_array[2]<<24) | (mac_addr_array[3]<<16) | (mac_addr_array[4]<<8) | mac_addr_array[5]) & 0xffffffff;
    mac_addr_inst.mac_lsb = mac_addr_lsb;
    mac_addr_inst.mac_msb = mac_addr_msb;
    return mac_addr_inst;
}

struct mac_addr_t convert_mac_addr_to_uint(unsigned char* mac_addr_char) {
  struct mac_addr_t mac_addr_inst;
  uint32_t mac_addr_lsb;
  uint32_t mac_addr_msb;

  fprintf(stderr, "Info: mac_addr_t = %02x:%02x:%02x:%02x:%02x:%02x\n", mac_addr_char[0], mac_addr_char[1], mac_addr_char[2], mac_addr_char[3], mac_addr_char[4], mac_addr_char[5]);

  mac_addr_msb = ((mac_addr_char[0]<<8) | mac_addr_char[1]) & 0x0000ffff;
  mac_addr_lsb = ((mac_addr_char[2]<<24) | (mac_addr_char[3]<<16) | (mac_addr_char[4]<<8) | mac_addr_char[5]) & 0xffffffff;
  mac_addr_inst.mac_lsb = mac_addr_lsb;
  mac_addr_inst.mac_msb = mac_addr_msb;
  return mac_addr_inst;
}

struct mac_addr_t get_mac_addr_from_str_ip(int sockfd, char* ip_str) {
  struct ifaddrs* ifaddr;
  struct ifaddrs* ifa;
  struct ifreq ifreq_local;
  int family;
  int return_value;
  char tmp_ip[NI_MAXHOST];
  fprintf(stderr, "Info: src_ip = %s\n", (char*) ip_str);
  if(getifaddrs(&ifaddr) == -1) {
  fprintf(stderr, "Error: not able to getifaddrs\n");
  exit(EXIT_FAILURE);
}
  for(ifa = ifaddr; ifa != NULL; ifa = ifa->ifa_next) {
    family = ifa->ifa_addr->sa_family;
    // Skip interfaces that are not IPv4 addresses
    if(family != AF_INET) {
      continue;
  }

  return_value = getnameinfo(ifa->ifa_addr, sizeof(struct sockaddr_in), tmp_ip, NI_MAXHOST, NULL, 0, NI_NUMERICHOST);

  // fprintf(stderr, "Info: tmp_ip = %s\n", tmp_ip);

  if(return_value != 0) {
    fprintf(stderr, "Error: getnameinfo() failed with %s\n", gai_strerror(return_value));
    exit(EXIT_FAILURE);
  }

  if (strcmp(tmp_ip, ip_str) == 0) {
    fprintf(stderr, "Info: Found network interface: %s\n", ifa->ifa_name);
    strncpy(ifreq_local.ifr_name, (char* ) ifa->ifa_name, IFNAMSIZ -1);
    ioctl(sockfd, SIOCGIFHWADDR, &ifreq_local);
    // fprintf(stderr, "Getting src_mac address:\n");
    return convert_mac_addr_to_uint((unsigned char* ) ifreq_local.ifr_hwaddr.sa_data);
    break;
  }
}
  fprintf(stderr, "Cannot find interface with IP address %s\n", ip_str);
  exit(EXIT_FAILURE);
}

uint8_t is_device_address(uint64_t address) {
  if((address & 0xfff0000000000000) == DEVICE_MEM_OFFSET) {
    // Device memory address
    return 1;
  } else {
    // Host memory address
    return 0;
  }
}

/* Used to get the PFN of a virtual address */
unsigned long get_page_frame_number_of_address(void *addr) {
  size_t return_code;
  // Getting the pagemap file for the current process
  FILE *pagemap = fopen("/proc/self/pagemap", "rb");

  // Seek to the page that the buffer is on
  unsigned long offset = (unsigned long)addr / getpagesize() * PAGEMAP_LENGTH;
  if(fseek(pagemap, (unsigned long)offset, SEEK_SET) != 0) {
    fprintf(stderr, "Error: Failed to seek pagemap to proper location\n");
    exit(1);
  }

  // The page frame number is in bits 0 - 54 so read the first 7 bytes and clear the 55th bit
  unsigned long page_frame_number = 0;
  return_code = fread(&page_frame_number, 1, PAGEMAP_LENGTH-1, pagemap);
  if(return_code != (PAGEMAP_LENGTH-1)) {
    fprintf(stderr, "Error: failed to get page frame number\n");
    return -1;
  }
  page_frame_number &= 0x7FFFFFFFFFFFFF;

  fclose(pagemap);
  return page_frame_number;
}

/* This function is used to get the physical address of a buffer. */
uint64_t get_buffer_paddr(void *buffer) {
  // Getting the page frame the buffer is in
  unsigned long page_frame_number = get_page_frame_number_of_address(buffer);

  Debug("Info: get_buffer_paddr - Page frame: 0x%lx\n", page_frame_number);

  // Getting the offset of the buffer into the page
  unsigned int distance_from_page_boundary = (unsigned long)buffer % getpagesize();

  Debug("Info: get_buffer_paddr - distance from page boundary: 0x%x\n", distance_from_page_boundary);

  uint64_t paddr = (uint64_t)(page_frame_number << PAGE_SHIFT) + (uint64_t)distance_from_page_boundary;

  Debug("Info: get_buffer_paddr - Physical address of buffer: 0x%lx\n", paddr);
  return paddr;
}

void config_rn_dev_axib_bdf(struct rn_dev_t* rn_dev, uint32_t high_addr, uint32_t low_addr) {
  int i;
  uint64_t win_size = 0;
  uint32_t bdf_addr_mask_high = 0;
  uint32_t bdf_addr_mask_low  = 0;

  uint32_t bdf_addr_high = 0;
  uint32_t bdf_addr_low  = 0;

  uint32_t bdf_win_config;
  uint32_t bdf_win_size_in_4Kpage;

  if(rn_dev == NULL) {
    fprintf(stderr, "Error: rn_dev is NULL\n");
    exit(EXIT_FAILURE);
  }

  win_size = get_win_size();
  rn_dev->winSize->win_size_msb = (uint32_t) ((win_size & 0xffffffff00000000) >> 32);
  rn_dev->winSize->win_size_lsb  = (uint32_t) (win_size & 0x00000000ffffffff);

  bdf_addr_mask_high = ADDR_MASK - rn_dev->winSize->win_size_msb;
  bdf_addr_mask_low  = ADDR_MASK - rn_dev->winSize->win_size_lsb;

  bdf_addr_high = high_addr & bdf_addr_mask_high;
  bdf_addr_low  = low_addr & bdf_addr_mask_low;

  // 128GB mapping per window
  bdf_win_size_in_4Kpage = (uint32_t) ( (((AXI_BAR_SIZE>>3) + 1)>>12) & 0x00000000ffffffff);
  bdf_win_config = 0xC0000000 | bdf_win_size_in_4Kpage;

  fprintf(stderr, "Info: Configuring 8 windows in QDMA AXI bridge BDF, each has 128GB mapping\n");
  for(i=0; i<8; i++) {
    write32_data(rn_dev->axil_ctl, AXIB_BDF_ADDR_TRANSLATE_ADDR_LSB+(i*0x20), bdf_addr_low);
    write32_data(rn_dev->axil_ctl, AXIB_BDF_ADDR_TRANSLATE_ADDR_MSB+(i*0x20), bdf_addr_high + (i*0x20));
    write32_data(rn_dev->axil_ctl, AXIB_BDF_PASID_RESERVED_ADDR+(i*0x20), 0);
    write32_data(rn_dev->axil_ctl, AXIB_BDF_FUNCTION_NUM_ADDR  +(i*0x20), 0);
    write32_data(rn_dev->axil_ctl, AXIB_BDF_MAP_CONTROL_ADDR   +(i*0x20), bdf_win_config);
    write32_data(rn_dev->axil_ctl, AXIB_BDF_RESERVED_ADDR      +(i*0x20), 0);
    Debug("[BDF] AXIB_BDF_ADDR_TRANSLATE_ADDR_LSB=0x%x, bdf_addr_low=0x%x\n", AXIB_BDF_ADDR_TRANSLATE_ADDR_LSB+(i*0x20), bdf_addr_low);
    Debug("[BDF] AXIB_BDF_ADDR_TRANSLATE_ADDR_MSB=0x%x, bdf_addr_high=0x%x\n", AXIB_BDF_ADDR_TRANSLATE_ADDR_MSB+(i*0x20), bdf_addr_high+(i*0x20));
    Debug("[BDF] AXIB_BDF_MAP_CONTROL_ADDR=0x%x, bdf_win_config=0x%x\n", AXIB_BDF_MAP_CONTROL_ADDR+(i*0x20), bdf_win_config);
  }
}

struct rdma_buff_t* allocate_rdma_buffer(struct rn_dev_t* rn_dev, uint64_t buf_size, char* buf_location) {
  struct rdma_buff_t* rdma_buffer;
  rdma_buffer = (struct rdma_buff_t*) malloc(sizeof(struct rdma_buff_t));
  if(rdma_buffer == NULL) {
    fprintf(stderr, "Error: failed to create rdma_buffer\n");
    exit(EXIT_FAILURE);
  }

  if(!strcmp(buf_location, HOST_MEM)) {
    // Allocate the buffer in the host memory
    // Check the buffer_offset and buf_size whether it meets 4KB alignment or not
    if (buf_size <= HARDWARE_PAGE_SIZE) {
      if (((rn_dev->buffer_offset & HARDWARE_PAGE_SIZE_ADDRESS_MASK) + buf_size) > HARDWARE_PAGE_SIZE) {
        rn_dev->buffer_offset =  (rn_dev->buffer_offset + HARDWARE_PAGE_SIZE) & HARDWARE_PAGE_SIZE_ALIGNMENT_MASK;
      }
    } else {
      // buf_size > HARDWARE_PAGE_SIZE
      if((rn_dev->buffer_offset & HARDWARE_PAGE_SIZE_ADDRESS_MASK) != 0) {
        // buffer_offset is not aligned with HARDWARE_PAGE_SIZE
        rn_dev->buffer_offset =  (rn_dev->buffer_offset + HARDWARE_PAGE_SIZE) & HARDWARE_PAGE_SIZE_ALIGNMENT_MASK;
      }
    }
    rdma_buffer->buffer = (void*)((uint64_t) rn_dev->base_buf->buffer + rn_dev->buffer_offset);
    rn_dev->buffer_offset += buf_size;
    rdma_buffer->buf_size = buf_size;

    // Get the physical address of the buffer
    rdma_buffer->dma_addr = get_buffer_paddr(rdma_buffer->buffer);
    Debug("Info: allocated host buffer vir addr = %p, physical addr = %lx, rn_dev->buffer_offset = 0x%lx\n", rdma_buffer->buffer, rdma_buffer->dma_addr, rn_dev->buffer_offset);
    Debug("Info: allocate_rdma_buffer - successfully allocated rdma host buffer\n");
  } else {
    if (!strcmp(buf_location, DEVICE_MEM)) {
      // Allocate the buffer in the device memory
      // TODO: We need to implement user-space device memory management function
      // Check the dev_buffer_offset and buf_size whether it meets 4KB alignment or not
      if (buf_size <= HARDWARE_PAGE_SIZE) {
        if (((rn_dev->dev_buffer_offset & HARDWARE_PAGE_SIZE_ADDRESS_MASK) + buf_size) > HARDWARE_PAGE_SIZE) {
          rn_dev->dev_buffer_offset =  (rn_dev->dev_buffer_offset + HARDWARE_PAGE_SIZE) & HARDWARE_PAGE_SIZE_ALIGNMENT_MASK;
        }
      } else {
        // buf_size > HARDWARE_PAGE_SIZE
        if((rn_dev->dev_buffer_offset & HARDWARE_PAGE_SIZE_ADDRESS_MASK) != 0) {
          // dev_buffer_offset is not aligned with HARDWARE_PAGE_SIZE
          rn_dev->dev_buffer_offset =  (rn_dev->dev_buffer_offset + HARDWARE_PAGE_SIZE) & HARDWARE_PAGE_SIZE_ALIGNMENT_MASK;
        }
      }
      rdma_buffer->buffer = (void*)(rn_dev->dev_buffer_offset | DEVICE_MEM_OFFSET);
      rdma_buffer->dma_addr = (uint64_t) (rn_dev->dev_buffer_offset | DEVICE_MEM_OFFSET);
      rn_dev->dev_buffer_offset += buf_size;
      rdma_buffer->buf_size = buf_size;

      // TODO: We need to put assert here later to make sure we won't exceed device memory.
      Debug("Info: allocated device buffer physical addr = %lx, rn_dev->dev_buffer_offset = 0x%lx\n", rdma_buffer->dma_addr, rn_dev->dev_buffer_offset);
      assert(rn_dev->dev_buffer_offset <= (uint64_t) DEVICE_MEM_SIZE);
    Debug("Info: allocate_rdma_buffer - successfully allocated rdma device buffer\n");
    } else {
      fprintf(stderr, "Error: please provide correct buffer location: [host_mem | dev_mem]\n");
      exit(EXIT_FAILURE);
    }
  }

  return rdma_buffer;
}

struct rn_dev_t* create_rn_dev(char* pcie_resource, int* pcie_resource_fd, uint32_t num_hugepages_request, uint32_t num_qp) {
  int scr;
  // int rdma = -1;
  void* axil_scr_base;
  uint32_t phy_addr_msb;
  uint32_t phy_addr_lsb;

  struct rn_dev_t* rn_dev = NULL;
  struct win_size_t* winSize = NULL;

  rn_dev = (struct rn_dev_t* ) malloc(sizeof(struct rn_dev_t));
  winSize = (struct win_size_t* ) malloc(sizeof(struct win_size_t));

  if(rn_dev == NULL) {
    fprintf(stderr, "Error: failed to allocate rn_dev\n");
    exit(EXIT_FAILURE);
  }

  rn_dev->axil_map_size = RN_SCR_MAP_SIZE;
  rn_dev->rdma_dev = NULL;
  rn_dev->base_buf = NULL;
  //rn_dev->rdma_dev->num_qp   = num_qp;
  rn_dev->winSize = winSize;
  rn_dev->winSize->win_size_lsb = 0;
  rn_dev->winSize->win_size_msb = 0;

  if((scr = open(pcie_resource, O_RDWR | O_SYNC)) == -1) {
    fprintf(stderr, "Error can't open %s file for the PCIe resource2!\n", pcie_resource);
    exit(EXIT_FAILURE);
  }

  *pcie_resource_fd = scr;

  Debug("Info: scr(=%d)) file open successfully\n", scr);

  axil_scr_base = mmap(NULL, RN_SCR_MAP_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, scr, 0);

  if (axil_scr_base == MAP_FAILED) {
    fprintf(stderr, "Error: axil_scr_base mmap failed\n");
    close(scr);
    exit(EXIT_FAILURE);
  }

  rn_dev->axil_ctl = (uint32_t* ) axil_scr_base;
  rn_dev->num_qp = num_qp;

  // Allocate 128MB memory space from HugePages
  rn_dev->base_buf = (struct rdma_buff_t*) malloc(sizeof(struct rdma_buff_t));
  if(rn_dev->base_buf == NULL) {
    fprintf(stderr, "Error: failed to create rn_dev->base_buf\n");
    exit(EXIT_FAILURE);
  }

  fprintf(stderr, "create_rn_dev - testing2\n");
  rn_dev->base_buf->buffer = mmap(NULL, num_hugepages_request * (1 << HUGE_PAGE_SHIFT),
                                  PROT_READ | PROT_WRITE, MAP_SHARED | MAP_ANONYMOUS |
                                  MAP_HUGETLB, -1, 0);

  // Lock the buffer in physical memory
  if(mlock(rn_dev->base_buf->buffer, num_hugepages_request * (1 << HUGE_PAGE_SHIFT)) == -1) {
    fprintf(stderr, "Error: failed to lock page in memory\n");
    exit(EXIT_FAILURE);
  }

  rn_dev->base_buf->dma_addr = get_buffer_paddr(rn_dev->base_buf->buffer);
  fprintf(stderr, "Info: pre-allocated hugepage buffer vir addr = %p, physical addr = 0x%lx\n", rn_dev->base_buf->buffer, rn_dev->base_buf->dma_addr);

  phy_addr_msb = (uint32_t) ((rn_dev->base_buf->dma_addr & 0xffffffff00000000) >> 32);
  phy_addr_lsb = (uint32_t) ((rn_dev->base_buf->dma_addr & 0x00000000ffffffff));

  // Configure QDMA slave AXI bridge
  config_rn_dev_axib_bdf(rn_dev, phy_addr_msb, phy_addr_lsb);

  rn_dev->buffer_offset = (uint64_t) 0;
  rn_dev->dev_buffer_offset = (uint64_t) 0;

  return rn_dev;
}
