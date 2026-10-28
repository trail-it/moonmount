# 公开发布 0.2.0

2026-10-28，用户授权以 `trail-it` 身份公开发布。GitHub 上传账号、后续 Git author/committer 和 Mooncakes 登录账号均已核对为 `trail-it`；仓库为 [trail-it/moonmount](https://github.com/trail-it/moonmount)，默认分支为 `main`，公开可见。

- Mooncakes：[`trail-it/moonmount@0.2.0`](https://mooncakes.io/docs/trail-it/moonmount@0.2.0)，服务返回 200；独立工程从公开注册表安装确切版本，JS/Wasm-GC 各 1 项公共 API 测试通过，见 [registry-consumption.json](test-evidence/registry-consumption.json)。
- 实际发布归档：53 个文件，MIT，repository 元数据正确；从公开下载地址重新下载并核对 registry 校验和，私有目录未分发，见 [published-archive.json](test-evidence/published-archive.json)。其 SHA-256 为 `e26bcb1651ab659cd2cbec987230b4d295af111c7ba6dbef0e0d7f37886845fc`。
- 本轮 Windows 检查：格式、检查、构建通过，JS/Wasm-GC 各 28 项测试通过；独立 oracle、快照工作流、解压归档消费及独立 Node 成品通过。Linux 真机证据保留 10 月 23 日实际结果；本轮真机连接超时，新的 Linux 验证由公开 CI 执行，不将旧结果改为本轮实测。
- 公开 CI：[verify 工作流](https://github.com/trail-it/moonmount/actions/workflows/ci.yml)，覆盖两个后端、独立 oracle、Linux/findmnt、归档和 registry 消费、独立 Node 成品、隔离命名空间内真实挂载场景。旧版工具链下载返回 403 后，改用官方可下载版本并在运行日志记录实际版本；最终结论以对应 SHA 的运行结果为准。
- 发布检查提交 `3a8f35c` 的 [完整 CI 已通过](https://github.com/trail-it/moonmount/actions/runs/40649798090)，包括实际 overmount/remount 和 registry 消费；摘要见 [public-ci.json](test-evidence/public-ci.json)。后续材料提交由相同工作流再次验证。
- 使用入口：[Node 成品与一页申报书 Release](https://github.com/trail-it/moonmount/releases/tag/v0.2.0)；源码使用 `moon add trail-it/moonmount@0.2.0`。

本地研发始于 10 月 18 日，首次公开于 10 月 28 日。原有 8 个中性本地身份提交保留原始作者、时间和 SHA，新发布工作由 `trail-it` 提交；不补造连续公开开发记录。有效阶段提交已不少于 10 个，未用空提交或无意义拆分凑数。

运行代码冻结于 `803ad2636d4b3bda51fa7aa2b524fa603eb184ff`；后续提交补充注册表消费检查、CI 修复和正式发布材料。注册表 0.2.0 是不可变归档，后续仓库中的发布证据与申报书更新不改写已发布包。未代填赛事报名、个人资料或声称通过官方审核。

以下保留历次本地交付记录，日期与“未发布”状态均描述当时情况。

---

# 本地交付 0.2.0：可直接使用的快照工具

2026-10-23。仍仅本地保存，模块 `local/moonmount@0.2.0`，未上传、发包或报名。

本轮补齐实际使用闭环：Linux `capture` → 新快照文件 → `show/query` → `compare`，以及 Windows 离线 `import/show/query/compare`。快照文件携带 namespace，比较自动核对；已有输出拒绝覆盖。提供 --help/--version 和四类变化摘要，保留旧版原始文本接口。

可直接交给使用者的文件：`output/cli/moonmount-0.2.0-node.zip`，解压后只需 Node.js >=22。运行时不需要 MoonBit/Python/npm。生成源为 `scripts/build_cli.py`，包内含使用说明、合成 fixture、MIT 许可和编译 core 的 LICENSE/NOTICE。另有 `_build/publish/local-moonmount-0.2.0.zip` 源码库归档。

验证：Windows 与用户 Linux 真机，JS/Wasm-GC 各 28 项测试；真机 63 条记录 × 7 字段、6 路径与 findmnt 一致；另有真实采集、保存、离线查询、自动 namespace 比较、拒绝覆盖和独立 Node 成品工作流。具体实际结果见 docs/test-evidence/offline.json、offline-linux.json、linux.json、cli-workflow*.json、standalone-linux.json、standalone-cli.json 和 package-consumption.json。28 项含 1 个文档测试，消费者测试及脚本检查分别记录，不混加。

Windows 工具链与真机工具链为 moon 0.1.20261012 / moonc v0.10.15，真机 Node v22.22.1；本轮按用户要求使用真机，不使用笔记本 Docker。真机验证放在项目内独立子目录，原工作副本保留。普通 user namespace 被真机限制，补充测试使用现有无交互 sudo 在独立 mount namespace 内完成；四项场景与新版快照比较均通过，宿主挂载未改动。

快照格式为 moonmount.snapshot/schema 1；新增 encode/decode_snapshot 公开 API 与 InvalidSnapshot 错误。原路径、传播和变化定义不变，已知限制仍见 architecture。正式仓库/namespace/公开身份待定，线上 CI 和 registry 消费未执行。

---

## 0.1.0 历史交付记录

# 本地交付 0.1.0

2026-10-20 修订（首次交付 2026-10-18），MoonMount，local/moonmount，仅本地保存。公开仓库、Git 公开作者身份、Mooncakes namespace 和参赛者待定。中性本地 Git 身份只记录真实开发阶段，不代表用户公开身份。

源码、核心测试、Node CLI、跨后端演示、API 文档、调研/方案、三分钟演示说明、申报草稿和一页 PDF 随项目保存。功能冻结后的历史以 `git log` 为准，不补造公开时间。

首次实测 Windows/Linux 工具链：moon 0.1.20261012 (748b63c)、moonc v0.10.15+943464bfa、moonrun 0.1.20261012。Windows 系统 PATH 原有旧版和 Linux 原有旧版未替换；验证使用项目内忽略目录的匹配版本，不包含凭据或登录状态。首次 Node Linux v22.22.1、findmnt/util-linux 2.41.3。当前 Windows：moon 20261012、moonc v0.10.15、Node v24.19.0；当前 Linux 容器：moon 0.1.20261016 (1af328f)、moonc v0.10.16+b1a0e846e、moonrun 20261016、Node v22.23.3、findmnt 2.38.1。两套实际工具链都通过完整检查，不改全局安装。

|范围|实际结果|
|---|---|
|Windows JS / Wasm-GC|2026-10-20：格式检查、+73/deny-warn、构建、每后端 24 项测试（含 1 文档测试）通过；demo JSON 相同|
|CLI 错误|7 类失败、行号/原因、严格 UTF-8、实际输入预算、非 Linux live 拒绝通过|
|独立 oracle|37 synthetic 挂载、19 路径、5 个可见挂载与 Python 逐组件模型一致；全局最长前缀错误的反例通过|
|Linux JS|首次实测 64 条记录 × 7 类字段、6 路径。10 月 20 日在本机 Linux 容器新增 25 条记录 × 7 字段、6 路径通过，见 linux.json；JS/Wasm-GC 每后端 24 项通过，见 offline-linux.json。历史记录保留为 linux-2026-10-18.json|
|实际挂载变化|4 场景通过：临时 namespace 内 bind/overmount、特殊字符路径及只读 remount；内核 O_PATH/fdinfo mnt_id 对照，见 mount-namespace.json|
|本地包|moon package 真实归档解压后全套 README 离线检查/oracle，以及独立模块 JS/Wasm-GC 消费，解压 CLI 运行；数量/归档大小/结果见 test-evidence/package-consumption.json|

归档位于 `_build/publish/local-moonmount-0.1.0.zip`，清单留忽略的 release-local/package-files.txt。归档包含源代码、必要 fixture、接口、README、许可证和复现脚本；排除 research/release-local/、工具链、原始宿主数据、构建结果、Git 私有记录、PDF 和 workflow。包消费记录本身排除，避免自指大小。未填写 repository 导致的 metadata 提示保留，没有编造仓库 URL。

新机器按 README 准备工具链；`python scripts/verify.py`、`python scripts/verify_oracle.py`、`python scripts/verify_package.py`。Linux 另运行 `python3 scripts/verify_linux.py`。工具链不是分发依赖附件。

公开发布、远端 CI、正式 registry 安装、报名和官方审核均未执行。CI 配置已准备；本地消费不会冒充注册表消费。后续发布需核对身份/真实归属，检查实际分发内容，并将 local 占位模块改为正式 namespace。

本轮修复 raw CR/控制字符及内核 source/type 的 hash 转义；公开 API 无变化。验证结果使用 checked_at_utc 实际执行时间。新增真实 mount namespace 场景需要隔离测试权限，产品本身仍只读。

核心修复提交 `2de236c`；实际内核 oracle 完善 `5f366f5`。本次可控本地技术项全部通过；公开流程状态仍按上表区分。原远程测试机本轮连接超时后，使用本机 Docker Linux 容器完成新的实测，不把历史数据改成当前结果。
