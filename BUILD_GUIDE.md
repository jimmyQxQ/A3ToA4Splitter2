# A3ToA4Splitter 构建指南

## 环境要求

- macOS 12.0 或更高版本
- Xcode 13.4 或更高版本
- Swift 5.5+
- iOS 15.0+ SDK

## 快速开始

### 方法一: 使用构建脚本 (推荐)

```bash
cd A3ToA4Splitter
chmod +x build.sh
./build.sh
```

脚本会自动:
1. 检查环境
2. 编译 Release 版本
3. 生成 IPA 文件

### 方法二: 手动构建

#### 1. 打开项目

```bash
open A3ToA4Splitter.xcodeproj
```

#### 2. Xcode 设置

- 选择目标设备为 `Any iOS Device (arm64)`
- 确保 Signing & Capabilities 中:
  - Team 设置为 None 或你的开发团队
  - Bundle Identifier 自定义为你的标识

#### 3. 编译归档

```bash
xcodebuild -project A3ToA4Splitter.xcodeproj \
    -scheme A3ToA4Splitter \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    archive -archivePath build/A3ToA4Splitter.xcarchive
```

#### 4. 导出 IPA

```bash
xcodebuild -exportArchive \
    -archivePath build/A3ToA4Splitter.xcarchive \
    -exportPath build/Export \
    -exportOptionsPlist exportOptions.plist
```

### 方法三: Xcode GUI 构建

1. 打开 `A3ToA4Splitter.xcodeproj`
2. 选择 Product -> Archive
3. 等待归档完成
4. 在 Organizer 中选择归档，点击 Distribute App
5. 选择 Ad Hoc / Development
6. 导出 IPA 文件

## 巨魔环境安装

### 准备条件

- iPhone 14 已安装 TrollStore
- 设备已越狱或使用巨魔环境

### 安装步骤

1. **传输 IPA 到设备**
   - 使用 AirDrop、iTunes 文件共享或 SCP
   - 将 IPA 保存到设备任意位置

2. **使用 TrollStore 安装**
   - 打开 TrollStore 应用
   - 点击右上角 "+" 或选择 IPA 文件
   - 选择要安装的 A3ToA4Splitter.ipa
   - 等待安装完成

3. **验证安装**
   - 主屏幕出现 "A3转A4" 图标
   - 点击打开应用

## 测试运行

### 在模拟器上测试

```bash
xcodebuild test -project A3ToA4Splitter.xcodeproj \
    -scheme A3ToA4Splitter \
    -destination 'platform=iOS Simulator,name=iPhone 14'
```

### 单元测试

项目包含以下测试用例:

| 测试类 | 测试内容 |
|--------|----------|
| A3ToA4SplitterTests | 文档类型检测、方向识别、图片分割、PDF生成 |
| LocalFileManagerTests | 文档增删改查操作 |

## 常见问题

### 签名问题

如果遇到签名错误，修改 Build Settings:

```
CODE_SIGN_STYLE = Manual
CODE_SIGN_IDENTITY = "-"
```

或使用自动签名:

```
CODE_SIGN_STYLE = Automatic
DEVELOPMENT_TEAM = 你的Team ID
```

### 巨魔环境无需签名

对于巨魔环境安装:
- 不需要有效的开发者证书
- 不需要 Apple ID 签名
- 直接安装未签名的 IPA 即可

### 编译错误

**问题**: `No such module 'PDFKit'`
**解决**: 确保目标平台是 iOS，macOS 不支持 PDFKit

**问题**: `PHPickerViewController` 不可用
**解决**: 将部署目标设置为 iOS 15.0+

## 项目配置

### 修改 Bundle ID

编辑 `A3ToA4Splitter.xcodeproj/project.pbxproj`:

```
PRODUCT_BUNDLE_IDENTIFIER = com.yourcompany.A3ToA4Splitter;
```

### 修改应用名称

编辑 `Info.plist`:

```xml
<key>CFBundleDisplayName</key>
<string>你的应用名称</string>
```

### 修改版本号

编辑 `Info.plist`:

```xml
<key>CFBundleShortVersionString</key>
<string>1.0.0</string>
<key>CFBundleVersion</key>
<string>1</string>
```

## 性能优化建议

1. **图片处理**
   - 大文件处理时已使用后台线程
   - 如需更快处理，可降低预览分辨率

2. **内存管理**
   - 处理超大图片时建议分块处理
   - 及时释放不用的图片缓存

3. **PDF 生成**
   - 默认使用 300 DPI，可在 Constants.swift 中调整
   - 更高 DPI 会增加文件大小和处理时间

## 调试技巧

### 启用详细日志

在 `DocumentProcessor.swift` 中:

```swift
print("处理时间: \(timeElapsed)秒")
```

### 检查文件存储

```swift
let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
print("文档路径: \(documentsPath)")
```

## 贡献与反馈

如有问题或建议，欢迎反馈。

---

**注意**: 本项目仅供学习和个人使用。请遵守当地法律法规。
