import UIKit
import PhotosUI
import MobileCoreServices
import UniformTypeIdentifiers

class MainViewController: UIViewController {
    
    // MARK: - UI Components
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.showsVerticalScrollIndicator = false
        return sv
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // 精简 Header：标题 + 副标题 + 导入按钮紧凑排列
    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBlue
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let headerTitle: UILabel = {
        let label = UILabel()
        label.text = "A3 转 A4 分割器"
        label.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let headerSubtitle: UILabel = {
        let label = UILabel()
        label.text = "快速将 A3 文档分割为 A4"
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = .white.withAlphaComponent(0.8)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let importButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("导入文档", for: .normal)
        button.setImage(UIImage(systemName: "doc.badge.plus"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        button.layer.cornerRadius = 10
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // 最近文件区域
    private let recentFilesLabel: UILabel = {
        let label = UILabel()
        label.text = "最近文件"
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let viewAllButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("查看全部", for: .normal)
        button.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.tintColor = .systemBlue
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let emptyStateView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    
    private let emptyIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "doc.text.magnifyingglass")
        iv.tintColor = .systemGray3
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "暂无处理记录"
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let recentFilesStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 8
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    // 可折叠使用指南
    private let guideView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let guideHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "使用指南"
        label.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let guideChevron: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "chevron.down")
        iv.tintColor = .secondaryLabel
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let guideContentView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let guideStepsLabel: UILabel = {
        let label = UILabel()
        label.text = "1. 点击导入文档按钮\n2. 选择 A3 尺寸的图片或 PDF\n3. 预览原始文档与分割效果\n4. 保存或分享分割后的 A4 文件"
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .systemBlue
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - Properties
    private var recentDocuments: [SplitDocument] = []
    private var isGuideExpanded = false
    private var guideContentHeightConstraint: NSLayoutConstraint!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        loadRecentDocuments()
        collapseGuide()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadRecentDocuments()
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = "A3转A4"
        view.backgroundColor = .systemBackground
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(headerView)
        headerView.addSubview(headerTitle)
        headerView.addSubview(headerSubtitle)
        headerView.addSubview(importButton)
        
        contentView.addSubview(recentFilesLabel)
        contentView.addSubview(viewAllButton)
        contentView.addSubview(emptyStateView)
        emptyStateView.addSubview(emptyIcon)
        emptyStateView.addSubview(emptyLabel)
        contentView.addSubview(recentFilesStackView)
        
        // 使用指南（可折叠）
        contentView.addSubview(guideView)
        
        // 指南 header 区域（可点击）
        let guideHeaderContainer = UIView()
        guideHeaderContainer.translatesAutoresizingMaskIntoConstraints = false
        guideHeaderContainer.isUserInteractionEnabled = true
        guideHeaderContainer.addSubview(guideHeaderLabel)
        guideHeaderContainer.addSubview(guideChevron)
        
        let guideTapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleGuide))
        guideHeaderContainer.addGestureRecognizer(guideTapGesture)
        
        guideView.addSubview(guideHeaderContainer)
        guideView.addSubview(guideContentView)
        guideContentView.addSubview(guideStepsLabel)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // 精简 Header
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            headerTitle.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 20),
            headerTitle.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            
            headerSubtitle.topAnchor.constraint(equalTo: headerTitle.bottomAnchor, constant: 4),
            headerSubtitle.leadingAnchor.constraint(equalTo: headerTitle.leadingAnchor),
            
            importButton.topAnchor.constraint(equalTo: headerSubtitle.bottomAnchor, constant: 16),
            importButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            importButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            importButton.heightAnchor.constraint(equalToConstant: 42),
            importButton.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -20),
            
            // 最近文件标题
            recentFilesLabel.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 20),
            recentFilesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            // 查看全部按钮（增强：带箭头图标，蓝色）
            viewAllButton.centerYAnchor.constraint(equalTo: recentFilesLabel.centerYAnchor),
            viewAllButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            emptyStateView.topAnchor.constraint(equalTo: recentFilesLabel.bottomAnchor, constant: 16),
            emptyStateView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            emptyStateView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            emptyStateView.heightAnchor.constraint(equalToConstant: 120),
            
            emptyIcon.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyIcon.centerYAnchor.constraint(equalTo: emptyStateView.centerYAnchor, constant: -15),
            emptyIcon.widthAnchor.constraint(equalToConstant: 44),
            emptyIcon.heightAnchor.constraint(equalToConstant: 44),
            
            emptyLabel.topAnchor.constraint(equalTo: emptyIcon.bottomAnchor, constant: 8),
            emptyLabel.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            
            recentFilesStackView.topAnchor.constraint(equalTo: recentFilesLabel.bottomAnchor, constant: 12),
            recentFilesStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            recentFilesStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // 可折叠指南
            guideView.topAnchor.constraint(equalTo: recentFilesStackView.bottomAnchor, constant: 20),
            guideView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            guideView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            guideView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
            
            // 指南 header
            guideHeaderContainer.topAnchor.constraint(equalTo: guideView.topAnchor),
            guideHeaderContainer.leadingAnchor.constraint(equalTo: guideView.leadingAnchor, constant: 16),
            guideHeaderContainer.trailingAnchor.constraint(equalTo: guideView.trailingAnchor, constant: -16),
            guideHeaderContainer.heightAnchor.constraint(equalToConstant: 44),
            
            guideHeaderLabel.centerYAnchor.constraint(equalTo: guideHeaderContainer.centerYAnchor),
            guideHeaderLabel.leadingAnchor.constraint(equalTo: guideHeaderContainer.leadingAnchor),
            
            guideChevron.centerYAnchor.constraint(equalTo: guideHeaderContainer.centerYAnchor),
            guideChevron.trailingAnchor.constraint(equalTo: guideHeaderContainer.trailingAnchor),
            guideChevron.widthAnchor.constraint(equalToConstant: 20),
            guideChevron.heightAnchor.constraint(equalToConstant: 20),
            
            // 指南内容
            guideContentView.topAnchor.constraint(equalTo: guideHeaderContainer.bottomAnchor),
            guideContentView.leadingAnchor.constraint(equalTo: guideView.leadingAnchor, constant: 16),
            guideContentView.trailingAnchor.constraint(equalTo: guideView.trailingAnchor, constant: -16),
            guideContentView.bottomAnchor.constraint(equalTo: guideView.bottomAnchor, constant: -12),
            
            guideStepsLabel.topAnchor.constraint(equalTo: guideContentView.topAnchor),
            guideStepsLabel.leadingAnchor.constraint(equalTo: guideContentView.leadingAnchor),
            guideStepsLabel.trailingAnchor.constraint(equalTo: guideContentView.trailingAnchor),
            guideStepsLabel.bottomAnchor.constraint(equalTo: guideContentView.bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // 指南内容高度约束（用于折叠动画）
        guideContentHeightConstraint = guideContentView.heightAnchor.constraint(equalToConstant: 0)
        guideContentHeightConstraint.isActive = true
    }
    
    private func setupActions() {
        importButton.addTarget(self, action: #selector(importButtonTapped), for: .touchUpInside)
        viewAllButton.addTarget(self, action: #selector(viewAllButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Guide Toggle
    @objc private func toggleGuide() {
        isGuideExpanded.toggle()
        
        UIView.animate(withDuration: 0.25) {
            if self.isGuideExpanded {
                self.guideContentHeightConstraint.constant = 0
                self.guideContentView.alpha = 0
                self.guideChevron.transform = .identity
            } else {
                self.guideContentHeightConstraint.constant = 100
                self.guideContentView.alpha = 1
                self.guideChevron.transform = CGAffineTransform(rotationAngle: .pi)
            }
            self.view.layoutIfNeeded()
        }
    }
    
    private func collapseGuide() {
        isGuideExpanded = false
        guideContentHeightConstraint.constant = 0
        guideContentView.alpha = 0
        guideChevron.transform = .identity
    }
    
    // MARK: - Data Loading
    private func loadRecentDocuments() {
        recentDocuments = Array(LocalFileManager.shared.allDocuments.prefix(3))
        updateRecentFilesUI()
    }
    
    private func updateRecentFilesUI() {
        recentFilesStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if recentDocuments.isEmpty {
            emptyStateView.isHidden = false
            recentFilesStackView.isHidden = true
        } else {
            emptyStateView.isHidden = true
            recentFilesStackView.isHidden = false
            
            for document in recentDocuments {
                let cell = createRecentFileView(for: document)
                recentFilesStackView.addArrangedSubview(cell)
            }
        }
    }
    
    private func createRecentFileView(for document: SplitDocument) -> UIView {
        let container = UIView()
        container.backgroundColor = .secondarySystemBackground
        container.layer.cornerRadius = 10
        container.translatesAutoresizingMaskIntoConstraints = false
        
        // 缩略图（优先使用文档缩略图）
        let thumbnailImageView = UIImageView()
        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.layer.cornerRadius = 6
        thumbnailImageView.backgroundColor = .systemGray5
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        
        if let thumbnail = document.thumbnail {
            thumbnailImageView.image = thumbnail
        } else {
            let iconName = document.documentType == .image ? "photo" : "doc.text"
            thumbnailImageView.image = UIImage(systemName: iconName)
            thumbnailImageView.tintColor = .systemGray3
            thumbnailImageView.contentMode = .center
        }
        
        let nameLabel = UILabel()
        nameLabel.text = document.displayName
        nameLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        nameLabel.textColor = .label
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let dateLabel = UILabel()
        dateLabel.text = document.createdDateString
        dateLabel.font = UIFont.systemFont(ofSize: 12)
        dateLabel.textColor = .secondaryLabel
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let typeLabel = UILabel()
        typeLabel.text = document.documentType == .image ? "图片" : "PDF"
        typeLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        typeLabel.textColor = .systemBlue
        typeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let arrowImageView = UIImageView()
        arrowImageView.image = UIImage(systemName: "chevron.right")
        arrowImageView.tintColor = .tertiaryLabel
        arrowImageView.contentMode = .scaleAspectFit
        arrowImageView.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(thumbnailImageView)
        container.addSubview(nameLabel)
        container.addSubview(dateLabel)
        container.addSubview(typeLabel)
        container.addSubview(arrowImageView)
        
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 64),
            
            thumbnailImageView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            thumbnailImageView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: 44),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: 44),
            
            nameLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            nameLabel.trailingAnchor.constraint(equalTo: arrowImageView.leadingAnchor, constant: -8),
            
            dateLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            dateLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            
            typeLabel.leadingAnchor.constraint(equalTo: dateLabel.trailingAnchor, constant: 8),
            typeLabel.centerYAnchor.constraint(equalTo: dateLabel.centerYAnchor),
            
            arrowImageView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            arrowImageView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            arrowImageView.widthAnchor.constraint(equalToConstant: 16),
            arrowImageView.heightAnchor.constraint(equalToConstant: 16)
        ])
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(recentFileTapped(_:)))
        container.addGestureRecognizer(tapGesture)
        container.isUserInteractionEnabled = true
        container.tag = recentDocuments.firstIndex(where: { $0.id == document.id }) ?? 0
        
        return container
    }
    
    // MARK: - Actions
    @objc private func importButtonTapped() {
        showImportOptions()
    }
    
    @objc private func viewAllButtonTapped() {
        let fileManagerVC = FileManagerViewController()
        navigationController?.pushViewController(fileManagerVC, animated: true)
    }
    
    @objc private func recentFileTapped(_ gesture: UITapGestureRecognizer) {
        let index = gesture.view?.tag ?? 0
        guard index < recentDocuments.count else { return }
        let document = recentDocuments[index]
        openDocument(document)
    }
    
    private func showImportOptions() {
        let alertController = UIAlertController(title: "导入文档", message: "选择导入方式", preferredStyle: .actionSheet)
        
        alertController.addAction(UIAlertAction(title: "从相册选择", style: .default) { [weak self] _ in
            self?.importFromPhotoLibrary()
        })
        
        alertController.addAction(UIAlertAction(title: "浏览文件", style: .default) { [weak self] _ in
            self?.importFromFiles()
        })
        
        alertController.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        if let popover = alertController.popoverPresentationController {
            popover.sourceView = importButton
            popover.sourceRect = importButton.bounds
        }
        
        present(alertController, animated: true)
    }
    
    private func importFromPhotoLibrary() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func importFromFiles() {
        let documentPicker: UIDocumentPickerViewController
        if #available(iOS 14.0, *) {
            let supportedTypes: [UTType] = [
                .pdf,
                .jpeg,
                .png,
                .heic,
                .tiff,
                .bmp,
                .webP
            ]
            documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
        } else {
            documentPicker = UIDocumentPickerViewController(documentTypes: [kUTTypeImage as String, kUTTypePDF as String], in: .import)
        }
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        documentPicker.shouldShowFileExtensions = true
        present(documentPicker, animated: true)
    }
    
    // MARK: - Document Processing
    private func processImportedFile(at url: URL) {
        print("[MainViewController] 开始处理导入文件: \(url.lastPathComponent), 是否可访问: \(FileManager.default.isReadableFile(atPath: url.path))")
        activityIndicator.startAnimating()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let fileName = url.lastPathComponent
                let savedURL = try LocalFileManager.shared.saveOriginalFile(from: url, fileName: fileName)
                let fileSize = (try? FileManager.default.attributesOfItem(atPath: savedURL.path)[.size] as? Int64) ?? 0
                print("[MainViewController] 文件已复制到: \(savedURL.path), 大小: \(fileSize) bytes")
                
                guard let docType = DocumentProcessor.shared.detectDocumentType(from: savedURL) else {
                    throw AppError.invalidFileFormat
                }
                print("[MainViewController] 文件类型: \(docType == .image ? "图片" : "PDF")")
                
                DispatchQueue.main.async {
                    self?.activityIndicator.stopAnimating()
                    
                    let previewVC = PreviewViewController(fileURL: savedURL, documentType: docType)
                    self?.navigationController?.pushViewController(previewVC, animated: true)
                }
            } catch {
                print("[MainViewController] 导入失败: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.activityIndicator.stopAnimating()
                    self?.showError(error)
                }
            }
        }
    }
    
    private func openDocument(_ document: SplitDocument) {
        let fileURL = URL(fileURLWithPath: document.originalFilePath)
        let previewVC = PreviewViewController(fileURL: fileURL, documentType: document.documentType)
        previewVC.existingDocument = document
        navigationController?.pushViewController(previewVC, animated: true)
    }
    
    private func showError(_ error: Error) {
        let message = (error as? AppError)?.errorDescription ?? error.localizedDescription
        let alert = UIAlertController(title: "错误", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - PHPickerViewControllerDelegate
extension MainViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let result = results.first else { return }
        
        result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { [weak self] url, error in
            guard let url = url else {
                DispatchQueue.main.async {
                    self?.showError(error ?? AppError.importFailed("无法读取图片"))
                }
                return
            }
            
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
            try? FileManager.default.copyItem(at: url, to: tempURL)
            
            DispatchQueue.main.async {
                self?.processImportedFile(at: tempURL)
            }
        }
    }
}

// MARK: - UIDocumentPickerDelegate
extension MainViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else {
            print("[MainViewController] 未选择文件")
            return
        }
        print("[MainViewController] 已选择文件: \(url.lastPathComponent), 路径: \(url.path)")
        
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing { url.stopAccessingSecurityScopedResource() }
        }
        
        processImportedFile(at: url)
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("[MainViewController] 用户取消了文件选择")
    }
}
