# 参赛者理解导读

需能在不依赖 AI 对话的情况下解释并修改以下逻辑。

1. 为什么磁盘容量查询不足以解释 bind mount？root 指文件系统内部被挂出来的子目录，point 指 namespace 内看到的位置。`root=/projects, point=/work` 时 `/work/a` 对应 `/projects/a`。
2. 为什么不能全局最长前缀？上层 overmount 隐藏旧挂载及其孩子。演示中 ID 3 的 point 更长但不可见；必须先跨过 ID 4，再观察它的孩子。
3. parent 缺失为什么合法？进程 root/chroot 隐藏了外层挂载；不能凭缺失父节点判断损坏。缺少可唯一定位的 `/` 时允许检查记录，但拒绝 resolve。
4. 为什么 filesystem_path 可缺失？Linux 的 nsfs root 可以是 opaque 标识，拼接目录会制造虚假路径。该回归来自真实 Linux 数据。
5. mount options 的 ro 与 super options 的 ro 有何区别？前者只约束该挂载，不能据此声称同一文件系统其他挂载只读。
6. shared 和 master 可同时存在吗？可以，表示共享且作为另一个组的 slave；unbindable 则不能与这两者并存。未知可选标签应保留，未来内核字段不应被默默丢弃。
7. 差分 Replaced 证明了什么？只证明可观察身份字段变化，不证明完整生命周期。相同 mount ID 可复用，namespace token 也需正确归属。
8. MoonBit 的贡献在哪里？解析、错误与预算、图约束、可见路径、传播查询、变化判断；JS 仅读文件和 namespace。Python oracle 逐组件遍历，findmnt 是独立系统实现。

建议修改练习：在 synthetic fixture 中给 ID 4 增加孩子，预测 resolve 结果，再运行示例。读 types.mbt → parse.mbt → topology.mbt → mount_test.mbt → scripts/verify_linux.py，检查为什么测试失败。不要把“全部测试通过”解释为任意内核/路径语义都支持。
