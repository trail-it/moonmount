# 验收准备复核

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
