#!/system/bin/sh
# hide_mumu_files v2.1
# 只隐藏反检测目标文件，不破坏 VM 核心功能

MODDIR=/data/adb/modules/hide_mumu_files
EMPTY_FILE=$MODDIR/empty
EMPTY_DIR=$MODDIR/empty_dir
touch $EMPTY_FILE
mkdir -p $EMPTY_DIR

# ========== 安全可隐藏的系统 bin（不会破坏 VM 启动） ==========
for bin in nemuinit; do
    TARGET="/system/bin/$bin"
    if [ -f "$TARGET" ]; then
        mount --bind $EMPTY_FILE "$TARGET" 2>/dev/null
    fi
done

# ========== 注意：不隐藏 nemuVM-nemu-service/control/input ==========
# 这些是 VM 核心进程，隐藏后 MuMu 无法启动

# ========== 模拟器配置文件目录 -> 空目录 ==========
if [ -d /system/etc/mumu-configs ]; then
    mount --bind $EMPTY_DIR /system/etc/mumu-configs 2>/dev/null
fi

# ========== 模拟器应用数据 (data/data) -> 空目录 ==========
for dir in com.mumu.store com.mumu.acc com.mumu.shared.sdk com.nemu.nlp com.nemu.oaidmanager; do
    TARGET="/data/data/$dir"
    if [ -d "$TARGET" ]; then
        mount --bind $EMPTY_DIR "$TARGET" 2>/dev/null
    fi
done

# ========== 模拟器共享存储数据 -> 空目录 ==========
for dir in com.mumu.store com.mumu.acc; do
    TARGET="/data/media/0/Android/data/$dir"
    if [ -d "$TARGET" ]; then
        mount --bind $EMPTY_DIR "$TARGET" 2>/dev/null
    fi
done
