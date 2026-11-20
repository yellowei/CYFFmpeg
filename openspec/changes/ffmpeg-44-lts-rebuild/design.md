# Design — ffmpeg-44-lts-rebuild

## Context

动机见 proposal.md（Why / What Changes），需求契约见 specs/av1-decoding/spec.md；此处只放解释方案所需的现状与约束。

- 入库产物：根 `CYFFmpeg.framework/CYFFmpeg` fat binary，lipo 实证 x86_64/armv7/arm64 三段，strings 实证 Lavc57.107.100，约 88MB、直接提交无 LFS（README 自述旧仓因不想用 LFS 而删库重导）。
- 全仓无任何被跟踪的构建脚本；历史管线在仓外——二进制里嵌着多条不同批次的 configure 命令行（x86_64 模拟器批含 openssl+x264+fdk-aac+smbclient 全家桶、arm64 批来自「noX264」目录），暴露 Homebrew Cellar 依赖路径、gas-preprocessor.pl、per-arch thin 目录——现产物是多批次静态库聚合后 lipo 的结果。（此点修正 clarify 锚点「configure 命令行未嵌进二进制」的一句话表述；不撼动「重建管线入库是核心工作」的结论。）
- `CYFFmpeg.xcodeproj` 为单聚合 target（framework 型、零脚本 phase），链接各 vendored .a 产出动态框架，并编译 cmdutils 胶合代码（`CYFFmpeg/ffmpeg-tools/`，其 libFFmpegiOSCLT.a 按 3.4 宏编译）。
- Vendored 输入目录（均被 git 跟踪）：libffmpeg / x264-iOS / fdk-aac-ios / openssl-ios / Smbclient / ffmpeg-tools。
- README/podspec 既有决定：Xcode 14 开发、Bitcode off、放弃 armv7/armv7s；podspec platform iOS 11.0、VALID_ARCHS arm64 x86_64、模拟器 EXCLUDED_ARCHS arm64（Intel 开发机在场）。
- product/0.2.2/CYFFmpeg.framework 是 macOS 别名占位文件、product/pre 是旧完整拷贝——均不被 CocoaPods 消费，本变更不动。
- **工作区残留（非本变更新增，一切扫描/核验步骤须排除）**：`lib.bak-20261115/`（内含空的 x264-openssl-originals）、`Headers.bak-20261115/`（空）、`CYFFmpeg/libffmpeg/dav1d/` 空占位目录（本变更不挂 dav1d，来源未记录）；`openssl-ios` 内的 `-tvOS` 变体库（工程未链接）——去留随依赖重编时按版本要求一并定夺；`.gitignore` 有一处未提交修改（+.claude），非本变更所为，勿混入本变更提交。`build/` 现为空壳且未被 .gitignore 覆盖（git check-ignore 亲验不命中），命令行驱动重链后会填入派生物，勿并入本变更提交（如需彻底干净可另提一笔 .gitignore 变更，不归本 change）。

## Goals / Non-Goals

**Goals：** 构建管线入库且可重复执行；产物满足两条机判质量门；元数据（podspec/README）与产物口径一致。

**Non-Goals:** 不改任何消费侧代码（归下游两仓 change）；不挂 dav1d 外部软解库（路线 A2 未选）；不启用 Bitcode；不建 CI；不做 CocoaPods trunk 发布动作；不动 product/ 历史副本。

## Decisions

- **D1 基线取 4.4.x LTS**（用户拍板 A1，备选与取舍见 clarify「Architecture Direction」，不重述）。具体 patch 版本以构建时官方最新 4.4.x 为准——实现细节，不影响契约。
- **D2 管线形态：shell 脚本入库（新建 scripts/ 目录）做逐架构交叉编译＋lipo 聚合；框架装配沿用现有 Xcode 聚合目标**，由脚本以命令行方式驱动。备选「纯脚本链替换装配」（linker＋install_name＋头文件拷贝）更彻底但与入库工程文件及 README「用 Xcode 14 开发」的现状决裂，选最小改动路线。（脚注：聚合目标维持**不 strip**——现产物符号表保留约 5.4 万条可读符号，证明现行目标从未 strip；符号表质量门依赖此前提，若实施启用 strip 会对正确产物假阴性。）
- **D3 工具链与部署底线**：统一 xcrun clang 交叉编译；aarch64 汇编保留 gas-preprocessor 兼容选项（历史 arm64 configure 行证明当时需要它；现代 Apple clang 可直接汇编，跑通即可摘）。部署底线统一抬到与 podspec 一致的 iOS 11.0（历史行为 min 8.0/模拟器 6.0，早已被打包元数据覆盖）；不再加 -fembed-bitcode（与 Bitcode off 决定一致）。
- **D4 依赖编译顺序**：x264 → fdk-aac → openssl → smbclient 家族（先 talloc/tdb/tevent/wbclient 后 libsmbclient），最后 FFmpeg 主体以各 prefix 路径引用它们；许可证开关按法务门槛开齐（gpl/nonfree/version3）。openssl 版本兼容性风险见 Risks。
- **D5 切片与 armv7 处置**：arm64＋x86_64，armv7 去除。事实依据：README 已决策放弃 armv7/armv7s、podspec VALID_ARCHS 已只列 arm64/x86_64、现 fat 中 armv7 段系旧仓时代残留——留着只会造成永远链不上又无人消费的孤儿段。（脚注：podspec 的 pod_target_xcconfig 被赋值两次，Ruby 语义下后一次〔仅 EXCLUDED_ARCHS〕整体覆盖前一次——「VALID_ARCHS 只列 arm64/x86_64」「ENABLE_BITCODE NO」文本虽在但不生效；D5/D3 的决定另有 README 明文支撑，不受此覆盖事实影响。任务 3.3 顺带把两处赋值合并为一个块——合并后仅现生效键保留活语句，VALID_ARCHS/ENABLE_BITCODE 以注释行保留（或显式接受其转为生效，写明即可），不让字面合并静默激活原本失效的键。）
- **D6 产物落盘策略**：根 framework 处直接替换（二进制＋Headers）；伞头文件允许最小修订，仅限删去 4.0 起已从安装树移除的头文件的 import（现钉入的 avfiltergraph.h 即此类——graph API 声明在 4.4 的 avfilter.h 中，功能面无损；备选：由构建脚本为其保留兼容桩，若下游有源码直接 import 该头则改用本方案），modulemap 结构不变；Xcode 工程 Headers 阶段的钉名引用随之调整。头文件集合必须确定性重建：非默认安装的内带头由脚本显式拷入，重生成后与现集合作差比对留痕（预期差异＝4.x 移除项＋openssl 基线若升级的差异）。product/* 不动（0.2.2 是别名占位文件、pre 是旧拷贝，均不被 pod 消费）。体积闸口见 Risks。签名现状说明：入库二进制的 ad-hoc 签名块系历史仓外管线拼批痕迹（framework target 的 CODE_SIGN_IDENTITY 为空串，工程本身不签名），重编后产物不带签名属预期行为、两条机判门不受影响；如需保持签名字样，由脚本在 lipo 后追加一步 `codesign -s -` 作为可选步骤写明即可，不必新增任务。
- **D7 podspec 版本号 bump 幅度留待发布时定**（见 Open Questions）；summary/description 行去掉「based on 3.4」旧口径、与新基线一致。

## Data Model

本变更不涉及持久化。

## Rule Boundary Attachment

不适用——不新增业务规则/校验/拦截，不新增执行路径（纯重编与产物替换）；两条验收是构建质量门（strings/符号表命令机判），不存在运行时判定挂载点。

## Risks / Trade-offs

- **[单文件体积闸口]** 现二进制约 88MB 直接提交（无 LFS），纳入 AV1 解码器后增长；GitHub 对非 LFS 单文件有约 100MB 硬顶 → 在 thin 库阶段即实测体积预估终值，armv7 段去除可部分对冲；若逼近/超过闸口，停下向用户报告存储策略再动（当年决策正是为了不用 LFS，不得擅改）。
- **[openssl 版本兼容]** 现 vendored headers 呈 OpenSSL 1.0.x 时代特征，4.4 的 crypto 后端可能要求更高版本线 → 依赖重编阶段先行确认；预案＝按「随版本要求重编」口径把 vendored openssl 基线升级。
- **[胶合代码编译不过]** ffmpeg-tools/cmdutils 胶合层按 3.4 宏面编译，4.4 弃用/宏调整会波及 → 对应任务覆盖适配重编，编译通过即算完成。
- **[多批次聚合史实无单一权威 configure 记录]** 还原的参数与历史精确值可能有差 → 以证据＋原意重建；许可证开关与特性清单必须一致，其余允许差异并在脚本注释留痕。
- **[人工回归留档]** AV1 样片真机首播属下游仓 CYPlayer change（av1-decode-support）的验证范围，不在本仓 tasks；本仓验证全部机判。

## Migration Plan

合并即迁移：入库产物在根 framework 处替换；podspec/README 同步；下游按链条顺序（B→C）在各自仓库消费。回滚＝revert 产物与元数据的提交即可（scripts/ 管线新增不需要回滚动作）。

## Open Questions

- podspec 新版本号取值（major 还是 minor）——发布时定，不影响 specs 与任务拆分。
- 4.4.x 具体 patch 版本——构建时以官方最新 4.4.x 为准，不影响契约。
