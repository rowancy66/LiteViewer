# MacImageViewer

MacImageViewer 是一个轻量的 macOS 原生看图小软件。第一版目标很简单：打开一张图片后，自动浏览同文件夹里的其他图片，并支持触控板缩放和左右滑动切换。

## 功能

- 支持常见图片格式：`jpg`、`jpeg`、`png`、`gif`、`tiff`、`tif`、`bmp`、`heic`、`heif`、`webp`
- 打开单张图片后，自动读取同文件夹内的图片
- 左侧缩略图栏，点击缩略图即可切换图片
- 双指捏合放大和缩小
- 双指左右滑动切换上一张 / 下一张
- 键盘左右方向键切换图片
- 支持“适合窗口”和“实际大小”
- 右键菜单支持复制图片文件、粘贴图片、复制路径、在 Finder 中显示、移到废纸篓
- 右键菜单支持旋转、翻转、中心裁剪，并另存为新的 PNG 图片
- 显示当前序号、文件名和图片尺寸

## 运行方法

请先确认 Mac 已安装 Xcode 或 Xcode Command Line Tools。

```bash
cd /Users/cy/Documents/codex/私人/MacImageViewer
swift run MacImageViewer
```

如果系统提示 Swift 工具链不匹配，请打开 Xcode，进入 `Settings -> Locations`，选择当前安装的 Xcode 作为 Command Line Tools。

## 打包成可双击的 App 和 DMG

运行：

```bash
cd /Users/cy/Documents/codex/私人/MacImageViewer
bash scripts/build-app.sh
```

生成结果在：

```text
dist/MacImageViewer.app
dist/MacImageViewer.dmg
```

之后你可以双击 `dist/MacImageViewer.app` 启动软件，也可以打开 `dist/MacImageViewer.dmg` 后再运行里面的 App。

如果 macOS 提示“无法验证开发者”，这是因为当前版本没有做开发者签名和公证。你可以在 Finder 里右键点击 App，选择“打开”，再确认打开。

## 设置为默认看图工具

1. 在 Finder 里找一张图片，例如 `.jpg` 或 `.png`。
2. 右键图片，选择“显示简介”。
3. 找到“打开方式”。
4. 选择 `MacImageViewer.app`。
5. 点击“全部更改...”。

这样同类图片以后就会默认用 MacImageViewer 打开。

如果“打开方式”里看不到 MacImageViewer，先双击运行一次 `dist/MacImageViewer.app`，或把它拖到“应用程序”文件夹，再回到上面的步骤。

## 自检方法

项目内置了一个不依赖 XCTest 的核心逻辑自检程序：

```bash
swift run MacImageViewerCoreChecks
```

它会检查：

- 图片格式识别是否正确
- 文件夹扫描是否只保留图片
- 图片列表是否按 Finder 风格排序
- 上一张 / 下一张在边界处是否能循环

## 使用说明

1. 启动软件。
2. 点击“打开”，选择任意一张图片。
3. 软件会自动读取这张图片所在文件夹里的其他图片。
4. 使用触控板双指捏合缩放。
5. 使用触控板左右滑动，或键盘左右方向键切换图片。
6. 点击左侧缩略图可以快速跳转到某张图片。
7. 在主图上右键，可以复制、粘贴、复制路径、在 Finder 显示或移到废纸篓。
8. 在主图上右键，可以选择旋转、翻转、中心裁剪；软件会生成新的 PNG 文件，不会直接破坏原图。

## 目录说明

- `Sources/MacImageViewerCore/`：图片格式识别、文件夹扫描、上一张 / 下一张导航等核心逻辑。
- `Sources/MacImageViewer/`：macOS 界面、窗口、按钮、触控板手势和图片绘制。
- `Sources/MacImageViewerCoreChecks/`：最小自检程序。
- `scripts/build-app.sh`：把项目打包成可双击运行的 `.app`。
- `packaging/Info.plist`：App 元数据和图片文档类型声明。

## 后续可以优化

- 增加幻灯片播放
- 增加 GIF 动图完整播放支持
- 增加可拖拽框选的自由裁剪
- 增加开发者签名和公证，减少 macOS 安全提示

## 维护建议

这个项目第一版故意保持简单：核心逻辑和界面逻辑分开，方便以后继续扩展。后续新增功能时，建议先改 `MacImageViewerCore` 并补充自检，再接到界面上。
