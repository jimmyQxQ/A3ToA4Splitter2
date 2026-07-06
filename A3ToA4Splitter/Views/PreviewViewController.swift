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
        label.font = UIFont.systemFont(ofSize: 11, weight: .medium)
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
        sv.alpha = 0
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

    // 处理进度标签
    private let progressLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.isHidden = true
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
        button.setTitle("保存 PDF", for: .normal)
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
        button.setTitle("分享", for: .normal)
        button.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        button.tintColor = .systemBlue
        button.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        button.layer.cornerRadius = 10
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
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
        view.addSubview(progressLabel)
        view.addSubview(actionStackView)
        actionStackView.addArrangedSubview(saveButton)
        actionStackView.addArrangedSubview(shareButton)
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            // segmentControl 在顶部，固定宽度
            previewSegmentControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            previewSegmentControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            previewSegmentControl.widthAnchor.constraint(equalToConstant: 200),
            
            // 原始预览：水平滚动显示所有A3页面（高度约占屏幕50%）
            scrollView.topAnchor.constraint(equalTo: previewSegmentControl.bottomAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            scrollView.heightAnchor.constraint(equalToConstant: 340),
            
            originalPreviewStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            originalPreviewStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            originalPreviewStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            originalPreviewStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            originalPreviewStackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            
            pageIndicatorLabel.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -8),
            pageIndicatorLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            pageIndicatorLabel.heightAnchor.constraint(equalToConstant: 22),
            pageIndicatorLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
            
            // 分割预览与原始预览同一位置
            splitPreviewScrollView.topAnchor.constraint(equalTo: previewSegmentControl.bottomAnchor, constant: 12),
            splitPreviewScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            splitPreviewScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            splitPreviewScrollView.heightAnchor.constraint(equalToConstant: 340),
            
            splitPreviewStackView.topAnchor.constraint(equalTo: splitPreviewScrollView.topAnchor),
            splitPreviewStackView.leadingAnchor.constraint(equalTo: splitPreviewScrollView.leadingAnchor),
            splitPreviewStackView.trailingAnchor.constraint(equalTo: splitPreviewScrollView.trailingAnchor),
            splitPreviewStackView.bottomAnchor.constraint(equalTo: splitPreviewScrollView.bottomAnchor),
            splitPreviewStackView.heightAnchor.constraint(equalTo: splitPreviewScrollView.heightAnchor),
            
            // 信息区（紧凑）
            infoLabel.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 12),
            infoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            infoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            outputInfoLabel.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 4),
            outputInfoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            outputInfoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // 进度提示
            progressLabel.topAnchor.constraint(equalTo: outputInfoLabel.bottomAnchor, constant: 8),
            progressLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // 按钮区
            actionStackView.topAnchor.constraint(equalTo: progressLabel.bottomAnchor, constant: 16),
            actionStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            actionStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            actionStackView.heightAnchor.constraint(equalToConstant: 48),
            
            saveButton.heightAnchor.constraint(equalToConstant: 48),
            shareButton.heightAnchor.constraint(equalToConstant: 48),
            
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
        showLoading("正在加载文档...")
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                guard let self = self else { return }
                
                if self.documentType == .image {
                    let (image, orientation) = try DocumentProcessor.shared.importImage(from: self.fileURL)
                    self.documentOrientation = orientation
                    self.originalPageThumbnails = [image]
                    self.splitImages = try DocumentProcessor.shared.splitA3ToA4(image: image, orientation: orientation)
                } else {
                    self.updateProgressOnMain("正在解析 PDF...")
                    let (pdf, orientation) = try DocumentProcessor.shared.importPDF(from: self.fileURL)
                    self.pdfDocument = pdf
                    self.documentOrientation = orientation
                    self.pdfTotalPages = pdf.pageCount
                    
                    // 分割所有页面（带进度）
                    if self.pdfTotalPages > 1 {
                        self.splitImages = try self.splitAllPagesWithProgress(pdfDocument: pdf, orientation: orientation)
                    } else {
                        self.updateProgressOnMain("正在分割...")
                        self.splitImages = try DocumentProcessor.shared.splitA3ToA4(pdfDocument: pdf, orientation: orientation)
                    }
                    
                    // 生成所有原始页面缩略图
                    self.updateProgressOnMain("正在生成预览...")
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
                
                DispatchQueue.main.async { [weak self] in
                    self?.hideLoading()
                    self?.updateUI()
                    self?.updateOriginalPreview()
                    self?.updatePreviewImages()
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.hideLoading()
                    self?.showError(error)
                }
            }
        }
    }
    
    // 带进度提示的多页分割
    private func splitAllPagesWithProgress(pdfDocument: PDFDocument, orientation: DocumentOrientation) throws -> [UIImage] {
        let pageCount = pdfDocument.pageCount
        var allSplitImages: [UIImage] = []
        let scale: CGFloat = 2.0
        
        for pageIndex in 0..<pageCount {
            let progressText = String(format: "正在分割第 %d / %d 页...", pageIndex + 1, pageCount)
            updateProgressOnMain(progressText)
            
            guard let page = pdfDocument.page(at: pageIndex) else { continue }
            
            let pageBounds = page.bounds(for: .mediaBox)
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
            
            let splitParts = try DocumentProcessor.shared.splitA3ToA4(image: pageImage, orientation: pageOrientation)
            allSplitImages.append(contentsOf: splitParts)
        }
        
        return allSplitImages
    }
    
    // MARK: - Loading / Progress
    private func showLoading(_ text: String) {
        activityIndicator.startAnimating()
        progressLabel.text = text
        progressLabel.isHidden = false
        saveButton.isEnabled = false
        shareButton.isEnabled = false
        saveButton.alpha = 0.5
        shareButton.alpha = 0.5
    }
    
    private func hideLoading() {
        activityIndicator.stopAnimating()
        progressLabel.isHidden = true
        saveButton.isEnabled = true
        shareButton.isEnabled = true
        saveButton.alpha = 1.0
        shareButton.alpha = 1.0
    }
    
    private func updateProgressOnMain(_ text: String) {
        DispatchQueue.main.async { [weak self] in
            self?.progressLabel.text = text
        }
    }
    
    private func updateUI() {
        guard !originalPageThumbnails.isEmpty else { return }
        
        let orientationText = documentOrientation == .landscape ? "横向" : "纵向"
        infoLabel.text = String(format: "%d 页 %@ A3 文档", originalPageThumbnails.count, orientationText)
        if pdfTotalPages > 1 {
            outputInfoLabel.text = "将输出 \(pdfTotalPages * 2) 页 A4 PDF（每页 A3 分割为 2 页 A4）"
            pageIndicatorLabel.text = "  共 \(pdfTotalPages) 页 A3  "
        } else {
            outputInfoLabel.text = "将输出 2 页 A4 PDF"
            pageIndicatorLabel.text = "  共 1 页 A3  "
        }
    }
    
    private func updateOriginalPreview() {
        guard !originalPageThumbnails.isEmpty else { return }
        
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
            imageView.isUserInteractionEnabled = true
            imageView.translatesAutoresizingMaskIntoConstraints = false
            
            // 点击查看大图
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(previewOriginalTapped(_:)))
            imageView.tag = index
            imageView.addGestureRecognizer(tapGesture)
            
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
                imageView.heightAnchor.constraint(equalToConstant: 310),
                
                label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 4),
                label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                label.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            ])
            
            container.widthAnchor.constraint(equalToConstant: 160).isActive = true
            originalPreviewStackView.addArrangedSubview(container)
        }
    }
    
    private func updatePreviewImages() {
        guard !splitImages.isEmpty else { return }
        
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
            imageView.isUserInteractionEnabled = true
            imageView.translatesAutoresizingMaskIntoConstraints = false
            
            // 点击查看大图
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(previewSplitTapped(_:)))
            imageView.tag = index
            imageView.addGestureRecognizer(tapGesture)
            
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
                imageView.heightAnchor.constraint(equalToConstant: 310),
                
                label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 4),
                label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                label.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            ])
            
            container.widthAnchor.constraint(equalToConstant: 160).isActive = true
            splitPreviewStackView.addArrangedSubview(container)
        }
    }
    
    // MARK: - Actions
    @objc private func segmentChanged() {
        let isOriginal = previewSegmentControl.selectedSegmentIndex == 0
        
        UIView.animate(withDuration: 0.25) {
            self.scrollView.alpha = isOriginal ? 1 : 0
            self.scrollView.isHidden = !isOriginal
            self.pageIndicatorLabel.alpha = isOriginal ? 1 : 0
            self.pageIndicatorLabel.isHidden = !isOriginal
            
            self.splitPreviewScrollView.alpha = isOriginal ? 0 : 1
            self.splitPreviewScrollView.isHidden = isOriginal
        }
    }
    
    // 点击原始预览图片查看大图
    @objc private func previewOriginalTapped(_ gesture: UITapGestureRecognizer) {
        guard let index = gesture.view?.tag, index < originalPageThumbnails.count else { return }
        let fullScreenVC = FullScreenImageViewController(image: originalPageThumbnails[index])
        fullScreenVC.modalPresentationStyle = .fullScreen
        present(fullScreenVC, animated: true)
    }
    
    // 点击分割预览图片查看大图
    @objc private func previewSplitTapped(_ gesture: UITapGestureRecognizer) {
        guard let index = gesture.view?.tag, index < splitImages.count else { return }
        let fullScreenVC = FullScreenImageViewController(image: splitImages[index])
        fullScreenVC.modalPresentationStyle = .fullScreen
        present(fullScreenVC, animated: true)
    }
    
    @objc private func savePDF() {
        guard !splitImages.isEmpty else {
            showError(AppError.invalidCropArea)
            return
        }
        
        showLoading("正在生成 PDF...")
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                guard let self = self else { return }
                
                let pdfData = try PDFGenerator.shared.generatePDF(from: self.splitImages)
                
                // 验证PDF页数
                let verifyDoc = PDFDocument(data: pdfData)
                let pageCount = verifyDoc?.pageCount ?? 0
                
                let expectedPages = self.splitImages.count
                guard pageCount == expectedPages else {
                    DispatchQueue.main.async { [weak self] in
                        self?.hideLoading()
                        self?.showError(AppError.pdfGenerationFailed)
                    }
                    return
                }
                
                let fileName = "\(self.fileURL.deletingPathExtension().lastPathComponent)_split.pdf"
                
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                try pdfData.write(to: tempURL)
                
                DispatchQueue.main.async { [weak self] in
                    self?.hideLoading()
                    self?.presentSaveDialog(fileURL: tempURL, fileName: fileName)
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.hideLoading()
                    self?.showError(error)
                }
            }
        }
    }
    
    // MARK: - 保存对话框（简化为2个选项）
    private func presentSaveDialog(fileURL: URL, fileName: String) {
        let saveLocal = UIAlertAction(title: "保存到本应用", style: .default) { [weak self] _ in
            self?.saveToLocalApp(fileURL: fileURL, fileName: fileName)
        }
        
        let saveToFiles = UIAlertAction(title: "保存到文件", style: .default) { [weak self] _ in
            self?.saveToFilesApp(fileURL: fileURL, fileName: fileName)
        }
        
        let cancel = UIAlertAction(title: "取消", style: .cancel)
        
        let alert = UIAlertController(title: "保存 PDF", message: nil, preferredStyle: .actionSheet)
        alert.addAction(saveLocal)
        alert.addAction(saveToFiles)
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
    
    private func saveToFilesApp(fileURL: URL, fileName: String) {
        if #available(iOS 14.0, *) {
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
        guard !splitImages.isEmpty else {
            showError(AppError.invalidCropArea)
            return
        }
        
        showLoading("正在生成 PDF...")
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                guard let self = self else { return }
                
                let pdfData = try PDFGenerator.shared.generatePDF(from: self.splitImages)
                
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("temp_share.pdf")
                try pdfData.write(to: tempURL)
                let verifyDoc = PDFDocument(url: tempURL)
                let pageCount = verifyDoc?.pageCount ?? 0
                
                guard pageCount == self.splitImages.count else {
                    DispatchQueue.main.async { [weak self] in
                        self?.hideLoading()
                        self?.showError(AppError.pdfGenerationFailed)
                    }
                    return
                }
                
                DispatchQueue.main.async { [weak self] in
                    self?.hideLoading()
                    
                    let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
                    
                    if let popover = activityVC.popoverPresentationController {
                        popover.sourceView = self?.shareButton
                        popover.sourceRect = self?.shareButton.bounds ?? .zero
                    }
                    
                    self?.present(activityVC, animated: true)
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.hideLoading()
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

// MARK: - 全屏图片预览
class FullScreenImageViewController: UIViewController {
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.minimumZoomScale = 1.0
        sv.maximumZoomScale = 4.0
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    init(image: UIImage) {
        super.init(nibName: nil, bundle: nil)
        imageView.image = image
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        view.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        scrollView.delegate = self
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(closeTapped))
        tapGesture.numberOfTapsRequired = 2
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}

extension FullScreenImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}
