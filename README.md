# MoonMount

纯 MoonBit 的 Linux 挂载拓扑、可见路径解析和 namespace 快照差分库。用于容器诊断、部署检查和文件系统工具：解释一个路径属于哪个挂载、对应文件系统内部的哪个目录，以及挂载叠加后哪些旧子树已被遮住。

版本 **0.2.0**，MIT，模块名 `trail-it/moonmount`。[GitHub 仓库](https://github.com/trail-it/moonmount) · [Mooncakes API](https://mooncakes.io/docs/trail-it/moonmount@0.2.0) · [自动验证](https://github.com/trail-it/moonmount/actions/workflows/ci.yml)。提供可直接运行的 Node 成品、可携带快照与自动 namespace 检查。

## 直接使用：无需安装 MoonBit

从 [0.2.0 Release](https://github.com/trail-it/moonmount/releases/tag/v0.2.0) 下载 `moonmount-0.2.0-node.zip`（从源码构建时位于 `output/cli/`）。解压到任意目录，只需 **Node.js 22 或更新版本**，运行时无需 MoonBit、Python 或 npm 安装。进入解压目录，在 Windows 或 Linux 上执行：

```sh
node moonmount.cjs --help
node moonmount.cjs import fixtures/stacked.mountinfo synthetic before.json
node moonmount.cjs show before.json
node moonmount.cjs query before.json /work/hidden/file
node moonmount.cjs compare before.json before.json
```

`query` 应返回挂载 4、文件系统路径 `/project/hidden/file`；`compare` 自身应返回零变化。输出文件必须是新路径，重复运行请换文件名。帮助和版本命令分别为 `--help`、`--version`。

## Linux 真机的完整流程

在成品解压目录执行，无需 root：

```sh
node moonmount.cjs capture before.json
node moonmount.cjs show before.json
node moonmount.cjs query before.json /proc/self/mountinfo
node moonmount.cjs capture after.json
node moonmount.cjs compare before.json after.json
```

两次采集之间的变化会列入 `summary` 和 `changes`。快照保存原始 mountinfo 和 namespace 标识，比较自动检查标识是否一致；不同 namespace 会报错。文件也可复制到 Windows 离线分析。文件可能包含机器上的挂载信息，POSIX 新建权限为 0600，由使用者决定是否分享。

|命令|用途|
|---|---|
|`capture NEW_SNAPSHOT`|在 Linux 保存当前挂载快照|
|`import RAW_FILE NAMESPACE NEW_SNAPSHOT`|把外部 mountinfo 转成携带标识的快照|
|`show SNAPSHOT`|列出保存的挂载|
|`query SNAPSHOT /absolute/path`|离线解释路径归属|
|`compare BEFORE AFTER`|自动检查 namespace，输出摘要和详情|
|`live [/absolute/path]`|在 Linux 直接查看，不保存|

`capture/live` 需要 Linux，Windows 提供离线分析，不采集 Windows 磁盘。工具不执行 mount/umount。父目录须存在，已有输出不会被覆盖。成功退出 0，失败在 stderr 说明并退出 1；JSON 命令每次输出一个 JSON 值。

## 从源码运行演示（开发者）

使用 MoonBit 2026-10-12 兼容工具链（[官方安装说明](https://docs.moonbitlang.com/en/latest/tutorial/tour.html)）；Node.js 用于 JS 命令行，Python 用于开发验证。Windows 若已准备本项目内的工具链，可先执行 `. ./scripts/windows-env.ps1`，只影响当前会话。完整版本见 docs/test-evidence/。

```sh
moon run examples/replay --target wasm-gc
moon run cmd/main --target js -- resolve fixtures/stacked.mountinfo synthetic /work/hidden/file
```

synthetic 场景中，挂载 4 覆盖 /work 上的挂载 2，挂载 3 的 /work/hidden 已隐藏。正确结果为挂载 **4**、文件系统内部路径 **/project/hidden/file**、parent 链 **[1,2,4]**。直接对所有记录取最长路径前缀会错选挂载 3。

Linux 实际只读采集：

```sh
moon run cmd/main --target js -- live
moon run cmd/main --target js -- live /proc/self/mountinfo
```

`live` 读取当前 Node 进程的 mount namespace，在读取 mountinfo 前后核对 boot ID 和 namespace 标识。采集结果可能含宿主路径，保存在本地忽略目录即可。无需 root，不修改挂载状态。

## API

在独立 MoonBit 项目中安装确切版本：

```sh
moon add trail-it/moonmount@0.2.0
```

在调用方 `moon.pkg` 导入 `"trail-it/moonmount" @mount`。开发者可运行 `python scripts/verify_package.py` 验证源码归档的独立消费。

```moonbit nocheck
let snapshot = @mount.parse(text, namespace_id="same-namespace-lifetime")
let result = snapshot.resolve("/work/main.mbt")
let changes = snapshot.diff(newer)
let peers = snapshot.peers(7)
```

完整可执行示例见 [API.mbt.md](API.mbt.md)，签名见 [pkg.generated.mbti](pkg.generated.mbti)。Snapshot 提供 get、mounts、children、ancestors、peers、slaves、resolve、diff。返回的数组是副本，不能修改快照内部图。

解析兼容路径四种内核转义、source/fs_type 的 `\043`，保留合法原样控制字符。解析保留 device、filesystem root、mountpoint、mount/super options、shared/master/propagate_from/unbindable 及未知 optional 字段。差分区分 Added、Removed、Changed 和可观察身份改变的 Replaced。

## 原始文本命令（兼容旧版）

```sh
moon run cmd/main --target js -- inspect FILE NAMESPACE
moon run cmd/main --target js -- resolve FILE NAMESPACE /absolute/path
moon run cmd/main --target js -- diff OLD_FILE NEW_FILE SAME_NAMESPACE
```

FILE 为 UTF-8 mountinfo 文本。NAMESPACE 是调用方记录的同一 namespace 生命周期标识，diff 不会推断文件来自何处，调用方须保证两文件属于同一 namespace。成功输出 JSON/退出 0；文件、输入、预算、拓扑或参数错误在 stderr 说明并退出 1。输出不修改输入。

## 验证

```sh
python scripts/verify.py
python scripts/verify_oracle.py
python scripts/verify_package.py
python scripts/verify_registry.py
python scripts/verify_cli_workflow.py
python scripts/build_cli.py
# Linux 上另外执行
python3 scripts/verify_linux.py
# 在支持 user namespace 的 Linux 上，执行真实挂载场景
unshare --user --map-root-user --mount --propagation private env MOONMOUNT_DISPOSABLE_NAMESPACE=1 python3 scripts/verify_mount_namespace.py
```

核心支持 JS/Wasm-GC，live 仅 Linux + Node。测试涵盖传播语义、四种转义、隐藏子树、bind root、环、歧义、预算和 namespace 拒绝。独立 Python oracle 逐路径组件遍历；实际包解压后还执行 README 的完整离线验证；Linux 用 findmnt 核对真实记录和路径。内核场景测试需可创建 user/mount namespace，或使用带 CAP_SYS_ADMIN 的一次性容器；它只操作测试命名空间的临时挂载。真实结果见 [交付记录](docs/release.md)。

## 范围与限制

路径解析是 namespace 内的**词法挂载归属解释**：输入必须是规范绝对路径，不含重复斜杠、尾斜杠（根除外）、`.`、`..` 或 NUL；不跟随符号链接、不检查存在/访问权限。缺少唯一根或同位置兄弟挂载有歧义时拒绝猜测，缺失外部父节点可正常检查。

最多 8 Mi UTF-16 单元文本、16384 条记录、单行 65536 单元；CLI 原始文本输入另限 8 MiB，严格 UTF-8。ID/设备号为 0..2147483647（ID/传播组正数）。不支持非 UTF-8 文件名、权限操作、事件订阅或所有内核未来格式。

mount ID 可能复用；相同记录不能证明两次观察之间没有卸载重建。选项按原有文本保存，顺序改变也可能报告 Changed。快照采集不是与其他系统状态同步的原子事务。传播组关系反映记录，不模拟内核传播操作。

调研、方案、[架构](https://github.com/trail-it/moonmount/blob/main/docs/architecture.md)、[参赛者导读](https://github.com/trail-it/moonmount/blob/main/docs/participant-guide.md)、[三分钟演示](https://github.com/trail-it/moonmount/blob/main/docs/demo.md)、[验收复核](https://github.com/trail-it/moonmount/blob/main/docs/acceptance-review.md) 和 [申报书](https://github.com/trail-it/moonmount/blob/main/submission-proposal.md) 随仓库提供。实际发布与验证状态见 [交付记录](https://github.com/trail-it/moonmount/blob/main/docs/release.md)。报名与官方审核由参赛者按赛事流程办理。

源码构建成品：`python scripts/build_cli.py`。生成的 `.cjs`/Node ZIP 不进入 Mooncakes 源码包；源码归档使用同一命令重新生成。

快照格式为 `format=moonmount.snapshot`、`schema=1`、`namespace_id`、`mountinfo`。库提供 `snapshot.encode()` 与 `decode_snapshot(text)`；损坏数据、未知 schema 会拒绝。`live/show` 展示报告不是可载入的快照，应使用 `capture/import` 保存。快照 JSON 的 CLI 上限为 64 MiB，库上限为 64 Mi UTF-16 单元，为原始文本的 JSON 转义保留余量。
