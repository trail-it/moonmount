# Mooncakes 生态调研

2026-10-18 实际读取 [公开 registry 数组](https://mooncakes.io/api-new/v0/modules)：3090 条、按 name 去重；无分页字段。仅遍历名称、描述、keywords，不代表逐个阅读源码。原件留 research/modules.json，抓取不进入分发。

覆盖 AI、agent、workflow、parser、compiler、database、web、image、crypto、testing、devtool、wasm、visualization，并追加 mount/mountinfo/namespace/procfs/filesystem/inotify、VCD、sourcemap、incremental。关键词数由 research/summary.json 记录。

|模块/确切版本|发布时间 created_at|已核对能力与本项目边界|
|---|---|---|
|[Milky2018/sysinfo@0.1.6](https://mooncakes.io/docs/Milky2018/sysinfo@0.1.6)|2026-10-13|读取 registry 发布归档 README、mbti、system_impl.mbt。Disk 提供容量、设备、mount_point、read_only；内部 MountEntry/parse_mount_table_entries 处理宿主桥产生的容量列表。未见公开 parent ID、filesystem root、传播关系、覆盖挂载解析、namespace 快照差分 API。并非没有挂载/磁盘查询能力。|
|[i5ting/chokidar@0.1.0](https://mooncakes.io/docs/i5ting/chokidar@0.1.0)|见 registry 原件|README.mbt.md 与公开接口提供 watcher、事件和 recursive/debounce；inotify/kqueue 观察目录内容，不解释 mount tree。|
|[xiaobai718-ab/moondisk@0.1.0](https://mooncakes.io/docs/xiaobai718-ab/moondisk@0.1.0)|见 registry 原件|README 提供目录扫描、空间增长、快照和清理计划；与挂载对象差分不同，不能把其已有 snapshot 能力说成空白。|
|[lqhy1234567/moonbit-vcd@0.3.1](https://mooncakes.io/docs/lqhy1234567/moonbit-vcd@0.3.1)|2026-08-24|README、mbti 已有 VCD 与信号分析，淘汰波形候选。|
|[Derk2006/sourcemap@0.1.1](https://mooncakes.io/docs/Derk2006/sourcemap@0.1.1)|2026-08-11|README 已有 parser/builder/lookup，淘汰 Source Map 候选。|
|[Lyhdsba/moonforge@0.1.3](https://mooncakes.io/docs/Lyhdsba/moonforge@0.1.3)|见 registry 原件|README 已有增量任务执行；另有 moon_taskforge、moon-ninja、多个 incr，淘汰增量构建。|

索引范围未发现专门提供 mountinfo 拓扑、叠加挂载可见路径解释、传播组与同 namespace 差分的公开 MoonBit 模块。此结论有检索范围限制；下载量/依赖数未获得，不推断采用率。

sysinfo GitHub 地址返回 404，已改从 [确切发布源码](https://download.mooncakes.io/user/Milky2018/sysinfo/0.1.6.zip) 核对，404 不解释为停止维护。最新源码提交与版本发布时间分别记录，不混为一谈。
