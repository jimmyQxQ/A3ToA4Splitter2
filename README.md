# A3 转 A4 分割器

一款适用于 iPhone 14 的 iOS 应用程序，用于将 A3 尺寸文档自动分割为两份 A4 尺寸文档。

## 功能特性

### 文档处理
- 支持导入 JPG、PNG 格式的图片文件
- 支持导入 PDF 文档
- 自动识别 A3 文档方向（横向/纵向）
- 智能裁切算法，精确分割为两份 A4 尺寸页面
- 保持原始比例，无拉伸变形

### 实时预览
- 原始文档与分割效果对比视图
- 动态裁切线显示
- 手势微调裁切区域
- 滑块精确控制裁切位置
- 实时更新预览效果

### 文件管理
- 本地保存生成的 PDF 文件
- 支持保存至系统相册
- 文件列表查看
- 文件重命名
- 文件删除
- 批量清空

### 分享功能
- 系统集成分享面板
- 支持分享到微信（通过系统分享）
- 支持邮件、AirDrop 等方式

## 系统要求

- iOS 15.0 及以上版本
- iPhone 14 (针对 6.1 英寸屏幕优化)
- 无需签名验证（支持巨魔环境安装）

## 技术栈

- Swift 5.5+
- UIKit 框架
- Core Graphics (图片处理)
- PDFKit (PDF 处理)
- Auto Layout (自适应布局)

## 项目结构

```
A3ToA4Splitter/
├── A3ToA4Splitter/
│   ├── AppDelegate.swift
│   ├── SceneDelegate.swift
│   ├── Info.plist
│   ├── Models/
│   │   ├── Document.swift
│   ├── Views/
│   │   ├── MainViewController.swift
│   │   ├── PreviewViewController.swift
│   │   ├── FileManagerViewController.swift
│   │   ├── CropOverlayView.swift
│   │   └── DocumentCell.swift
│   ├── Utils/
│   │   ├── Constants.swift
│   │   ├── DocumentProcessor.swift
│   │   ├── PDFGenerator.swift
│   │   └── LocalFileManager.swift
│   └── Resources/
│       └── LaunchScreen.storyboard
└── A3ToA4SplitterTests/
    └── A3ToA4SplitterTests.swift
```

## 安装说明

### 通过巨魔环境安装

1. 在 Mac 上使用 Xcode 打开项目
2. 选择正确的签名配置（无需有效开发者账号）
3. 编译生成 IPA 文件
4. 通过巨魔工具（TrollStore）安装到 iPhone 14

### 编译步骤

```bash
# 1. 使用 Xcode 打开项目
open A3ToA4Splitter.xcodeproj

# 2. 选择目标设备为 Generic iOS Device
# 3. Product -> Archive 进行归档
# 4. 导出为 IPA 文件
```

## 使用指南

### 基本流程

1. **导入文档**
   - 点击首页"导入文档"按钮
   - 选择从相册或文件浏览器导入
   - 支持 JPG、PNG、PDF 格式

2. **调整裁切**
   - 在预览界面查看原始文档
   - 拖动裁切线或调整滑块位置
   - 实时查看分割后的 A4 预览效果

3. **保存与分享**
   - 点击"保存PDF"按钮保存到本地
   - 点击分享按钮通过系统分享面板发送

### 裁切技巧

- 默认裁切位置为文档中线（50%）
- 可通过手势直接拖动裁切线
- 使用底部滑块进行精确微调
- 点击"重置"恢复默认位置

## 性能优化

- 图片处理采用异步线程，避免阻塞主线程
- 使用 Core Graphics 进行高效的图片裁切
- PDF 生成使用 UIGraphicsPDFRenderer
- 预览界面保持 60fps 流畅度

## 错误处理

应用内置完善的错误处理机制：

- 文件格式不支持提示
- 文件过大警告（>50MB）
- 图片处理失败重试
- 存储空间不足提醒
- 权限请求说明

## 隐私权限

应用需要以下权限：

- **相册访问**: 用于导入图片和保存处理后的文件
- **文件访问**: 用于导入本地 PDF 文档

## 开发说明

### 核心算法

A3 到 A4 的分割逻辑：

```
横向 A3 (420 x 297 mm):
  - 从中间纵向裁切
  - 左半部分 -> A4-1 (210 x 297 mm)
  - 右半部分 -> A4-2 (210 x 297 mm)

纵向 A3 (297 x 420 mm):
  - 从中间横向裁切
  - 上半部分 -> A4-1 (210 x 297 mm)
  - 下半部分 -> A4-2 (210 x 297 mm)
```

### 自定义裁切

可通过 `CropConfiguration` 调整裁切位置：

```swift
var config = CropConfiguration.default
config.cropX = 0.4  // 40% 位置裁切
config.isManual = true
```

## 测试

运行单元测试：

```bash
cd A3ToA4Splitter
xcodebuild test -scheme A3ToA4Splitter -destination 'platform=iOS Simulator,name=iPhone 14'
```

测试覆盖：
- 文档类型检测
- 方向识别
- 图片分割算法
- PDF 生成
- 文件管理操作

## 常见问题

**Q: 为什么需要 iOS 15.0 以上版本？**
A: 应用使用了 PHPickerViewController 和 UTType 等新 API。

**Q: 支持哪些文件格式？**
A: 支持 JPG、JPEG、PNG、HEIC、TIFF、BMP 图片格式和 PDF 文档。

**Q: 分割后的文件保存在哪里？**
A: 保存在应用沙盒的 Documents/SplitDocuments 目录中。

**Q: 如何分享到微信？**
A: 使用系统分享面板，选择微信即可分享生成的 PDF 文件。

## 版本历史

### v1.0.0
- 初始版本
- A3 到 A4 分割功能
- 实时预览与裁切
- 文件管理与分享

## 许可证

本项目仅供学习和个人使用。

## 联系方式

如有问题或建议，欢迎反馈。
