#!/bin/bash

# ZN-M2 纯AP固件 DIY 脚本

# 1. 清理旧版插件 (防止冲突)
rm -rf feeds/luci/applications/luci-app-passwall
rm -rf feeds/luci/applications/luci-app-passwall2

# 2. 集成最新版 PassWall2
# 核心依赖包 (sing-box / dns2socks / xray-core 等)
git clone --depth=1 https://github.com/Openwrt-Passwall/openwrt-passwall-packages package/openwrt-passwall-packages
# PassWall2 主程序
git clone --depth=1 https://github.com/Openwrt-Passwall/openwrt-passwall2 package/luci-app-passwall2

# 3. 写入 .config 配置补丁 (与 znm2-ap.config 配合作为双重保障)
cat >> .config <<EOF
# PassWall2 推荐配置：使用 Sing-Box 核心并开启 NFT 代理
CONFIG_PACKAGE_luci-app-passwall2=y
CONFIG_PACKAGE_luci-i18n-passwall2-zh-cn=y
CONFIG_PACKAGE_luci-app-passwall2_Nftables_Transparent_Proxy=y
CONFIG_PACKAGE_luci-app-passwall2_INCLUDE_SingBox=y
CONFIG_PACKAGE_sing-box=y
CONFIG_PCRE2_JIT_ENABLED=y
EOF

# 4. 最后刷新依赖
make defconfig
