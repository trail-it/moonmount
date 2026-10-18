# 来源与独立贡献

MoonMount 是独立编写的 MoonBit 实现，MIT。未复制或移植 libmount、sysinfo、chokidar、moondisk 的实现。AI 辅助了调研、代码、测试与文档；参赛者须能解释 docs/participant-guide.md 中的不变量和限制，并对使用的代码负责。

格式/语义参考：[Linux mountinfo 手册](https://man7.org/linux/man-pages/man5/proc_pid_mountinfo.5.html)、[内核 shared subtree 文档](https://www.kernel.org/doc/Documentation/filesystems/sharedsubtree.txt)。引用格式事实，不重分发手册全文。

运行依赖仅 MoonBit 标准库（[moonbitlang/core](https://github.com/moonbitlang/core)，Apache-2.0 WITH LLVM-exception）和 Node.js 宿主。Node.js 的 fs/TextDecoder 适配只读文件，不实现挂载解析或路径决策；工具链/Node 未随包附带。

开发验证使用 Python 标准库、util-linux/findmnt（GPL-2.0 等各组件许可；只调用系统程序，不链接或重分发实现）。一页 PDF 使用 ReportLab 和 Windows 微软雅黑系统字体生成，字体不随源码包分发；PDF 仅包含必要嵌入子集，保留可编辑 Markdown。所有公开 fixture 为自编 synthetic，MIT。

未分发 registry 镜像、第三方发布源码归档、真实宿主快照或个人 skill。原始材料仅在忽略的本地 research/release-local 目录。
