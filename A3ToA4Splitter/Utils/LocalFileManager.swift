import UIKit

class LocalFileManager {
    
    static let shared = LocalFileManager()
    
    private let fileManager = FileManager.default
    private let documentsPath: URL
    private let appFolder: URL
    private let metadataFile: URL
    
    private var documents: [SplitDocument] = []
    
    private init() {
        do {
            documentsPath = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            appFolder = documentsPath.appendingPathComponent(Constants.documentsDirectoryName, isDirectory: true)
            metadataFile = appFolder.appendingPathComponent("documents_metadata.json")
            
            if !fileManager.fileExists(atPath: appFolder.path) {
                try fileManager.createDirectory(at: appFolder, withIntermediateDirectories: true, attributes: nil)
            }
            
            loadDocuments()
        } catch {
            fatalError("无法初始化文件管理器: \(error)")
        }
    }
    
    // MARK: - 文档管理
    var allDocuments: [SplitDocument] {
        return documents.sorted { $0.createdAt > $1.createdAt }
    }
    
    func addDocument(_ document: SplitDocument) {
        documents.append(document)
        saveDocuments()
        NotificationCenter.default.post(name: .documentDidUpdate, object: nil)
    }
    
    func updateDocument(_ document: SplitDocument) {
        if let index = documents.firstIndex(where: { $0.id == document.id }) {
            documents[index] = document
            saveDocuments()
            NotificationCenter.default.post(name: .documentDidUpdate, object: nil)
        }
    }
    
    func deleteDocument(_ document: SplitDocument) throws {
        // 删除关联的文件
        let originalURL = URL(fileURLWithPath: document.originalFilePath)
        if fileManager.fileExists(atPath: originalURL.path) {
            try fileManager.removeItem(at: originalURL)
        }
        
        for path in document.splitFilePaths {
            let url = URL(fileURLWithPath: path)
            if fileManager.fileExists(atPath: url.path) {
                try fileManager.removeItem(at: url)
            }
        }
        
        documents.removeAll { $0.id == document.id }
        saveDocuments()
        NotificationCenter.default.post(name: .documentDidUpdate, object: nil)
    }
    
    func renameDocument(_ document: SplitDocument, newName: String) {
        var updatedDocument = document
        updatedDocument.name = newName
        updateDocument(updatedDocument)
    }
    
    // MARK: - 文件操作
    func saveOriginalFile(from url: URL, fileName: String) throws -> URL {
        let destinationURL = appFolder.appendingPathComponent("original_\(fileName)")
        
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        
        // 处理安全范围的URL（iOS文档选择器返回的URL）
        let sourceURL: URL
        if url.startAccessingSecurityScopedResource() {
            defer { url.stopAccessingSecurityScopedResource() }
            sourceURL = url
        } else {
            sourceURL = url
        }
        
        // 如果源文件和目标文件路径相同，直接返回
        if sourceURL.path == destinationURL.path {
            return destinationURL
        }
        
        try fileManager.copyItem(at: sourceURL, to: destinationURL)
        
        // 验证文件已成功复制
        guard fileManager.fileExists(atPath: destinationURL.path) else {
            throw AppError.importFailed("文件复制失败")
        }
        
        return destinationURL
    }
    
    func saveSplitFile(data: Data, fileName: String) throws -> URL {
        let destinationURL = appFolder.appendingPathComponent("split_\(fileName)")
        try data.write(to: destinationURL)
        return destinationURL
    }
    
    func fileExists(at path: String) -> Bool {
        return fileManager.fileExists(atPath: path)
    }
    
    // MARK: - 持久化
    private func saveDocuments() {
        do {
            let data = try JSONEncoder().encode(documents)
            try data.write(to: metadataFile)
        } catch {
            print("保存文档元数据失败: \(error)")
        }
    }
    
    private func loadDocuments() {
        guard fileManager.fileExists(atPath: metadataFile.path) else { return }
        
        do {
            let data = try Data(contentsOf: metadataFile)
            documents = try JSONDecoder().decode([SplitDocument].self, from: data)
        } catch {
            print("加载文档元数据失败: \(error)")
        }
    }
    
    // MARK: - 分享
    func getShareURL(for document: SplitDocument) -> [URL] {
        var urls: [URL] = []
        
        for path in document.splitFilePaths {
            let url = URL(fileURLWithPath: path)
            if fileManager.fileExists(atPath: url.path) {
                urls.append(url)
            }
        }
        
        return urls
    }
    
    // MARK: - 清理
    func clearAllDocuments() throws {
        let contents = try fileManager.contentsOfDirectory(at: appFolder, includingPropertiesForKeys: nil)
        for url in contents {
            if url.lastPathComponent != "documents_metadata.json" {
                try fileManager.removeItem(at: url)
            }
        }
        documents.removeAll()
        saveDocuments()
        NotificationCenter.default.post(name: .documentDidUpdate, object: nil)
    }
}
