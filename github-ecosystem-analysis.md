# GitHub 生态调研

读取日期 2026-10-18。检索 MoonBit + mountinfo/mount namespace/procfs、VCD、sourcemap、incremental；读取官方 awesome-moonbit，查看 moonbit-community 组织公开索引。搜索引擎对 language:MoonBit/topic:moonbit 覆盖不完整，未把空结果当作不存在证明。

GitHub API 读取仓库元数据、默认分支、最多 10 条 all-state issues，以及 README/代表性 mbti。原件与失败记录在 research/。候选比较基于实际能力，未发现并虚构具体用户 issue。

|仓库|最近 pushed_at / stars（读取时）|审阅与判断|
|---|---|---|
|[i5ting/chokidar](https://github.com/i5ting/chokidar)|2026-05-18 / 3|默认分支 codex/chokidar-native；README.mbt.md、pkg.generated.mbti；文件事件 API，可与本项目组合。issues 返回空。|
|[xiaobai718-ab/moondisk](https://github.com/xiaobai718-ab/moondisk)|2026-09-29 / 0|README：目录扫描、容量归类、清理与增长；不替代 mount 对象 parent/overmount 语义。issues 返回空。|
|[lqhy1234567/moonbit-vcd](https://github.com/lqhy1234567/moonbit-vcd)|2026-08-24 / 0|master 的 README、公开接口，已有数字波形处理。issues 返回空。|
|[Derk2006/sourcemap](https://github.com/Derk2006/sourcemap)|2026-08-11 / 0|master README 显示功能高度一致，不再重复。issues 返回空。|
|[moonbit-community/sysinfo](https://github.com/moonbit-community/sysinfo)|API 404；未知|通过 registry 归档核对 API，不声称已阅读不可访问仓库的 issues 或 roadmap。|

时间只证明可见活动，不单独证明维护质量。未发现可据以认领的具体上游待办；本项目是基于公开 Linux 接口的独立原创实现。

非 MoonBit 的成熟对照：[util-linux/libmount](https://github.com/util-linux/util-linux)、findmnt。用于 Linux 实机独立 oracle，不移植其 C 源码。协议依据：[mountinfo 手册](https://man7.org/linux/man-pages/man5/proc_pid_mountinfo.5.html)、[内核 shared subtree 文档](https://www.kernel.org/doc/Documentation/filesystems/sharedsubtree.txt)。

本批项目去重：MoonNetlink 处理网络对象；MoonPressure 处理 cgroup 压力与准入；MoonFlacTag 处理媒体元数据；MoonMount 处理文件系统挂载可见拓扑。没有共享实现改名或拆分同一项目。
