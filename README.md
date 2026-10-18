# MoonMount

纯 MoonBit 的 Linux 挂载拓扑、可见路径解析和 namespace 快照差分库。用于容器诊断、部署检查和文件系统工具：解释一个路径属于哪个挂载、对应文件系统内部的哪个目录，以及挂载叠加后哪些旧子树已被遮住。

本地版本 0.1.0，MIT，临时模块名 `local/moonmount`。已完成本地交付，公开仓库、发布 namespace 和参赛者身份待定。

## 三分钟体验

使用 MoonBit 2026-10-12 兼容工具链；Node.js 用于 JS 命令行，Python 用于开发验证。Windows 若已准备本项目内的工具链，可先执行 `. ./scripts/windows-env.ps1`，只影响当前会话。完整版本见 docs/test-evidence/。

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

在调用方 moon.pkg 导入 `"local/moonmount" @mount`；当前通过本地 moon.work 使用，正式 registry 安装留待发布。

```moonbit nocheck
let snapshot = @mount.parse(text, namespace_id="same-namespace-lifetime")
let result = snapshot.resolve("/work/main.mbt")
let changes = snapshot.diff(newer)
let peers = snapshot.peers(7)
```

完整可执行示例见 [API.mbt.md](API.mbt.md)，签名见 [pkg.generated.mbti](pkg.generated.mbti)。Snapshot 提供 get、mounts、children、ancestors、peers、slaves、resolve、diff。返回的数组是副本，不能修改快照内部图。

解析保留 device、filesystem root、mountpoint、mount/super options、shared/master/propagate_from/unbindable 及未知 optional 字段。差分区分 Added、Removed、Changed 和可观察身份改变的 Replaced。

## CLI

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
# Linux 上另外执行
python3 scripts/verify_linux.py
```

核心支持 JS/Wasm-GC，live 仅 Linux + Node。测试涵盖传播语义、四种转义、隐藏子树、bind root、环、歧义、预算和 namespace 拒绝。独立 Python oracle 逐路径组件遍历；Linux 用 findmnt 核对真实记录和路径。真实结果见 [交付记录](docs/release.md)。

## 范围与限制

路径解析是 namespace 内的**词法挂载归属解释**：输入必须是规范绝对路径，不含重复斜杠、尾斜杠（根除外）、`.`、`..` 或 NUL；不跟随符号链接、不检查存在/访问权限。缺少唯一根或同位置兄弟挂载有歧义时拒绝猜测，缺失外部父节点可正常检查。

最多 8 Mi UTF-16 单元文本、16384 条记录、单行 65536 单元；CLI 另限制实际输入 8 MiB，严格 UTF-8。ID/设备号为 0..2147483647（ID/传播组正数）。不支持非 UTF-8 文件名、权限操作、事件订阅或所有内核未来格式。

mount ID 可能复用；相同记录不能证明两次观察之间没有卸载重建。选项按原有文本保存，顺序改变也可能报告 Changed。快照采集不是与其他系统状态同步的原子事务。传播组关系反映记录，不模拟内核传播操作。

调研、方案、[架构](docs/architecture.md)、[参赛者导读](docs/participant-guide.md)、[三分钟演示](docs/demo.md)、[验收复核](docs/acceptance-review.md) 和 [申报草稿](submission-proposal.md) 均在本地。未执行公开发布、注册表安装、报名或官方审核。
