import UIKit

protocol CropOverlayViewDelegate: AnyObject {
    func cropOverlayView(_ view: CropOverlayView, didChangeCropPosition position: CGFloat)
    func cropOverlayView(_ view: CropOverlayView, didEndChangingCropPosition position: CGFloat)
}

class CropOverlayView: UIView {
    
    weak var delegate: CropOverlayViewDelegate?
    
    var cropPosition: CGFloat = 0.5 {
        didSet {
            cropPosition = max(0.1, min(0.9, cropPosition))
            setNeedsDisplay()
        }
    }
    
    var documentOrientation: DocumentOrientation = .landscape
    
    private var isDragging = false
    private let handleWidth: CGFloat = 40.0
    private let handleHeight: CGFloat = 60.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .clear
        isUserInteractionEnabled = true
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // 绘制裁切线
        let linePath = UIBezierPath()
        
        if documentOrientation == .landscape {
            let x = rect.width * cropPosition
            linePath.move(to: CGPoint(x: x, y: 0))
            linePath.addLine(to: CGPoint(x: x, y: rect.height))
        } else {
            let y = rect.height * cropPosition
            linePath.move(to: CGPoint(x: 0, y: y))
            linePath.addLine(to: CGPoint(x: rect.width, y: y))
        }
        
        // 主裁切线
        Constants.cropLineColor.setStroke()
        linePath.lineWidth = Constants.cropLineWidth
        linePath.stroke()
        
        // 虚线效果
        let dashPattern: [CGFloat] = [8, 4]
        linePath.setLineDash(dashPattern, count: 2, phase: 0)
        UIColor.white.setStroke()
        linePath.lineWidth = Constants.cropLineWidth * 0.8
        linePath.stroke()
        
        // 绘制拖拽手柄
        drawHandle(in: rect, context: context)
        
        // 绘制左右/上下区域标记
        drawRegionMarkers(in: rect)
    }
    
    private func drawHandle(in rect: CGRect, context: CGContext) {
        let handleRect: CGRect
        
        if documentOrientation == .landscape {
            let x = rect.width * cropPosition
            let y = rect.height / 2 - handleHeight / 2
            handleRect = CGRect(x: x - handleWidth / 2, y: y, width: handleWidth, height: handleHeight)
        } else {
            let y = rect.height * cropPosition
            let x = rect.width / 2 - handleHeight / 2
            handleRect = CGRect(x: x, y: y - handleWidth / 2, width: handleHeight, height: handleWidth)
        }
        
        context.saveGState()
        
        // 手柄背景
        let path = UIBezierPath(roundedRect: handleRect, cornerRadius: 8)
        UIColor.systemBlue.withAlphaComponent(0.9).setFill()
        path.fill()
        
        // 手柄边框
        UIColor.white.setStroke()
        path.lineWidth = 2
        path.stroke()
        
        // 手柄指示器
        let indicatorPath = UIBezierPath()
        if documentOrientation == .landscape {
            let centerX = handleRect.midX
            indicatorPath.move(to: CGPoint(x: centerX - 6, y: handleRect.midY - 4))
            indicatorPath.addLine(to: CGPoint(x: centerX, y: handleRect.midY))
            indicatorPath.addLine(to: CGPoint(x: centerX + 6, y: handleRect.midY - 4))
            indicatorPath.move(to: CGPoint(x: centerX - 6, y: handleRect.midY + 4))
            indicatorPath.addLine(to: CGPoint(x: centerX, y: handleRect.midY))
            indicatorPath.addLine(to: CGPoint(x: centerX + 6, y: handleRect.midY + 4))
        } else {
            let centerY = handleRect.midY
            indicatorPath.move(to: CGPoint(x: handleRect.midX - 4, y: centerY - 6))
            indicatorPath.addLine(to: CGPoint(x: handleRect.midX, y: centerY))
            indicatorPath.addLine(to: CGPoint(x: handleRect.midX - 4, y: centerY + 6))
            indicatorPath.move(to: CGPoint(x: handleRect.midX + 4, y: centerY - 6))
            indicatorPath.addLine(to: CGPoint(x: handleRect.midX, y: centerY))
            indicatorPath.addLine(to: CGPoint(x: handleRect.midX + 4, y: centerY + 6))
        }
        UIColor.white.setStroke()
        indicatorPath.lineWidth = 2
        indicatorPath.stroke()
        
        context.restoreGState()
    }
    
    private func drawRegionMarkers(in rect: CGRect) {
        let label1 = "A4-1"
        let label2 = "A4-2"
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 14),
            .foregroundColor: UIColor.white.withAlphaComponent(0.8)
        ]
        
        let shadow = NSShadow()
        shadow.shadowColor = UIColor.black.withAlphaComponent(0.5)
        shadow.shadowOffset = CGSize(width: 1, height: 1)
        shadow.shadowBlurRadius = 2
        
        var attributesWithShadow = attributes
        attributesWithShadow[.shadow] = shadow
        
        if documentOrientation == .landscape {
            let x = rect.width * cropPosition
            let size1 = label1.size(withAttributes: attributesWithShadow)
            let size2 = label2.size(withAttributes: attributesWithShadow)
            
            label1.draw(at: CGPoint(x: (x - size1.width) / 2, y: rect.height - 30), withAttributes: attributesWithShadow)
            label2.draw(at: CGPoint(x: x + (rect.width - x - size2.width) / 2, y: rect.height - 30), withAttributes: attributesWithShadow)
        } else {
            let y = rect.height * cropPosition
            let size1 = label1.size(withAttributes: attributesWithShadow)
            let size2 = label2.size(withAttributes: attributesWithShadow)
            
            label1.draw(at: CGPoint(x: rect.width - size1.width - 10, y: (y - size1.height) / 2), withAttributes: attributesWithShadow)
            label2.draw(at: CGPoint(x: rect.width - size2.width - 10, y: y + (rect.height - y - size2.height) / 2), withAttributes: attributesWithShadow)
        }
    }
    
    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        if isTouchOnHandle(location) {
            isDragging = true
            UIView.animate(withDuration: 0.1) {
                self.alpha = 0.8
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDragging, let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        let newPosition: CGFloat
        if documentOrientation == .landscape {
            newPosition = location.x / bounds.width
        } else {
            newPosition = location.y / bounds.height
        }
        
        cropPosition = newPosition
        delegate?.cropOverlayView(self, didChangeCropPosition: cropPosition)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isDragging {
            isDragging = false
            UIView.animate(withDuration: 0.1) {
                self.alpha = 1.0
            }
            delegate?.cropOverlayView(self, didEndChangingCropPosition: cropPosition)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isDragging = false
        UIView.animate(withDuration: 0.1) {
            self.alpha = 1.0
        }
    }
    
    private func isTouchOnHandle(_ location: CGPoint) -> Bool {
        let handleRect: CGRect
        
        if documentOrientation == .landscape {
            let x = bounds.width * cropPosition
            let y = bounds.height / 2 - handleHeight / 2
            handleRect = CGRect(x: x - handleWidth, y: y - 10, width: handleWidth * 2, height: handleHeight + 20)
        } else {
            let y = bounds.height * cropPosition
            let x = bounds.width / 2 - handleHeight / 2
            handleRect = CGRect(x: x - 10, y: y - handleWidth, width: handleHeight + 20, height: handleWidth * 2)
        }
        
        return handleRect.contains(location)
    }
}
