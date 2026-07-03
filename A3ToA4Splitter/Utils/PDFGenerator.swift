import UIKit
import PDFKit

class PDFGenerator {
    
    static let shared = PDFGenerator()
    
    private init() {}
    
    // MARK: - 从图片生成PDF
    func generatePDF(from images: [UIImage], dpi: CGFloat = Constants.pdfDPI) throws -> Data {
        guard !images.isEmpty else {
            throw AppError.pdfGenerationFailed
        }
        
        let pageWidth = Constants.a4Width / 25.4 * dpi  // mm to inches to points
        let pageHeight = Constants.a4Height / 25.4 * dpi
        let pageSize = CGSize(width: pageWidth, height: pageHeight)
        
        let pdfMetadata: [AnyHashable: Any] = [
            kCGPDFContextCreator: "A3ToA4Splitter",
            kCGPDFContextTitle: "Split Document",
            kCGPDFContextAuthor: "A3ToA4Splitter App"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetadata as [String: Any]
        
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize), format: format)
        
        let data = renderer.pdfData { context in
            for (index, image) in images {
                if index > 0 {
                    context.beginPage()
                }
                
                let imageSize = image.size
                let imageRatio = imageSize.width / imageSize.height
                let pageRatio = pageSize.width / pageSize.height
                
                var drawRect: CGRect
                if imageRatio > pageRatio {
                    let newHeight = pageSize.width / imageRatio
                    let yOffset = (pageSize.height - newHeight) / 2
                    drawRect = CGRect(x: 0, y: yOffset, width: pageSize.width, height: newHeight)
                } else {
                    let newWidth = pageSize.height * imageRatio
                    let xOffset = (pageSize.width - newWidth) / 2
                    drawRect = CGRect(x: xOffset, y: 0, width: newWidth, height: pageSize.height)
                }
                
                image.draw(in: drawRect)
            }
        }
        
        return data
    }
    
    // MARK: - 保存PDF到文件
    func savePDF(data: Data, fileName: String) throws -> URL {
        let fileManager = FileManager.default
        let documentsPath = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let appFolder = documentsPath.appendingPathComponent(Constants.documentsDirectoryName, isDirectory: true)
        
        if !fileManager.fileExists(atPath: appFolder.path) {
            try fileManager.createDirectory(at: appFolder, withIntermediateDirectories: true, attributes: nil)
        }
        
        let fileURL = appFolder.appendingPathComponent("\(fileName).pdf")
        try data.write(to: fileURL)
        
        return fileURL
    }
    
    // MARK: - 从PDFDocument生成新的PDF
    func generatePDF(from pdfDocument: PDFDocument, cropConfig: CropConfiguration, orientation: DocumentOrientation) throws -> Data {
        guard let firstPage = pdfDocument.page(at: 0) else {
            throw AppError.pdfGenerationFailed
        }
        
        let pageBounds = firstPage.bounds(for: .mediaBox)
        
        // 创建两个A4页面
        let a4Width = Constants.a4Width / 25.4 * 72.0  // 转换为points (72 dpi)
        let a4Height = Constants.a4Height / 25.4 * 72.0
        let a4Size = CGSize(width: a4Width, height: a4Height)
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextCreator as String: "A3ToA4Splitter",
            kCGPDFContextTitle as String: "Split PDF Document"
        ]
        
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: a4Size), format: format)
        
        let data = renderer.pdfData { context in
            // 第一页
            self.drawPDFPage(page: firstPage, in: context, pageBounds: pageBounds, a4Size: a4Size, isFirstHalf: true, cropConfig: cropConfig, orientation: orientation)
            
            // 第二页
            context.beginPage()
            self.drawPDFPage(page: firstPage, in: context, pageBounds: pageBounds, a4Size: a4Size, isFirstHalf: false, cropConfig: cropConfig, orientation: orientation)
        }
        
        return data
    }
    
    private func drawPDFPage(page: PDFPage, in context: UIGraphicsPDFRendererContext, pageBounds: CGRect, a4Size: CGSize, isFirstHalf: Bool, cropConfig: CropConfiguration, orientation: DocumentOrientation) {
        let cgContext = context.cgContext
        
        cgContext.saveGState()
        
        if orientation == .landscape {
            let cropX = pageBounds.width * cropConfig.cropX
            let scaleX = a4Size.width / cropX
            let scaleY = a4Size.height / pageBounds.height
            let scale = min(scaleX, scaleY)
            
            if isFirstHalf {
                cgContext.translateBy(x: 0, y: a4Size.height)
                cgContext.scaleBy(x: scale, y: -scale)
                page.draw(with: .mediaBox, to: cgContext)
            } else {
                cgContext.translateBy(x: -cropX * scale + a4Size.width * 0.5, y: a4Size.height)
                cgContext.scaleBy(x: scale, y: -scale)
                page.draw(with: .mediaBox, to: cgContext)
            }
        } else {
            let cropY = pageBounds.height * cropConfig.cropX
            let scaleX = a4Size.width / pageBounds.width
            let scaleY = a4Size.height / cropY
            let scale = min(scaleX, scaleY)
            
            if isFirstHalf {
                cgContext.translateBy(x: 0, y: a4Size.height)
                cgContext.scaleBy(x: scale, y: -scale)
                page.draw(with: .mediaBox, to: cgContext)
            } else {
                cgContext.translateBy(x: 0, y: a4Size.height + cropY * scale)
                cgContext.scaleBy(x: scale, y: -scale)
                page.draw(with: .mediaBox, to: cgContext)
            }
        }
        
        cgContext.restoreGState()
    }
    
    // MARK: - 保存到相册
    func saveToPhotoAlbum(data: Data, completion: @escaping (Bool, Error?) -> Void) {
        if let image = UIImage(data: data) {
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
            completion(true, nil)
        } else {
            // PDF文件不能直接保存到相册，需要先转换
            completion(false, AppError.saveFailed)
        }
    }
    
    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("保存到相册失败: \(error.localizedDescription)")
        } else {
            print("成功保存到相册")
        }
    }
}
