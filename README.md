# J2Me_ReSize
✨ Debian 平台 J2ME 游戏画面适配工具  
一键环境部署 | 图片智能处理 | 双源容错下载 | 彩色炫酷终端界面

## 📌 项目简介
本项目基于 **Debian x86_64** 系统运行，依托 **OpenJDK 8** 运行环境与 **ASM 4.0 字节码插桩** 技术，一键完成环境部署、JAR 文件画面适配、背景图透明挖空处理。

无需复杂手动配置，脚本自动拉取依赖与项目文件；支持两种处理模式：基础版仅画面偏移适配，背景图版支持自定义背景图并自动挖空中间游戏区域。

## 🎨 界面特色
- 彩色分级状态提示，运行进度直观清晰
- 艺术字开场动画，终端视觉体验出色
- 自动检测 sudo 权限、安装系统依赖
- 异常报错高亮提醒，便捷排查故障问题
- 双模式选择，灵活适配不同需求场景
- 双源下载（GitHub 直连 + github.dpik.top 镜像），国内网络友好

## 🧰 核心依赖
- 运行环境：OpenJDK 8（`apt install openjdk-8-jdk`）
- 字节码插桩：ASM 4.0
- 图片处理：ImageMagick、FFmpeg
- J2ME 标准库：CLDC 1.1 / MIDP 2.0

## 📋 运行环境要求
1. Debian x86_64 系统（Debian 12+ 推荐）
2. 网络状态正常，可拉取 GitHub 资源
3. `sudo` 权限（用于安装系统软件包）
4. 待处理文件：J2ME 格式 JAR 游戏文件
5. 背景图（可选）：支持常见图片格式（PNG/JPG/JPEG）

## 🚀 快速使用教程

### 1. 拉取环境安装脚本
打开终端，执行以下命令自动完成工具与环境部署：

```bash
# 国内加速源（优先推荐）
wget -qO- https://github.dpik.top/https://raw.githubusercontent.com/XXIF/J2Me_ReSize/main/install.sh | bash
```

```bash
# GitHub 官方源
wget -qO- https://raw.githubusercontent.com/XXIF/J2Me_ReSize/main/install.sh | bash
```

> 首次运行会自动通过 `apt` 安装 OpenJDK 8、ImageMagick、FFmpeg 等依赖，并自动拉取项目文件。

### 2. 工具使用
环境部署完毕后，执行以下命令启动工具：

```bash
./run.sh
```

根据终端交互提示，选择处理模式并输入相关文件路径：

**模式选择**：
- `[1] 基础版` - 仅画面偏移适配，将游戏画面偏移至屏幕中央
- `[2] 背景图版` - 带背景图处理，支持自定义背景并自动挖空中间区域

**输入示例**：
```bash
请选择处理模式 [1/2]: 2
请输入原始 JAR 文件路径: /home/user/game.jar
请输入背景图片路径: /home/user/bg.jpg
```

处理完成的 JAR 文件，会自动在原目录生成带 `_Resize` 后缀的成品文件。

## 📐 画面布局说明
处理后的画面尺寸为 **240x320**，中间 **176x208** 区域为游戏画面显示区：
- 画面偏移：水平偏移 32px，垂直偏移 56px
- 背景挖空：中间 176x208 区域保持透明，游戏画面叠加显示
- 支持原始分辨率：176x208 / 176x220 / 208x208 / 128x160

## 🖼️ 背景图处理规则
- 自动将图片缩放/裁剪至 240x320
- 中间 176x208 区域自动挖空透明
- 最终图片压缩至小于 15KB

## ⚠️ 相关须知
1. 首次启动会自动下载 OpenJDK 8、ASM 4.0、ImageMagick 相关依赖，请耐心等待
2. 需要 `sudo` 权限安装系统软件包，请确保当前用户在 sudoers 中
3. ASM 4.0 从 Maven Central 直连下载（约 46KB），无需代理
4. `run.sh` 脚本首次执行后请勿移动或删除，避免路径失效
5. 本工具仅限个人学习研究使用，禁止用于侵权破解等违规行为

## 📁 项目结构
```
J2Me_ReSize/
├── install.sh        # 环境安装脚本（自动拉取依赖与项目文件）
├── run.sh            # 运行脚本（内含字节码插桩代码）
├── cldcapi11.jar     # J2ME CLDC 1.1 标准库
└── midpapi20.jar     # J2ME MIDP 2.0 标准库
```

## 🤝 支持与贡献
欢迎提交 Issue 和 Pull Request！  
项目地址：[https://github.com/XXIF/J2Me_ReSize](https://github.com/XXIF/J2Me_ReSize)

## 💰 赞助支持
如果本项目对您有帮助，欢迎打赏支持开发！

| 微信 | 支付宝 |
|:---:|:---:|
| ![微信收款码](wxpay.png) | ![支付宝收款码](alipay.jpg) |

## 🎀 交流群
- QQ 群号：133052781

## 📄 许可证
MIT License
