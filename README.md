# MuMu 模拟器伪装与优化模块合集

将 MuMu Player 12 伪装为 **Redmi K40S (munch)**，隐藏模拟器特征并去除广告。

## 模块清单

| 模块 | 功能 |
|:---|:---|
| `fix_k40s_board_hardware` | 修正主板平台 (`kona`) 和硬件标识 (`qcom`) |
| `fix_k40s_fingerprint` | 修正系统指纹为 K40S MIUI 13 |
| `fix_k40s_serial_safe` | 固化设备序列号 |
| `hide_mumu_files` | 隐藏 MuMu 特征文件/目录（安全版，不碰 VM 核心） |
| `remove_mumu_ads_v5` | Bind-mount 空文件覆盖 5 个广告系统应用 |

## 详细指南

见 [`huizo.md`](huizo.md) — 包含完整的环境配置、刷入步骤、验证命令和常见问题。
