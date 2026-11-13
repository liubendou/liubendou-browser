# 六本豆 macOS 版

基于 Safarier v1.5.0 的品牌定制版本，支持 Apple 芯片 Mac，要求 macOS 14 或更高版本。

## GitHub 打包

代码推送到 `main` 分支后会自动运行 **Build 六本豆 macOS**。
也可以进入 GitHub 仓库的 Actions，选择同名工作流并点 Run workflow。
构建完成后下载 `Liubendou-v1.5.0-macOS-arm64` 附件，解压得到：

- `六本豆-v1.5.0-macOS-arm64.zip`
- 对应的 `.sha256` 校验文件

应用压缩包内是 `六本豆.app`，拖到 Mac 的「应用程序」目录即可安装。
与原版相同，构建使用 ad-hoc 签名，未进行 Apple 公证。

## 修改内容

应用名、窗口标题、应用菜单、关于页、扩展提示、权限说明、中英文翻译及自动化接入指南
统一为「六本豆」。图标采用绿色底色与「六」字品牌标记，管理器增加品牌栏。
更新地址为 `liubendou/liubendou-browser`；私有仓库的 Releases 页面需要登录 GitHub 查看，
应用内匿名自动检查无法访问私有发布，因此不会从上游自动安装原品牌。

源码内部的 Safarier 模块名、代理协议名及 Safari/WebKit 技术名称不影响用户界面品牌。
上游来源和第三方许可证保留在 `NOTICE.md` 及应用内 `Contents/Resources/ThirdParty` 中。

## 本地 Mac 构建

```sh
python3 scripts/prepare-helpers.py
bash scripts/build-app.sh
```

默认生成 `dist/六本豆.app`（arm64）。
