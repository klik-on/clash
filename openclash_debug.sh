#!/bin/bash
. /lib/functions.sh
. /usr/share/openclash/ruby.sh

set_lock() {
   exec 885>"/tmp/lock/openclash_debug.lock" 2>/dev/null
   flock -x 885 2>/dev/null
}

del_lock() {
   flock -u 885 2>/dev/null
   rm -rf "/tmp/lock/openclash_debug.lock"
}

DEBUG_LOG="/tmp/openclash_debug.log"
LOGTIME=$(echo $(date "+%Y-%m-%d %H:%M:%S"))
uci -q commit openclash
set_lock

enable_custom_dns=$(uci -q get openclash.config.enable_custom_dns)
rule_source=$(uci -q get openclash.config.rule_source)
enable_custom_clash_rules=$(uci -q get openclash.config.enable_custom_clash_rules) 
ipv6_enable=$(uci -q get openclash.config.ipv6_enable)
ipv6_dns=$(uci -q get openclash.config.ipv6_dns)
enable_redirect_dns=$(uci -q get openclash.config.enable_redirect_dns)
disable_masq_cache=$(uci -q get openclash.config.disable_masq_cache)
proxy_mode=$(uci -q get openclash.config.proxy_mode)
intranet_allowed=$(uci -q get openclash.config.intranet_allowed)
enable_udp_proxy=$(uci -q get openclash.config.enable_udp_proxy)
enable_rule_proxy=$(uci -q get openclash.config.enable_rule_proxy)
en_mode=$(uci -q get openclash.config.en_mode)
RAW_CONFIG_FILE=$(uci -q get openclash.config.config_path)
CONFIG_FILE="/etc/openclash/$(uci -q get openclash.config.config_path |awk -F '/' '{print $5}' 2>/dev/null)"
core_type=$(uci -q get openclash.config.core_version)
cpu_model=$(opkg status libc 2>/dev/null |grep 'Architecture' |awk -F ': ' '{print $2}' 2>/dev/null)
core_version=$(/etc/openclash/core/clash -v 2>/dev/null |awk -F ' ' '{print $2}' 2>/dev/null)
core_tun_version=$(/etc/openclash/core/clash_tun -v 2>/dev/null |awk -F ' ' '{print $2}' 2>/dev/null)
core_meta_version=$(/etc/openclash/core/clash_meta -v 2>/dev/null |awk -F ' ' '{print $3}' 2>/dev/null)
servers_update=$(uci -q get openclash.config.servers_update)
mix_proxies=$(uci -q get openclash.config.mix_proxies)
op_version=$(opkg status luci-app-openclash 2>/dev/null |grep 'Version' |awk -F 'Version: ' '{print "v"$2}')
china_ip_route=$(uci -q get openclash.config.china_ip_route)
common_ports=$(uci -q get openclash.config.common_ports)
router_self_proxy=$(uci -q get openclash.config.router_self_proxy)

if [ -z "$RAW_CONFIG_FILE" ] || [ ! -f "$RAW_CONFIG_FILE" ]; then
	CONFIG_NAME=$(ls -lt /etc/openclash/config/ | grep -E '.yaml|.yml' | head -n 1 |awk '{print $9}')
	if [ ! -z "$CONFIG_NAME" ]; then
      RAW_CONFIG_FILE="/etc/openclash/config/$CONFIG_NAME"
      CONFIG_FILE="/etc/openclash/$CONFIG_NAME"
  fi
fi

ts_cf()
{
	if [ "$1" != 1 ]; then
	   echo "disabled"
	else
	   echo "enable"
  fi
}

ts_re()
{
	if [ -z "$1" ]; then
	   echo "Not Installed"
	else
	   echo "Installed"
  fi
}

dns_re()
{
   if [ "$1" = "1" ]; then
	   echo "Dnsmasq Forward"
   elif [ "$1" = "2" ]; then
	   echo "Firewall Forward"
   else
      echo "disabled"
   fi
}

echo "OpenClash debug log" > "$DEBUG_LOG"
cat >> "$DEBUG_LOG" <<-EOF
Translate: by reyre-stb
Generation time: $LOGTIME
Plugin version: $op_version
Privacy Tips: Before uploading this log, please pay attention to check and shield public network IP, nodes, passwords and other related sensitive information

\`\`\`
EOF

cat >> "$DEBUG_LOG" <<-EOF

#====================== System Information =======================#

Host model: $(cat /tmp/sysinfo/model 2>/dev/null)
Firmware version: $(cat /usr/lib/os-release 2>/dev/null |grep OPENWRT_RELEASE 2>/dev/null |awk -F '"' '{print $2}' 2>/dev/null)
LuCI version: $(opkg status luci 2>/dev/null |grep 'Version' |awk -F ': ' '{print $2}' 2>/dev/null)
Kernel version: $(uname -r 2>/dev/null)
Processor architecture: $cpu_model

#When this item has a value, if you do not use IPv6, it is recommended to disable IPV6 DHCP in the settings of network-interface-lan
IPV6-DHCP: $(uci -q get dhcp.lan.dhcpv6)

#This result should only have the DNS listening address of the configuration file
Dnsmasq forwarding settings: $(uci -q get dhcp.@dnsmasq[0].server)
EOF

cat >> "$DEBUG_LOG" <<-EOF

#======================= Dependency Check =======================#

dnsmasq-full: $(ts_re "$(opkg status dnsmasq-full 2>/dev/null |grep 'Status' |awk -F ': ' '{print $2}' 2>/dev/null)")
coreutils: $(ts_re "$(opkg status coreutils 2>/dev/null |grep 'Status' |awk -F ': ' '{print $2}' 2>/dev/null)")
coreutils-nohup: $(ts_re "$(opkg status coreutils-nohup 2>/dev/null |grep 'Status' |awk -F ': ' '{print $2}' 2>/dev/null)")
bash: $(ts_re "$(opkg status bash 2>/dev/null |grep 'Status' |awk -F ': ' '{print $2}' 2>/dev/null)")
curl: $(ts_re "$(opkg status curl 2>/dev/null |grep 'Status' |awk -F ': ' '{print $2}' 2>/dev/null)")
ca-certificates: $(ts_re "$(opkg status ca-certificates 2>/dev/null |grep 'Status' |awk -F ': ' '{print $2}' 2>/dev/null)")
ipset: $(ts_re "$(opkg status ipset 2>/dev/null |grep 'Status' |awk -F ': ' '{print $2}' 2>/dev/null)")
ip-full: $(ts_re "$(opkg status ip-full 2>/dev/null |grep 'Status' |awk -F ': ' '{print $2}' 2>/dev/null)")
libcap: $(ts_re "$(opkg status libcap 2>/dev/null |grep 'Status' |awk -F ': ' '{print $2}' 2>/dev/null)")
libcap-bin: $(ts_re "$(opkg status libcap-bin 2>/dev/null |grep 'Status' |awk -F ': ' '{print $2}' 2>/dev/null)")
ruby: $(ts_re "$(opkg status ruby 2>/dev/null |grep 'Status' |awk -F ': ' '{print $2}' 2>/dev/null)")
ruby-yaml: $(ts_re "$(opkg status ruby-yaml 2>/dev/null |grep 'Status' |awk -F ': ' '{print $2}' 2>/dev/null)")
ruby-psych: $(ts_re "$(opkg status ruby-psych 2>/dev/null |grep 'Status' |awk -F ': ' '{print $2}' 2>/dev/null)")
ruby-pstore: $(ts_re "$(opkg status ruby-pstore 2>/dev/null |grep 'Status' |awk -F ': ' '{print $2}' 2>/dev/null)")
kmod-tun(TUN mode): $(ts_re "$(opkg status kmod-tun 2>/dev/null |grep 'Status' |awk -F ': ' '{print $2}' 2>/dev/null)")
luci-compat(Luci >= 19.07): $(ts_re "$(opkg status luci-compat 2>/dev/null |grep 'Status' |awk -F ': ' '{print $2}' 2>/dev/null)")
kmod-inet-diag(PROCESS-NAME): $(ts_re "$(opkg status kmod-inet-diag 2>/dev/null |grep 'Status' |awk -F ': ' '{print $2}' 2>/dev/null)")
unzip: $(ts_re "$(opkg status unzip 2>/dev/null |grep 'Status' |awk -F ': ' '{print $2}' 2>/dev/null)")
EOF
if [ -n "$(command -v fw4)" ]; then
cat >> "$DEBUG_LOG" <<-EOF
kmod-nft-tproxy: $(ts_re "$(opkg status kmod-nft-tproxy 2>/dev/null |grep 'Status' |awk -F ': ' '{print $2}' 2>/dev/null)")
EOF
else
cat >> "$DEBUG_LOG" <<-EOF
iptables-mod-tproxy: $(ts_re "$(opkg status iptables-mod-tproxy 2>/dev/null |grep 'Status' |awk -F ': ' '{print $2}' 2>/dev/null)")
kmod-ipt-tproxy: $(ts_re "$(opkg status kmod-ipt-tproxy 2>/dev/null |grep 'Status' |awk -F ': ' '{print $2}' 2>/dev/null)")
iptables-mod-extra: $(ts_re "$(opkg status iptables-mod-extra 2>/dev/null |grep 'Status' |awk -F ': ' '{print $2}' 2>/dev/null)")
kmod-ipt-extra: $(ts_re "$(opkg status kmod-ipt-extra 2>/dev/null |grep 'Status' |awk -F ': ' '{print $2}' 2>/dev/null)")
kmod-ipt-nat: $(ts_re "$(opkg status kmod-ipt-nat 2>/dev/null |grep 'Status' |awk -F ': ' '{print $2}' 2>/dev/null)")
EOF
fi

EOF

#core
cat >> "$DEBUG_LOG" <<-EOF

#====================== Kernel Check =======================#

EOF
if pidof clash >/dev/null; then
cat >> "$DEBUG_LOG" <<-EOF
Running status: Running
Process pid: $(pidof clash)
Run permissions: `getpcaps $(pidof clash)`
Run as user: $(ps |grep "/etc/openclash/clash" |grep -v grep |awk '{print $2}' 2>/dev/null)
EOF
else
cat >> "$DEBUG_LOG" <<-EOF
Running status: not running
EOF
fi
if [ "$core_type" = "0" ]; then
   core_type="no schema selected"
fi
cat >> "$DEBUG_LOG" <<-EOF
Selected architecture: $core_type

#When the kernel version number cannot be displayed below, please confirm whether your kernel version is correct or whether you have permission
EOF

cat >> "$DEBUG_LOG" <<-EOF
Tun kernel version: $core_tun_version
EOF
if [ ! -f "/etc/openclash/core/clash_tun" ]; then
cat >> "$DEBUG_LOG" <<-EOF
Tun kernel file: does not exist
EOF
else
cat >> "$DEBUG_LOG" <<-EOF
Tun kernel file: exists
EOF
fi
if [ ! -x "/etc/openclash/core/clash_tun" ]; then
cat >> "$DEBUG_LOG" <<-EOF
Tun kernel operation permission: No
EOF
else
cat >> "$DEBUG_LOG" <<-EOF
Tun kernel operation permission: normal
EOF
fi

cat >> "$DEBUG_LOG" <<-EOF

Dev kernel version: $core_version
EOF
if [ ! -f "/etc/openclash/core/clash" ]; then
cat >> "$DEBUG_LOG" <<-EOF
Dev kernel file: does not exist
EOF
else
cat >> "$DEBUG_LOG" <<-EOF
Dev kernel file: exists
EOF
fi
if [ ! -x "/etc/openclash/core/clash" ]; then
cat >> "$DEBUG_LOG" <<-EOF
Dev kernel running permission: No
EOF
else
cat >> "$DEBUG_LOG" <<-EOF
Dev kernel operation permission: normal
EOF
fi

cat >> "$DEBUG_LOG" <<-EOF

Meta core version: $core_meta_version
EOF

if [ ! -f "/etc/openclash/core/clash_meta" ]; then
cat >> "$DEBUG_LOG" <<-EOF
Meta core file: does not exist
EOF
else
cat >> "$DEBUG_LOG" <<-EOF
Meta core file: exists
EOF
fi
if [ ! -x "/etc/openclash/core/clash_meta" ]; then
cat >> "$DEBUG_LOG" <<-EOF
Meta kernel operation permission: no
EOF
else
cat >> "$DEBUG_LOG" <<-EOF
Meta kernel operation permission: normal
EOF
fi

cat >> "$DEBUG_LOG" <<-EOF

#====================== Plugin Settings ========================#

Current configuration file: $RAW_CONFIG_FILE
Startup configuration file: $CONFIG_FILE
Run mode: $en_mode
Default proxy mode: $proxy_mode
UDP traffic forwarding (tproxy): $(ts_cf "$enable_udp_proxy")
DNS hijacking: $(dns_re "$enable_redirect_dns")
Custom DNS: $(ts_cf "$enable_custom_dns")
IPV6 proxy: $(ts_cf "$ipv6_enable")
IPV6-DNS resolution: $(ts_cf "$ipv6_dns")
Disable Dnsmasq cache: $(ts_cf "$disable_masq_cache")
Custom rules: $(ts_cf "$enable_custom_clash_rules")
Intranet only: $(ts_cf "$intranet_allowed")
Proxy only hit rule traffic: $(ts_cf "$enable_rule_proxy")
Only allow common port traffic: $(ts_cf "$common_ports")
Bypass Mainland China IP: $(ts_cf "$china_ip_route")
Router native proxy: $(ts_cf "$router_self_proxy")

#When the startup is abnormal, it is recommended to close this item and try again
Mix node: $(ts_cf "$mix_proxies")
Keep configuration: $(ts_cf "$servers_update")
EOF

cat >> "$DEBUG_LOG" <<-EOF

#When the startup is abnormal, it is recommended to close this item and try again
Third-party rules: $(ts_cf "$rule_source")
EOF


if [ "$enable_custom_clash_rules" -eq 1 ]; then
cat >> "$DEBUG_LOG" <<-EOF

#======================= Custom Rules One =======================#
EOF
cat /etc/openclash/custom/openclash_custom_rules.list >> "$DEBUG_LOG"

cat >> "$DEBUG_LOG" <<-EOF

#======================= Custom Rules II =======================#
EOF
cat /etc/openclash/custom/openclash_custom_rules_2.list >> "$DEBUG_LOG"
fi

cat >> "$DEBUG_LOG" <<-EOF

#======================= Configuration file =======================#

EOF
if [ -f "$CONFIG_FILE" ]; then
   ruby_read "$CONFIG_FILE" ".select {|x| 'proxies' != x and 'proxy-providers' != x }.to_yaml" 2>/dev/null >> "$DEBUG_LOG"
else
   ruby_read "$RAW_CONFIG_FILE" ".select {|x| 'proxies' != x and 'proxy-providers' != x }.to_yaml" 2>/dev/null >> "$DEBUG_LOG"
fi

sed -i '/^ \{0,\}secret:/d' "$DEBUG_LOG" 2>/dev/null

#firewall
cat >> "$DEBUG_LOG" <<-EOF

#======================= Custom Firewall Settings =======================#

EOF

cat /etc/openclash/custom/openclash_custom_firewall_rules.sh >> "$DEBUG_LOG" 2>/dev/null

cat >> "$DEBUG_LOG" <<-EOF

#======================= IPTABLES Firewall Settings =======================#

#IPv4 NAT chain

EOF
iptables-save -t nat >> "$DEBUG_LOG" 2>/dev/null

cat >> "$DEBUG_LOG" <<-EOF

#IPv4 Mangle chain

EOF
iptables-save -t mangle >> "$DEBUG_LOG" 2>/dev/null

cat >> "$DEBUG_LOG" <<-EOF

#IPv4 Filter chain

EOF
iptables-save -t filter >> "$DEBUG_LOG" 2>/dev/null

cat >> "$DEBUG_LOG" <<-EOF

#IPv6 NAT chain

EOF
ip6tables-save -t nat >> "$DEBUG_LOG" 2>/dev/null

cat >> "$DEBUG_LOG" <<-EOF

#IPv6 Mangle chain

EOF
ip6tables-save -t mangle >> "$DEBUG_LOG" 2>/dev/null

cat >> "$DEBUG_LOG" <<-EOF

#IPv6 Filter chain

EOF
ip6tables-save -t filter >> "$DEBUG_LOG" 2>/dev/null

if [ -n "$(command -v fw4)" ]; then
cat >> "$DEBUG_LOG" <<-EOF

#======================= NFTABLES Firewall Settings =======================#

EOF
   for nft in "input" "forward" "dstnat" "srcnat" "nat_output" "mangle_prerouting" "mangle_output"; do
      nft list chain inet fw4 "$nft" >> "$DEBUG_LOG" 2>/dev/null
   done >/dev/null 2>&1
   for nft in "openclash" "openclash_mangle" "openclash_mangle_output" "openclash_output" "openclash_post" "openclash_wan_input" "openclash_dns_hijack" "openclash_mangle_v6" "openclash_mangle_output_v6" "openclash_post_v6" "openclash_wan6_input"; do
      nft list chain inet fw4 "$nft" >> "$DEBUG_LOG" 2>/dev/null
   done >/dev/null 2>&1
fi

cat >> "$DEBUG_LOG" <<-EOF

#====================== IPSET STATUS =======================#

EOF
ipset list |grep "Name:" >> "$DEBUG_LOG"

cat >> "$DEBUG_LOG" <<-EOF

#======================= Routing Table Status ========================#

EOF
echo "#route -n" >> "$DEBUG_LOG"
route -n >> "$DEBUG_LOG" 2>/dev/null
echo "#ip route list" >> "$DEBUG_LOG"
ip route list >> "$DEBUG_LOG" 2>/dev/null
echo "#ip rule show" >> "$DEBUG_LOG"
ip rule show >> "$DEBUG_LOG" 2>/dev/null

if [ "$en_mode" != "fake-ip" ] && [ "$en_mode" != "redir-host" ]; then
cat >> "$DEBUG_LOG" <<-EOF

#====================== Tun device status =======================#

EOF
ip tuntap list >> "$DEBUG_LOG" 2>/dev/null
fi

cat >> "$DEBUG_LOG" <<-EOF

#====================== Port Occupancy Status =======================#

EOF
netstat -nlp |grep clash >> "$DEBUG_LOG" 2>/dev/null

cat >> "$DEBUG_LOG" <<-EOF

#======================= Test local DNS query (www.baidu.com) ======================#

EOF
nslookup www.baidu.com >> "$DEBUG_LOG" 2>/dev/null

cat >> "$DEBUG_LOG" <<-EOF

#====================== Test kernel DNS query (www.instagram.com) ======================#

EOF
/usr/share/openclash/openclash_debug_dns.lua "www.instagram.com" >> "$DEBUG_LOG" 2>/dev/null

if [ -s "/tmp/resolv.conf.auto" ]; then
cat >> "$DEBUG_LOG" <<-EOF

#===================== resolve.conf.auto =====================#

EOF
cat /tmp/resolv.conf.auto >> "$DEBUG_LOG"
fi

if [ -s "/tmp/resolv.conf.d/resolv.conf.auto" ]; then
cat >> "$DEBUG_LOG" <<-EOF

#===================== resolv.conf.d =====================#

EOF
cat /tmp/resolv.conf.d/resolv.conf.auto >> "$DEBUG_LOG"
fi

cat >> "$DEBUG_LOG" <<-EOF

#======================= Test local network connection (www.baidu.com) ======================#

EOF
curl -SsI -m 5 www.baidu.com >> "$DEBUG_LOG" 2>/dev/null

cat >> "$DEBUG_LOG" <<-EOF

#======================= Test local network download (raw.githubusercontent.com) ======================#

EOF
VERSION_URL="https://raw.githubusercontent.com/vernesong/OpenClash/master/version"
if pidof clash >/dev/null; then
   curl -SsIL -m 3 --retry 2 "$VERSION_URL" >> "$DEBUG_LOG" 2>/dev/null
else
   curl -SsIL -m 3 --retry 2 "$VERSION_URL" >> "$DEBUG_LOG" 2>/dev/null
fi

cat >> "$DEBUG_LOG" <<-EOF

#======================= Recent log =======================#

EOF
tail -n 50 "/tmp/openclash.log" >> "$DEBUG_LOG" 2>/dev/null

cat >> "$DEBUG_LOG" <<-EOF

#======================= Active Connection Information ========================#

EOF
/usr/share/openclash/openclash_debug_getcon.lua

cat >> "$DEBUG_LOG" <<-EOF

\`\`\`
EOF

wan_ip=$(/usr/share/openclash/openclash_get_network.lua "wanip")
wan_ip6=$(/usr/share/openclash/openclash_get_network.lua "wanip6")

if [ -n "$wan_ip" ]; then
	for i in $wan_ip; do
      wanip=$(echo "$i" |awk -F '.' '{print $1"."$2"."$3}')
      sed -i "s/${wanip}/*WAN IP*/g" "$DEBUG_LOG" 2>/dev/null
  done
fi

if [ -n "$wan_ip6" ]; then
	for i in $wan_ip6; do
      wanip=$(echo "$i" |awk -F: 'OFS=":",NF-=1')
      sed -i "s/${wanip}/*WAN IP*/g" "$DEBUG_LOG" 2>/dev/null
  done
fi

del_lock