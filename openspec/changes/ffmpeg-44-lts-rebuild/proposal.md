# Proposal — ffmpeg-44-lts-rebuild

## Why

现产物 CYFFmpeg.framework（fat binary：x86_64/armv7/arm64）构建于 FFmpeg 3.4 基线（二进制内嵌版本串实证 Lavc57.107.100），不含任何 AV1 软解码器——符号表里可见的「av1」子串全部属于 Windows Media 时代的编解码器（wmav1），AV1 本体无注册符号。下游播放链（CYFileBrowser ← CYPlayer ← 本仓）因此端到端解不出 AV1 视频流。用户拍板路线 A1：升级到保留旧 API 的最后大版本 FFmpeg 4.4 LTS（原生 av1dec 自 4.3 起；旧 API 弃用但未移除），消费侧代码零迁移。

## What Changes

- 取 FFmpeg 4.4.x LTS 源码基线重新构建，替换入库产物（根 framework 二进制＋Headers）。
- 构建管线在本仓重建并入库（脚本进版本管理）——全仓现状无任何被跟踪的构建脚本，历史管线在仓外（见关联场景 #1 证据）。
- 依赖链 x264 / fdk-aac / openssl / libsmbclient（含 talloc/tdb/tevent/wbclient 伴生库）按升级核心版本要求随重编；许可证门槛开齐：x264 GPL→--enable-gpl、fdk-aac nonfree→--enable-nonfree、连历史既定 --enable-version3 一并保持。
- 架构切片定为 arm64 设备＋x86_64 模拟器；armv7 段去除（理由存档：README 已决策放弃 armv7/armv7s，podspec VALID_ARCHS 已只列 arm64/x86_64，现 fat 中 armv7 段为旧仓时代历史残留）。
- 打包元数据同步：podspec 版本号 bump 与描述口径（现 summary 写「based on 3.4」）、README 特性清单同步。
- 质量门两条可执行命令（机判）：新二进制 strings 出 `Lavc58.` 前缀；符号表含 AV1 解码器注册符号。
- 对消费侧非破坏性变更（旧 API 弃用未移除，接口面不变）。

## Related Surface

清点结论承 clarify.md（划界经上游访谈确认），逐条附代码位置证据；标注〔撰写时补核〕者为撰写阶段新增检索事实，归入同条目范畴、不改变划界结论。

| # | 关联面 | 代码证据 | 划定结论 |
|---|---|---|---|
| 1 | 核心面：framework 产物与构建管线 | `CYFFmpeg.framework/CYFFmpeg` fat binary（lipo 实证 x86_64/armv7/arm64；strings 实证 Lavc57.107.100）；全仓无任何被跟踪的 *.sh/*.py（build/ 是 Xcode 派生数据）；README 自述旧仓为避免 LFS 删除重导。〔撰写时补核〕原始 configure 命令行**其实嵌进了二进制**（至少三条不同批次：x86_64 模拟器批含 openssl+x264+fdk+smbclient 全家桶，arm64 批来自「noX264」目录），并暴露历史管线仓外位置（Homebrew Cellar 依赖路径、gas-preprocessor.pl、per-arch thin 目录聚合）——这反而强化「重建构建管线入库是核心工作」的原结论 | ✅ 纳入（取 4.4.x 源码＋重建构建管线入库＋替换产物——本变更主体；product/ 下历史副本不动：0.2.2 为 macOS 别名占位文件、pre 为旧完整拷贝，均不被 CocoaPods 消费） |
| 2 | Vendored 依赖静态库 | `CYFFmpeg/x264-iOS/`（头文件目录 x264.h/x264_config.h＋libx264.a，仓内无源码）、`CYFFmpeg/openssl-ios/`（include/lib）、`CYFFmpeg/Smbclient/`（libsmbclient.a/libtalloc.a/libtdb.a/libtevent.a/libwbclient.a）均已跟踪。〔撰写时补核〕同类还有 `CYFFmpeg/fdk-aac-ios/`（libfdk-aac.a＋headers）、`CYFFmpeg/libffmpeg/`（include＋lib 全套 .a）、`CYFFmpeg/ffmpeg-tools/`（cmdutils 胶合 libFFmpegiOSCLT.a，按 3.4 宏编译、需随 4.4 重编）——六处统一口径：入库皆为预编译 .a＋头文件，无源码 | ✅ 纳入（随版本要求重编；许可证开关开齐） |
| 3 | 工程/打包元数据 | `CYFFmpeg.podspec`（v1.0.0，summary 写明 based on 3.4、含 x264/fdk-aac/smbclient/cmdutils；platform iOS 11.0、VALID_ARCHS arm64 x86_64、ENABLE_BITCODE NO）；`CYFFmpeg.xcodeproj`〔撰写时补核〕单聚合 target（framework 型、无脚本 phase），链接各 vendored .a 产出动态框架 | ✅ 纳入（版本描述与产物同步；README 另记 Xcode 14、Bitcode off、armv7/armv7s 放弃决定） |
| 4 | 下游消费者：../CYPlayer（pod 依赖本仓） | CYPlayer podspec 依赖 Masonry + CYFFmpeg | ⛔ 排除，归 CYPlayer 仓 change av1-decode-support（真编译真跑＋错误码接线在那边） |
| 5 | 下游消费者：../CYFileBrowser（终端产品） | 其 Podfile :path 引用 CYPlayer | ⛔ 排除，归其 change ftp-av1-playback（端到端钉在那边） |
| 6 | 架构切片口径 | 现 fat 含 armv7 残留；新产物口径 = arm64 设备＋x86_64 模拟器（Intel 开发机在场，podspec 模拟器 EXCLUDED_ARCHS arm64） | ✅ 纳入（切片策略见上；armv7 去留按事实定＝去除，理由已记录） |

共享处理逻辑判定：本变更动的是被两个下游消费的共享底座（解码库），联动方式维持 clarify 结论——消费者各自在自己的 change 里验升级效果（B 验真编译真跑、C 验端到端钉），不在本仓排消费者适配任务。跨仓所有权拆分（A→B→C）系用户访谈拍板，本仓只做自己这一层。

## Implementation Outline

按步骤用人话讲清怎么做（工具命令名与许可证开关是验收锚点，保持精确；其余不用代码级名词）：

1. **数据来源**：官方源取 FFmpeg 4.4.x 基线与各依赖对应版本，落在仓外工作区；构建脚本入库本仓（新建 scripts/ 目录），产出的静态库与头文件回填既有 vendored 目录（#2 所列六处）——六处 vendored 目录入库的均只有二进制＋头文件，源码一律取自官方源。
2. **依赖先行**：按 x264 → fdk-aac → openssl → smbclient 家族（先 talloc/tdb/tevent/wbclient 后 libsmbclient）的顺序，分架构分别交叉编译；许可证开关按法务门槛一次开齐（gpl/nonfree/version3），配置里缺任一口即判配置无效、不出货。
3. **核心重编**：FFmpeg 主体按 4.4 基线分架构编译，参数参照二进制里嵌的历史 configure 行还原意图（交叉编译、关调试/文档/命令行程序、开 pic），并把上述依赖接入；部署底线对齐打包元数据的 iOS 11.0；不再嵌 Bitcode（与 README/podspec 的关闭决定一致）。
4. **聚合装配**：单架构产物按新切片口径（arm64＋x86_64，无 armv7）合并成 fat，再由现有 Xcode 聚合目标重链动态框架（脚本以命令行驱动），公开头文件随 4.4 基线更新（伞头文件与模块定义不变）。
5. **落盘与元数据**：入库产物在根 framework 处替换（二进制＋Headers）；podspec 版本号 bump、summary/description 去掉「based on 3.4」旧口径；README 特性清单同步（版本基线、切片口径、新增 AV1 支持项）；product/ 历史副本不动。
6. **质量门闭环（全机判）**：对最终产物跑两条命令——strings 抽取出 `Lavc58.` 前缀；符号表含 AV1 解码器注册符号。两条现产物都过不了（现为 Lavc57.、AV1 无注册符号），故构成真实门槛。
7. **关联链路适配**：#1/#2/#3/#6 四条划入面按上述步骤适配；#4/#5 两条下游在各自仓库的 change 里消费验证，本仓不为它们排任务（ownership 拆分已由用户确认）。

## Rule Boundary

不适用——本变更纯重编与产物替换，不新增/修改业务规则、校验或拦截逻辑，不新增/改变任何执行路径；两条验收是构建质量门（机器可判命令），不是运行时判定规则。复核结论与 clarify 一致。

## Capabilities

### New Capabilities

- `av1-decoding`: 本仓解码库重建的交付契约——升级后 AV1 软解码器可用（符号级实证）、版本基线、依赖链版本对齐、许可证开关开齐、架构切片达标、消费侧零迁移接口面。（clarify Initial Capabilities 唯一授权名单，无增删。）

### Modified Capabilities

无——openspec/specs/ 当前为空，无既有能力可改。

## Impact

- 替换：根 `CYFFmpeg.framework/`（二进制现约 88MB、直接提交无 LFS，增长风险见 design Risks）＋ Headers。
- 输入目录（均被跟踪）：`CYFFmpeg/libffmpeg/`、`CYFFmpeg/x264-iOS/`、`CYFFmpeg/fdk-aac-ios/`、`CYFFmpeg/openssl-ios/`、`CYFFmpeg/Smbclient/`、`CYFFmpeg/ffmpeg-tools/`（胶合库需重编）。
- 新增入库：scripts/ 构建管线；`CYFFmpeg.xcodeproj`（重链）；`CYFFmpeg.podspec`（版本/描述）；`README.md`（特性清单）。
- 契约变更点：无 DDL、无运行时接口契约（本仓无端点）；podspec 版本行为打包元数据同步，非行为契约。
- 不动：`product/0.2.2/`（macOS 别名占位文件）、`product/pre/`（旧完整拷贝）。
- 下游归属一句话交代：CYPlayer 仓 change av1-decode-support 与 CYFileBrowser 仓 change ftp-av1-playback 各自在自己仓库消费本产物，不进本仓任务清单。
