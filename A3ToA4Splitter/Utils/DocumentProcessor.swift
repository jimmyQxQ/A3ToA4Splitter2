import UIKit
import PDFKit
import CoreGraphics

class DocumentProcessor {
    
    static let shared = DocumentProcessor()
    
    private init() {}
    
    // MARK: - 文档类型检测
    func detectDocumentType(from url: URL) -> DocumentType? {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "jpg", "jpeg", "png", "heic", "tiff", "bmp":
            return .image
        case "pdf":
            return .pdf
        default:
            return nil
        }
    }
    
    // MARK: - 图片导入与处理
    func importImage(from url: URL) throws -> (UIImage, DocumentOrientation) {
        guard let image = UIImage(contentsOfFile: url.path) else {
            throw AppError.importFailed("无法读取图片文件")
        }
        
        let orientation = detectOrientation(image: image)
        return (image, orientation)
    }
    
    func detectOrientation(image: UIImage) -> DocumentOrientation {
        let size = image.size
        let ratio = size.width / size.height
        
        // A3 纵向比例约为 0.707 (297/420)
        // A3 横向比例约为 1.414 (420/297)
        // 允许一定误差范围
        if ratio < 1.0 {
            return .portrait
        } else {
            return .landscape
        }
    }
    
    // MARK: - PDF导入
    func importPDF(from url: URL) throws -> (PDFDocument, DocumentOrientation) {
        guard let pdfDocument = PDFDocument(url: url) else {
            throw AppError.importFailed("无法读取PDF文件")
        }
        
        guard let firstPage = pdfDocument.page(at: 0) else {
            throw AppError.importFailed("PDF文件没有页面")
        }
        
        let bounds = firstPage.bounds(for: .mediaBox)
        let ratio = bounds.width / bounds.height
        
        let orientation: DocumentOrientation = ratio < 1.0 ? .portrait : .landscape
        return (pdfDocument, orientation)
    }
    
    // MARK: - 核心分割算法
    func splitA3ToA4(image: UIImage, orientation: DocumentOrientation, cropConfig: CropConfiguration = .default) throws -> [UIImage] {
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            print("图片分割处理时间: \(String(format: "%.3f", timeElapsed))秒")
        }
        
        guard let cgImage = image.cgImage else {
            throw AppError.imageProcessingFailed
        }
        
        let originalWidth = CGFloat(cgImage.width)
        let originalHeight = CGFloat(cgImage.height)
        
        var splitImages: [UIImage] = []
        
        if orientation == .landscape {
            // 横向A3: 从中间裁切为两份纵向A4
            let cropX = originalWidth * cropConfig.cropX
            let leftWidth = cropX
            let rightWidth = originalWidth - cropX
            
            // 左半部分 (第一份A4)
            if let leftImage = cropImage(cgImage, rect: CGRect(x: 0, y: 0, width: leftWidth, height: originalHeight)) {
                // 调整为A4比例
                let scaledLeft = scaleToA4(image: leftImage, targetOrientation: .portrait)
                splitImages.append(scaledLeft)
            }
            
            // 右半部分 (第二份A4)
            if let rightImage = cropImage(cgImage, rect: CGRect(x: cropX, y: 0, width: rightWidth, height: originalHeight)) {
                let scaledRight = scaleToA4(image: rightImage, targetOrientation: .portrait)
                splitImages.append(scaledRight)
            }
        } else {
            // 纵向A3: 从中间横向裁切为两份纵向A4
            let cropY = originalHeight * cropConfig.cropX
            let topHeight = cropY
            let bottomHeight = originalHeight - cropY
            
            // 上半部分
            if let topImage = cropImage(cgImage, rect: CGRect(x: 0, y: 0, width: originalWidth, height: topHeight)) {
                let scaledTop = scaleToA4(image: topImage, targetOrientation: .portrait)
                splitImages.append(scaledTop)
            }
            
            // 下半部分
            if let bottomImage = cropImage(cgImage, rect: CGRect(x: 0, y: cropY, width: originalWidth, height: bottomHeight)) {
                let scaledBottom = scaleToA4(image: bottomImage, targetOrientation: .portrait)
                splitImages.append(scaledBottom)
            }
        }
        
        guard splitImages.count == 2 else {
            throw AppError.imageProcessingFailed
        }
        
        return splitImages
    }
    
    // MARK: - PDF分割
    func splitA3ToA4(pdfDocument: PDFDocument, orientation: DocumentOrientation, cropConfig: CropConfiguration = .default) throws -> [UIImage] {
        guard let firstPage = pdfDocument.page(at: 0) else {
            throw AppError.pdfGenerationFailed
        }
        
        let pageBounds = firstPage.bounds(for: .mediaBox)
        let scale: CGFloat = 2.0 // 渲染分辨率倍数
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: pageBounds.width * scale, height: pageBounds.height * scale))
        let pageImage = renderer.image { context in
            UIColor.white.set()
            context.fill(context.format.bounds)
            context.cgContext.saveGState()
            context.cgContext.translateBy(x: 0, y: pageBounds.height * scale)
            context.cgContext.scaleBy(x: scale, y: -scale)
            firstPage.draw(with: .mediaBox, to: context.cgContext)
            context.cgContext.restoreGState()
        }
        
        return try splitA3ToA4(image: pageImage, orientation: orientation, cropConfig: cropConfig)
    }
    
    // MARK: - 图片裁切
    private func cropImage(_ cgImage: CGImage, rect: CGRect) -> UIImage? {
        guard let croppedCGImage = cgImage.cropping(to: rect) else {
            return nil
        }
        return UIImage(cgImage: croppedCGImage)
    }
    
    // MARK: - 缩放到A4比例
    private func scaleToA4(image: UIImage, targetOrientation: DocumentOrientation) -> UIImage {
        let targetRatio: CGFloat = targetOrientation == .portrait ? 
            (Constants.a4Width / Constants.a4Height) : 
            (Constants.a4Height / Constants.a4Width)
        
        let currentSize = image.size
        let currentRatio = currentSize.width / currentSize.height
        
        var targetSize: CGSize
        
        if abs(currentRatio - targetRatio) < 0.01 {
            // 比例已经接近，直接返回
            return image
        }
        
        // 调整尺寸以匹配A4比例
        if currentRatio > targetRatio {
            let newHeight = currentSize.width / targetRatio
            targetSize = CGSize(width: currentSize.width, height: newHeight)
        } else {
            let newWidth = currentSize.height * targetRatio
            targetSize = CGSize(width: newWidth, height: currentSize.height)
        }
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = true
        
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        let scaledImage = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: targetSize))
            
            let drawRect: CGRect
            if currentRatio > targetRatio {
                let drawHeight = currentSize.width / targetRatio
                let yOffset = (drawHeight - currentSize.height) / 2
                drawRect = CGRect(x: 0, y: yOffset, width: currentSize.width, height: currentSize.height)
            } else {
                let drawWidth = currentSize.height * targetRatio
                let xOffset = (drawWidth - currentSize.width) / 2
                drawRect = CGRect(x: xOffset, y: 0, width: currentSize.width, height: currentSize.height)
            }
            
            image.draw(in: drawRect)
        }
        
        return scaledImage
    }
    
    // MARK: - 生成缩略图
    func generateThumbnail(from image: UIImage, maxSize: CGSize = CGSize(width: 200, height: 200)) -> UIImage? {
        let size = image.size
        let ratio = min(maxSize.width / size.width, maxSize.height / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    // MARK: - 生成预览图
    func generatePreviewImage(original: UIImage, cropConfig: CropConfiguration, orientation: DocumentOrientation) -> UIImage? {
        let size = original.size
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let previewImage = renderer.image { context in
            // 绘制原始图片（半透明）
            context.cgContext.saveGState()
            context.cgContext.setAlpha(0.5)
            original.draw(in: CGRect(origin: .zero, size: size))
            context.cgContext.restoreGState()
            
            // 绘制裁切线
            let linePath = UIBezierPath()
            if orientation == .landscape {
                let cropX = size.width * cropConfig.cropX
                linePath.move(to: CGPoint(x: cropX, y: 0))
                linePath.addLine(to: CGPoint(x: cropX, y: size.height))
            } else {
                let cropY = size.height * cropConfig.cropX
                linePath.move(to: CGPoint(x: 0, y: cropY))
                linePath.addLine(to: CGPoint(x: size.width, y: cropY))
            }
            
            Constants.cropLineColor.setStroke()
            linePath.lineWidth = Constants.cropLineWidth * 2
            linePath.stroke()
            
            // 绘制裁切区域标记
            let dashPattern: [CGFloat] = [10, 5]
            linePath.lineWidth = Constants.cropLineWidth
            linePath.setLineDash(dashPattern, count: 2, phase: 0)
            UIColor.white.setStroke()
            linePath.stroke()
        }
        
        return previewImage
    }
}
