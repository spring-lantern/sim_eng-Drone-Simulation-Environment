这里用
# 递归克隆含子模块的源码仓库
git clone --recurse-submodules https://github.com/TommyChangUMD/ros-jazzy-ros1-bridge-builder.git
克隆了一份TommyChang 工具以防万一
然后
```bash
cd /home/sl/sim_eng/other
tar -zcvf ros-jazzy-ros1-bridge-builder.tar.gz ros-jazzy-ros1-bridge-builder
```
做成了压缩包，不压缩就会出现git套git的尴尬