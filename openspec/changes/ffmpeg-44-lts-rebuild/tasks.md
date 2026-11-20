<!--
  每个 ## N. 是一个独立迭代（task group）。每组自带质量保证：实现＋测试＋质量门。
  各组可独立实施，组内全部完成后产物编译通过、脚本可重复执行。
  序号即实施顺序（依赖链：依赖链重编 → 核心与聚合 → 装配与元数据）。
  本仓为链条第一环，无前置 change；下游两仓改动不进本清单（归属见 proposal 关联场景 #4/#5）。
-->

## 1. 依赖链逐架构重编

- [ ] 1.1 新建 scripts/ 管线骨架：架构参数、仓外工作区、安装前缀的公共约定（供依赖脚本与主体脚本共用）[infra]
- [ ] 1.2 新增 x264 逐架构重编脚本并跑通双切片，产出回填 x264-iOS 目录 [spec:av1-decoding#dependency-chain-alignment]
- [ ] 1.3 新增 fdk-aac 逐架构重编脚本并跑通双切片，产出回填 fdk-aac-ios 目录 [spec:av1-decoding#dependency-chain-alignment]
- [ ] 1.4 新增 openssl 逐架构重编脚本并跑通双切片，产出回填 openssl-ios 目录（含版本兼容性确认点，预案见 design D4/Risks；现存 -tvOS 变体库的去留先于重编按版本要求定夺）[spec:av1-decoding#dependency-chain-alignment]
- [ ] 1.5 新增 Smbclient 家族重编脚本并跑通双切片：先 talloc/tdb/tevent/wbclient，后 libsmbclient [spec:av1-decoding#dependency-chain-alignment]
- [ ] 1.6 配对一致性自动核验：各输入目录的头文件与静态库出自同一构建批次，无新旧混配（扫描范围排除工作区残留 *.bak-20261115 与空占位目录，见 design Context）[spec:av1-decoding#dependency-chain-alignment]
- [ ] 1.7 组质量门：四套依赖在双切片全部编译成功且 1.6 核验通过 [infra]

## 2. FFmpeg 4.4 核心交叉编译与 fat 聚合

- [ ] 2.1 钉定 4.4.x 基线并编写主体逐架构编译脚本：参数按历史证据还原意图，许可证开关开齐（gpl/nonfree/version3），部署底线对齐打包元数据（iOS 11.0），不嵌 Bitcode [spec:av1-decoding#license-switches]
- [ ] 2.2 分别执行 arm64 与 x86_64 编译（以安装前缀引用第 1 组新产出），入库到 libffmpeg 目录 [spec:av1-decoding#version-baseline]
- [ ] 2.3 将 ffmpeg-tools 胶合层适配 4.4 宏面并重编入库 [spec:av1-decoding#consumer-zero-migration]
- [ ] 2.4 单架构输出按新切片口径聚合为 fat（arm64＋x86_64，不含 armv7）[spec:av1-decoding#arch-slices]
- [ ] 2.5 自动断言：归档的最终 configure 参数中 gpl/nonfree/version3 三项齐全，缺任一项即判配置无效不出货 [spec:av1-decoding#license-switches]
- [ ] 2.6 thin 层冒烟：单架构产物的符号表已出现 AV1 解码器注册符号 [spec:av1-decoding#av1-software-decoder]
- [ ] 2.7 组质量门：双架构编译全绿、聚合脚本干净跑通 [infra]

## 3. 框架装配、产物替换与元数据同步

- [ ] 3.1 由现有聚合目标 CYFFmpeg.xcodeproj 重链动态框架（输入已全部替换为新静态库与胶合产物），公开头文件随 4.4 基线更新（伞头文件按 design D6 作最小修订或兼容桩，工程钉名引用随之调整；头文件集合确定性重建，与现集合作差比对留痕）[spec:av1-decoding#consumer-zero-migration]
- [ ] 3.2 入库产物在根 framework 处替换（二进制＋Headers）；product/ 历史副本不动 [infra]
- [ ] 3.3 podspec 版本号 bump、summary/description 口径与新基线一致（去掉「based on 3.4」旧表述）；顺带把重复的 pod_target_xcconfig 赋值合并为一个块——合并后仅现生效键（EXCLUDED_ARCHS 等）保留活语句，VALID_ARCHS/ENABLE_BITCODE 以注释行保留（若明确接受二者被合并激活亦可，写明即可），避免字面合并让 Ruby 后写覆盖中原本失效的键静默激活（见 design D5 脚注）[infra]
- [ ] 3.4 README 特性清单同步：版本基线、切片口径、新增 AV1 软解码支持项 [infra]
- [ ] 3.5 质量门命令一：对最终 fat binary 运行 strings，抽取到 Lavc58. 前缀版本串 [spec:av1-decoding#version-baseline]
- [ ] 3.6 质量门命令二：最终 fat binary 符号表存在 AV1 解码器注册符号（聚合目标须维持不 strip——机判门前提，见 design D2 脚注）[spec:av1-decoding#av1-software-decoder]
