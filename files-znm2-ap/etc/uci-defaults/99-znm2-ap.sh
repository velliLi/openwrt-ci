#!/bin/sh
# ZN-M2 纯AP模式 - 首次启动初始化
# 所有网口(lan1 lan2 lan3 wan)与双频WiFi桥接为 br-lan，
# br-lan 通过 DHCP 从上级路由器自动获取管理IP

# ---------- 1. 网络：纯AP桥接 ----------
uci -q delete network.wan
uci -q delete network.wan6
uci -q delete network.lan

uci set network.lan=interface
uci set network.lan.proto='dhcp'
uci set network.lan.device='br-lan'
uci set network.lan.force_link='1'

# 删除 config_generate 生成的旧 br-lan 设备定义
idx=0
while uci -q get "network.@device[$idx].name" >/dev/null; do
	[ "$(uci -q get network.@device[$idx].name)" = "br-lan" ] && {
		uci delete "network.@device[$idx]"
		break
	}
	idx=$((idx+1))
done

uci set network.brlan=device
uci set network.brlan.name='br-lan'
uci set network.brlan.type='bridge'
uci set network.brlan.ports='lan1 lan2 lan3 wan'

# ---------- 2. 无线：双频 AP ----------
for r in 0 1; do
	uci set wireless.radio$r.disabled='0'
	uci set wireless.radio$r.country='CN'
done

uci set wireless.default_radio0.mode='ap'
uci set wireless.default_radio0.network='lan'
uci set wireless.default_radio0.ssid='ZN-M2-AP'
uci set wireless.default_radio0.encryption='none'

uci set wireless.default_radio1.mode='ap'
uci set wireless.default_radio1.network='lan'
uci set wireless.default_radio1.ssid='ZN-M2-AP'
uci set wireless.default_radio1.encryption='none'

# ---------- 3. 系统：主机名与主题 ----------
uci set system.@system[0].hostname='ZN-M2-AP'
uci set luci.main.mediaurlbase='/luci-static/argon'

uci commit
exit 0
