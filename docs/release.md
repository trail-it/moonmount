# 本地交付 0.1.0

2026-10-18，MoonMount，local/moonmount，仅本地保存。公开仓库、Git 公开作者身份、Mooncakes namespace 和参赛者待定。中性本地 Git 身份只记录真实开发阶段，不代表用户公开身份。

源码、核心测试、Node CLI、跨后端演示、API 文档、调研/方案、三分钟演示说明、申报草稿和一页 PDF 随项目保存。功能冻结后的历史以 `git log` 为准，不补造公开时间。

实测 Windows/Linux 工具链：moon 0.1.20261012 (748b63c)、moonc v0.10.15+943464bfa、moonrun 0.1.20261012。Windows 系统 PATH 原有旧版和 Linux 原有旧版未替换；验证使用项目内忽略目录的匹配版本，不包含凭据或登录状态。Node Linux v22.22.1；findmnt/util-linux 2.41.3。

|范围|实际结果|
|---|---|
|Windows JS / Wasm-GC|格式检查、+73/deny-warn、构建、每后端 22 项测试（含 1 文档测试）通过；demo JSON 相同|
|CLI 错误|7 类失败、行号/原因、严格 UTF-8、实际输入预算、非 Linux live 拒绝通过|
|独立 oracle|37 synthetic 挂载、19 路径、5 个可见挂载与 Python 逐组件模型一致；全局最长前缀错误的反例通过|
|Linux JS|真实只读采集；64 条记录的 7 类字段、6 路径与 findmnt 一致；namespace 前后标识/失败路径通过|
|本地包|moon package 真实归档解压后独立模块 JS/Wasm-GC 消费，解压 CLI 运行；数量/归档大小/结果见 test-evidence/package-consumption.json|

归档位于 `_build/publish/local-moonmount-0.1.0.zip`，清单留忽略的 release-local/package-files.txt。归档包含源代码、必要 fixture、接口、README、许可证和复现脚本；排除 research/release-local/、工具链、原始宿主数据、构建结果、Git 私有记录、PDF 和 workflow。包消费记录本身排除，避免自指大小。未填写 repository 导致的 metadata 提示保留，没有编造仓库 URL。

新机器按 README 准备工具链；`python scripts/verify.py`、`python scripts/verify_oracle.py`、`python scripts/verify_package.py`。Linux 另运行 `python3 scripts/verify_linux.py`。工具链不是分发依赖附件。

公开发布、远端 CI、正式 registry 安装、报名和官方审核均未执行。CI 配置已准备；本地消费不会冒充注册表消费。后续发布需核对身份/真实归属，检查实际分发内容，并将 local 占位模块改为正式 namespace。
