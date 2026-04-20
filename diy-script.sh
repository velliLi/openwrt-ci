#!/bin/bash

# 1. 基础系统设置
sed -i 's/192.168.1.1/192.168.2.1/g' package/base-files/files/bin/config_generate
sed -i 's|/bin/login|/bin/login -f root|g' feeds/packages/utils/ttyd/files/ttyd.config

# 2. 清理冲突插件 (这一步非常重要，防止老版本 Passwall 干扰)
rm -rf feeds/luci/applications/luci-app-passwall
rm -rf feeds/luci/applications/luci-app-passwall2
rm -rf feeds/packages/net/sing-box
rm -rf feeds/packages/net/v2ray-geodata

# 3. 刷新并安装 Feeds
./scripts/feeds update -a
./scripts/feeds install -a

# 4. 集成你的自定义 PassWall2 与相关包
# 移除已有的同名目录，确保 git clone 成功
rm -rf package/luci-app-passwall2
git clone --depth=1 https://github.com/velliLi/openwrt-passwall2 package/luci-app-passwall2

# Passwall 依赖包 (由于你用了纯 sing-box，这些包依然需要提供 chinadns-ng 等)
rm -rf package/openwrt-passwall-packages
git clone --depth=1 https://github.com/Openwrt-Passwall/openwrt-passwall-packages package/openwrt-passwall-packages

# Argon 主题与 Lucky
git clone --depth=1 https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config package/luci-app-argon-config
git clone --depth=1 https://github.com/gdy666/luci-app-lucky package/lucky

# 5. 防火墙环境统一 (适配 Firewall4/NFT)
# 强制将所有旧的 iptables 依赖项映射到 nft
sed -i 's/iptables-mod-tproxy/iptables-nft/g' package/luci-app-passwall2/Makefile
find ./package/ -name "Makefile" | xargs sed -i 's/iptables /iptables-nft /g'

# 6. 核心优化：强制选中你修改后的配置项
# 注意：CONFIG_PACKAGE_sing-box 必须显式选中，否则 passwall2 找不到核心
cat >> .config <<EOF
# 基础防火墙
CONFIG_PACKAGE_iptables-nft=y
CONFIG_PACKAGE_ip6tables-nft=y
CONFIG_PACKAGE_ca-bundle=y

# PassWall2 核心配置
CONFIG_PACKAGE_luci-app-passwall2=y
CONFIG_PACKAGE_luci-app-passwall2_Nftables_Transparent_Proxy=y
CONFIG_PACKAGE_luci-app-passwall2_INCLUDE_SingBox=y
# 显式选中 sing-box (必选)
CONFIG_PACKAGE_sing-box=y

# 禁用不需要的 geodata 包以节省空间 (因为你用了 .srs)
# CONFIG_PACKAGE_v2ray-geoip is not set
# CONFIG_PACKAGE_v2ray-geosite is not set

# 主题
CONFIG_PACKAGE_luci-theme-argon=y
CONFIG_PACKAGE_luci-app-argon-config=y
EOF

# 7. 修正依赖并自动补全 config
make defconfig
