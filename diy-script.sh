#!/bin/bash

# 1. 基础配置修改
sed -i 's/192.168.1.1/192.168.2.1/g' package/base-files/files/bin/config_generate

# 2. 清理冲突项
rm -rf feeds/packages/net/mosdns
rm -rf feeds/packages/net/msd_lite
rm -rf feeds/packages/net/smartdns
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/applications/luci-app-mosdns
rm -rf feeds/luci/applications/luci-app-netdata
rm -rf feeds/luci/applications/luci-app-serverchan

# 3. 下载插件 (保持你需要的)
git clone --depth=1 https://github.com/kongfl888/luci-app-adguardhome package/luci-app-adguardhome
git clone --depth=1 https://github.com/Jason6111/luci-app-netdata package/luci-app-netdata
git clone --depth=1 -b lede https://github.com/pymumu/luci-app-smartdns package/luci-app-smartdns
git clone --depth=1 https://github.com/pymumu/openwrt-smartdns package/smartdns
git clone --depth=1 -b 18.06 https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config package/luci-app-argon-config

# 4. 更新 feeds (这一步会拉回 hostapd)
./scripts/feeds update -a
./scripts/feeds install -a

# 5. 【关键步】执行完 feeds 后再次强制删除无线残留
# 这是防止系统由于依赖关系自动补回 hostapd 导致编译失败
rm -rf package/network/services/hostapd
rm -rf feeds/packages/net/wpad
rm -rf feeds/packages/net/hostapd
rm -rf feeds/packages/net/ath11k-firmware
