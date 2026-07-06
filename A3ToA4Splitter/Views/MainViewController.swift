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
    
    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBlue
        view.layer.cornerRadius = 20
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let headerIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "doc.on.doc.fill")
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let headerTitle: UILabel = {
        let label = UILabel()
        label.text = "A3 转 A4 分割器"
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let headerSubtitle: UILabel = {
        let label = UILabel()
        label.text = "快速将A3文档分割为两份A4"
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .white.withAlphaComponent(0.8)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let importButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("导入文档", for: .normal)
        button.setImage(UIImage(systemName: "square.and.arrow.down"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        button.layer.cornerRadius = 12
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let recentFilesLabel: UILabel = {
        let label = UILabel()
        label.text = "最近文件"
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let viewAllButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("查看全部", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
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
    
    private let guideView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let guideTitle: UILabel = {
        let label = UILabel()
        label.text = "使用指南"
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let guideStepsLabel: UILabel = {
        let label = UILabel()
        label.text = "1. 点击导入文档按钮\n2. 选择A3尺寸的图片或PDF\n3. 调整裁切线位置\n4. 预览并保存分割后的A4文件"
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
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        loadRecentDocuments()
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
        headerView.addSubview(headerIcon)
        headerView.addSubview(headerTitle)
        headerView.addSubview(headerSubtitle)
        headerView.addSubview(importButton)
        
        contentView.addSubview(recentFilesLabel)
        contentView.addSubview(viewAllButton)
        contentView.addSubview(emptyStateView)
        emptyStateView.addSubview(emptyIcon)
        emptyStateView.addSubview(emptyLabel)
        contentView.addSubview(recentFilesStackView)
        
        contentView.addSubview(guideView)
        guideView.addSubview(guideTitle)
        guideView.addSubview(guideStepsLabel)
        
        view.addSubview(activityIndicator)
        
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
            
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            headerIcon.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 24),
            headerIcon.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            headerIcon.widthAnchor.constraint(equalToConstant: 50),
            headerIcon.heightAnchor.constraint(equalToConstant: 50),
            
            headerTitle.topAnchor.constraint(equalTo: headerIcon.bottomAnchor, constant: 12),
            headerTitle.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            
            headerSubtitle.topAnchor.constraint(equalTo: headerTitle.bottomAnchor, constant: 4),
            headerSubtitle.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            
            importButton.topAnchor.constraint(equalTo: headerSubtitle.bottomAnchor, constant: 20),
            importButton.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            importButton.widthAnchor.constraint(equalToConstant: 160),
            importButton.heightAnchor.constraint(equalToConstant: 44),
            importButton.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -24),
            
            recentFilesLabel.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 24),
            recentFilesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            viewAllButton.centerYAnchor.constraint(equalTo: recentFilesLabel.centerYAnchor),
            viewAllButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            emptyStateView.topAnchor.constraint(equalTo: recentFilesLabel.bottomAnchor, constant: 20),
            emptyStateView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            emptyStateView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            emptyStateView.heightAnchor.constraint(equalToConstant: 150),
            
            emptyIcon.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyIcon.centerYAnchor.constraint(equalTo: emptyStateView.centerYAnchor, constant: -15),
            emptyIcon.widthAnchor.constraint(equalToConstant: 50),
            emptyIcon.heightAnchor.constraint(equalToConstant: 50),
            
            emptyLabel.topAnchor.constraint(equalTo: emptyIcon.bottomAnchor, constant: 8),
            emptyLabel.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            
            recentFilesStackView.topAnchor.constraint(equalTo: recentFilesLabel.bottomAnchor, constant: 12),
            recentFilesStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            recentFilesStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            guideView.topAnchor.constraint(equalTo: recentFilesStackView.bottomAnchor, constant: 24),
            guideView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            guideView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            guideView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
            
            guideTitle.topAnchor.constraint(equalTo: guideView.topAnchor, constant: 16),
            guideTitle.leadingAnchor.constraint(equalTo: guideView.leadingAnchor, constant: 16),
            
            guideStepsLabel.topAnchor.constraint(equalTo: guideTitle.bottomAnchor, constant: 8),
            guideStepsLabel.leadingAnchor.constraint(equalTo: guideView.leadingAnchor, constant: 16),
            guideStepsLabel.trailingAnchor.constraint(equalTo: guideView.trailingAnchor, constant: -16),
            guideStepsLabel.bottomAnchor.constraint(equalTo: guideView.bottomAnchor, constant: -16),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupActions() {
        importButton.addTarget(self, action: #selector(importButtonTapped), for: .touchUpInside)
        viewAllButton.addTarget(self, action: #selector(viewAllButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Data Loading
    private func loadRecentDocuments() {
        recentDocuments = Array(LocalFileManager.shared.allDocuments.prefix(3))
        updateRecentFilesUI()
    }
    
    private func updateRecentFilesUI() {
        // 清除现有视图
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
        
        let iconImageView = UIImageView()
        let iconName = document.documentType == .image ? "photo" : "doc.text"
        iconImageView.image = UIImage(systemName: iconName)
        iconImageView.tintColor = .systemBlue
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
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
        
        let arrowImageView = UIImageView()
        arrowImageView.image = UIImage(systemName: "chevron.right")
        arrowImageView.tintColor = .tertiaryLabel
        arrowImageView.contentMode = .scaleAspectFit
        arrowImageView.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(iconImageView)
        container.addSubview(nameLabel)
        container.addSubview(dateLabel)
        container.addSubview(arrowImageView)
        
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 60),
            
            iconImageView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            iconImageView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            nameLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            nameLabel.trailingAnchor.constraint(equalTo: arrowImageView.leadingAnchor, constant: -8),
            
            dateLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            dateLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            
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
            let supportedTypes: [UTType] = [.image, .pdf]
            documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)
        } else {
            documentPicker = UIDocumentPickerViewController(documentTypes: [kUTTypeImage as String, kUTTypePDF as String], in: .import)
        }
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true)
    }
    
    // MARK: - Document Processing
    private func processImportedFile(at url: URL) {
        print("[MainViewController] 开始处理导入文件: \(url.lastPathComponent), 是否可访问: \(FileManager.default.isReadableFile(atPath: url.path))")
        activityIndicator.startAnimating()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                // 1. 先复制文件到应用目录（处理安全范围URL）
                let fileName = url.lastPathComponent
                let savedURL = try LocalFileManager.shared.saveOriginalFile(from: url, fileName: fileName)
                print("[MainViewController] 文件已复制到: \(savedURL.path), 大小: \(FileManager.default.fileSize(atPath: savedURL.path) ?? 0) bytes")
                
                // 2. 检测文件类型
                guard let docType = DocumentProcessor.shared.detectDocumentType(from: savedURL) else {
                    throw AppError.invalidFileFormat
                }
                print("[MainViewController] 文件类型: \(docType == .image ? "图片" : "PDF")")
                
                // 3. 获取PDF页数信息
                var pageCount = 1
                if docType == .pdf, let pdfDoc = PDFDocument(url: savedURL) {
                    pageCount = pdfDoc.pageCount
                    print("[MainViewController] PDF页数: \(pageCount)")
                }
                
                DispatchQueue.main.async {
                    self?.activityIndicator.stopAnimating()
                    
                    let previewVC = PreviewViewController(fileURL: savedURL, documentType: docType, totalPages: pageCount)
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
            
            // 复制到临时目录
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
        guard let url = urls.first else { return }
        processImportedFile(at: url)
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    }
}
