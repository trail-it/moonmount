# 0.2.0 完整操作演示

解压 `output/cli/moonmount-0.2.0-node.zip`，进入目录，先运行 `node moonmount.cjs --help`。

0-30 秒：解释 Linux 容器里的路径归属，介绍成品只需要 Node。

30-90 秒：`import fixtures/stacked.mountinfo synthetic before.json`，接着 `show before.json` 和 `query before.json /work/hidden/file`。结果应为 ID 4 和 /project/hidden/file；展示报告与可载入文件不同。

90-140 秒：在 Linux 真机用 `capture actual-before.json`，再 `capture actual-after.json`，`compare actual-before.json actual-after.json`。namespace 自动记录和检查；无变化时计数为零。两个不同 namespace 的文件会拒绝比较。

140-180 秒：从另一目录运行成品查询，展示不依赖源码目录；重复写入 before.json 会拒绝覆盖。指出离线分析可在 Windows 执行，capture 仅 Linux；符号链接和权限检查不属于词法归属解释。

以下保留早期核心算法演示作为补充。

---

# 三分钟演示

0-30 秒：容器 `/work` 可为文件系统子目录的 bind mount；磁盘表只显示容量，无法解释其来源和被覆盖的旧子树。

30-90 秒：执行 `moon run examples/replay --target wasm-gc`，明确输入 synthetic。展示 ID 2 的 `/work`、ID 3 的旧 `/work/hidden`、ID 4 在 `/work` 的叠加。输出选择 4、chain=[1,2,4]、filesystem_path=/project/hidden/file。用 CLI 查询 `/work/cache/a`，结果归于 ID 5。

90-140 秒：演示输出的 Changed：ID 4 从 per-mount ro 改为 rw。解释 master/shared 关系，展示不同 namespace 的库调用会报错。非法相对路径和坏字段返回非零并含错误行号。

140-180 秒：Linux 执行 `moon run cmd/main --target js -- live /proc/self/mountinfo`。查看脱敏 Linux evidence 中当前记录数、7 字段及 6 个真实路径对照；展示 mount-namespace.json 的实际覆盖挂载、特殊字符和只读 remount 场景。说明 nsfs opaque root、symlink 和 mount ID 复用限制。结尾指向本地 README、测试和申报草稿。

运行可复现验证：`python scripts/verify.py`、`python scripts/verify_oracle.py`；Linux `python3 scripts/verify_linux.py`。演示没有录屏附件，CLI 命令是可运行演示入口。
