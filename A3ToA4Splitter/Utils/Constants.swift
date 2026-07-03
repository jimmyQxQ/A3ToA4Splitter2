import UIKit

enum Constants {
    // A3尺寸 (297 x 420 mm)
    static let a3Width: CGFloat = 297.0
    static let a3Height: CGFloat = 420.0
    
    // A4尺寸 (210 x 297 mm)
    static let a4Width: CGFloat = 210.0
    static let a4Height: CGFloat = 297.0
    
    // A3横向尺寸 (420 x 297 mm)
    static let a3LandscapeWidth: CGFloat = 420.0
    static let a3LandscapeHeight: CGFloat = 297.0
    
    // iPhone 14 屏幕尺寸
    static let iPhone14Width: CGFloat = 390.0  // 逻辑像素
    static let iPhone14Height: CGFloat = 844.0 // 逻辑像素
    
    // PDF生成DPI
    static let pdfDPI: CGFloat = 300.0
    
    // 文件管理
    static let documentsDirectoryName = "SplitDocuments"
    static let maxImportFileSize: Int = 50 * 1024 * 1024 // 50MB
    
    // 动画时长
    static let animationDuration: TimeInterval = 0.3
    
    // 裁切线颜色
    static let cropLineColor = UIColor.systemRed
    static let cropLineWidth: CGFloat = 2.0
    
    // 边距
    static let defaultMargin: CGFloat = 16.0
}

enum AppError: LocalizedError {
    case invalidFileFormat
    case fileTooLarge
    case imageProcessingFailed
    case pdfGenerationFailed
    case saveFailed
    case shareFailed
    case invalidCropArea
    case importFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidFileFormat:
            return "不支持的文件格式，请导入JPG、PNG或PDF文件"
        case .fileTooLarge:
            return "文件过大，请导入小于50MB的文件"
        case .imageProcessingFailed:
            return "图片处理失败，请重试"
        case .pdfGenerationFailed:
            return "PDF生成失败"
        case .saveFailed:
            return "保存失败"
        case .shareFailed:
            return "分享失败"
        case .invalidCropArea:
            return "无效的裁切区域"
        case .importFailed(let message):
            return "导入失败: \(message)"
        }
    }
}

extension Notification.Name {
    static let documentDidUpdate = Notification.Name("documentDidUpdate")
}
