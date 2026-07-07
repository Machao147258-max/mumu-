# MuMu 模拟器伪装 Redmi K40S 完整指南

## 环境信息
- **模拟器版本**: MuMu Player 12 (Android 12)
- **伪装目标**: Redmi K40S (开发代号 `munch`，骁龙 870 / `kona` 平台)
- **核心目的**: 通过修改系统属性和配置文件，使模拟器在基础检测中呈现为真实的 Redmi K40S 设备

---

## 第一阶段：机型伪装（硬件属性）

### 关键参数

| 参数 | Key | 目标值 |
|:---|:---|:---|
| 手机型号 | `ro.product.model` | `22021211RC` |
| 手机品牌 | `ro.product.brand` | `Xiaomi` |
| 设备代号 | `ro.product.device` | `munch` |
| 制造商 | `ro.product.manufacturer` | `Xiaomi` |
| 主板平台 | `ro.board.platform` | `kona` |
| 硬件标识 | `ro.hardware` | `qcom` |
| 屏幕密度 | `ro.sf.lcd_density` | `440` |

### 实施步骤

**1. 外部配置修改（持久化）**

文件路径：`D:\MuMuPlayer\vms\MuMuPlayer-12.0-0\configs\customer_config.json`

```json
"phone": {
  "brand": "Xiaomi",
  "code": "munch",
  "imei": "865146042407069",
  "manufacturer": "Xiaomi",
  "miit": "22021211RC",
  "mode": {
    "choose": "phone.mode.custom"
  },
  "model": "22021211RC",
  "number": "",
  "vdid": "72216d2d-2a42-422a-8aa7-e0f398be9459"
}
```

> `phone.mode` 必须设为 `custom`，否则模拟器会使用预设模板覆盖自定义设置。

**2. 内部属性修正**

```bash
adb.exe -s 127.0.0.1:7555 shell
su
echo ro.product.device=munch > /data/local.prop
echo ro.product.manufacturer=Xiaomi >> /data/local.prop
echo ro.board.platform=kona >> /data/local.prop
echo ro.hardware=qcom >> /data/local.prop
chmod 644 /data/local.prop
```

**3. 底层服务覆盖（Magisk 模块）**

MuMu 内置 `nemuinit` 服务会在启动时强制重置 `ro.board.platform` 和 `ro.hardware`。使用 Magisk 模块 `fix_k40s_board_hardware` 的 `post-fs-data.sh` 对其覆盖：

```bash
#!/system/bin/sh
resetprop ro.board.platform kona
resetprop ro.hardware qcom
resetprop ro.product.device munch
```

### 验证命令

```bash
adb.exe -s 127.0.0.1:7555 shell "getprop ro.product.model && getprop ro.product.brand && getprop ro.product.device && getprop ro.product.manufacturer && getprop ro.board.platform && getprop ro.hardware"
```

预期输出：`22021211RC` / `Xiaomi` / `munch` / `Xiaomi` / `kona` / `qcom`

### 注意事项
- 品牌必须选择 **`Xiaomi`**（而非 `Redmi`），否则底层硬件映射会错误
- 修改完成后必须完全退出模拟器（右键托盘图标 -> 退出），再重新打开
- `/system/etc/rand_dev_prop/` 下存在随机机型文件，建议统一替换

---

## 第二阶段：系统指纹伪装

### 关键参数

| 参数 | Key | 目标值 |
|:---|:---|:---|
| 系统指纹 | `ro.build.fingerprint` | `Redmi/munch/munch:12/SKQ1.211006.001/V13.0.5.0.SLMCNXM:user/release-keys` |
| 系统描述 | `ro.build.description` | `munch-user 12 SKQ1.211006.001 V13.0.5.0.SLMCNXM release-keys` |
| 安全补丁 | `ro.build.version.security_patch` | `2022-05-01` |

### Magisk 模块 `fix_k40s_fingerprint`

```bash
#!/system/bin/sh
resetprop ro.build.fingerprint Redmi/munch/munch:12/SKQ1.211006.001/V13.0.5.0.SLMCNXM:user/release-keys
resetprop ro.system.build.fingerprint Redmi/munch/munch:12/SKQ1.211006.001/V13.0.5.0.SLMCNXM:user/release-keys
resetprop ro.vendor.build.fingerprint Redmi/munch/munch:12/SKQ1.211006.001/V13.0.5.0.SLMCNXM:user/release-keys
resetprop ro.build.description munch-user 12 SKQ1.211006.001 V13.0.5.0.SLMCNXM release-keys
resetprop ro.build.version.security_patch 2022-05-01
```

### 注意事项
- 部分深度检测 App 会分别读取 system 和 vendor 的指纹，两者不一致会被判定异常
- `ro.build.description` 有时无法完全覆盖，大多数 App 主要校验 `ro.build.fingerprint`

---

## 第三阶段：文件系统绕过

### 完整残留文件清单

| 路径 | 类型 | 说明 |
|:---|:---|:---|
| `/system/bin/nemuinit` | 可执行文件 | MuMu 核心初始化服务，强制重置硬件属性 |
| `/system/bin/nemuinput` | 可执行文件 | 虚拟输入设备 |
| `/system/bin/nemufreepfn` | 可执行文件 | 物理页帧号管理 |
| `/system/bin/nemu_sys_opt` | 可执行文件 | 系统优化服务 |
| `/system/bin/nemuVM-nemu-service` | 可执行文件 | VM 服务 |
| `/system/bin/nemuVM-nemu-control` | 可执行文件 | VM 控制 |
| `/system/bin/new.mount.nemusf` | 可执行文件 | SF 挂载 |
| `/system/bin/new.nemuVM-nemu-sf` | 可执行文件 | VM SF |
| `/system/lib/libnemuinitaidl.so` | 系统库 | 32位 init AIDL |
| `/system/lib64/libnemuinitaidl.so` | 系统库 | 64位 init AIDL |
| `/system/lib64/mumuvmmguest.ko` | 内核模块 | MuMu VM guest |
| `/system/lib64/mumuvmmsf.ko` | 内核模块 | MuMu VM SF |
| `/system/etc/mumu-configs/` | 配置目录 | 设备配置档案（40+ 文件含 `mumu.config` 暴露源信息） |
| `/system/priv-app/nemu-vinput-pack/` | 系统应用 | 虚拟输入包 |
| `/system/priv-app/nemu-cloner/` | 系统应用 | 设备克隆器 |
| `/system/priv-app/nemu-vapi-android-pack/` | 系统应用 | VAPI Android 包 |
| `/system/priv-app/com.mumu.store/` | 系统应用 | MuMu 游戏中心 |
| `/system/priv-app/com.mumu.acc/` | 系统应用 | MuMu 账号服务 |
| `/system/priv-app/com.nemu.nlp/` | 系统应用 | NLP 服务 |
| `/system/priv-app/com.nemu.oaidmanager/` | 系统应用 | OAID 管理器 |
| `/system/priv-app/com.mumu.shared.sdk/` | 系统应用 | 共享 SDK |
| `/data/data/com.mumu.store` | 应用数据 | MuMu 游戏中心数据 |
| `/data/data/com.mumu.acc` | 应用数据 | MuMu 账号服务数据 |
| `/data/data/com.nemu.nlp` | 应用数据 | NLP 服务数据 |
| `/data/data/com.nemu.oaidmanager` | 应用数据 | OAID 管理器数据 |
| `/data/data/com.mumu.shared.sdk` | 应用数据 | 共享 SDK 数据 |
| `/data/media/0/Android/data/com.mumu.store` | 共享存储 | 游戏中心外部数据 |
| `/data/media/0/Android/data/com.mumu.acc` | 共享存储 | 账号服务外部数据 |

### Magisk 模块 `hide_mumu_files` (v2.1)

```bash
#!/system/bin/sh
MODDIR=/data/adb/modules/hide_mumu_files
EMPTY_FILE=$MODDIR/empty
EMPTY_DIR=$MODDIR/empty_dir
touch $EMPTY_FILE
mkdir -p $EMPTY_DIR

# 1. 系统可执行文件（只隐藏检测目标，不碰 VM 核心）
for bin in nemuinit; do
    TARGET="/system/bin/$bin"
    [ -f "$TARGET" ] && mount --bind $EMPTY_FILE "$TARGET" 2>/dev/null
done

# 2. 配置文件目录 -> 空目录
[ -d /system/etc/mumu-configs ] && mount --bind $EMPTY_DIR /system/etc/mumu-configs 2>/dev/null

# 3. data/data 应用数据 -> 空目录
for dir in com.mumu.store com.mumu.acc com.mumu.shared.sdk com.nemu.nlp com.nemu.oaidmanager; do
    [ -d "/data/data/$dir" ] && mount --bind $EMPTY_DIR "/data/data/$dir" 2>/dev/null
done

# 4. 共享存储 -> 空目录
for dir in com.mumu.store com.mumu.acc; do
    [ -d "/data/media/0/Android/data/$dir" ] && mount --bind $EMPTY_DIR "/data/media/0/Android/data/$dir" 2>/dev/null
done
```

### 注意事项
- **关键警告：不要隐藏 VM 核心文件！** 以下文件禁止 bind mount，否则 MuMu 无法启动：
  - `nemuVM-nemu-service` / `nemuVM-nemu-control` — VM 进程
  - `nemuinput` — 虚拟输入
  - `nemu_sys_opt` / `nemufreepfn` — 系统优化
  - `libnemuinitaidl.so` / `mumuvmmguest.ko` — 系统库
- System 分区虽然在 MuMu 上是 rw，但直接删除文件会被模拟器自愈机制恢复
- bind mount 到空文件/空目录是最可靠的隐藏方式，模拟器重启不会恢复（除非重新安装）
- **使用 `--bind $EMPTY_FILE` 而非 `--bind /dev/null`** — `/dev/null` 在 MuMu 内核上 mount 会报 `bad /etc/fstab`

---

## 第四阶段：序列号固化

### 关键参数

| 参数 | Key | 目标值 |
|:---|:---|:---|
| 设备序列号 | `ro.serialno` | `865146042407069` |

### Magisk 模块 `fix_k40s_serial_safe`（安全模式）

```bash
#!/system/bin/sh
resetprop ro.serialno 865146042407069
```

### 注意事项
- **严禁**修改 `ril.serialnumber` 等基带相关属性，会导致模拟器断网/卡死
- 普通 App 在 Android 10+ 已无法读取 IMEI，只要 `ro.serialno` 合法即可
- 不要修改 MAC 地址，会导致网络桥接断开

---

## 第五阶段：去除广告与游戏中心

### 敏感应用

| 包名/目录 | 说明 | 处理方式 |
|:---|:---|:---|
| `com.mumu.store` | MuMu 游戏中心（广告） | 挂载空文件替换 APK |
| `com.mumu.acc` | MuMu 账号服务（广告） | 挂载空文件替换 APK |
| `com.nemu.nlp` | 模拟器 NLP 服务（广告推送） | 挂载空文件替换 APK |
| `com.nemu.oaidmanager` | OAID 管理器（广告追踪） | 挂载空文件替换 APK |
| `com.mumu.shared.sdk` | 共享 SDK（广告 SDK） | 挂载空文件替换 APK |
| ~~`nemu-vinput-pack`~~ | ❌ 不隐藏 — VM 核心输入，隐藏后无法操作模拟器 | — |
| ~~`nemu-cloner`~~ | ❌ 不隐藏 — VM 配套服务 | — |
| ~~`nemu-vapi-android-pack`~~ | ❌ 不隐藏 — VM API 接口 | — |

### Magisk 模块 `remove_mumu_ads_v5` (v5.0)

```bash
#!/system/bin/sh
EMPTY=/data/adb/modules/remove_mumu_ads_v5/empty.apk
touch $EMPTY

# 游戏中心（广告）
mount -o bind $EMPTY /system/priv-app/com.mumu.store/com.mumu.store.apk
# 账号服务（广告）
mount -o bind $EMPTY /system/priv-app/com.mumu.acc/com.mumu.acc.apk
# NLP 服务（广告推送）
mount -o bind $EMPTY /system/priv-app/com.nemu.nlp/com.nemu.nlp.apk
# OAID 管理器（广告追踪）
mount -o bind $EMPTY /system/priv-app/com.nemu.oaidmanager/com.nemu.oaidmanager.apk
# Shared SDK（广告 SDK）
mount -o bind $EMPTY /system/priv-app/com.mumu.shared.sdk/com.mumu.shared.sdk.apk

# 注意：不碰 nemu-vinput-pack / nemu-cloner / nemu-vapi-android-pack
# 这些是 VM 核心组件，隐藏后 MuMu 无法正常使用
```

### 注意事项
- V4 方案（`pm uninstall --user 0`）在 MuMu 上无效，包管理命令无法移除系统预装应用
- V5 方案利用 bind mount 空文件覆盖 APK，系统认为 APK 已损坏，强制隐藏图标（与 V2 同方案）

---

## 验证命令汇总

一次性验证所有伪装项：

```bash
adb.exe -s 127.0.0.1:7555 shell "
echo '=== Model ===' && getprop ro.product.model
echo '=== Brand ===' && getprop ro.product.brand
echo '=== Device ===' && getprop ro.product.device
echo '=== Board ===' && getprop ro.board.platform
echo '=== Hardware ===' && getprop ro.hardware
echo '=== Fingerprint ===' && getprop ro.build.fingerprint
echo '=== Security Patch ===' && getprop ro.build.version.security_patch
echo '=== Serial ===' && getprop ro.serialno
"
```

---

## 模块清单

| 模块 | 功能 | 覆盖范围 | 文件 |
|:---|:---|:---|:---|
| fix_k40s_board_hardware | 修正主板平台和硬件标识 | `ro.board.platform`, `ro.hardware` | `fix_k40s_board_hardware.zip` |
| fix_k40s_fingerprint | 修正系统指纹和安全补丁 | `ro.build.fingerprint` x3, `ro.build.description` | `fix_k40s_fingerprint.zip` |
| hide_mumu_files v2.1 | 隐藏 MuMu 特征文件和目录（安全版，不碰 VM 核心） | nemuinit + mumu-configs + 5 data/data + 2 shared storage | `hide_mumu_files.zip` |
| fix_k40s_serial_safe | 固化设备序列号 | `ro.serialno` | `fix_k40s_serial_safe.zip` |
| remove_mumu_ads_v5 | 去除广告/游戏中心/OAID（安全版，5个广告 APK） | 5 个广告系统应用 APK | `remove_mumu_ads_v5.zip` |
| frida_hidden_v3 | nosuke-server 魔改 Frida 17.11.0 (端口 31337) | Frida 隐藏进程 | `D:\汇总\frida\frida模块\frida_hidden_v3.zip` |

---

## 残留文件检测与清理流程

### 检测命令

```bash
# 1. 检查系统可执行文件
adb.exe -s 127.0.0.1:7555 shell "su -c 'ls -la /system/bin/nemuinit /system/bin/nemuinput /system/bin/nemufreepfn /system/bin/nemu_sys_opt /system/bin/nemuVM-nemu-service /system/bin/nemuVM-nemu-control'"

# 2. 检查系统库
adb.exe -s 127.0.0.1:7555 shell "su -c 'ls -la /system/lib64/libnemuinitaidl.so /system/lib64/mumuvmmguest.ko /system/lib/libnemuinitaidl.so'"

# 3. 检查配置文件目录
adb.exe -s 127.0.0.1:7555 shell "su -c 'ls /system/etc/mumu-configs/'"

# 4. 检查系统应用 APK
adb.exe -s 127.0.0.1:7555 shell "su -c 'ls -la /system/priv-app/com.nemu.oaidmanager/com.nemu.oaidmanager.apk /system/priv-app/nemu-vinput-pack/nemu-vinput-pack.apk /system/priv-app/nemu-vapi-android-pack/nemu-vapi-android-pack.apk'"

# 5. 检查应用数据目录
adb.exe -s 127.0.0.1:7555 shell "su -c 'ls -la /data/data/com.mumu.store /data/data/com.mumu.acc /data/media/0/Android/data/com.mumu.store'"

# 6. 检查包列表
adb.exe -s 127.0.0.1:7555 shell "su -c 'pm list packages | grep -iE \"mumu|nemu\"'"

# 7. 一次性验证所有属性
adb.exe -s 127.0.0.1:7555 shell "
echo '=== Model ===' && getprop ro.product.model
echo '=== Board ===' && getprop ro.board.platform
echo '=== Hardware ===' && getprop ro.hardware
echo '=== Fingerprint ===' && getprop ro.build.fingerprint
echo '=== Serial ===' && getprop ro.serialno
echo '=== emu props ===' && getprop ro.kernel.qemu
echo '=== checkjni ===' && getprop ro.kernel.android.checkjni
"
```

### 预期效果（模块生效后）
- `/system/bin/nemuinit` 尺寸为 `0`（仅隐藏核心初始化，不碰 VM 进程）
- `/system/etc/mumu-configs/` 为空目录（40+ 设备配置全部隐藏）
- 5 个广告系统应用 APK 尺寸为 `0`（图标消失，无法打开）
- `pm list packages` 不显示任何 `mumu`/`nemu` 包
- 属性均为 K40S 目标值，无任何 `qemu`/`emu`/`mumu` 特征
- VM 核心文件不变（nemuVM-*, nemuinput, 系统库）— 保证模拟器正常运行

---

# MuMu 模拟器 Magisk 模块刷入指南

## 环境信息

| 项目 | 值 |
|:---|:---|
| ADB 路径 | `D:\MuMuPlayer\nx_main\adb.exe` |
| 目标设备 | `127.0.0.1:7555` (MuMu 默认端口) 或桥接模式 `192.168.x.x:5555` |
| 模块存放目录 | `D:\汇总\mumu必刷` |

## 前置条件

1. MuMu 模拟器已安装并启动
2. Magisk (面具) 已安装并正常运行
3. ADB 调试已开启
4. 模拟器已获取 Root 权限

## 连接模拟器

```powershell
& "D:\MuMuPlayer\nx_main\adb.exe" connect 127.0.0.1:7555
& "D:\MuMuPlayer\nx_main\adb.exe" -s 127.0.0.1:7555 shell "su -c 'echo connected'"
```

如果未连接，先执行：
```powershell
& "D:\MuMuPlayer\nx_main\adb.exe" kill-server
& "D:\MuMuPlayer\nx_main\adb.exe" start-server
& "D:\MuMuPlayer\nx_main\adb.exe" connect 127.0.0.1:7555
```

## 模块刷入流程

### 刷入步骤总览

每次刷入一个模块：

```
推送模块 zip → 写入设备临时目录 → Magisk 安装模块 → 验证 → 全部刷完后重启
```

### 第零步：启用 Zygisk（一次性）

```bash
adb shell "su -c 'magisk --sqlite \"INSERT OR REPLACE INTO settings VALUES(zygisk,1)\"'"
```

> 重启后生效。如果 Magisk App 中已开启 Zygisk，可跳过此步。

---

### 步骤一：刷入机型伪装模块

**模块文件**: `fix_k40s_board_hardware.zip`

```powershell
$ADB = "D:\MuMuPlayer\nx_main\adb.exe"
$DEVICE = "127.0.0.1:7555"
$MODDIR = "D:\汇总\mumu必刷"

& $ADB -s $DEVICE push "$MODDIR\fix_k40s_board_hardware.zip" /data/local/tmp/
& $ADB -s $DEVICE shell "su -c 'magisk --install-module /data/local/tmp/fix_k40s_board_hardware.zip'"
& $ADB -s $DEVICE shell "su -c 'rm /data/local/tmp/fix_k40s_board_hardware.zip'"
```

**预期输出**: `- Successfully installed module`

---

### 步骤二：刷入系统指纹模块

**模块文件**: `fix_k40s_fingerprint.zip`

```powershell
& $ADB -s $DEVICE push "$MODDIR\fix_k40s_fingerprint.zip" /data/local/tmp/
& $ADB -s $DEVICE shell "su -c 'magisk --install-module /data/local/tmp/fix_k40s_fingerprint.zip'"
& $ADB -s $DEVICE shell "su -c 'rm /data/local/tmp/fix_k40s_fingerprint.zip'"
```

---

### 步骤三：刷入文件系统隐藏模块

**模块文件**: `hide_mumu_files.zip`

```powershell
& $ADB -s $DEVICE push "$MODDIR\hide_mumu_files.zip" /data/local/tmp/
& $ADB -s $DEVICE shell "su -c 'magisk --install-module /data/local/tmp/hide_mumu_files.zip'"
& $ADB -s $DEVICE shell "su -c 'rm /data/local/tmp/hide_mumu_files.zip'"
```

---

### 步骤四：刷入序列号固化模块

**模块文件**: `fix_k40s_serial_safe.zip`

```powershell
& $ADB -s $DEVICE push "$MODDIR\fix_k40s_serial_safe.zip" /data/local/tmp/
& $ADB -s $DEVICE shell "su -c 'magisk --install-module /data/local/tmp/fix_k40s_serial_safe.zip'"
& $ADB -s $DEVICE shell "su -c 'rm /data/local/tmp/fix_k40s_serial_safe.zip'"
```

---

### 步骤五：刷入去除广告模块

**模块文件**: `remove_mumu_ads_v5.zip`

```powershell
& $ADB -s $DEVICE push "$MODDIR\remove_mumu_ads_v5.zip" /data/local/tmp/
& $ADB -s $DEVICE shell "su -c 'magisk --install-module /data/local/tmp/remove_mumu_ads_v5.zip'"
& $ADB -s $DEVICE shell "su -c 'rm /data/local/tmp/remove_mumu_ads_v5.zip'"
```

> **V5 说明**: Bind-mount 空文件覆盖 MuMu 游戏中心/账号服务/NLP 的 APK，重启生效。

---

### 步骤六：刷入 Frida 反检测模块（可选）

**模块文件**: `frida_hidden_v3.zip` (位于 `D:\汇总\frida\frida模块\`)

```powershell
& $ADB -s $DEVICE push "D:\汇总\frida\frida模块\frida_hidden_v3.zip" /data/local/tmp/
& $ADB -s $DEVICE shell "su -c 'magisk --install-module /data/local/tmp/frida_hidden_v3.zip'"
& $ADB -s $DEVICE shell "su -c 'rm /data/local/tmp/frida_hidden_v3.zip'"
```

> nosuke-server (魔改 Frida 17.11.0)，以 `sys-helper` 进程名运行，端口 31337

---

## 一键刷入全部模块

> **重要：MuMu 的 `/data/local/tmp/` 文件名有长度限制（约 28 字符），必须用短文件名**

```powershell
$ADB = "D:\MuMuPlayer\nx_main\adb.exe"
$DEVICE = "127.0.0.1:7555"
$MODDIR = "D:\汇总\mumu必刷"

# 模块列表 (短文件名映射)
$moduleMap = @{
    "a.zip" = "fix_k40s_board_hardware.zip"
    "b.zip" = "fix_k40s_fingerprint.zip"
    "c.zip" = "fix_k40s_serial_safe.zip"
    "d.zip" = "hide_mumu_files.zip"
    "e.zip" = "remove_mumu_ads_v5.zip"
}

# 推送并安装
foreach ($entry in $moduleMap.GetEnumerator()) {
    $shortName = $entry.Key
    $fullName = $entry.Value
    $modName = $fullName -replace '\.zip$', ''
    Write-Host "=== 刷入: $fullName ==="
    & $ADB -s $DEVICE push "$MODDIR\$fullName" /data/local/tmp/$shortName
    & $ADB -s $DEVICE shell "su -c 'magisk --install-module /data/local/tmp/$shortName'"
    & $ADB -s $DEVICE shell "su -c 'rm /data/local/tmp/$shortName'"
    Write-Host ""
}

# 检查安装结果，缺失的模块手动修复
Write-Host "=== 检查模块列表 ==="
$installed = & $ADB -s $DEVICE shell "su -c 'ls /data/adb/modules/'" | Out-String
$installed -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' -and $_ -ne 'module.prop' -and $_ -ne 'update' } | Write-Host "- $_"

Write-Host "`n=== 检查 modules_update ==="
$updateDir = & $ADB -s $DEVICE shell "su -c 'ls /data/adb/modules_update/ 2>/dev/null'" | Out-String
Write-Host $updateDir

# 如果模块不在 modules/ 中，从 modules_update/ 手动复制
Write-Host "`n=== 修复缺失模块 ==="
foreach ($entry in $moduleMap.GetEnumerator()) {
    $shortName = $entry.Key
    $fullName = $entry.Value
    $modName = $fullName -replace '\.zip$', ''
    $check = & $ADB -s $DEVICE shell "su -c 'test -d /data/adb/modules/$modName && echo exists'" | Out-String
    if ($check.Trim() -ne 'exists') {
        Write-Host "缺失: $modName — 从 modules_update 修复..."
        & $ADB -s $DEVICE shell "su -c 'mkdir -p /data/adb/modules_update/$modName && unzip -o /data/local/tmp/$shortName -d /data/adb/modules_update/$modName && cp -r /data/adb/modules_update/$modName /data/adb/modules/'"
    }
}
```

---

## 重启生效

全部刷入完成后重启模拟器：

```powershell
& $ADB -s $DEVICE shell "su -c 'reboot'"
```

> 或手动退出模拟器（右键托盘图标 → 退出），然后重新打开。

---

## 验证

重启后运行验证脚本：

```powershell
& $ADB -s $DEVICE shell "
echo '=== Hardware ==='
getprop ro.product.model
getprop ro.product.brand
getprop ro.product.device
getprop ro.board.platform
getprop ro.hardware
echo ''
echo '=== Fingerprint ==='
getprop ro.build.fingerprint
getprop ro.build.version.security_patch
echo ''
echo '=== Serial ==='
getprop ro.serialno
echo ''
echo '=== Modules ==='
ls /data/adb/modules/
echo ''
echo '=== nemuinit ==='
ls -la /system/bin/nemuinit
echo ''
echo '=== Ads ==='
ls -la /system/priv-app/com.mumu.store/com.mumu.store.apk
"
```

**预期输出**:
```
=== Hardware ===
22021211RC
Xiaomi
munch
kona
qcom

=== Fingerprint ===
Redmi/munch/munch:12/SKQ1.211006.001/V13.0.5.0.SLMCNXM:user/release-keys
2022-05-01

=== Serial ===
865146042407069

=== Modules ===
fix_k40s_board_hardware
fix_k40s_fingerprint
fix_k40s_serial_safe
hide_mumu_files
remove_mumu_ads_v5

=== nemuinit ===
-rw-r--r-- 1 root root 0 ... /system/bin/nemuinit

=== Ads ===
-rw-rw-rw- 1 root root 0 ... /system/priv-app/com.mumu.store/com.mumu.store.apk
```

---

## 常见问题

### 模块刷入失败
```powershell
# 查看已安装模块
& $ADB -s $DEVICE shell "su -c 'ls /data/adb/modules/'"

# 查看 Magisk 日志
& $ADB -s $DEVICE shell "su -c 'cat /data/adb/magisk.log'"
```

### 文件推送后名称被截断 / 模块安装后不在列表
```powershell
# MuMu 的 /data/local/tmp/ 文件名有长度限制（约 28 字符）
# 推送时使用短文件名：
& $ADB -s $DEVICE push "$MODDIR\fix_k40s_board_hardware.zip" /data/local/tmp/a.zip
& $ADB -s $DEVICE shell "su -c 'magisk --install-module /data/local/tmp/a.zip'"

# 如果 `magisk --install-module` 说 Done 但模块没出现，
# 手动解压到 modules_update/ 再复制到 modules/：
& $ADB -s $DEVICE shell "su -c 'mkdir -p /data/adb/modules_update/<模块名>'"
& $ADB -s $DEVICE shell "su -c 'unzip -o /data/local/tmp/a.zip -d /data/adb/modules_update/<模块名>'"
& $ADB -s $DEVICE shell "su -c 'cp -r /data/adb/modules_update/<模块名> /data/adb/modules/'"
```

### 模块冲突 / 需临时禁用某模块
```powershell
# 在模块目录下创建 disable 文件即可禁用
& $ADB -s $DEVICE shell "su -c 'touch /data/adb/modules/<模块名>/disable'"
# 删除 disable 重新启用
& $ADB -s $DEVICE shell "su -c 'rm /data/adb/modules/<模块名>/disable'"
```

### ADB 连接不上
```powershell
& $ADB kill-server
& $ADB start-server
& $ADB connect 127.0.0.1:7555
```
