import XCTest
@testable import A3ToA4Splitter

class A3ToA4SplitterTests: XCTestCase {
    
    var documentProcessor: DocumentProcessor!
    var pdfGenerator: PDFGenerator!
    
    override func setUpWithError() throws {
        super.setUp()
        documentProcessor = DocumentProcessor.shared
        pdfGenerator = PDFGenerator.shared
    }
    
    override func tearDownWithError() throws {
        documentProcessor = nil
        pdfGenerator = nil
        super.tearDown()
    }
    
    // MARK: - 文档类型检测测试
    func testDetectDocumentType() {
        let imageURL = URL(fileURLWithPath: "/tmp/test.jpg")
        let pngURL = URL(fileURLWithPath: "/tmp/test.png")
        let pdfURL = URL(fileURLWithPath: "/tmp/test.pdf")
        let invalidURL = URL(fileURLWithPath: "/tmp/test.txt")
        
        XCTAssertEqual(documentProcessor.detectDocumentType(from: imageURL), .image)
        XCTAssertEqual(documentProcessor.detectDocumentType(from: pngURL), .image)
        XCTAssertEqual(documentProcessor.detectDocumentType(from: pdfURL), .pdf)
        XCTAssertNil(documentProcessor.detectDocumentType(from: invalidURL))
    }
    
    // MARK: - 方向检测测试
    func testDetectOrientation() {
        // 创建横向图片 (宽 > 高)
        let landscapeSize = CGSize(width: 420, height: 297)
        UIGraphicsBeginImageContext(landscapeSize)
        let landscapeImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        let landscapeOrientation = documentProcessor.detectOrientation(image: landscapeImage)
        XCTAssertEqual(landscapeOrientation, .landscape)
        
        // 创建纵向图片 (高 > 宽)
        let portraitSize = CGSize(width: 297, height: 420)
        UIGraphicsBeginImageContext(portraitSize)
        let portraitImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        let portraitOrientation = documentProcessor.detectOrientation(image: portraitImage)
        XCTAssertEqual(portraitOrientation, .portrait)
    }
    
    // MARK: - A3到A4分割测试
    func testSplitA3ToA4Landscape() throws {
        // 创建模拟的横向A3图片 (420 x 297)
        let a3Size = CGSize(width: 420 * 2, height: 297 * 2)
        UIGraphicsBeginImageContext(a3Size)
        
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(origin: .zero, size: a3Size))
        
        // 左半部分画红色，右半部分画蓝色
        context.setFillColor(UIColor.red.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: a3Size.width / 2, height: a3Size.height))
        
        context.setFillColor(UIColor.blue.cgColor)
        context.fill(CGRect(x: a3Size.width / 2, y: 0, width: a3Size.width / 2, height: a3Size.height))
        
        let testImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        // 执行分割
        let splitImages = try documentProcessor.splitA3ToA4(image: testImage, orientation: .landscape)
        
        // 验证结果
        XCTAssertEqual(splitImages.count, 2, "应该分割为2张图片")
        
        // 验证每张图片的尺寸接近A4比例 (210:297)
        for image in splitImages {
            let ratio = image.size.width / image.size.height
            let a4Ratio: CGFloat = 210.0 / 297.0
            XCTAssertLessThan(abs(ratio - a4Ratio), 0.1, "分割后的图片比例应接近A4比例")
        }
    }
    
    func testSplitA3ToA4Portrait() throws {
        // 创建模拟的纵向A3图片 (297 x 420)
        let a3Size = CGSize(width: 297 * 2, height: 420 * 2)
        UIGraphicsBeginImageContext(a3Size)
        
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(origin: .zero, size: a3Size))
        
        // 上半部分画绿色，下半部分画黄色
        context.setFillColor(UIColor.green.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: a3Size.width, height: a3Size.height / 2))
        
        context.setFillColor(UIColor.yellow.cgColor)
        context.fill(CGRect(x: 0, y: a3Size.height / 2, width: a3Size.width, height: a3Size.height / 2))
        
        let testImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        // 执行分割
        let splitImages = try documentProcessor.splitA3ToA4(image: testImage, orientation: .portrait)
        
        // 验证结果
        XCTAssertEqual(splitImages.count, 2, "应该分割为2张图片")
        
        // 验证每张图片的尺寸接近A4比例
        for image in splitImages {
            let ratio = image.size.width / image.size.height
            let a4Ratio: CGFloat = 210.0 / 297.0
            XCTAssertLessThan(abs(ratio - a4Ratio), 0.1, "分割后的图片比例应接近A4比例")
        }
    }
    
    // MARK: - 裁切配置测试
    func testCropConfiguration() {
        var config = CropConfiguration.default
        XCTAssertEqual(config.cropX, 0.5)
        XCTAssertFalse(config.isManual)
        
        config.cropX = 0.3
        config.isManual = true
        XCTAssertEqual(config.leftRatio, 0.3)
        XCTAssertEqual(config.rightRatio, 0.7)
    }
    
    // MARK: - PDF生成测试
    func testPDFGeneration() throws {
        // 创建测试图片
        let size = CGSize(width: 200, height: 300)
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        let testImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        // 生成PDF
        let pdfData = try pdfGenerator.generatePDF(from: [testImage, testImage])
        
        // 验证PDF数据
        XCTAssertGreaterThan(pdfData.count, 0, "PDF数据不应为空")
        
        // 验证PDF格式 (PDF文件以%PDF开头)
        let header = String(data: pdfData.prefix(4), encoding: .ascii)
        XCTAssertEqual(header, "%PDF", "生成的数据应为有效PDF格式")
    }
    
    // MARK: - 缩略图生成测试
    func testThumbnailGeneration() {
        let size = CGSize(width: 1000, height: 2000)
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        let testImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        let thumbnail = documentProcessor.generateThumbnail(from: testImage, maxSize: CGSize(width: 200, height: 200))
        
        XCTAssertNotNil(thumbnail, "缩略图不应为空")
        XCTAssertLessThanOrEqual(thumbnail!.size.width, 200, "缩略图宽度应不超过最大值")
        XCTAssertLessThanOrEqual(thumbnail!.size.height, 200, "缩略图高度应不超过最大值")
    }
    
    // MARK: - 性能测试
    func testSplitPerformance() throws {
        // 创建大图测试性能
        let largeSize = CGSize(width: 2000, height: 1414)
        UIGraphicsBeginImageContext(largeSize)
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(origin: .zero, size: largeSize))
        let largeImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        measure {
            do {
                _ = try documentProcessor.splitA3ToA4(image: largeImage, orientation: .landscape)
            } catch {
                XCTFail("分割失败: \(error)")
            }
        }
    }
    
    // MARK: - 错误处理测试
    func testInvalidCropArea() {
        let smallSize = CGSize(width: 10, height: 10)
        UIGraphicsBeginImageContext(smallSize)
        let smallImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        // 测试无效裁切位置
        var invalidConfig = CropConfiguration(cropX: 0.0, isManual: true)
        XCTAssertThrowsError(try documentProcessor.splitA3ToA4(image: smallImage, orientation: .landscape, cropConfig: invalidConfig))
    }
}

// MARK: - 本地文件管理器测试
class LocalFileManagerTests: XCTestCase {
    
    func testDocumentCRUD() {
        let document = SplitDocument(
            name: "测试文档",
            originalFilePath: "/tmp/test.pdf",
            documentType: .pdf,
            orientation: .landscape
        )
        
        // 添加文档
        LocalFileManager.shared.addDocument(document)
        
        // 验证文档已添加
        let documents = LocalFileManager.shared.allDocuments
        XCTAssertTrue(documents.contains(where: { $0.id == document.id }))
        
        // 重命名
        LocalFileManager.shared.renameDocument(document, newName: "新名称")
        let renamedDoc = LocalFileManager.shared.allDocuments.first { $0.id == document.id }
        XCTAssertEqual(renamedDoc?.name, "新名称")
        
        // 删除文档
        do {
            try LocalFileManager.shared.deleteDocument(document)
            let afterDelete = LocalFileManager.shared.allDocuments
            XCTAssertFalse(afterDelete.contains(where: { $0.id == document.id }))
        } catch {
            XCTFail("删除文档失败: \(error)")
        }
    }
}
