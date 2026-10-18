# 项目竞争分析

2026-10-18；0-5 定性评分，竞争/难度越高越拥挤/越难，其余越高越有利。潜力不是获奖概率，不将五列求和。

|项目|已有竞争|MoonBit 缺口|实现难度|展示效果|获奖潜力|
|---|---:|---:|---:|---:|---:|
|数字波形分析|5|1|3|4|2|
|Source Map 工具|5|1|3|3|2|
|增量构建|5|1|4|3|2|
|MoonMount 挂载拓扑解释|2|4|3|4|4|

前三项分别有 moonbit-vcd、多个 sourcemap、moonforge/incr 等，已有用户需求和主要操作高度一致，淘汰。相应 registry/GitHub 来源见两份生态报告。

MoonMount 的相邻竞争为 sysinfo 的磁盘查询、moondisk 的目录快照和 chokidar 的文件事件。它们分别解决容量、目录内容和变化通知；本项目新增 parent 链、bind filesystem root、overmount 隐藏子树、传播组、namespace 内对象差分与有歧义时拒绝解析。成熟 C libmount 是行为对照。它增加可嵌入 MoonBit 工具的 Linux 专有能力，不是给通用工具换系统名称。

与十月规则对应：明确独立边界、MoonBit 核心、可复现测试、真实 Linux 调用、文档和许可。公开持续开发与正式申报留待用户后续指定发布目标；本地历史不冒充公开历史。
