# 架构与 API 契约

根包独立拥有公开 Mount、Snapshot、Resolution、Change 与 MountError，内部拆分 types/parse/topology。无第三方运行模块或 C 绑定。cmd/main 的 JS 适配负责文件读取、严格 UTF-8 解码、namespace 标识及错误退出；所有协议、图和变化判断都在 MoonBit。

## 解析与不变量

先检查总长度、行长度和记录数，按六个固定字段和 `-` 分隔符解析；四种内核转义只解码一次。ID、设备号、传播组严格十进制及 Int32 上界。未知 optional 字段保留，已知传播字段检查重复/冲突；mount options 和 superblock options 分开。

Snapshot 构建 ID 索引和 parent → children 索引。重复 ID、非根自环、其他 parent 环以及 child point 不在 parent point 下均拒绝。父节点缺失允许，因为 chroot 可隐藏外层挂载。公开 Mount 的字段只读且只含不可变值；Snapshot 返回的数组均复制，调用方不能破坏内部图。

root 并非总是绝对目录：实际 Linux namespace 文件挂载可出现 `mnt:[…]` 这类 root。保留原样；Resolution.filesystem_path 为 String?，仅 root 为规范绝对目录时生成 Some(path)，不适用时为 None（JSON 省略该键）。不能把 opaque root 冒充目录拼接。

## 可见路径解析

1. 找唯一的 namespace 根：point=/ 且 parent=self 或父节点不在记录中。
2. 从该节点开始，筛选当前节点直接孩子中 point 为目标路径组件前缀的挂载，优先最短 point。
3. 同位置叠加挂载沿 parent 链继续进入；旧挂载其他孩子不会越过覆盖后的新挂载重新出现。
4. 直系候选存在同长度歧义则报错。经过节点 ID 作为 chain 返回。
5. 以选中挂载 root 拼接剩余相对路径；opaque root 返回 None。

这与全局最长前缀不同：记录 3 的 /work/hidden 被记录 4 在 /work 的叠加遮住，不能选 3。解析没有文件 I/O，不做符号链接、路径存在和权限检查；路径必须已是 namespace 内规范绝对形式。

建图/环检测为 O(n) 期望时间，索引 O(n) 空间。一次 resolve 扫描所经过节点的孩子，总计最多 O(n)，额外存储返回 chain。ancestors 沿 parent 链；peer/slave 过滤 O(n)。不把这些操作宣传为内核等价路径查找。

## 差分与传播

diff 要求 namespace_id 相同；真实 namespace 生命周期的归属由调用方保证，CLI diff 的 token 是声明，不是认证。先按旧记录顺序报告移除/变化，再按新记录顺序报告新增。共享 ID 的 device/root/fs_type/source 改变为 Replaced；其余字段文本变化为 Changed。相同 ID 和相同记录无法检测中间卸载重建；选项重排可能产生 Changed。

peers(group) 选择 shared 同组，slaves(group) 选择 master 指向组的直接从属挂载；propagate_from 和 unbindable 保留，不模拟内核传播副作用。

## 平台与资源

核心：JS、Wasm-GC。Node CLI：离线两平台，live 只 Linux；不声明 native。CLI 打开文件后分块读取，实际累计超过 8 MiB 即失败并关闭，不能靠 procfs 的 stat.size=0 判断长度。UTF-8 解码 fatal，拒绝非法字节。库限制 8 Mi UTF-16 单元、单行 65536、16384 记录，非空 namespace token 最多 256 单元。核心不拥有 OS 资源。

live 前后核对 boot ID + mount namespace 链接；仅表示采集时 namespace 标识稳定，不保证文件系统状态跨多个系统接口原子一致。没有守护进程或事件订阅。所有输出由调用方决定是否保存，库和 CLI 不执行挂载变更。
