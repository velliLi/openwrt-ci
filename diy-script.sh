#!/bin/bash

# ================================
# 1. 修改基础系统设置
# ================================

# 修改默认 LAN IP
sed -i 's/192.168.1.1/192.168.2.1/g' package/base-files/files/bin/config_generate

# ttyd 免登录
sed -i 's|/bin/login|/bin/login -f root|g' feeds/packages/utils/ttyd/files/ttyd.config


# ================================
# 2. 更新 feeds（必须放在最前）
# ================================
./scripts/feeds update -a
./scripts/feeds install -a


# ================================
# 3. 删除 feeds 中旧版插件
# ================================
rm -rf feeds/luci/applications/luci-app-passwall2
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/applications/luci-app-argon-config
rm -rf feeds/luci/applications/luci-app-attendedsysupgrade


# ================================
# 4. clone 最新插件（不会被覆盖）
# ================================
# Passwall2
git clone --depth=1 https://github.com/velliLi/openwrt-passwall2 package/luci-app-passwall2
git clone --depth=1 https://github.com/Openwrt-Passwall/openwrt-passwall-packages package/openwrt-passwall-packages

# Argon 主题
git clone --depth=1 https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config package/luci-app-argon-config

# Lucky
git clone --depth=1 https://github.com/gdy666/lucky package/lucky

# MosDNS
git clone --depth=1 https://github.com/sbwml/luci-app-mosdns package/luci-app-mosdns


# ================================
# 5. 修复 mbedtls 在 GCC14 下 memset inline 失败
# ================================
patch -p1 << "EOF"
--- a/package/libs/mbedtls/Makefile
+++ b/package/libs/mbedtls/Makefile
@@ -54,6 +54,7 @@ define Build/Compile
        $(call Build/Compile/Default)
 endef

+TARGET_CFLAGS += -fno-builtin-memset -fno-tree-loop-distribute-patterns

 EOF


# ================================
# 6. 写入补充配置（避免被覆盖）
# ================================
cat >> .config <<EOF
CONFIG_PACKAGE_luci-app-passwall2=y
CONFIG_PACKAGE_luci-app-passwall2_INCLUDE_SingBox=y
CONFIG_PACKAGE_luci-app-passwall2_Nftables_Transparent_Proxy=y
CONFIG_PACKAGE_luci-theme-argon=y
CONFIG_PACKAGE_luci-app-argon-config=y
EOF
