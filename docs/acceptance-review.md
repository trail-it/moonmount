# 验收准备复核

2026-10-18，十月赛；MoonMount 0.1.0；main；local/moonmount。公开身份、仓库与 namespace 待指定。

总体：本地源码与材料就绪；公开持续开发/发包/远端 CI 待发布；未报名、入群或取得官方审核结果。本复核不是赛事方结论。

规则依据：[官方十月站点源码](https://github.com/moonbitlang/Hackathon2026/blob/main/src/App.tsx)，2026-10-18 经 raw GitHub 读取。报名/验收截至 10 月 31 日、十月最多提交 3 次、每队不超过 3 人；MoonBit 主体、可运行成果、公开持续开发与开源合规。次数适用主体和修改计数不自行推断；本次不执行报名。以下测试矩阵是本项目质量标准，不声称每项为官方硬条款。

|检查|证据|状态|
|---|---|---|
|独立需求/生态去重|根目录两份生态报告、竞争分析、方案|已调研，包含相邻 API 和失败请求|
|MoonBit 核心|types/parse/topology；JS 仅宿主读取|独立原创，无 C 核心/上游实现搬运|
|格式/检查/测试/构建|docs/test-evidence/offline.json|JS/Wasm-GC 各 22 项通过，含 1 文档测试；+73、deny-warn|
|独立 oracle|docs/test-evidence/oracle.json|37 挂载、19 路径、5 个可见挂载；隐藏子树反例通过|
|Linux 实际调用|docs/test-evidence/linux.json|64 条记录 × 7 字段、6 个路径与 findmnt 一致；读取失败和 namespace 标识通过|
|实际归档消费|scripts/verify_package.py；test-evidence/package-consumption.json|实际 zip 解压后独立模块运行公共 API，详细结果以生成记录为准|
|接口/示例/文档|pkg.generated.mbti、API.mbt.md、examples/replay、docs/|可运行示例；两后端 demo JSON 一致|
|来源与许可|LICENSE、THIRD_PARTY.md、fixtures/README.md|MIT；synthetic fixture；AI 辅助披露|
|分发边界|.gitignore/.moonignore、实际 zip 清单|排除原始宿主、抓取、工具链、私有记录；PDF 只在本地项目材料中|
|CI/注册表|.github/workflows/ci.yml|配置已准备，未触发远端 CI、未发布或 registry 消费|
|申报|submission-proposal.md、output/pdf/|本地草稿；公开身份/链接待定|

关键修复：实机发现合法的非目录 nsfs root；解析保留原值，filesystem_path 用 Option 表达不适用，新增回归。没有使用 synthetic 数据替代实机成功结论。

范围：Linux mountinfo、规范绝对路径的词法归属；不跟随 symlink、不检查权限/存在、不保证相同记录无中间重建；不支持非 UTF-8 文件名和 native 后端。完整预算/错误语义见 architecture。

人工剩余：参赛者理解和确认真实身份；后续如发布须指定 owner/repo、公开 Git 身份、Mooncakes namespace，再公开持续维护、验证远端 CI 和确切版本 registry 安装，按官方入口报名。本次不猜填个人资料。
