import UIKit
import PDFKit

class PreviewViewController: UIViewController {
    
    // MARK: - UI Components
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.minimumZoomScale = 0.5
        sv.maximumZoomScale = 3.0
        return sv
    }()
    
    private let imageContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let originalImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = .systemGray6
        iv.layer.cornerRadius = 8
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let cropOverlayView = CropOverlayView()
    
    private let previewSegmentControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["原始", "分割预览"])
        sc.selectedSegmentIndex = 0
        sc.translatesAutoresizingMaskIntoConstraints = false
        return sc
    }()
    
    private let leftPreviewView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = .systemGray6
        iv.layer.cornerRadius = 8
        iv.clipsToBounds = true
        iv.layer.borderWidth = 1
        iv.layer.borderColor = UIColor.systemBlue.cgColor
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.isHidden = true
        return iv
    }()
    
    private let rightPreviewView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = .systemGray6
        iv.layer.cornerRadius = 8
        iv.clipsToBounds = true
        iv.layer.borderWidth = 1
        iv.layer.borderColor = UIColor.systemBlue.cgColor
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.isHidden = true
        return iv
    }()
    
    private let leftLabel: UILabel = {
        let label = UILabel()
        label.text = "A4-1"
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .systemBlue
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()
    
    private let rightLabel: UILabel = {
        let label = UILabel()
        label.text = "A4-2"
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .systemBlue
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
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
    
    private let slider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0.1
        slider.maximumValue = 0.9
        slider.value = 0.5
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()
    
    private let sliderLabel: UILabel = {
        let label = UILabel()
        label.text = "裁切位置"
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let resetButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("重置", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
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
    
    private var originalImage: UIImage?
    private var pdfDocument: PDFDocument?
    private var documentOrientation: DocumentOrientation = .landscape
    private var cropConfig = CropConfiguration.default
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
        title = "预览与编辑"
        view.backgroundColor = .systemBackground
        
        view.addSubview(scrollView)
        scrollView.addSubview(imageContainerView)
        imageContainerView.addSubview(originalImageView)
        imageContainerView.addSubview(cropOverlayView)
        
        view.addSubview(leftPreviewView)
        view.addSubview(rightPreviewView)
        view.addSubview(leftLabel)
        view.addSubview(rightLabel)
        
        view.addSubview(previewSegmentControl)
        view.addSubview(infoLabel)
        view.addSubview(sliderLabel)
        view.addSubview(slider)
        view.addSubview(resetButton)
        view.addSubview(actionStackView)
        actionStackView.addArrangedSubview(saveButton)
        actionStackView.addArrangedSubview(shareButton)
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            scrollView.heightAnchor.constraint(equalToConstant: 280),
            
            imageContainerView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            imageContainerView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            imageContainerView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            imageContainerView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            imageContainerView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            
            originalImageView.topAnchor.constraint(equalTo: imageContainerView.topAnchor),
            originalImageView.leadingAnchor.constraint(equalTo: imageContainerView.leadingAnchor),
            originalImageView.trailingAnchor.constraint(equalTo: imageContainerView.trailingAnchor),
            originalImageView.bottomAnchor.constraint(equalTo: imageContainerView.bottomAnchor),
            
            cropOverlayView.topAnchor.constraint(equalTo: originalImageView.topAnchor),
            cropOverlayView.leadingAnchor.constraint(equalTo: originalImageView.leadingAnchor),
            cropOverlayView.trailingAnchor.constraint(equalTo: originalImageView.trailingAnchor),
            cropOverlayView.bottomAnchor.constraint(equalTo: originalImageView.bottomAnchor),
            
            leftPreviewView.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 12),
            leftPreviewView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            leftPreviewView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.45, constant: -20),
            leftPreviewView.heightAnchor.constraint(equalToConstant: 200),
            
            rightPreviewView.topAnchor.constraint(equalTo: leftPreviewView.topAnchor),
            rightPreviewView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            rightPreviewView.widthAnchor.constraint(equalTo: leftPreviewView.widthAnchor),
            rightPreviewView.heightAnchor.constraint(equalTo: leftPreviewView.heightAnchor),
            
            leftLabel.topAnchor.constraint(equalTo: leftPreviewView.bottomAnchor, constant: 4),
            leftLabel.centerXAnchor.constraint(equalTo: leftPreviewView.centerXAnchor),
            
            rightLabel.topAnchor.constraint(equalTo: rightPreviewView.bottomAnchor, constant: 4),
            rightLabel.centerXAnchor.constraint(equalTo: rightPreviewView.centerXAnchor),
            
            previewSegmentControl.topAnchor.constraint(equalTo: leftLabel.bottomAnchor, constant: 12),
            previewSegmentControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            infoLabel.topAnchor.constraint(equalTo: previewSegmentControl.bottomAnchor, constant: 8),
            infoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            infoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            sliderLabel.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 12),
            sliderLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            resetButton.centerYAnchor.constraint(equalTo: sliderLabel.centerYAnchor),
            resetButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            slider.topAnchor.constraint(equalTo: sliderLabel.bottomAnchor, constant: 8),
            slider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            slider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            actionStackView.topAnchor.constraint(equalTo: slider.bottomAnchor, constant: 16),
            actionStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            actionStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            actionStackView.heightAnchor.constraint(equalToConstant: 48),
            
            saveButton.heightAnchor.constraint(equalToConstant: 48),
            shareButton.heightAnchor.constraint(equalToConstant: 48),
            shareButton.widthAnchor.constraint(equalToConstant: 60),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        scrollView.delegate = self
        cropOverlayView.delegate = self
    }
    
    private func setupActions() {
        previewSegmentControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        slider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        resetButton.addTarget(self, action: #selector(resetCrop), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(savePDF), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(sharePDF), for: .touchUpInside)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        originalImageView.isUserInteractionEnabled = true
        originalImageView.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Document Loading
    private func loadDocument() {
        activityIndicator.startAnimating()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                guard let self = self else { return }
                
                if self.documentType == .image {
                    let (image, orientation) = try DocumentProcessor.shared.importImage(from: self.fileURL)
                    self.originalImage = image
                    self.documentOrientation = orientation
                    self.splitImages = try DocumentProcessor.shared.splitA3ToA4(image: image, orientation: orientation)
                } else {
                    let (pdf, orientation) = try DocumentProcessor.shared.importPDF(from: self.fileURL)
                    self.pdfDocument = pdf
                    self.documentOrientation = orientation
                    self.splitImages = try DocumentProcessor.shared.splitA3ToA4(pdfDocument: pdf, orientation: orientation)
                    
                    // 生成预览图
                    if let firstPage = pdf.page(at: 0) {
                        let bounds = firstPage.bounds(for: .mediaBox)
                        let renderer = UIGraphicsImageRenderer(size: CGSize(width: bounds.width, height: bounds.height))
                        self.originalImage = renderer.image { context in
                            UIColor.white.set()
                            context.fill(context.format.bounds)
                            context.cgContext.saveGState()
                            context.cgContext.translateBy(x: 0, y: bounds.height)
                            context.cgContext.scaleBy(x: 1, y: -1)
                            firstPage.draw(with: .mediaBox, to: context.cgContext)
                            context.cgContext.restoreGState()
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.updateUI()
                    self.updatePreviewImages()
                }
            } catch {
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.showError(error)
                }
            }
        }
    }
    
    private func updateUI() {
        guard let image = originalImage else { return }
        
        originalImageView.image = image
        cropOverlayView.documentOrientation = documentOrientation
        cropOverlayView.cropPosition = 0.5
        cropOverlayView.isHidden = false
        
        let size = image.size
        infoLabel.text = String(format: "原始尺寸: %.0f x %.0f 像素 | 方向: %@",
                                size.width, size.height,
                                documentOrientation == .landscape ? "横向A3" : "纵向A3")
        
        slider.value = 0.5
    }
    
    private func updatePreviewImages() {
        guard splitImages.count >= 2 else { return }
        
        leftPreviewView.image = splitImages[0]
        rightPreviewView.image = splitImages[1]
    }
    
    private func updateSplitPreview() {
        guard let original = originalImage else { return }
        
        activityIndicator.startAnimating()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                guard let self = self else { return }
                
                if self.documentType == .image {
                    self.splitImages = try DocumentProcessor.shared.splitA3ToA4(
                        image: original,
                        orientation: self.documentOrientation,
                        cropConfig: self.cropConfig
                    )
                } else if let pdf = self.pdfDocument {
                    self.splitImages = try DocumentProcessor.shared.splitA3ToA4(
                        pdfDocument: pdf,
                        orientation: self.documentOrientation,
                        cropConfig: self.cropConfig
                    )
                }
                
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.updatePreviewImages()
                }
            } catch {
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.showError(error)
                }
            }
        }
    }
    
    // MARK: - Actions
    @objc private func segmentChanged() {
        let isOriginal = previewSegmentControl.selectedSegmentIndex == 0
        
        scrollView.isHidden = !isOriginal
        cropOverlayView.isHidden = !isOriginal
        leftPreviewView.isHidden = isOriginal
        rightPreviewView.isHidden = isOriginal
        leftLabel.isHidden = isOriginal
        rightLabel.isHidden = isOriginal
    }
    
    @objc private func sliderValueChanged() {
        let position = CGFloat(slider.value)
        cropConfig.cropX = position
        cropConfig.isManual = true
        cropOverlayView.cropPosition = position
        
        // 延迟更新预览
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(updateSplitPreview), object: nil)
        perform(#selector(updateSplitPreview), with: nil, afterDelay: 0.3)
    }
    
    @objc private func resetCrop() {
        cropConfig = .default
        slider.value = 0.5
        cropOverlayView.cropPosition = 0.5
        updateSplitPreview()
    }
    
    @objc private func imageTapped() {
        guard let image = originalImage else { return }
        
        let previewVC = ImagePreviewViewController(image: image)
        previewVC.modalPresentationStyle = .fullScreen
        present(previewVC, animated: true)
    }
    
    @objc private func savePDF() {
        guard !splitImages.isEmpty else {
            showError(AppError.invalidCropArea)
            return
        }
        
        activityIndicator.startAnimating()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                guard let self = self else { return }
                
                let pdfData = try PDFGenerator.shared.generatePDF(from: self.splitImages)
                let fileName = "\(self.fileURL.deletingPathExtension().lastPathComponent)_split"
                let savedURL = try PDFGenerator.shared.savePDF(data: pdfData, fileName: fileName)
                
                // 生成缩略图
                let thumbnail = DocumentProcessor.shared.generateThumbnail(from: self.splitImages[0])
                let thumbnailData = thumbnail?.pngData()
                
                let document = SplitDocument(
                    name: fileName,
                    originalFilePath: self.fileURL.path,
                    documentType: self.documentType,
                    orientation: self.documentOrientation,
                    thumbnailData: thumbnailData
                )
                
                var updatedDocument = document
                updatedDocument.splitFilePaths = [savedURL.path]
                LocalFileManager.shared.addDocument(updatedDocument)
                
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.showSuccess("PDF已保存")
                }
            } catch {
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.showError(error)
                }
            }
        }
    }
    
    @objc private func sharePDF() {
        guard !splitImages.isEmpty else {
            showError(AppError.invalidCropArea)
            return
        }
        
        activityIndicator.startAnimating()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                guard let self = self else { return }
                
                let pdfData = try PDFGenerator.shared.generatePDF(from: self.splitImages)
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("temp_share.pdf")
                try pdfData.write(to: tempURL)
                
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    
                    let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
                    
                    if let popover = activityVC.popoverPresentationController {
                        popover.sourceView = self.shareButton
                        popover.sourceRect = self.shareButton.bounds
                    }
                    
                    self.present(activityVC, animated: true)
                }
            } catch {
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.showError(error)
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

// MARK: - UIScrollViewDelegate
extension PreviewViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageContainerView
    }
}

// MARK: - CropOverlayViewDelegate
extension PreviewViewController: CropOverlayViewDelegate {
    func cropOverlayView(_ view: CropOverlayView, didChangeCropPosition position: CGFloat) {
        cropConfig.cropX = position
        cropConfig.isManual = true
        slider.value = Float(position)
    }
    
    func cropOverlayView(_ view: CropOverlayView, didEndChangingCropPosition position: CGFloat) {
        updateSplitPreview()
    }
}

// MARK: - Image Preview ViewController
class ImagePreviewViewController: UIViewController {
    
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

extension ImagePreviewViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}
