//
//  MenuContents.swift
//  ToolKit
//
//  Created by Simeon Saint-Saens on 3/12/18.
//  Copyright © 2018 Two Lives Left. All rights reserved.
//

import UIKit
import SnapKit

extension UIScrollView {
    var maxContentOffset: CGPoint {
        return CGPoint(x: contentSize.width - bounds.size.width, y: contentSize.height - bounds.size.height + contentInset.bottom)
    }
}

class MenuContents: UIView {
    
    typealias MenuViewType = MenuItem.MenuViewType
    
    private let maxHeight: CGFloat
    private let shadowView = UIView()
    private let tintView = UIView()
    private let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
    private let scrollContainer = UIView()
    private let scrollView = UIScrollView()
    
    var highlightChanged: () -> Void = {}
    
    let stackView: UIStackView
    
    private let titleLabel = UILabel()
    private let imageView = UIImageView()
    
    private let radius: CGFloat
    
    private var edgeScrollTimer: Timer?
    
    private var verticalAlignment: MenuView.VerticalAlignment
    
    private var menuItemViews: [MenuViewType] {
        get {
            return stackView.subviews.compactMap {
                $0 as? MenuViewType
            }
        }
    }
    
    var items: [MenuItem] {
        didSet {
            //Diff the stack view
        }
    }
    
    var title: MenuView.Title? {
        get {
            let title: MenuView.Title?
            if let text = titleLabel.text {
                title = .text(text)
            } else if let image = imageView.image {
                title = .image(image)
            } else {
                title = nil
            }
            
            return title
        }
        set {
            switch newValue {
            case .text(let text)?:
                titleLabel.text = text
            case .image(let image)?:
                imageView.image = image
            case nil:
                titleLabel.text = nil
                imageView.image = nil
            }
        }
    }
    
    var highlightedPosition: CGPoint? {
        didSet {
            let pos = highlightedPosition ?? CGPoint(x: CGFloat.infinity, y: CGFloat.infinity)
            updateHighlightedPosition(pos)
        }
    }
    
    var isInteractiveDragActive: Bool = false {
        didSet {
            if isInteractiveDragActive == false {
                edgeScrollTimer?.invalidate()
                edgeScrollTimer = nil
            }
        }
    }
    
    private var isScrollable: Bool {
        return scrollView.contentSize.height > scrollView.bounds.size.height
    }
    
    private func pointIsInsideBottomEdgeScrollingBoundary(_ point: CGPoint) -> Bool {
        return point.y > scrollView.bounds.size.height - 24 && isScrollable
    }
    
    private func pointIsInsideTopEdgeScrollingBoundary(_ point: CGPoint) -> Bool {
        return point.y < 70 && isScrollable
    }
    
    private func updateHighlightedPosition(_ point: CGPoint) {
        let point = CGPoint(x: point.x, y: point.y < 0 ? point.y + scrollContainer.bounds.height : point.y)
        
        menuItemViews.forEach {
            var view = $0
            
            let point = convert(point, to: $0)
            let contains = $0.point(inside: point, with: nil)
            
            view.highlighted = contains
            view.highlightPosition = point
        }
        
        let pointInsideBoundary = pointIsInsideTopEdgeScrollingBoundary(point) || pointIsInsideBottomEdgeScrollingBoundary(point)
        
        if pointInsideBoundary && edgeScrollTimer == nil && isInteractiveDragActive {
            edgeScrollTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true, block: {
                [weak self] _ in
                
                guard let self = self else {
                    return
                }
                
                let highlightedPosition = self.highlightedPosition ?? .zero
                let point = CGPoint(x: highlightedPosition.x, y: highlightedPosition.y < 0 ? highlightedPosition.y + self.scrollContainer.bounds.height : highlightedPosition.y)
                let offsetAmount: CGFloat = 2
                
                if self.pointIsInsideBottomEdgeScrollingBoundary(point) {
                    var offset = self.scrollView.contentOffset
                    offset.y += offsetAmount
                    
                    let maxOffset = self.scrollView.maxContentOffset
                    
                    if offset.y < maxOffset.y {
                        self.scrollView.contentOffset = offset
                    }
                }
                
                if self.pointIsInsideTopEdgeScrollingBoundary(point) {
                    var offset = self.scrollView.contentOffset
                    offset.y -= offsetAmount
                    
                    let minOffset = -self.scrollView.contentInset.top
                    
                    if offset.y > minOffset {
                        self.scrollView.contentOffset = offset
                    }
                }
                
                self.updateHighlightedPosition(point)
            })
        } else if !pointInsideBoundary {
            edgeScrollTimer?.invalidate()
            edgeScrollTimer = nil
        }
    }
    
    func selectPosition(_ point: CGPoint, completion: @escaping (MenuItem) -> Void) {
        menuItemViews.enumerated().forEach {
            index, view in
            
            let point = convert(point, to: view)
            if view.point(inside: point, with: nil) {
                var view = view
                view.highlighted = true
                view.highlightPosition = point
                
                view.startSelectionAnimation {
                    [weak self] in
                    if let self = self {
                        completion(self.items[index])
                    }
                }
            }
        }
    }
    
    init(title: MenuView.Title, items: [MenuItem], theme: MenuTheme, maxHeight: CGFloat = 300, radius: CGFloat = 8.0, verticalAlignment: MenuView.VerticalAlignment) {

        let itemViews: [MenuViewType] = items.map {
            let item = $0.view
            item.applyTheme(theme)
            return item
        }
        
        stackView = UIStackView(arrangedSubviews: itemViews)
        imageView.contentMode = .scaleAspectFit
        
        self.maxHeight = maxHeight
        self.items = items
        self.radius = radius
        self.verticalAlignment = verticalAlignment
        
        super.init(frame: .zero)
        
        addSubview(shadowView)
        
        shadowView.snp.makeConstraints {
            make in
            
            make.edges.equalToSuperview().inset(-20)
        }
        
        addSubview(effectView)
        
        effectView.snp.makeConstraints {
            make in
            
            make.edges.equalToSuperview()
        }
        
        effectView.contentView.addSubview(tintView)
        effectView.contentView.addSubview(titleLabel)
        effectView.contentView.addSubview(imageView)
        effectView.contentView.addSubview(scrollContainer)
        
        scrollContainer.addSubview(scrollView)
        scrollView.addSubview(stackView)
        
        scrollContainer.snp.makeConstraints {
            make in
            make.edges.equalToSuperview()
        }
        
        scrollView.snp.makeConstraints {
            make in
            
            make.edges.equalToSuperview()
            make.height.equalTo(maxHeight)
        }
        
        tintView.snp.makeConstraints {
            make in
            
            make.edges.equalToSuperview()
        }
        
        stackView.snp.makeConstraints {
            make in
            
            make.top.bottom.equalToSuperview()
            if #available(iOS 11.0, *) {
                make.left.right.equalTo(scrollView.frameLayoutGuide)
            } else {
                make.left.right.equalTo(self)
            }
        }
        
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .equalSpacing
        stackView.spacing = 0
        
        menuItemViews.forEach {
            var item = $0
            
            item.didHighlight = {
                [weak self] in
                self?.highlightChanged()
            }
        }
        
        applyTheme(theme)
        
        defer {
            self.title = title
        }
    }
    
    private func computePath(withParentView view: UIView,
                             horizontalAlignment: MenuView.HorizontalAlignment,
                             verticalAlignment: MenuView.VerticalAlignment) -> UIBezierPath {
        let localViewBounds: CGRect
        let mainRectCorners: UIRectCorner
        
        switch (horizontalAlignment, verticalAlignment) {
        case (.center, .bottom):
            localViewBounds = view.bounds.offsetBy(dx: bounds.size.width/2.0 - view.bounds.size.width/2.0, dy: 0.0)
            mainRectCorners = .allCorners
        case (.right, .bottom):
            localViewBounds = view.bounds
            mainRectCorners = [.topRight, .bottomLeft, .bottomRight]
        case (.left, .bottom):
            localViewBounds = view.bounds.offsetBy(dx: bounds.size.width - view.bounds.size.width, dy: 0.0)
            mainRectCorners = [.topLeft, .bottomLeft, .bottomRight]
        case (.center, .top):
            localViewBounds = view.bounds.offsetBy(dx: bounds.size.width/2.0 - view.bounds.size.width/2.0, dy: bounds.height - view.bounds.height)
            mainRectCorners = .allCorners
        case (.right, .top):
            localViewBounds = view.bounds.offsetBy(dx: 0, dy: bounds.height - view.bounds.height)
            mainRectCorners = [.bottomRight, .topLeft, .topRight]
        case (.left, .top):
            localViewBounds = view.bounds.offsetBy(dx: bounds.size.width - view.bounds.size.width, dy: bounds.height - view.bounds.height)
            mainRectCorners = [.bottomLeft, .topLeft, .topRight]
        }
        
        let parentPathRectCorners: UIRectCorner
        switch verticalAlignment {
        case .bottom:
            parentPathRectCorners = [.topLeft, .topRight]
        case .top:
            parentPathRectCorners = [.bottomLeft, .bottomRight]
        }
        
        let parentPath = UIBezierPath(roundedRect: localViewBounds, byRoundingCorners: parentPathRectCorners, cornerRadii: CGSize(width: radius, height: radius))
        
        let midPath = UIBezierPath()
        
        switch (horizontalAlignment, verticalAlignment) {
        case (.center, .bottom):
            midPath.move(to: CGPoint(x: localViewBounds.minX, y: localViewBounds.maxY))
            midPath.addLine(to: CGPoint(x: localViewBounds.maxX, y: localViewBounds.maxY))
            midPath.addArc(withCenter: CGPoint(x: localViewBounds.maxX + radius, y: localViewBounds.maxY), radius: radius, startAngle: .pi, endAngle: .pi/2.0, clockwise: false)
            midPath.addLine(to: CGPoint(x: localViewBounds.minX - radius, y: localViewBounds.maxY + radius))
            midPath.addArc(withCenter: CGPoint(x: localViewBounds.minX - radius, y: localViewBounds.maxY), radius: radius, startAngle: .pi/2.0, endAngle: 0.0, clockwise: false)
        case (.right, .bottom):
            midPath.move(to: CGPoint(x: localViewBounds.minX, y: localViewBounds.maxY))
            midPath.addLine(to: CGPoint(x: localViewBounds.maxX, y: localViewBounds.maxY))
            midPath.addArc(withCenter: CGPoint(x: localViewBounds.maxX + radius, y: localViewBounds.maxY), radius: radius, startAngle: .pi, endAngle: .pi/2.0, clockwise: false)
            midPath.addLine(to: CGPoint(x: localViewBounds.minX, y: localViewBounds.maxY + radius))
        case (.left, .bottom):
            midPath.move(to: CGPoint(x: localViewBounds.minX, y: localViewBounds.maxY))
            midPath.addLine(to: CGPoint(x: localViewBounds.maxX, y: localViewBounds.maxY))
            midPath.addLine(to: CGPoint(x: localViewBounds.maxX, y: localViewBounds.maxY + radius))
            midPath.addLine(to: CGPoint(x: localViewBounds.minX - radius, y: localViewBounds.maxY + radius))
            midPath.addArc(withCenter: CGPoint(x: localViewBounds.minX - radius, y: localViewBounds.maxY), radius: radius, startAngle: .pi/2.0, endAngle: 0.0, clockwise: false)
        case (.center, .top):
            midPath.move(to: CGPoint(x: localViewBounds.minX, y: localViewBounds.minY))
            midPath.addLine(to: CGPoint(x: localViewBounds.maxX, y: localViewBounds.minY))
            midPath.addArc(withCenter: CGPoint(x: localViewBounds.maxX + radius, y: localViewBounds.minY), radius: radius, startAngle: .pi, endAngle: .pi*1.5, clockwise: true)
            midPath.addLine(to: CGPoint(x: localViewBounds.minX + radius, y: localViewBounds.minY - radius))
            midPath.addArc(withCenter: CGPoint(x: localViewBounds.minX - radius, y: localViewBounds.minY), radius: radius, startAngle: .pi*1.5, endAngle: 0, clockwise: true)
        case (.right, .top):
            midPath.move(to: CGPoint(x: localViewBounds.minX, y: localViewBounds.minY))
            midPath.addLine(to: CGPoint(x: localViewBounds.maxX, y: localViewBounds.minY))
            midPath.addArc(withCenter: CGPoint(x: localViewBounds.maxX + radius, y: localViewBounds.minY), radius: radius, startAngle: .pi, endAngle: .pi*1.5, clockwise: true)
            midPath.addLine(to: CGPoint(x: localViewBounds.minX, y: localViewBounds.minY - radius))
        case (.left, .top):
            midPath.move(to: CGPoint(x: localViewBounds.minX, y: localViewBounds.minY))
            midPath.addLine(to: CGPoint(x: localViewBounds.maxX, y: localViewBounds.minY))
            midPath.addLine(to: CGPoint(x: localViewBounds.maxX, y: localViewBounds.minY - radius))
            midPath.addLine(to: CGPoint(x: localViewBounds.minX - radius, y: localViewBounds.minY - radius))
            midPath.addArc(withCenter: CGPoint(x: localViewBounds.minX - radius, y: localViewBounds.minY), radius: radius, startAngle: .pi*1.5, endAngle: 0.0, clockwise: true)
        }
        
        midPath.close()
        
        let yOffset: CGFloat
        let localViewHeight: CGFloat
        switch verticalAlignment {
        case .bottom:
            yOffset = localViewBounds.maxY + radius
            localViewHeight = yOffset
        case .top:
            yOffset = 0
            localViewHeight = localViewBounds.height + radius
        }
        let mainPath = UIBezierPath(roundedRect: CGRect(x: 0, y: yOffset, width: bounds.size.width, height: bounds.size.height - localViewHeight), byRoundingCorners: mainRectCorners, cornerRadii: CGSize(width: radius, height: radius))
        
        parentPath.append(midPath)
        parentPath.append(mainPath)
        
        return parentPath
    }
    
    func pointInsideMenuShape(_ point: CGPoint) -> Bool {
        let contentsPoint = convert(point, to: scrollContainer)
        
        return scrollContainer.bounds.contains(contentsPoint)
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        guard let superview = superview else {
            return
        }
        
        //We're rendering under the superview, so let's do that
        titleLabel.snp.remakeConstraints {
            make in
            
            make.center.equalTo(superview)
        }
        
        imageView.snp.remakeConstraints { maker in
            maker.left.right.equalTo(superview).inset(12)
            switch verticalAlignment {
            case .bottom:
                maker.top.equalTo(superview).offset(8)
                maker.bottom.equalTo(superview).offset(-12)
            case .top:
                maker.top.equalTo(superview).offset(12)
                maker.bottom.equalTo(superview).offset(-8)
            }
        }
        
        let scrollInset: UIEdgeInsets
        switch verticalAlignment {
        case .bottom:
            scrollInset = UIEdgeInsets(top: radius + 6, left: 0, bottom: 6, right: 0)
        case .top:
            scrollInset = UIEdgeInsets(top: radius + 6, left: 0, bottom: radius + 6, right: 0)
        }
        
        scrollView.scrollIndicatorInsets = scrollInset
        scrollView.contentInset = scrollInset
        
        let insetAdjustment = scrollView.contentInset.top + scrollView.contentInset.bottom
        
        scrollContainer.snp.remakeConstraints {
            make in
            
            make.left.right.equalToSuperview()
            switch verticalAlignment {
            case .bottom:
                make.bottom.equalToSuperview()
                make.top.equalTo(superview.snp.bottom)
            case .top:
                make.top.equalToSuperview()
                make.bottom.equalTo(superview.snp.top)
            }
        }
        
        scrollView.snp.remakeConstraints {
            make in
            
            make.width.greaterThanOrEqualTo(superview.snp.width).offset(100)
            make.bottom.equalToSuperview()
            make.height.equalTo(stackView).offset(insetAdjustment).priority(.low)
            make.height.lessThanOrEqualTo(maxHeight).priority(.required)
            make.top.left.right.equalToSuperview()
        }
        
        applyContentMask()
    }
    
    func focusInitialViewIfNecessary() {
        for item in stackView.arrangedSubviews {
            
            if let item = item as? MenuViewType,
                let rect = item.initialFocusedRect {
                
                let updatedRect = item.convert(rect, to: scrollView)
                scrollView.scroll(toVisible: updatedRect, animated: false)
                
                break
            }
            
        }
    }
    
    func generateMaskAndShadow(horizontalAlignment: MenuView.HorizontalAlignment, verticalAlignment: MenuView.VerticalAlignment) {
        guard let view = superview else {
            return
        }
        
        let path = computePath(withParentView: view, horizontalAlignment: horizontalAlignment, verticalAlignment: verticalAlignment)
        
        //Mask effect view
        let shapeMask = CAShapeLayer()
        shapeMask.path = path.cgPath
        effectView.layer.mask = shapeMask
        
        //Create inverse mask for shadow layer
        path.apply(CGAffineTransform(translationX: 20, y: 20))
        
        let sublayer = shadowView.layer
        
        sublayer.shadowPath = path.cgPath
        sublayer.shadowOffset = CGSize(width: 0, height: 6)
        
        let imageRenderer = UIGraphicsImageRenderer(size: shadowView.bounds.size)
        
        let shadowMask = imageRenderer.image {
            context in
            
            UIColor.white.setFill()
            context.fill(shadowView.bounds)
            path.fill(with: .clear, alpha: 1.0)
        }
        
        let imageMask = CALayer()
        imageMask.frame = shadowView.bounds
        imageMask.contents = shadowMask.cgImage
        
        sublayer.mask = imageMask
        
        if verticalAlignment == .top {
            scrollView.setContentOffset(scrollView.maxContentOffset, animated: false)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func applyTheme(_ theme: MenuTheme) {
        titleLabel.font = theme.font
        titleLabel.textColor = theme.textColor
        effectView.effect = theme.blurEffect
        tintView.backgroundColor = theme.backgroundTint
        
        shadowView.layer.shadowOpacity = theme.shadowOpacity
        shadowView.layer.shadowRadius = theme.shadowRadius
        shadowView.layer.shadowColor = theme.shadowColor.cgColor
    }
    
    //MARK: - Content Masking
    
    override var frame: CGRect {
        didSet {
            updateContentMask()
        }
    }
    
    override var bounds: CGRect {
        didSet {
            updateContentMask()
        }
    }
    
    func updateContentMask() {
        if let maskLayer = scrollContainer.layer.mask as? CAGradientLayer {
            maskLayer.frame = bounds
            
            let height = bounds.size.height
            let stop2 = 12 / height
            
            maskLayer.startPoint = CGPoint(x: 0.5, y: 0)
            maskLayer.endPoint = CGPoint(x: 0.5, y: stop2)
        }
    }
    
    private func applyContentMask() {
        let maskLayer = CAGradientLayer()
        
        maskLayer.frame = bounds
        maskLayer.colors = [UIColor.clear.cgColor, UIColor.clear.cgColor, UIColor.white.cgColor]
        maskLayer.locations = [0, 0.72, 1.0]
        maskLayer.startPoint = CGPoint(x: 0.5, y: 0)
        maskLayer.endPoint = CGPoint(x: 0.5, y: 0.33)
        
        scrollContainer.layer.mask = maskLayer
    }
}


