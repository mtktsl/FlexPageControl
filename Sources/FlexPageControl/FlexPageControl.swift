import UIKit

enum Constants {
    static let maxVisibleDotCount: Int = 3
    static let midVisibleDotCount: Int = 2
}

public protocol FlexPageControlDelegate: AnyObject {
    func onValueChange(_ sender: FlexPageControl, oldValue: Int, newValue: Int, didTap: Bool)
}

public class FlexPageControl: UIControl {
    
    public weak var delegate: FlexPageControlDelegate?
    
    public var currentValue: Int = 0 {
        didSet {
            currentValue = min(max(currentValue, 0), max(numberOfPages-1, 0))
            changeSelectedDot(
                oldValue: oldValue,
                newValue: currentValue
            )
            delegate?.onValueChange(self, oldValue: oldValue, newValue: currentValue, didTap: valueChangeOnTap)
            valueChangeOnTap = false
        }
    }
    public var numberOfPages: Int = 0 {
        didSet {
            generateDots()
            setNeedsLayout()
        }
    }
    
    public var currentDotFlexWidth: CGFloat = 0
    
    private var dotFlexWidth: CGFloat {
        return currentDotFlexWidth > 0
        ? currentDotFlexWidth
        : 2 * dotSize + dotSpacing
    }
    
    private lazy var lastFlexWidth: CGFloat = dotFlexWidth
    private var lastFlexXPos: CGFloat = .zero
    
    private var dotCount: Int {
        if numberOfPages <= 0 {
            return 0
        } else if numberOfPages == 1 {
            return 1
        } else {
            return 3
        }
    }
    
    private var isMiddle: Bool {
        return currentValue != .zero && currentValue != numberOfPages-1
    }
    
    public var dotSize: CGFloat = 15 {
        didSet {
            setNeedsLayout()
        }
    }
    
    public var animationSpeed: Double = 0.3
    
    public var dotSpacing: CGFloat = 15
    public var dotScaleFactor: CGFloat = 1
    
    public var pageIndicatorTintColor: UIColor = .lightGray
    public var pageIndicatorBorderColor: UIColor = .darkGray
    
    public var currentPageIndicatorTintColor: UIColor = .gray
    public var currentPageIndicatorBorderColor: UIColor = .darkGray
    
    public var pageIndicatorBorderWidth: CGFloat = 2
    public var currentPageIndicatorBorderWidth: CGFloat = 1
    
    private var dots = [UIView]()
    private let dotContainerView = UIView()
    private var dotContainerWidthConstraint: NSLayoutConstraint?
    private var dotContainerHeightConstraint: NSLayoutConstraint?
    
    private var isSwiped = false
    private var valueChangeOnTap = false
    
    public init() {
        super.init(frame: .zero)
        setupDotContainer()
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupDotContainer()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        setDotContainerSize()
        alignDots()
        setDotCornerRadius()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented for FlexPageControl")
    }
    
    public override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        super.beginTracking(touch, with: event)
        isSwiped = false
        return true
    }
    
    public override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        super.continueTracking(touch, with: event)
        
        let xPos = touch.location(in: self).x
        let xPer = xPos / self.frame.size.width
        valueChangeOnTap = true
        currentValue = Int(CGFloat(numberOfPages) * xPer)
        isSwiped = true
        
        return true
    }
    
    public override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        super.endTracking(touch, with: event)
        if isSwiped { return }
        
        valueChangeOnTap = true
        if (touch?.location(in: self).x ?? 0) > self.frame.midX {
            currentValue += 1
        } else {
            currentValue -= 1
        }
    }
    
    private func generateSingleDot() -> UIView {
        let dot = UIView()
        dot.backgroundColor = pageIndicatorTintColor
        dot.layer.borderWidth = pageIndicatorBorderWidth
        dot.layer.borderColor = pageIndicatorBorderColor.cgColor
        dot.isUserInteractionEnabled = false
        return dot
    }
    
    private func resetDots() {
        for dot in dots {
            dot.removeFromSuperview()
        }
        dots = []
    }
    
    private func generateDots() {
        resetDots()
        for _ in 0 ..< dotCount {
            let dot = generateSingleDot()
            dots.append(dot)
            dotContainerView.addSubview(dot)
        }
        if dotCount > 1 {
            dots[1].layer.zPosition = 1
        }
    }
    
    private func alignDots() {
        for (index, dot) in dots.enumerated() {
            align(dot: dot, at: index)
        }
        setupSelectedDot()
    }
    
    private func align(dot: UIView, at index: Int) {
        
        if index == 0 {
            alignFirstDot(dot)
        } else {
            let xLocation = CGFloat(index) * (dotSize + dotSpacing)
            dot.frame = CGRect(
                x: xLocation,
                y: .zero,
                width: dotSize,
                height: dotSize
            )
        }
    }
    
    private func alignFirstDot(_ dot: UIView) {
        dot.frame = CGRect(
            origin: .zero,
            size: .init(
                width: dotSize,
                height: dotSize
            )
        )
    }
    
    private func setupDotContainer() {
        dotContainerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dotContainerView)
        NSLayoutConstraint.activate([
            dotContainerView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            dotContainerView.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
        dotContainerView.isUserInteractionEnabled = false
    }
    
    private func setDotContainerSize() {
        var dotCount = 0
        if numberOfPages < 0 {
            dotCount = 0
        } else if numberOfPages == 1 {
            dotCount = 1
        } else {
            dotCount = 3
        }
        dotContainerWidthConstraint?.isActive = false
        var calculatedWidth = CGFloat(dotCount) * dotSize
        calculatedWidth += CGFloat(min(max(dotCount-1, 0), Constants.maxVisibleDotCount)) * dotSpacing
        dotContainerWidthConstraint = dotContainerView.widthAnchor.constraint(
            equalToConstant: calculatedWidth
        )
        dotContainerWidthConstraint?.isActive = true
        
        dotContainerHeightConstraint?.isActive = false
        dotContainerHeightConstraint = dotContainerView.heightAnchor.constraint(
            equalToConstant: dotSize
        )
        dotContainerHeightConstraint?.isActive = true
    }
    
    private func setDotCornerRadius() {
        for dot in dots {
            dot.layer.cornerRadius = dotSize / 2
        }
    }
    
    private func changeSelectedDot(oldValue: Int, newValue: Int) {
        
        if oldValue == .zero && newValue > oldValue {
            if isMiddle {
                moveFlextToMiddle()
            } else {
                moveFlextToMiddle() { [weak self] in
                    self?.moveFlexToRight()
                }
            }
        } else if oldValue == numberOfPages-1 && newValue < oldValue {
            if isMiddle {
                moveFlextToMiddle()
            } else {
                moveFlextToMiddle() { [weak self] in
                    self?.moveFlexToLeft()
                }
            }
        } else if newValue > oldValue {
            if isMiddle {
                moveFlexToRight() { [weak self] in
                    self?.moveFlextToMiddle()
                }
            } else {
                moveFlexToRight()
            }
        } else if newValue < oldValue {
            if isMiddle {
                moveFlexToLeft() { [weak self] in
                    self?.moveFlextToMiddle()
                }
            } else {
                moveFlexToLeft()
            }
        }
    }
    
    private func moveFlexToLeft(completion: (() -> Void)? = nil) {
        setFlex(
            xPos: .zero,
            width: dotFlexWidth,
            duration: animationSpeed,
            endingClosure: completion
        )
    }
    
    private func moveFlextToMiddle(completion: (() -> Void)? = nil) {
        setFlex(
            xPos: dotSize + dotSpacing,
            width: dotSize,
            duration: animationSpeed,
            endingClosure: completion
        )
    }
    
    private func moveFlexToRight(completion: (() -> Void)? = nil) {
        setFlex(
            xPos: dotSize + dotSpacing,
            width: dotFlexWidth,
            duration: animationSpeed,
            endingClosure: completion
        )
    }
    
    private func setFlex(
        xPos: CGFloat,
        width: CGFloat,
        duration: Double,
        endingClosure: (() -> Void)? = nil
    ) {
        UIView.animate(withDuration: duration) { [weak self] in
            guard let self else { return }
            dots[1].frame.origin.x = xPos
            dots[1].frame.size.width = width
            dots[1].setNeedsLayout()
        } completion: { success in
            endingClosure?()
        }
        
        lastFlexWidth = width
        lastFlexXPos = xPos
    }
    
    private func setupSelectedDot() {
        if dotCount == 1 {
            dots[0].bounds.size.width = dotFlexWidth
            dots[0].setNeedsLayout()
        } else {
            dots[1].frame.origin.x = lastFlexXPos
            dots[1].frame.size.width = lastFlexWidth
            
            dots[1].backgroundColor = currentPageIndicatorTintColor
            dots[1].layer.borderColor = currentPageIndicatorBorderColor.cgColor
            dots[1].layer.borderWidth = currentPageIndicatorBorderWidth
            
            dots[1].setNeedsLayout()
        }
    }
}
