import UIKit
import PDFKit

class PreviewViewController: UIViewController {
    
    // MARK: - UI Components
    // 原始预览：水平滚动显示所有A3页面
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.showsHorizontalScrollIndicator = true
        return sv
    }()
    
    private let originalPreviewStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 12
        sv.alignment = .fill
        sv.distribution = .fillEqually
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private let pageIndicatorLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        label.layer.cornerRadius = 10
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let previewSegmentControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["原始", "分割预览"])
        sc.selectedSegmentIndex = 0
        sc.translatesAutoresizingMaskIntoConstraints = false
        return sc
    }()
    
    // 分割预览：水平滚动显示所有页面
    private let splitPreviewScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.showsHorizontalScrollIndicator = true
        sv.isHidden = true
        return sv
    }()
    
    private let splitPreviewStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 12
        sv.alignment = .fill
        sv.distribution = .fillEqually
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private let infoLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let outputInfoLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = .systemBlue
        label.textAlignment = .center
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let actionStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.distribution = .fillEqually
        sv.spacing = 12
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("保存PDF", for: .normal)
        button.setImage(UIImage(systemName: "square.and.arrow.down"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 10
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let shareButton: UIButton = {
        let button = UIButton(type: .system)
        let shareImage = UIImage(systemName: "square.and.arrow.up")
        button.setImage(shareImage, for: .normal)
        button.tintColor = .systemBlue
        button.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .systemBlue
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - Properties
    private let fileURL: URL
    private let documentType: DocumentType
    var existingDocument: SplitDocument?
    private var pdfTotalPages: Int = 1
    
    private var originalPageThumbnails: [UIImage] = []
    private var pdfDocument: PDFDocument?
    private var documentOrientation: DocumentOrientation = .landscape
    private var splitImages: [UIImage] = []
    
    // MARK: - Initialization
    init(fileURL: URL, documentType: DocumentType) {
        self.fileURL = fileURL
        self.documentType = documentType
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        loadDocument()
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = "预览"
        view.backgroundColor = .systemBackground
        
        view.addSubview(previewSegmentControl)
        
        scrollView.addSubview(originalPreviewStackView)
        view.addSubview(scrollView)
        view.addSubview(pageIndicatorLabel)
        
        splitPreviewScrollView.addSubview(splitPreviewStackView)
        view.addSubview(splitPreviewScrollView)
        
        view.addSubview(infoLabel)
        view.addSubview(outputInfoLabel)
        view.addSubview(actionStackView)
        actionStackView.addArrangedSubview(saveButton)
        actionStackView.addArrangedSubview(shareButton)
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            // segmentControl 在顶部
            previewSegmentControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            previewSegmentControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // 原始预览：水平滚动显示所有A3页面
            scrollView.topAnchor.constraint(equalTo: previewSegmentControl.bottomAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            scrollView.heightAnchor.constraint(equalToConstant: 220),
            
            originalPreviewStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            originalPreviewStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            originalPreviewStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            originalPreviewStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            originalPreviewStackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            
            pageIndicatorLabel.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -8),
            pageIndicatorLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            pageIndicatorLabel.heightAnchor.constraint(equalToConstant: 24),
            pageIndicatorLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
            
            // 分割预览与原始预览同一位置
            splitPreviewScrollView.topAnchor.constraint(equalTo: previewSegmentControl.bottomAnchor, constant: 12),
            splitPreviewScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            splitPreviewScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            splitPreviewScrollView.heightAnchor.constraint(equalToConstant: 220),
            
            splitPreviewStackView.topAnchor.constraint(equalTo: splitPreviewScrollView.topAnchor),
            splitPreviewStackView.leadingAnchor.constraint(equalTo: splitPreviewScrollView.leadingAnchor),
            splitPreviewStackView.trailingAnchor.constraint(equalTo: splitPreviewScrollView.trailingAnchor),
            splitPreviewStackView.bottomAnchor.constraint(equalTo: splitPreviewScrollView.bottomAnchor),
            splitPreviewStackView.heightAnchor.constraint(equalTo: splitPreviewScrollView.heightAnchor),
            
            // 信息区
            infoLabel.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 16),
            infoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            infoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            outputInfoLabel.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 6),
            outputInfoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            outputInfoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            actionStackView.topAnchor.constraint(equalTo: outputInfoLabel.bottomAnchor, constant: 24),
            actionStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            actionStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            actionStackView.heightAnchor.constraint(equalToConstant: 48),
            
            saveButton.heightAnchor.constraint(equalToConstant: 48),
            shareButton.heightAnchor.constraint(equalToConstant: 48),
            shareButton.widthAnchor.constraint(equalToConstant: 60),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupActions() {
        previewSegmentControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        saveButton.addTarget(self, action: #selector(savePDF), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(sharePDF), for: .touchUpInside)
    }
    
    // MARK: - Document Loading
    private func loadDocument() {
        activityIndicator.startAnimating()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                guard let self = self else { return }
                
                if self.documentType == .image {
                    let (image, orientation) = try DocumentProcessor.shared.importImage(from: self.fileURL)
                    self.documentOrientation = orientation
                    self.originalPageThumbnails = [image]
                    self.splitImages = try DocumentProcessor.shared.splitA3ToA4(image: image, orientation: orientation)
                } else {
                    let (pdf, orientation) = try DocumentProcessor.shared.importPDF(from: self.fileURL)
                    self.pdfDocument = pdf
                    self.documentOrientation = orientation
                    self.pdfTotalPages = pdf.pageCount
                    print("[PreviewViewController] PDF页数: \(self.pdfTotalPages)")
                    
                    // 分割所有页面
                    if self.pdfTotalPages > 1 {
                        self.splitImages = try DocumentProcessor.shared.splitAllPages(pdfDocument: pdf, orientation: orientation)
                    } else {
                        self.splitImages = try DocumentProcessor.shared.splitA3ToA4(pdfDocument: pdf, orientation: orientation)
                    }
                    
                    // 生成所有原始页面缩略图
                    self.originalPageThumbnails = []
                    for pageIndex in 0..<pdf.pageCount {
                        guard let page = pdf.page(at: pageIndex) else { continue }
                        let bounds = page.bounds(for: .mediaBox)
                        let thumbScale: CGFloat = 0.3
                        let thumbSize = CGSize(width: bounds.width * thumbScale, height: bounds.height * thumbScale)
                        let renderer = UIGraphicsImageRenderer(size: thumbSize)
                        let thumbImage = renderer.image { context in
                            UIColor.white.set()
                            context.fill(context.format.bounds)
                            context.cgContext.saveGState()
                            context.cgContext.translateBy(x: 0, y: thumbSize.height)
                            context.cgContext.scaleBy(x: thumbScale, y: -thumbScale)
                            page.draw(with: .mediaBox, to: context.cgContext)
                            context.cgContext.restoreGState()
                        }
                        self.originalPageThumbnails.append(thumbImage)
                    }
                }
                
                print("[PreviewViewController] 加载完成，splitImages数量: \(self.splitImages.count)，原始缩略图数量: \(self.originalPageThumbnails.count)")
                
                DispatchQueue.main.async { [weak self] in
                    self?.activityIndicator.stopAnimating()
                    self?.updateUI()
                    self?.updateOriginalPreview()
                    self?.updatePreviewImages()
                }
            } catch {
                print("[PreviewViewController] 加载文档失败: \(error.localizedDescription)")
                DispatchQueue.main.async { [weak self] in
                    self?.activityIndicator.stopAnimating()
                    self?.showError(error)
                }
            }
        }
    }
    
    private func updateUI() {
        guard !originalPageThumbnails.isEmpty else { return }
        
        let size = originalPageThumbnails[0].size
        infoLabel.text = String(format: "原始尺寸: %.0f x %.0f 像素 | 方向: %@ | 共 %d 页",
                                size.width, size.height,
                                documentOrientation == .landscape ? "横向A3" : "纵向A3",
                                originalPageThumbnails.count)
        if pdfTotalPages > 1 {
            outputInfoLabel.text = "将输出 1 份 \(pdfTotalPages * 2) 页 A4 PDF（\(pdfTotalPages) 页 A3 → 每页分割为 2 页 A4）"
            pageIndicatorLabel.text = "  共 \(pdfTotalPages) 页 A3  "
        } else {
            outputInfoLabel.text = "将输出 1 份 2 页 A4 PDF"
            pageIndicatorLabel.text = "  共 1 页 A3  "
        }
    }
    
    private func updateOriginalPreview() {
        guard !originalPageThumbnails.isEmpty else { return }
        
        // 清空之前的原始预览
        originalPreviewStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for (index, image) in originalPageThumbnails.enumerated() {
            let container = UIView()
            container.translatesAutoresizingMaskIntoConstraints = false
            
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFit
            imageView.backgroundColor = .systemGray6
            imageView.layer.cornerRadius = 8
            imageView.clipsToBounds = true
            imageView.layer.borderWidth = 1
            imageView.layer.borderColor = UIColor.systemGray4.cgColor
            imageView.image = image
            imageView.translatesAutoresizingMaskIntoConstraints = false
            
            let label = UILabel()
            label.text = "A3-\(index + 1)"
            label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
            label.textColor = .secondaryLabel
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            
            container.addSubview(imageView)
            container.addSubview(label)
            
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: container.topAnchor),
                imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                imageView.heightAnchor.constraint(equalToConstant: 200),
                
                label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 4),
                label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                label.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            ])
            
            // 每个预览容器固定宽度
            container.widthAnchor.constraint(equalToConstant: 150).isActive = true
            
            originalPreviewStackView.addArrangedSubview(container)
        }
    }
    
    private func updatePreviewImages() {
        guard !splitImages.isEmpty else { return }
        
        // 清空之前的分割预览
        splitPreviewStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for (index, image) in splitImages.enumerated() {
            let container = UIView()
            container.translatesAutoresizingMaskIntoConstraints = false
            
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFit
            imageView.backgroundColor = .systemGray6
            imageView.layer.cornerRadius = 8
            imageView.clipsToBounds = true
            imageView.layer.borderWidth = 1
            imageView.layer.borderColor = UIColor.systemBlue.cgColor
            imageView.image = image
            imageView.translatesAutoresizingMaskIntoConstraints = false
            
            let label = UILabel()
            label.text = "A4-\(index + 1)"
            label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
            label.textColor = .systemBlue
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            
            container.addSubview(imageView)
            container.addSubview(label)
            
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: container.topAnchor),
                imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                imageView.heightAnchor.constraint(equalToConstant: 200),
                
                label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 4),
                label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                label.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            ])
            
            // 每个预览容器固定宽度
            container.widthAnchor.constraint(equalToConstant: 150).isActive = true
            
            splitPreviewStackView.addArrangedSubview(container)
        }
    }
    
    // MARK: - Actions
    @objc private func segmentChanged() {
        let isOriginal = previewSegmentControl.selectedSegmentIndex == 0
        
        scrollView.isHidden = !isOriginal
        pageIndicatorLabel.isHidden = !isOriginal
        splitPreviewScrollView.isHidden = isOriginal
    }
    
    @objc private func savePDF() {
        print("[PreviewViewController] 点击保存PDF，splitImages数量: \(splitImages.count)")
        guard !splitImages.isEmpty else {
            showError(AppError.invalidCropArea)
            return
        }
        
        activityIndicator.startAnimating()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                guard let self = self else { return }
                
                print("[PreviewViewController] 开始生成PDF，共 \(self.splitImages.count) 张图片")
                let pdfData = try PDFGenerator.shared.generatePDF(from: self.splitImages)
                print("[PreviewViewController] PDF生成成功，数据大小: \(pdfData.count) bytes")
                
                // 验证PDF页数
                let verifyDoc = PDFDocument(data: pdfData)
                let pageCount = verifyDoc?.pageCount ?? 0
                print("[PreviewViewController] PDF验证页数: \(pageCount)")
                
                let expectedPages = self.splitImages.count
                guard pageCount == expectedPages else {
                    DispatchQueue.main.async { [weak self] in
                        self?.activityIndicator.stopAnimating()
                        self?.showError(AppError.pdfGenerationFailed)
                    }
                    return
                }
                
                let fileName = "\(self.fileURL.deletingPathExtension().lastPathComponent)_split.pdf"
                
                // 保存到临时目录，然后让用户选择保存位置
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                try pdfData.write(to: tempURL)
                
                DispatchQueue.main.async { [weak self] in
                    self?.activityIndicator.stopAnimating()
                    self?.presentSaveDialog(fileURL: tempURL, fileName: fileName)
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.activityIndicator.stopAnimating()
                    self?.showError(error)
                }
            }
        }
    }
    
    // MARK: - 保存对话框
    private func presentSaveDialog(fileURL: URL, fileName: String) {
        // 选项1: 保存到本地应用目录（始终可用）
        let saveLocal = UIAlertAction(title: "保存到应用（推荐）", style: .default) { [weak self] _ in
            self?.saveToLocalApp(fileURL: fileURL, fileName: fileName)
        }
        
        // 选项2: 通过系统分享保存（可保存到文件/ iCloud）
        let saveViaSystem = UIAlertAction(title: "另存为...", style: .default) { [weak self] _ in
            self?.presentDocumentPickerForSave(fileURL: fileURL, fileName: fileName)
        }
        
        // 选项3: 复制到文件 App
        let copyFiles = UIAlertAction(title: "复制到「文件」App", style: .default) { [weak self] _ in
            self?.saveToFilesApp(fileURL: fileURL, fileName: fileName)
        }
        
        let cancel = UIAlertAction(title: "取消", style: .cancel)
        
        let alert = UIAlertController(title: "保存 PDF", message: "选择保存方式", preferredStyle: .actionSheet)
        alert.addAction(saveLocal)
        alert.addAction(saveViaSystem)
        alert.addAction(copyFiles)
        alert.addAction(cancel)
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = saveButton
            popover.sourceRect = saveButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    private func saveToLocalApp(fileURL: URL, fileName: String) {
        do {
            let savedURL = try PDFGenerator.shared.savePDF(data: try Data(contentsOf: fileURL), fileName: (fileName as NSString).deletingPathExtension)
            
            // 记录到文件管理器
            let thumbnail = DocumentProcessor.shared.generateThumbnail(from: splitImages[0])
            let thumbnailData = thumbnail?.pngData()
            
            let document = SplitDocument(
                name: (fileName as NSString).deletingPathExtension,
                originalFilePath: self.fileURL.path,
                documentType: self.documentType,
                orientation: self.documentOrientation,
                thumbnailData: thumbnailData
            )
            var updatedDocument = document
            updatedDocument.splitFilePaths = [savedURL.path]
            LocalFileManager.shared.addDocument(updatedDocument)
            
            let pathAlert = UIAlertController(
                title: "保存成功",
                message: "文件已保存到应用内部\n\n路径：SplitDocuments/\(fileName)",
                preferredStyle: .alert
            )
            pathAlert.addAction(UIAlertAction(title: "确定", style: .default))
            present(pathAlert, animated: true)
        } catch {
            showError(error)
        }
    }
    
    private func presentDocumentPickerForSave(fileURL: URL, fileName: String) {
        // 使用 UIDocumentPicker 以"导出"模式让用户选择目标位置
        let tempDir = FileManager.default.temporaryDirectory
        let exportURL = tempDir.appendingPathComponent(fileName)
        try? FileManager.default.copyItem(at: fileURL, to: exportURL)
        
        // 使用 UIActivityViewController 带 "Save to Files" 让用户选位置
        let activityVC = UIActivityViewController(
            activityItems: [exportURL],
            applicationActivities: nil
        )
        activityVC.completionWithItemsHandler = { [weak self] _, completed, _, _ in
            if completed {
                self?.showSuccess("已通过系统保存到指定位置")
            }
        }
        
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = shareButton
            popover.sourceRect = shareButton.bounds
        }
        
        present(activityVC, animated: true)
    }
    
    private func saveToFilesApp(fileURL: URL, fileName: String) {
        // iOS 14+ 的 UIDocumentPicker for export
        if #available(iOS 14.0, *) {
            // 先确保临时文件存在
            let tempDir = FileManager.default.temporaryDirectory
            let exportURL = tempDir.appendingPathComponent(fileName)
            try? FileManager.default.removeItem(at: exportURL)
            try? FileManager.default.copyItem(at: fileURL, to: exportURL)
            
            let documentPicker = UIDocumentPickerViewController(forExporting: [exportURL])
            documentPicker.delegate = self
            present(documentPicker, animated: true)
        }
    }
    
    @objc private func sharePDF() {
        print("[PreviewViewController] 点击分享PDF，splitImages数量: \(splitImages.count)")
        guard !splitImages.isEmpty else {
            showError(AppError.invalidCropArea)
            return
        }
        
        activityIndicator.startAnimating()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                guard let self = self else { return }
                
                print("[PreviewViewController] 开始生成分享PDF")
                let pdfData = try PDFGenerator.shared.generatePDF(from: self.splitImages)
                print("[PreviewViewController] 分享PDF生成成功，数据大小: \(pdfData.count) bytes")
                
                // 验证PDF页数
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("temp_share.pdf")
                try pdfData.write(to: tempURL)
                let verifyDoc = PDFDocument(url: tempURL)
                let pageCount = verifyDoc?.pageCount ?? 0
                print("[PreviewViewController] PDF验证页数: \(pageCount)")
                
                guard pageCount == self.splitImages.count else {
                    DispatchQueue.main.async { [weak self] in
                        self?.activityIndicator.stopAnimating()
                        self?.showError(AppError.pdfGenerationFailed)
                    }
                    return
                }
                
                DispatchQueue.main.async { [weak self] in
                    self?.activityIndicator.stopAnimating()
                    
                    let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
                    
                    if let popover = activityVC.popoverPresentationController {
                        popover.sourceView = self?.shareButton
                        popover.sourceRect = self?.shareButton.bounds ?? .zero
                    }
                    
                    self?.present(activityVC, animated: true)
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.activityIndicator.stopAnimating()
                    self?.showError(error)
                }
            }
        }
    }
    
    private func showError(_ error: Error) {
        let message = (error as? AppError)?.errorDescription ?? error.localizedDescription
        let alert = UIAlertController(title: "错误", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
    
    private func showSuccess(_ message: String) {
        let alert = UIAlertController(title: "成功", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UIDocumentPickerDelegate
extension PreviewViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let savedURL = urls.first else { return }
        let pathAlert = UIAlertController(
            title: "保存成功",
            message: "文件已保存到：\n\(savedURL.lastPathComponent)",
            preferredStyle: .alert
        )
        pathAlert.addAction(UIAlertAction(title: "确定", style: .default))
        present(pathAlert, animated: true)
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    }
}
