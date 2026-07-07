#!/system/bin/sh
# remove_mumu_ads_v5
# Bind-mount 空文件覆盖 MuMu 广告/非核心系统应用 APK
# 注意：不碰 nemu-vinput-pack/nemu-cloner/nemu-vapi-android-pack
# 这些是 VM 输入/API 核心组件，移除会导致功能异常

EMPTY=/data/adb/modules/remove_mumu_ads_v5/empty.apk
touch $EMPTY

# 游戏中心（广告）
mount -o bind $EMPTY /system/priv-app/com.mumu.store/com.mumu.store.apk 2>/dev/null

# 账号服务（广告）
mount -o bind $EMPTY /system/priv-app/com.mumu.acc/com.mumu.acc.apk 2>/dev/null

# NLP 服务（广告推送）
mount -o bind $EMPTY /system/priv-app/com.nemu.nlp/com.nemu.nlp.apk 2>/dev/null

# OAID 管理器（广告追踪）
mount -o bind $EMPTY /system/priv-app/com.nemu.oaidmanager/com.nemu.oaidmanager.apk 2>/dev/null

# Shared SDK（广告 SDK）
mount -o bind $EMPTY /system/priv-app/com.mumu.shared.sdk/com.mumu.shared.sdk.apk 2>/dev/null
