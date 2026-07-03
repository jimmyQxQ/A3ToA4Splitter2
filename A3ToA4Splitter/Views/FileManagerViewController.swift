import UIKit

class FileManagerViewController: UIViewController {
    
    // MARK: - UI Components
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .systemBackground
        tv.separatorStyle = .none
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.register(DocumentCell.self, forCellReuseIdentifier: DocumentCell.reuseIdentifier)
        return tv
    }()
    
    private let emptyStateView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    
    private let emptyIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "folder.badge.questionmark")
        iv.tintColor = .systemGray3
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "暂无文件"
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let emptyDetailLabel: UILabel = {
        let label = UILabel()
        label.text = "导入并处理文档后，文件将显示在这里"
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .tertiaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Properties
    private var documents: [SplitDocument] = []
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        loadDocuments()
        
        NotificationCenter.default.addObserver(self, selector: #selector(documentsUpdated), name: .documentDidUpdate, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = "文件管理"
        view.backgroundColor = .systemBackground
        
        view.addSubview(tableView)
        view.addSubview(emptyStateView)
        emptyStateView.addSubview(emptyIcon)
        emptyStateView.addSubview(emptyLabel)
        emptyStateView.addSubview(emptyDetailLabel)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateView.widthAnchor.constraint(equalTo: view.widthAnchor),
            
            emptyIcon.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyIcon.topAnchor.constraint(equalTo: emptyStateView.topAnchor),
            emptyIcon.widthAnchor.constraint(equalToConstant: 60),
            emptyIcon.heightAnchor.constraint(equalToConstant: 60),
            
            emptyLabel.topAnchor.constraint(equalTo: emptyIcon.bottomAnchor, constant: 16),
            emptyLabel.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            
            emptyDetailLabel.topAnchor.constraint(equalTo: emptyLabel.bottomAnchor, constant: 8),
            emptyDetailLabel.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyDetailLabel.bottomAnchor.constraint(equalTo: emptyStateView.bottomAnchor)
        ])
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func setupNavigationBar() {
        let clearButton = UIBarButtonItem(
            image: UIImage(systemName: "trash"),
            style: .plain,
            target: self,
            action: #selector(clearAllDocuments)
        )
        clearButton.tintColor = .systemRed
        navigationItem.rightBarButtonItem = clearButton
    }
    
    // MARK: - Data Loading
    private func loadDocuments() {
        documents = LocalFileManager.shared.allDocuments
        updateEmptyState()
        tableView.reloadData()
    }
    
    @objc private func documentsUpdated() {
        loadDocuments()
    }
    
    private func updateEmptyState() {
        let isEmpty = documents.isEmpty
        emptyStateView.isHidden = !isEmpty
        tableView.isHidden = isEmpty
    }
    
    // MARK: - Actions
    @objc private func clearAllDocuments() {
        guard !documents.isEmpty else { return }
        
        let alert = UIAlertController(
            title: "确认删除",
            message: "确定要删除所有文件吗？此操作不可恢复。",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
            do {
                try LocalFileManager.shared.clearAllDocuments()
                self?.loadDocuments()
            } catch {
                self?.showError(error)
            }
        })
        
        present(alert, animated: true)
    }
    
    private func showError(_ error: Error) {
        let message = (error as? AppError)?.errorDescription ?? error.localizedDescription
        let alert = UIAlertController(title: "错误", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
    
    private func showDocumentOptions(for document: SplitDocument, at indexPath: IndexPath) {
        let alert = UIAlertController(title: document.displayName, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "重命名", style: .default) { [weak self] _ in
            self?.showRenameAlert(for: document)
        })
        
        alert.addAction(UIAlertAction(title: "分享", style: .default) { [weak self] _ in
            self?.shareDocument(document)
        })
        
        alert.addAction(UIAlertAction(title: "查看", style: .default) { [weak self] _ in
            self?.viewDocument(document)
        })
        
        alert.addAction(UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
            self?.deleteDocument(document)
        })
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = tableView
            popover.sourceRect = tableView.rectForRow(at: indexPath)
        }
        
        present(alert, animated: true)
    }
    
    private func showRenameAlert(for document: SplitDocument) {
        let alert = UIAlertController(title: "重命名", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = document.displayName
            textField.placeholder = "输入新名称"
        }
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定", style: .default) { [weak self] _ in
            guard let newName = alert.textFields?.first?.text, !newName.isEmpty else { return }
            LocalFileManager.shared.renameDocument(document, newName: newName)
            self?.loadDocuments()
        })
        
        present(alert, animated: true)
    }
    
    private func shareDocument(_ document: SplitDocument) {
        let urls = LocalFileManager.shared.getShareURL(for: document)
        guard !urls.isEmpty else {
            showError(AppError.shareFailed)
            return
        }
        
        let activityVC = UIActivityViewController(activityItems: urls, applicationActivities: nil)
        
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(activityVC, animated: true)
    }
    
    private func viewDocument(_ document: SplitDocument) {
        let fileURL = URL(fileURLWithPath: document.originalFilePath)
        let previewVC = PreviewViewController(fileURL: fileURL, documentType: document.documentType)
        previewVC.existingDocument = document
        navigationController?.pushViewController(previewVC, animated: true)
    }
    
    private func deleteDocument(_ document: SplitDocument) {
        let alert = UIAlertController(
            title: "确认删除",
            message: "确定要删除\"\(document.displayName)\"吗？",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
            do {
                try LocalFileManager.shared.deleteDocument(document)
                self?.loadDocuments()
            } catch {
                self?.showError(error)
            }
        })
        
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension FileManagerViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return documents.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: DocumentCell.reuseIdentifier, for: indexPath) as? DocumentCell else {
            return UITableViewCell()
        }
        
        let document = documents[indexPath.row]
        cell.configure(with: document)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension FileManagerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let document = documents[indexPath.row]
        showDocumentOptions(for: document, at: indexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let document = documents[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "删除") { [weak self] _, _, completion in
            do {
                try LocalFileManager.shared.deleteDocument(document)
                self?.documents.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .automatic)
                self?.updateEmptyState()
                completion(true)
            } catch {
                self?.showError(error)
                completion(false)
            }
        }
        deleteAction.image = UIImage(systemName: "trash")
        
        let shareAction = UIContextualAction(style: .normal, title: "分享") { [weak self] _, _, completion in
            self?.shareDocument(document)
            completion(true)
        }
        shareAction.image = UIImage(systemName: "square.and.arrow.up")
        shareAction.backgroundColor = .systemBlue
        
        return UISwipeActionsConfiguration(actions: [deleteAction, shareAction])
    }
}
