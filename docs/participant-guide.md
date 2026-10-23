# 参赛者理解导读

需能在不依赖 AI 对话的情况下解释并修改以下逻辑。

1. 为什么磁盘容量查询不足以解释 bind mount？root 指文件系统内部被挂出来的子目录，point 指 namespace 内看到的位置。`root=/projects, point=/work` 时 `/work/a` 对应 `/projects/a`。
2. 为什么不能全局最长前缀？上层 overmount 隐藏旧挂载及其孩子。演示中 ID 3 的 point 更长但不可见；必须先跨过 ID 4，再观察它的孩子。
3. parent 缺失为什么合法？进程 root/chroot 隐藏了外层挂载；不能凭缺失父节点判断损坏。缺少可唯一定位的 `/` 时允许检查记录，但拒绝 resolve。
4. 为什么 filesystem_path 可缺失？Linux 的 nsfs root 可以是 opaque 标识，拼接目录会制造虚假路径。该回归来自真实 Linux 数据。
5. mount options 的 ro 与 super options 的 ro 有何区别？前者只约束该挂载，不能据此声称同一文件系统其他挂载只读。
6. shared 和 master 可同时存在吗？可以，表示共享且作为另一个组的 slave；unbindable 则不能与这两者并存。未知可选标签应保留，未来内核字段不应被默默丢弃。
7. 差分 Replaced 证明了什么？只证明可观察身份字段变化，不证明完整生命周期。相同 mount ID 可复用，namespace token 也需正确归属。
8. MoonBit 的贡献在哪里？解析、错误与预算、图约束、可见路径、传播查询、变化判断；JS 仅读文件和 namespace。Python oracle 逐组件遍历，findmnt 是独立解析对照；实际覆盖路径用内核 O_PATH/fdinfo mnt_id，避免旧 findmnt 选中被覆盖条目。

建议修改练习：在 synthetic fixture 中给 ID 4 增加孩子，预测 resolve 结果，再运行示例。读 types.mbt → parse.mbt → topology.mbt → mount_test.mbt → scripts/verify_linux.py，检查为什么测试失败。不要把“全部测试通过”解释为任意内核/路径语义都支持。

9. 内核文件名转义为何不能按“去掉所有控制字符”处理？path 字段只引用空格、Tab、LF、反斜杠，合法 CR、其他非分隔控制字符和 DEL 会原样出现；source/type 的 mangle 还会引用 #。必须按字段解码，Python 读取 mountinfo 时也不能做通用换行转换。
10. 为什么全新解压验证有价值？开发目录自带 release-local 与构建缓存可能掩盖缺失目录。现在先从真实归档运行 README 检查，再建独立消费模块，才能验证给新用户的命令。

11. 展示报告与可载入快照有何区别？live/show 输出供查看；capture/import 保存原始正文、schema 和 namespace_id。decode_snapshot 重建图并重新校验，不信任持久化数组。compare 使用文件中的标识，避免误用手填的共同 token。
12. 成品需要什么？用户只需 Node 22+；开发构建才需要 MoonBit/Python。ZIP 附带 core 的许可和 NOTICE，因为编译后的标准库片段随 .cjs 分发。
