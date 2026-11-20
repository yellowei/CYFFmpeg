# av1-decoding（delta）

## Purpose

定义本仓解码库重建的交付契约：升级后 AV1 软解码器必须符号级实证可用，版本基线、依赖链版本对齐、许可证开关开齐、架构切片与消费侧零迁移接口面均以可执行命令机判验收。本能力只约束「交付物长什么样」，不约束实现步骤（实现见 design.md）。

<!-- 规则边界三类场景（应当拦截/应当放行/等价路径放行）：不适用——本变更为纯重编与产物替换，不新增业务规则/校验/拦截，也不新增执行路径（理由同 proposal「Rule Boundary」与 clarify 复核结论）。
     跨接口业务链路（第四类强制场景）：不适用——本仓无运行时接口/端点，不存在跨接口的业务顺序链路；端到端播放链路钉在下游仓 change（CYFileBrowser 的 ftp-av1-playback）。 -->

## ADDED Requirements

### Requirement: version-baseline

系统 SHALL 交付基于 FFmpeg 4.4.x LTS 基线构建的解码库产物，其 libavcodec 版本串前缀为 `Lavc58.`。

#### Scenario: 版本串断言（质量门一）

- **WHEN** 对最终 fat binary 运行 strings 抽取并过滤 libavcodec 版本串前缀
- **THEN** 输出存在以 `Lavc58.` 开头的行（现产物为 Lavc57.107.100，跑不过本条——此即门槛真实性所在）

### Requirement: av1-software-decoder

交付产物 SHALL 注册原生 AV1 软解码器（由 4.4 基线自带，SHALL NOT 为此额外引入外部软解库），且可用性可在符号表层面验证。

#### Scenario: 解码器注册符号断言（质量门二）

- **WHEN** 对最终 fat binary 导出符号表并检索 AV1 解码器注册符号
- **THEN** 存在 AV1 解码器的注册符号（现产物仅含 Windows Media 时代的 wmav1 字样、AV1 本体无注册符号，跑不过本条）

### Requirement: license-switches

构建配置 MUST 同时开齐满足法务门槛的全部许可证开关——x264 的 GPL 门槛对应 --enable-gpl，fdk-aac 的 nonfree 门槛对应 --enable-nonfree，历史既定的 --enable-version3 一并保持——三者缺一即视为配置无效。

#### Scenario: 开关齐备

- **WHEN** 检视一次成功构建归档下来的最终 configure 参数
- **THEN** --enable-gpl、--enable-nonfree、--enable-version3 三项均在

#### Scenario: 缺开关不出货

- **WHEN** 构建配置缺少 GPL 或 nonfree 任一项
- **THEN** 管线判定配置无效并拒绝产出入库产物（不得依赖人工把关）

### Requirement: dependency-chain-alignment

依赖链（x264、fdk-aac、openssl、libsmbclient 及其 talloc/tdb/tevent/wbclient 伴生库）SHALL 按升级核心的版本要求随重编，各依赖的头文件与静态库内容成对一致。

#### Scenario: 配对一致性核验

- **WHEN** 每个依赖的重编完成后运行自动核验
- **THEN** 该依赖入库的头文件与静态库出自同一构建批次（版本标识互证），无新旧混配

### Requirement: arch-slices

最终产物 MUST 恰含 arm64（设备）与 x86_64（模拟器）两个切片段；armv7 段予以去除，理由存档：README 已决策放弃 armv7/armv7s、打包元数据 VALID_ARCHS 已只列 arm64/x86_64、现 fat 中 armv7 段系旧仓时代历史残留。

#### Scenario: 切片断言

- **WHEN** 对最终 fat binary 运行 lipo -info
- **THEN** 报告恰为 x86_64 与 arm64 两段，不含 armv7

### Requirement: consumer-zero-migration

交付产物 SHALL 保持既有公开 API 面可用（弃用告警可接受、但符号未移除），使下游仓库无需源码迁移即可编译链接；公开头文件 SHALL 随 4.4 基线同步更新；伞头文件 MAY 作且仅作针对 4.0 起已从安装树移除的头文件的 import 之最小修订（备选：由构建脚本为其保留兼容桩），模块定义保持不变。

#### Scenario: 老入口符号抽查

- **WHEN** 在最终 fat binary 符号表抽查既有使用文档引用的公开入口（如 avcodec_open2、av_read_frame、av_seek_frame）
- **THEN** 被抽查入口的符号全部存在，无一缺失；抽样集合另含胶合层与 libsmbclient 族的入口符号各一（如 `_ffmpeg_main`、`_smbc_open`——下游有源码直接调用二者），断言方式与前述 av* 入口一致
