#!/bin/bash

# 进入 OpenWrt 源码目录 (CI 环境中通常已在当前目录)
# cd $OPENWRT_PATH

# 1. 基础系统设置：修改默认 IP
sed -i 's/192.168.1.1/192.168.2.1/g' package/base-files/files/bin/config_generate

# ttyd 免登录
sed -i 's|/bin/login|/bin/login -f root|g' feeds/packages/utils/ttyd/files/ttyd.config

# 2. 清理冲突及旧版插件 (确保 feeds 更新前清理干净)
rm -rf feeds/packages/net/smartdns
rm -rf feeds/luci/applications/luci-app-smartdns
rm -rf feeds/luci/applications/luci-app-mosdns
rm -rf feeds/luci/applications/luci-app-passwall
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/applications/luci-app-argon-config
rm -rf feeds/packages/net/v2ray-geodata

# 清理旧版 mosdns 和 v2ray-geodata 的 Makefile (避免包名冲突)
find ./ | grep Makefile | grep mosdns | xargs rm -f 2>/dev/null || true
find ./ | grep Makefile | grep v2ray-geodata | xargs rm -f 2>/dev/null || true

# 3. 刷新并安装 Feeds
./scripts/feeds update -a
./scripts/feeds install -a

# 4. 集成最新版 PassWall2 与 Argon (修正分支问题)
# 核心依赖包
git clone --depth=1 https://github.com/Openwrt-Passwall/openwrt-passwall-packages package/openwrt-passwall-packages
# PassWall2 主程序
git clone --depth=1 https://github.com/velliLi/openwrt-passwall2 package/luci-app-passwall2
# Argon 主题：移除 -b 18.06 以兼容新版 OpenWrt 界面
git clone --depth=1 https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config package/luci-app-argon-config
# 补全Lucky
git clone --depth=1 https://github.com/gdy666/luci-app-lucky package/lucky
# MosDNS v5 (包含 mosdns 二进制 + luci-app + v2dat)
git clone --depth=1 https://github.com/sbwml/luci-app-mosdns -b v5 package/mosdns
git clone --depth=1 https://github.com/sbwml/v2ray-geodata package/v2ray-geodata

# 更新 golang 至 1.24+ (mosdns v5 编译需要)
rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang -b 24.x feeds/packages/lang/golang
# SmartDNS
git clone --depth=1 -b lede https://github.com/pymumu/luci-app-smartdns package/luci-app-smartdns
git clone --depth=1 https://github.com/pymumu/openwrt-smartdns package/smartdns

# 5. 统一防火墙至 NFT (解决 6.x 内核兼容性)
find ./feeds/ -name "Makefile" | xargs sed -i 's/iptables /iptables-nft /g'
find ./package/ -name "Makefile" | xargs sed -i 's/iptables /iptables-nft /g'
find ./feeds/ -name "Makefile" | xargs sed -i 's/xtables-legacy//g'

# 6. 写入 .config 配置补丁 (与 diy.config 配合作为双重保障)
cat >> .config <<EOF
# PassWall2 推荐配置：使用 Sing-Box 核心并开启 NFT 代理
CONFIG_PACKAGE_luci-app-passwall2=y
CONFIG_PACKAGE_luci-app-passwall2_Nftables_Transparent_Proxy=y
CONFIG_PACKAGE_luci-app-passwall2_INCLUDE_SingBox=y

#Lucky
CONFIG_PACKAGE_lucky=y
CONFIG_PACKAGE_luci-app-lucky=y

# 默认主题设置
CONFIG_PACKAGE_luci-theme-argon=y
CONFIG_PACKAGE_luci-app-argon-config=y

# MosDNS
CONFIG_PACKAGE_mosdns=y
CONFIG_PACKAGE_luci-app-mosdns=y

# 防火墙与证书补全
CONFIG_PACKAGE_ca-bundle=y
EOF

# 8. 最后刷新依赖
make defconfig
