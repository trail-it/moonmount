# MoonMount 0.1.0

2026-10-18 · 十月赛本地申报草稿 · GitHub ID / 项目仓库 / Mooncakes namespace：待指定。

一个为 MoonBit 生态提供 Linux 挂载拓扑、路径归属解释与快照变化分析能力的开源项目。面向容器诊断、部署检查和文件系统工具，解释 bind mount 的内部目录，以及叠加挂载为何让旧子挂载不可见。

调研读取 3090 条 registry 元数据、相关公开 API/README、GitHub 活动与 issues。sysinfo 已有磁盘/挂载容量，chokidar 已有文件事件，moondisk 已有目录快照；本项目新增 parent 图、overmount 可见性、filesystem root、传播组和同 namespace 对象差分。检索范围未发现同等独立模块，不断言全网不存在。

独立原创、MIT：纯 MoonBit 完成有界 mountinfo 解析、四种转义、图约束、可见路径、传播查询及 Added/Removed/Changed/Replaced；Node 仅负责文件和 namespace 标识读取。不移植 libmount，不把宿主绑定当作核心。

moon 0.1.20261012 / moonc v0.10.15；JS/Wasm-GC 各 22 项测试含文档示例，格式/check/build 与警告检查通过。独立 Python oracle：37 synthetic 挂载、19 路径。Linux 实机 64 条记录 × 7 字段、6 个路径与 findmnt 一致；真实 nsfs root 发现推动 Option 模型修复。实际包归档从独立模块消费，结果见 docs/test-evidence/。

3 分钟演示：先解释容器路径问题，再运行 examples/replay 看到 /work/hidden/file 正确落到挂载 4；比较 Changed、查看传播组与错误行为，最后 Linux live/findmnt 对照。入口与完整讲解见 docs/demo.md。

限制：词法归属，不解析 symlink/权限；非 UTF-8 文件名、native、事件订阅不在支持范围。opaque root 无目录映射；mount ID 复用不能由相同快照排除。预算和错误契约见 docs/architecture.md。

AI 辅助调研、实现与文档；参赛者须理解核心不变量并承担代码责任，见 docs/participant-guide.md。后续按失败样例回归、维护公开 API 和兼容性。

本地真实阶段历史已保存。公开持续开发、正式仓库/发包、远端 CI、registry 安装、报名与官方审核待后续指定目标和办理；本草稿不声称已满足公开流程或通过审核。规则于 2026-10-18 通过官方 Hackathon2026/src/App.tsx 核对。
