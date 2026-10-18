# Fixture 来源

stacked.mountinfo 为本项目手写的 synthetic 场景，MIT。设备名和 ID 均为虚构。挂载 4 覆盖挂载 2，原挂载 3 仍出现在记录中但路径不可见；挂载 5 属于覆盖后的新树。关键断言：/work/hidden/file → 挂载 4 → filesystem 内 /project/hidden/file。

真实 Linux mountinfo 原件只保存在忽略目录，不作为公开 fixture。
