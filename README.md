# 六本豆

[![MIT License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![macOS Build](https://github.com/liubendou/liubendou-browser/actions/workflows/build-liubendou.yml/badge.svg)](https://github.com/liubendou/liubendou-browser/actions/workflows/build-liubendou.yml)

六本豆是一款基于 macOS 原生 WebKit 的多环境隔离浏览器，使用 Swift、SwiftUI 和 AppKit 构建。
本项目基于 [Safarier v1.5.0](https://github.com/Cd1s/safarier/tree/v1.5.0) 进行品牌界面定制，
浏览器源码及本项目的修改以 [MIT 许可证](LICENSE) 开源。

## 功能

- 多环境管理：为不同环境分别保存 Cookie、登录状态、缓存及浏览数据。
- 独立代理：支持代理、订阅节点和前置连接，集成 sing-box 与 Mieru 辅助程序。
- 环境设置：配置语言、时区和设备预设，使用系统 WebKit 提供的隐私能力。
- 自动化接入：通过本地 CLI 操作环境、读取页面快照、填写表单和截图。
- 六本豆品牌界面：统一应用名称、菜单、关于页、中英文品牌文案和绿色「六」字图标。

目前提供 Apple 芯片版（arm64）构建，要求 **macOS 14 或更高版本**。

## 下载与安装

进入 [GitHub Actions 构建页面](https://github.com/liubendou/liubendou-browser/actions/workflows/build-liubendou.yml)，
选择一次成功的构建，在 Artifacts 中下载 `Liubendou-v1.5.0-macOS-arm64`。
下载 Actions 附件需要登录 GitHub，附件保留 30 天；过期后可重新运行构建或从源码编译。

附件包含应用压缩包和对应的 `.sha256` 校验文件。解压应用压缩包，将 `六本豆.app` 拖入 Mac 的「应用程序」目录。
当前构建使用 ad-hoc 签名，未进行 Apple 公证。

## 从源码构建

需要 Mac、Xcode 和 Python 3；GitHub 构建流程使用 Xcode 26.2。

```sh
git clone https://github.com/liubendou/liubendou-browser.git
cd liubendou-browser
python3 scripts/prepare-helpers.py
bash scripts/build-app.sh
```

默认生成 `dist/六本豆.app`（arm64）。辅助程序从固定版本的上游发布包提取，下载时校验 SHA-256。

运行测试：

```sh
swift test
```

## GitHub 自动打包

构建相关文件推送到 `main` 分支时会自动运行 **Build 六本豆 macOS**。
维护者也可进入 Actions，选择同名工作流并点击 Run workflow。
流程包含相关测试、源码编译、应用签名、品牌检查，以及压缩包解压后的签名验证。

应用的更新地址指向本仓库。当前安装包通过 Actions 提供；应用内自动更新需要本仓库另行发布对应的 GitHub Release 附件。

## 参与贡献

欢迎通过 [Issues](https://github.com/liubendou/liubendou-browser/issues) 反馈问题，或提交 Pull Request。
开发约定见 [贡献指南](CONTRIBUTING.zh-CN.md)，详细构建说明见 [六本豆-构建说明.md](六本豆-构建说明.md)。

源码保留 Safarier 内部 Swift 模块和自动化接口名称，以维持现有实现的兼容性。
原项目说明保留在 [README.upstream.md](README.upstream.md)。

## 许可证与来源

浏览器源码及本项目修改采用 [MIT License](LICENSE)。来源与第三方信息见 [NOTICE.md](NOTICE.md)。

sing-box 和 Mieru 辅助程序分别遵循各自的 GPL-3.0-or-later 许可证，Yams 遵循其 MIT 许可证；
这些组件的许可证不会被本仓库的 MIT 许可证替代。构建后的应用保留组件许可证及源码位置说明。
