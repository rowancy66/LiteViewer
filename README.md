# LiteViewer

LiteViewer 是一个轻量的 macOS 原生看图软件。它的目标很简单：像系统“预览”或 Quick Look 一样干净地打开图片，但可以用左右方向键或触控板左右滑动，直接切换同一个文件夹里的上一张 / 下一张照片。

当前版本优先保证基础看图体验稳定：界面尽量简洁，主窗口使用深色背景和透明标题栏，不做缩略图栏和复杂图库。

## 主要功能

- 支持常见图片格式：`jpg`、`jpeg`、`png`、`gif`、`tiff`、`tif`、`bmp`、`heic`、`heif`、`webp`
- 双击或默认打开一张图片后，自动读取同文件夹里的其他图片
- 按键盘左方向键：上一张
- 按键盘右方向键：下一张
- 触控板左右滑动：上一张 / 下一张
- 触控板双指捏合：放大 / 缩小
- 自动预加载上一张和下一张，减少切换时的卡顿
- 右键菜单支持复制当前图片、把剪贴板图片粘贴到当前文件夹、向左旋转、向右旋转、在访达中显示
- 支持“适合窗口”和“实际大小”
- 显示当前序号、文件名和图片尺寸

## 打包成可安装的 App 和 DMG

请先确认 Mac 已安装 Xcode 或 Xcode Command Line Tools。

在项目目录运行：

```bash
cd /Users/cy/Documents/codex/私人/MacImageViewer
bash scripts/build-app.sh
```

生成结果：

```text
dist/LiteViewer.app
dist/LiteViewer.dmg
```

推荐使用 `dist/LiteViewer.dmg` 安装。

## 如何安装

1. 双击打开 `dist/LiteViewer.dmg`。
2. 把里面的 `LiteViewer.app` 拖到 `Applications` / “应用程序”。
3. 打开“应用程序”文件夹，找到 `LiteViewer.app`。
4. 第一次打开时，如果 macOS 提示“无法验证开发者”，请右键点击 `LiteViewer.app`，选择“打开”，再确认打开。

这样安装后，系统更容易在“打开方式”里识别到 LiteViewer。

## 如何设为默认看图工具

macOS 的默认打开方式是按文件类型分别设置的。比如 `.jpg` 和 `.png` 通常需要各设置一次。

以 `.jpg` 为例：

1. 先确认 `LiteViewer.app` 已经在“应用程序”文件夹里，并且已经打开过一次。
2. 在 Finder 里找一张 `.jpg` 图片。
3. 右键这张图片，选择“显示简介”。
4. 找到“打开方式”。
5. 如果列表里能看到 `LiteViewer` 或 `LiteViewer.app`，直接选择它。
6. 如果列表里看不到，选择“其他...”，然后到“应用程序”里手动选 `LiteViewer.app`。
7. 点击“全部更改...”。

如果你也想让 `.png` 默认用 LiteViewer 打开，请再找一张 `.png` 图片，重复上面的步骤。

## 如何使用

1. 双击一张图片，或者打开 LiteViewer 后点击“打开”。
2. 软件会自动读取这张图片所在文件夹里的其他图片。
3. 按键盘左 / 右方向键切换照片。
4. 也可以在触控板上左右滑动切换照片。
5. 双指捏合可以放大或缩小图片。
6. 在图片上点右键，可以复制图片、粘贴图片、旋转图片，或在访达中定位当前文件。

## 开发调试

如果只想从源码运行：

```bash
cd /Users/cy/Documents/codex/私人/MacImageViewer
swift run LiteViewer
```

注意：`swift run` 只适合开发调试，不适合拿来设置默认打开图片的软件。设置默认打开时，请使用打包出来并放进“应用程序”的 `.app`。

## 自检方法

项目内置了一个轻量自检程序：

```bash
swift run LiteViewerCoreChecks
```

它会检查：

- 图片格式识别是否正确
- 文件夹扫描是否只保留图片
- 图片列表是否按 Finder 风格排序
- 上一张 / 下一张在边界处是否能循环
- 两张图时上一张 / 下一张辅助定位是否稳定
- 从系统打开图片时，启动参数是否能正确识别

## 目录说明

- `Sources/MacImageViewerCore/`：图片格式识别、文件夹扫描、上一张 / 下一张导航等核心逻辑。
- `Sources/MacImageViewer/`：LiteViewer 的 macOS 界面、窗口、按钮、触控板手势和图片绘制。
- `Sources/MacImageViewerCoreChecks/`：最小自检程序。
- `scripts/build-app.sh`：打包 `.app` 和 `.dmg`。
- `packaging/Info.plist`：App 元数据和图片文档类型声明。

## 后续可以优化

- 做开发者签名和公证，减少 macOS 安全提示。
- 继续打磨更接近 Quick Look 的无边框视觉细节。
- 如果基础看图体验稳定，再考虑少量常用文件操作。
