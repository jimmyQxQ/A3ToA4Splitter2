import UIKit
import PDFKit

enum DocumentType {
    case image
    case pdf
}

enum DocumentOrientation {
    case portrait    // 纵向 A3 (297 x 420)
    case landscape   // 横向 A3 (420 x 297)
    
    var isLandscape: Bool {
        return self == .landscape
    }
}

struct SplitDocument: Identifiable, Codable {
    let id: UUID
    var name: String
    let createdAt: Date
    let originalFilePath: String
    let documentType: DocumentType
    let orientation: DocumentOrientation
    var splitFilePaths: [String]
    var thumbnailData: Data?
    
    var displayName: String {
        return name
    }
    
    var createdDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: createdAt)
    }
    
    var thumbnail: UIImage? {
        guard let data = thumbnailData else { return nil }
        return UIImage(data: data)
    }
    
    init(id: UUID = UUID(), name: String, originalFilePath: String, documentType: DocumentType, orientation: DocumentOrientation, thumbnailData: Data? = nil) {
        self.id = id
        self.name = name
        self.createdAt = Date()
        self.originalFilePath = originalFilePath
        self.documentType = documentType
        self.orientation = orientation
        self.splitFilePaths = []
        self.thumbnailData = thumbnailData
    }
}

extension SplitDocument {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(originalFilePath, forKey: .originalFilePath)
        try container.encode(documentType == .image ? "image" : "pdf", forKey: .documentType)
        try container.encode(orientation == .portrait ? "portrait" : "landscape", forKey: .orientation)
        try container.encode(splitFilePaths, forKey: .splitFilePaths)
        try container.encode(thumbnailData, forKey: .thumbnailData)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        originalFilePath = try container.decode(String.self, forKey: .originalFilePath)
        
        let typeString = try container.decode(String.self, forKey: .documentType)
        documentType = typeString == "image" ? .image : .pdf
        
        let orientationString = try container.decode(String.self, forKey: .orientation)
        orientation = orientationString == "portrait" ? .portrait : .landscape
        
        splitFilePaths = try container.decode([String].self, forKey: .splitFilePaths)
        thumbnailData = try container.decodeIfPresent(Data.self, forKey: .thumbnailData)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, createdAt, originalFilePath, documentType, orientation, splitFilePaths, thumbnailData
    }
}

struct CropConfiguration {
    var cropX: CGFloat  // 裁切线X位置 (0.0 - 1.0)
    var isManual: Bool
    
    static let `default` = CropConfiguration(cropX: 0.5, isManual: false)
    
    var leftRatio: CGFloat {
        return cropX
    }
    
    var rightRatio: CGFloat {
        return 1.0 - cropX
    }
}

struct ProcessingResult {
    let success: Bool
    let document: SplitDocument?
    let error: Error?
    let processingTime: TimeInterval
}
