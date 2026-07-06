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
        
        // 规范化图片，消除 EXIF 方向影响，确保 image.size 与 cgImage 尺寸一致
        let normalizedImage = image.normalized()
        let orientation = detectOrientation(image: normalizedImage)
        return (normalizedImage, orientation)
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
        
        print("[DocumentProcessor] 分割完成，生成图片数量: \(splitImages.count)")
        for (i, img) in splitImages.enumerated() {
            print("[DocumentProcessor] 分割图片 [\(i)]: \(img.size.width) x \(img.size.height)")
        }
        
        guard splitImages.count == 2 else {
            throw AppError.imageProcessingFailed
        }
        
        return splitImages
    }
    
    // MARK: - PDF分割（单页）
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
    
    // MARK: - PDF分割（多页）——遍历每一页，每页A3分割为2页A4
    func splitAllPages(pdfDocument: PDFDocument, orientation: DocumentOrientation, cropConfig: CropConfiguration = .default) throws -> [UIImage] {
        let pageCount = pdfDocument.pageCount
        print("[DocumentProcessor] 开始分割多页PDF，总页数: \(pageCount)")
        guard pageCount > 0 else {
            throw AppError.pdfGenerationFailed
        }
        
        var allSplitImages: [UIImage] = []
        let scale: CGFloat = 2.0
        
        for pageIndex in 0..<pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else {
                print("[DocumentProcessor] 警告: 第 \(pageIndex + 1) 页无法读取，跳过")
                continue
            }
            
            let pageBounds = page.bounds(for: .mediaBox)
            // 检测每页的方向
            let pageRatio = pageBounds.width / pageBounds.height
            let pageOrientation: DocumentOrientation = pageRatio < 1.0 ? .portrait : .landscape
            
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: pageBounds.width * scale, height: pageBounds.height * scale))
            let pageImage = renderer.image { context in
                UIColor.white.set()
                context.fill(context.format.bounds)
                context.cgContext.saveGState()
                context.cgContext.translateBy(x: 0, y: pageBounds.height * scale)
                context.cgContext.scaleBy(x: scale, y: -scale)
                page.draw(with: .mediaBox, to: context.cgContext)
                context.cgContext.restoreGState()
            }
            
            let splitParts = try splitA3ToA4(image: pageImage, orientation: pageOrientation, cropConfig: cropConfig)
            print("[DocumentProcessor] 第 \(pageIndex + 1) 页分割完成，产出 \(splitParts.count) 张A4图片")
            allSplitImages.append(contentsOf: splitParts)
        }
        
        print("[DocumentProcessor] 多页PDF分割完成，总产出: \(allSplitImages.count) 张A4图片")
        return allSplitImages
    }
    
    // MARK: - 图片裁切
    private func cropImage(_ cgImage: CGImage, rect: CGRect) -> UIImage? {
        // 确保裁切区域在图片范围内，坐标取整防止越界
        let imgWidth = CGFloat(cgImage.width)
        let imgHeight = CGFloat(cgImage.height)
        
        let x = max(0, min(floor(rect.origin.x), imgWidth - 1))
        let y = max(0, min(floor(rect.origin.y), imgHeight - 1))
        let w = max(1, min(ceil(rect.size.width), imgWidth - x))
        let h = max(1, min(ceil(rect.size.height), imgHeight - y))
        
        let safeRect = CGRect(x: x, y: y, width: w, height: h)
        
        guard let croppedCGImage = cgImage.cropping(to: safeRect) else {
            print("裁切失败: rect=\(safeRect), imageSize=\(imgWidth)x\(imgHeight)")
            return nil
        }
        return UIImage(cgImage: croppedCGImage)
    }
    
    // MARK: - 缩放到A4比例
    private func scaleToA4(image: UIImage, targetOrientation: DocumentOrientation) -> UIImage {
        let targetRatio: CGFloat = targetOrientation == .portrait ?
            (Constants.a4Width / Constants.a4Height) :
            (Constants.a4Height / Constants.a4Width)
        
        var workingImage = image
        let currentRatio = image.size.width / image.size.height
        let isCurrentLandscape = currentRatio > 1.0
        let isTargetLandscape = targetOrientation == .landscape
        
        // 如果当前方向与目标方向不一致，先旋转90度
        if isCurrentLandscape != isTargetLandscape {
            workingImage = rotateImage(workingImage, by: 90) ?? workingImage
        }
        
        let currentSize = workingImage.size
        let adjustedRatio = currentSize.width / currentSize.height
        
        if abs(adjustedRatio - targetRatio) < 0.01 {
            return workingImage
        }
        
        // 调整尺寸以匹配A4比例
        var targetSize: CGSize
        if adjustedRatio > targetRatio {
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
            if adjustedRatio > targetRatio {
                let drawHeight = currentSize.width / targetRatio
                let yOffset = (drawHeight - currentSize.height) / 2
                drawRect = CGRect(x: 0, y: yOffset, width: currentSize.width, height: currentSize.height)
            } else {
                let drawWidth = currentSize.height * targetRatio
                let xOffset = (drawWidth - currentSize.width) / 2
                drawRect = CGRect(x: xOffset, y: 0, width: currentSize.width, height: currentSize.height)
            }
            
            workingImage.draw(in: drawRect)
        }
        
        return scaledImage
    }
    
    // MARK: - 旋转图片
    private func rotateImage(_ image: UIImage, by degrees: CGFloat) -> UIImage? {
        let radians = degrees * .pi / 180
        let rotatedSize = CGRect(origin: .zero, size: image.size)
            .applying(CGAffineTransform(rotationAngle: radians))
            .integral.size
        
        UIGraphicsBeginImageContextWithOptions(rotatedSize, false, image.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        context.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
        context.rotate(by: radians)
        image.draw(in: CGRect(x: -image.size.width / 2, y: -image.size.height / 2,
                               width: image.size.width, height: image.size.height))
        
        let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return rotatedImage
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

// MARK: - UIImage Extension
extension UIImage {
    /// 规范化图片，消除 EXIF 方向影响
    /// 确保 image.size 与 cgImage 尺寸方向一致
    func normalized() -> UIImage {
        if imageOrientation == .up { return self }
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? self
        UIGraphicsEndImageContext()
        return normalizedImage
    }
}
