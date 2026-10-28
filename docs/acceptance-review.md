# 验收准备复核

## 2026-10-28 公开发布复核

目标身份 `trail-it` 已确认；[GitHub 仓库](https://github.com/trail-it/moonmount) 公开、默认分支 `main`，真实阶段历史不少于 10 个提交。GitHub 上传和 Mooncakes 均使用该账号，后续提交采用其官方 noreply 身份；保留先前中性本地研发历史。

[`trail-it/moonmount@0.2.0`](https://mooncakes.io/docs/trail-it/moonmount@0.2.0) 已发布，重新下载的 53 文件归档与 registry 校验和一致；独立消费工程不使用本地 workspace 替换，两个后端分别完成 1 项公开 API 测试，覆盖快照往返、遮蔽子树、opaque root、差分及快照不可变性。证据见 test-evidence/registry-consumption.json 和 published-archive.json。

本轮 Windows 各后端 28 项测试、独立 oracle、源码归档与独立 Node 成品验证通过。新的 Linux 检查通过 [公开 CI 工作流](https://github.com/trail-it/moonmount/actions/workflows/ci.yml) 执行，最终通过状态以对应提交 SHA 为准；用户 Linux 真机 10 月 23 日的结果保留原日期。本轮真机 SSH 超时，未在笔记本开启 Docker。

发布检查提交 `3a8f35c` 的 [完整 CI 已成功](https://github.com/trail-it/moonmount/actions/runs/40649798090)：两后端、Linux、归档与注册表消费、独立 Node 成品、真实隔离挂载场景全部完成，见 test-evidence/public-ci.json；正式材料提交继续由相同工作流核验。

[Markdown 申报书](https://github.com/trail-it/moonmount/blob/main/submission-proposal.md) 与 [一页 PDF](https://github.com/trail-it/moonmount/blob/main/output/pdf/MoonMount-proposal-0.2.0.pdf) 已按用户给出的 8 项内容更新，包含 3 个完整场景、原创与依赖许可、正式仓库及包链接。规则于本轮通过官方 App.tsx 再次核对，十月报名与验收截止为 10 月 31 日，最多提交 3 次；本次不代填报名或取得官方审核结论。

首次公开发生在 10 月 28 日，本地 10 月 18 日起的研发历史不冒充此前已持续公开。公开持续开发这一赛事要求由评审结合实际历史判断。

---

## 2026-10-23 本地复核记录

2026-10-23 复核（首次交付 2026-10-18），十月赛；MoonMount 0.2.0；main；local/moonmount。公开身份、仓库与 namespace 待指定。

总体：本地源码与材料就绪；公开持续开发/发包/远端 CI 待发布；未报名、入群或取得官方审核结果。本复核不是赛事方结论。

规则依据：[官方十月站点源码](https://github.com/moonbitlang/Hackathon2026/blob/main/src/App.tsx)，2026-10-20 再次经 raw GitHub 读取。报名/验收截至 10 月 31 日、十月最多提交 3 次、每队不超过 3 人；MoonBit 主体、可运行成果、公开持续开发与开源合规。次数适用主体和修改计数不自行推断；本次不执行报名。以下测试矩阵是本项目质量标准，不声称每项为官方硬条款。

|检查|证据|状态|
|---|---|---|
|独立需求/生态去重|根目录两份生态报告、竞争分析、方案|已调研，包含相邻 API 和失败请求|
|MoonBit 核心|types/parse/topology；JS 仅宿主读取|独立原创，无 C 核心/上游实现搬运|
|格式/检查/测试/构建|docs/test-evidence/offline.json|Windows 与 Linux 上 JS/Wasm-GC 均各 28 项通过，含 1 文档测试；+73、deny-warn；另见 offline-linux.json|
|独立 oracle|docs/test-evidence/oracle.json|37 挂载、19 路径、5 个可见挂载；隐藏子树反例通过|
|Linux 实际调用|docs/test-evidence/linux.json|本轮在用户 Linux 真机验证字段与 6 路径、采集/保存/查询/比较、读取失败和 namespace 标识，结果见 linux.json；历史证据保留原日期|
|真实覆盖/重挂载|scripts/verify_mount_namespace.py；test-evidence/mount-namespace.json|4 场景通过：overmount、bind root、特殊字符、真实只读 remount；用 O_PATH/fdinfo mnt_id 对照|
|实际归档消费|scripts/verify_package.py；test-evidence/package-consumption.json|真实 zip 解压后先运行 README 全套离线检查和 oracle，再从独立模块运行公共 API；结果以生成记录为准|
|接口/示例/文档|pkg.generated.mbti、API.mbt.md、examples/replay、docs/|可运行示例；两后端 demo JSON 一致|
|来源与许可|LICENSE、THIRD_PARTY.md、fixtures/README.md|MIT；synthetic fixture；AI 辅助披露|
|分发边界|.gitignore/.moonignore、实际 zip 清单|排除原始宿主、抓取、工具链、私有记录；PDF 只在本地项目材料中|
|CI/注册表|.github/workflows/ci.yml|配置已准备，未触发远端 CI、未发布或 registry 消费|
|申报|submission-proposal.md、output/pdf/|本地草稿；公开身份/链接待定|

关键修复：首次实机发现 nsfs opaque root 并改为 Option 路径；本轮修复合法 CR/控制字符被误拒绝及 source/type 的 # 转义，均保留回归。验证脚本改为实际执行时间，并补齐全新解压目录所需目录创建，避免依赖工作副本残留。

范围：Linux mountinfo、规范绝对路径的词法归属；不跟随 symlink、不检查权限/存在、不保证相同记录无中间重建；不支持非 UTF-8 文件名和 native 后端。完整预算/错误语义见 architecture。

人工剩余：参赛者理解和确认真实身份；后续如发布须指定 owner/repo、公开 Git 身份、Mooncakes namespace，再公开持续维护、验证远端 CI 和确切版本 registry 安装，按官方入口报名。本次不猜填个人资料。

本轮验收按官方六项要求核对：MoonBit 主体、可运行成果、实质新增、MIT/来源、解释导读的本地材料已具备；公开仓库及连续公开记录属于尚未执行的外部流程。不能把“尚未上传”解释为这项官方要求已通过。本地真实历史保留了 10 月 18 日与 20 日的工作，不补造公开开发日期。

结论：本次本地技术检查通过，已知解析缺陷及新用户复现缺项已修复。代码与材料审查未发现尚未处理的本地技术阻塞。官方“公开仓库及连续记录”未执行；AI 可解释一项提供导读和演示材料，参赛者仍需实际掌握并向评审说明。

## 2026-10-23 完整使用复核

新增可携带快照、自动 namespace 拒绝比较、损坏/未知 schema 拒绝、输出文件不覆盖、离线完整工作流，以及无需 MoonBit/Python 的独立 Node ZIP。Windows 与 Linux 真机执行公开命令，最终成品解压后从无关目录执行；证据见 cli-workflow.json、cli-workflow-linux.json、standalone-linux.json、standalone-cli.json。源码实际包和 Node 成品分开核查。
