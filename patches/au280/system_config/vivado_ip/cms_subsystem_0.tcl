# create block design
set cms_subsystem cms_subsystem_0
create_ip -name cms_subsystem -vendor xilinx.com -library ip -version 4.0 -module_name $cms_subsystem -dir ${ip_build_dir}
get_ips $cms_subsystem
