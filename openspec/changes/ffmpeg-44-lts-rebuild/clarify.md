# Clarify — ffmpeg-44-lts-rebuild

访谈与结构化在上游会话（CYFileBrowser 仓）由主代理完成，决策以用户原话逐字记录于此；本仓 openspec 由用户初始化，三仓同规（spec-driven-standard）。本仓无 AGENTS.md（空集，承母仓先例）；architecture/interface/database 技能类别均无匹配（降级记录在案）。

## Open Questions

决策树逐轮走到的分支（每轮问当时前提已落定的全部问题；顺序按访谈实录）：

- AV1 解码能力的实现路线怎么选？（A1=升级 FFmpeg 4.4 LTS 吃自带原生软解 / A2=一步到位升 6.x 挂 dav1d / B=只走新芯片硬件解码 / C=服务端转码 / D=仅补显式报错）——影响面横跨三个仓的构建与代码迁移量。
- 依赖链跟版本到什么程度？x264 / fdk-aac / openssl / libsmbclient 是否随重编？许可证开关（GPL/nonfree）怎么落？
- 构建管线放哪？仓内现状没有任何构建脚本——framework 是预编译产物（README 自述旧仓为避免 LFS 删除重导）；撰写时实测修正：二进制各切片其实嵌有多批次完整 configure 命令行（恰证历史管线在仓外多机拼合，见 design Context），重建构建管线本体仍是核心工作。
- 架构切片怎么定？现 fat binary 含 armv7 历史残留；口径 = arm64 设备 + x86_64 模拟器（Intel 开发机在场）。
- 质量门以什么形式验收？（口径 = 两条可执行命令：二进制 strings 出 `Lavc58.` 前缀；符号表含 av1 解码器注册符号）
- 复杂度分层判断（SIMPLE/COMPLEX）与撰写方式。

## User Answers

- **「选A1」**——解码库升级到保留旧 API 的最后大版本（4.4 LTS，原生 av1dec 自 4.3 起），旧 API 弃用但未移除；消费侧代码零迁移为核心卖点。
- **「我建议是在CYFFmpeg和CYPlayer中分两个change，这个CYFileBrowser其实是文件浏览器，引入了CYPlayer」**——按所有权拆分：重编归本仓（本变更）、真编译真跑+错误码接线归 CYPlayer 仓变更（av1-decode-support）、CYFileBrowser 退纯消费方（其变更 ftp-av1-playback）。
- **「三仓同规。你直接进AB对应的仓库跑propose。」**——三仓统一 spec-driven-standard（schema/config 已同步完毕），用户指示主代理直接进本仓跑 propose 管线；剩余未知项均为事实勘察（无需向用户新提问），答案以上游会话记录为准。
- 链条顺序 A → B → C 仅在各仓 tasks 用前置 change 标注表达；本仓是链条第一环，无前置。
- **2026-11-20 显式接受**——本仓审查三轮上限用尽收口（封笔时 1 Low + 3 Info，事实锚/措辞级，修法已逐字采纳、未复审封笔），用户明确接受该收口状态，满足 schema 交棒条件（加赛核验轮可提供，落档时未行使）。

## Related-Surface Survey

关联场景清点，逐条附代码位置证据；划定结论均经上游访谈确认（✅=划入本 change，⛔=排除并附理由）：

| # | 关联面 | 代码证据 | 划定结论 |
|---|---|---|---|
| 1 | 核心面：framework 产物与构建管线 | `CYFFmpeg.framework/CYFFmpeg` fat binary（x86_64/armv7/arm64，strings 实证 Lavc57.107.100）；全仓无任何构建脚本（build/ 之外无 *.sh/*.py，build/ 是 Xcode 派生数据）；README 自述旧仓为避免 LFS 删除重导；二进制内嵌多条不同批次的完整 configure 命令行（撰写时实测修正——历史管线系仓外多机拼合） | ✅ 纳入（取 FFmpeg 4.4.x 源码 + 重建构建管线入库 + 替换产物——本变更主体） |
| 2 | Vendored 依赖静态库 | `CYFFmpeg/x264-iOS/`（头文件目录 x264.h/x264_config.h ＋ libx264.a，仓内无源码）、`CYFFmpeg/openssl-ios/`（include/lib）、`CYFFmpeg/Smbclient/`（libsmbclient.a/libtalloc.a 等）；〔撰写时补核〕`CYFFmpeg/fdk-aac-ios/`、`CYFFmpeg/libffmpeg/`、`CYFFmpeg/ffmpeg-tools/`（胶合库）同样被跟踪——六处统一口径：入库的都是预编译 .a＋头文件，源码一律取自官方源 | ✅ 纳入（随版本要求重编；许可证门槛：x264 GPL→--enable-gpl、fdk-aac nonfree→--enable-nonfree，配置须一并开齐） |
| 3 | 工程/打包元数据 | `CYFFmpeg.podspec`（v1.0.0，summary 行写明 based on 3.4、含 x264/fdk-aac/smbclient/cmdutils）；`CYFFmpeg.xcodeproj` | ✅ 纳入（版本描述与产物同步；README 另记 Xcode 14、Bitcode off、armv7/armv7s 放弃决定） |
| 4 | 下游消费者：../CYPlayer（pod 依赖本仓） | CYPlayer podspec 依赖 Masonry + CYFFmpeg | ⛔ 排除，归 CYPlayer 仓 change av1-decode-support（真编译真跑 + 错误码接线在那边） |
| 5 | 下游消费者：../CYFileBrowser（终端产品） | 其 Podfile :path 引用 CYPlayer | ⛔ 排除，归其 change ftp-av1-playback（端到端钉在那边） |
| 6 | 架构切片口径 | 现 fat 含 armv7 残留；新产物口径 = arm64 设备 + x86_64 模拟器 | ✅ 纳入（切片策略在 proposal 写明；armv7 段去留按事实定并记录理由） |

共享处理逻辑判定：本变更动的是被两个下游消费的共享底座（解码库），联动方式是「消费者各自在自己的 change 里验升级效果」（B 验真编译真跑、C 验端到端钉），不在本仓排消费者适配任务。

## Architecture Direction

**定型**：FFmpeg 3.4 → 4.4 LTS（原生 av1dec 自 4.3，旧 API 弃用未移除）；依赖链（x264/fdk-aac/openssl/libsmbclient）按版本要求随重编；构建管线在本仓重建并入库（脚本进版本管理）；产物替换保持现有 vendored framework 形态，切片 = arm64 设备 + x86_64 模拟器；质量门两条可执行命令：二进制 strings 出 `Lavc58.` 前缀、符号表含 av1 解码器注册符号。

**备选与取舍**（均已在访谈中走过）：A2（直上 6.x 挂 dav1d）——速度最好但消费方要做解码 API 迁移，用户选 A1 的最小动作优先；B（只做新芯片硬件路）——iOS 14 底线下够不着，只能当顺手加速；C（服务端转码）——面向通用 NAS 不能假设服务器有转码器，排除；D（只做显式报错）——与任何路线不冲突，接线归 B。

**spec 边界**：新建能力 `av1-decoding`（库交付契约：AV1 软解码器可用＋构建产物质量门）。本仓无运行时接口契约（DDL/API 端点）。

**规则边界**：不适用——本变更不新增/修改业务规则、校验或拦截，不新增/改变执行路径（纯重编与产物替换）；撰写者复核后如实填。

（七要素结构化方案摘要正文按分工记于 proposal.md 对应小节；本节保留访谈基线四块，确认链经上方 User Answers 逐字记录闭合。）

## Authoring Tier

- Tier: COMPLEX
- Rationale: 多任务组且存在跨组依赖（依赖链重编 → ffmpeg 核心 → 打包/元数据 → 质量门），构建管线从零创建、多架构交叉编译、许可证开关联动，符合 COMPLEX 判据；由全新单会话生成代理撰写其余四件套，本文件（clarify）由主代理亲写。

## 执行边界

第 3 轮（末轮）架构审查给出；本小节第一个 yaml 围栏为机器可读段。收口说明：三轮上限用尽未达正式 PASS 印章——封笔时为 1 Low + 3 Info（x264-iOS「源码目录」事实修正、符号抽样建议、build/ 派生数据提示、签名为历史管线残留的现状说明），均事实锚/措辞级、无 Critical/High/Medium，全部由审查者自带具体修法、分派方已逐字采纳（clarify/proposal/spec/design 同步改毕），未复审即封笔——如需正式 PASS 印章可随时加赛一轮核验。

```yaml
task_groups:
  "1":
    allowed_directories:
      - "scripts"
      - "CYFFmpeg/x264-iOS"
      - "CYFFmpeg/fdk-aac-ios"
      - "CYFFmpeg/openssl-ios"
      - "CYFFmpeg/Smbclient"
    allowed_packages:
      - "scripts"
      - "CYFFmpeg/x264-iOS"
      - "CYFFmpeg/fdk-aac-ios"
      - "CYFFmpeg/openssl-ios"
      - "CYFFmpeg/Smbclient"
    notes: >-
      本组入库面＝新建 scripts/ ＋四个 vendored 目录的回填产物；源码取自官方源落仓外工作区（六处 vendored 目录仓内只有预编译 .a＋头文件，无源码）。配对核验扫描排除 Headers.bak-20261115、lib.bak-20261115（含空的 x264-openssl-originals）、libffmpeg/dav1d 空占位；openssl 的 -tvOS 变体按任务 1.4 先定去留再回填。libsmbclient.a 现约 94MiB，最贴近非 LFS 单文件上限，thin 阶段实测体积即按 design Risks 的预估机制执行。
  "2":
    allowed_directories:
      - "scripts"
      - "CYFFmpeg/libffmpeg"
      - "CYFFmpeg/ffmpeg-tools"
    allowed_packages:
      - "scripts"
      - "CYFFmpeg/libffmpeg"
      - "CYFFmpeg/ffmpeg-tools"
    notes: >-
      4.4 安装树回填 libffmpeg（include＋lib 全套）；胶合层从 4.4 官方源码重编后回填 ffmpeg-tools（.a 与生成的 config.h/cmdutils.h/ffmpeg.h）；fat 聚合仅 arm64＋x86_64。勿触碰 lib.bak-20261115 与 dav1d 空占位；许可证三项开关断言（任务 2.5）与 thin 层 AV1 符号冒烟（任务 2.6）都在本组闭合。
  "3":
    allowed_directories:
      - "scripts"
      - "CYFFmpeg.framework"
      - "CYFFmpeg.xcodeproj"
    allowed_packages:
      - "CYFFmpeg.podspec"
      - "README.md"
    notes: >-
      根 framework 的二进制＋Headers 替换（确定性重建并与现集合作差比对留痕）；伞头文件按 D6 作最小修订或脚本侧兼容桩（scripts 因此保持放开）；pbxproj Headers 阶段钉名随之调整；聚合目标维持不 strip（机判门前提）；命令行重链会填充根 build/（未被 .gitignore 覆盖），连同 *.bak-20261115、dav1d 空占位、.gitignore 未提交行一并排除在本变更提交之外；product/ 历史副本不动。
```

## Initial Capabilities

- `av1-decoding`: 本仓交付的解码库构建契约——升级后 AV1 软解码器可用（符号级实证）、依赖链版本对齐、许可证开关开齐、架构切片达标、质量门以两条命令验收。
