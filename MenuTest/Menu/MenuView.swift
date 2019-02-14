//
//  MenuView.swift
//  Menus
//
//  Created by Simeon on 2/6/18.
//  Copyright © 2018 Two Lives Left. All rights reserved.
//

import UIKit
import SnapKit

//MARK: - MenuView

open class MenuView: UIView, MenuThemeable, UIGestureRecognizerDelegate {
    public enum Title {
        case text(String)
        case image(UIImage)
    }
    
    public static let menuWillPresent = Notification.Name("CodeaMenuWillPresent")
    
    private let titleLabel = UILabel()
    private let imageView = UIImageView()
    private let gestureBarView = UIView()
    private let tintView = UIView()
    private let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
    private let feedback = UISelectionFeedbackGenerator()
    
    public var title: Title {
        didSet {
            switch title {
            case .text(let text):
                titleLabel.text = text
            case .image(let image):
                imageView.image = image
            }
            
            contents?.title = title
        }
    }
    
    private var menuPresentationObserver: Any!
    
    private var contents: MenuContents?
    private var theme: MenuTheme
    private var longPress: UILongPressGestureRecognizer!
    private var tapGesture: UITapGestureRecognizer!
    
    public var itemsSource: (() -> [MenuItem])?
    
    public enum HorizontalAlignment {
        case left
        case center
        case right
    }
    
    public enum VerticalAlignment {
        case bottom
        case top
    }
    
    public var horizontalContentAlignment = HorizontalAlignment.right {
        didSet {
            titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        }
    }
    
    public var verticalContentAlignment = VerticalAlignment.bottom {
        didSet {
            relayoutGestureBar()
        }
    }
    
    public init(title: Title, theme: MenuTheme, itemsSource: (() -> [MenuItem])? = nil) {
        self.itemsSource = itemsSource
        self.title = title
        self.theme = theme
        
        super.init(frame: .zero)
        
        titleLabel.textColor = theme.darkTintColor
        titleLabel.textAlignment = .center
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        
        imageView.contentMode = .scaleAspectFit
        
        switch title {
        case .text(let text):
            titleLabel.text = text
        case .image(let image):
            imageView.image = image
        }
        
        let clippingView = UIView()
        clippingView.clipsToBounds = true
        
        addSubview(clippingView)
        
        clippingView.snp.makeConstraints {
            make in
            
            make.edges.equalToSuperview()
        }
        
        clippingView.layer.cornerRadius = 8.0
        
        clippingView.addSubview(effectView)
        
        effectView.snp.makeConstraints {
            make in
            
            make.edges.equalToSuperview()
        }
        
        effectView.contentView.addSubview(tintView)
        effectView.contentView.addSubview(titleLabel)
        effectView.contentView.addSubview(imageView)
        effectView.contentView.addSubview(gestureBarView)
        
        tintView.snp.makeConstraints {
            make in
            
            make.edges.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints {
            make in
            
            make.left.right.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
        }
        
        imageView.snp.remakeConstraints { maker in
            maker.left.right.equalToSuperview().inset(12)
            maker.width.greaterThanOrEqualTo(imageView.snp.height)
            switch verticalContentAlignment {
            case .bottom:
                maker.top.equalToSuperview().offset(8)
                maker.bottom.equalToSuperview().offset(-12)
            case .top:
                maker.top.equalToSuperview().offset(12)
                maker.bottom.equalToSuperview().offset(-8)
            }
        }
        
        gestureBarView.layer.cornerRadius = 1.0
        gestureBarView.snp.makeConstraints {
            make in
            
            make.centerX.equalToSuperview()
            make.height.equalTo(2)
            make.width.equalTo(20)
            switch verticalContentAlignment {
            case .bottom:
                make.bottom.equalToSuperview().inset(3)
            case .top:
                make.top.equalToSuperview().inset(3)
            }
        }
        
        longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressGesture(_:)))
        longPress.minimumPressDuration = 0.0
        longPress.delegate = self
        addGestureRecognizer(longPress)
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
        tapGesture.delegate = self
        addGestureRecognizer(tapGesture)
        
        applyTheme(theme)
        
        menuPresentationObserver = NotificationCenter.default.addObserver(forName: MenuView.menuWillPresent, object: nil, queue: nil) {
            [weak self] notification in
            
            if let poster = notification.object as? MenuView, let this = self, poster !== this {
                self?.hideContents(animated: false)
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(menuPresentationObserver)
    }
    
    //MARK: - Required Init
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Gesture Handling
    
    private var gestureStart: Date = .distantPast
    
    @objc private func longPressGesture(_ sender: UILongPressGestureRecognizer) {
        
        //Highlight whatever we can
        if let contents = self.contents {
            let localPoint = sender.location(in: self)
            let contentsPoint = convert(localPoint, to: contents)
            
            if contents.pointInsideMenuShape(contentsPoint) {
                contents.highlightedPosition = CGPoint(x: contentsPoint.x, y: localPoint.y)
            }
        }

        switch sender.state {
        case .began:
            if !isShowingContents {
                gestureStart = Date()
                showContents()
            } else {
                gestureStart = .distantPast
            }
            
            contents?.isInteractiveDragActive = true
        case .cancelled:
            fallthrough
        case .ended:
            let gestureEnd = Date()
            
            contents?.isInteractiveDragActive = false
            
            if gestureEnd.timeIntervalSince(gestureStart) > 0.3 {
                selectPositionAndHideContents(sender)
            }
            
        default:
            ()
        }
    }
    
    @objc private func tapped(_ sender: UITapGestureRecognizer) {
        selectPositionAndHideContents(sender)
    }
    
    private func selectPositionAndHideContents(_ gesture: UIGestureRecognizer) {
        if let contents = contents {
            let point = convert(gesture.location(in: self), to: contents)
            
            if contents.point(inside: point, with: nil) {
                contents.selectPosition(point, completion: {
                    [weak self] menuItem in
                    
                    self?.hideContents(animated: true)
                    
                    menuItem.performAction()
                })
            } else {
                hideContents(animated: true)
            }
        }
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == longPress && otherGestureRecognizer == tapGesture {
            return true
        }
        return false
    }
    
    public func showContents() {
        NotificationCenter.default.post(name: MenuView.menuWillPresent, object: self)
        
        let contents = MenuContents(title: title, items: itemsSource?() ?? [], theme: theme, verticalAlignment: verticalContentAlignment)
        
        for view in contents.stackView.arrangedSubviews {
            if let view = view as? MenuItemView {
                var updatableView = view
                updatableView.updateLayout = {
                    [weak self] in
                    
                    self?.relayoutContents()
                }
            }
        }
        
        addSubview(contents)
        
        contents.snp.makeConstraints {
            make in
        
            switch horizontalContentAlignment {
            case .left:
                make.right.equalToSuperview()
            case .right:
                make.left.equalToSuperview()
            case .center:
                make.centerX.equalToSuperview()
            }
            
            switch verticalContentAlignment {
            case .bottom:
                make.top.equalToSuperview()
            case .top:
                make.bottom.equalToSuperview()
            }
        }
        
        effectView.isHidden = true
        
        longPress?.minimumPressDuration = 0.07
        
        self.contents = contents
        
        setNeedsLayout()
        layoutIfNeeded()
        
        contents.generateMaskAndShadow(horizontalAlignment: horizontalContentAlignment, verticalAlignment: verticalContentAlignment)
        contents.focusInitialViewIfNecessary()
        
        feedback.prepare()
        contents.highlightChanged = {
            [weak self] in
            
            self?.feedback.selectionChanged()
        }
    }
    
    public func hideContents(animated: Bool) {
        let contentsView = contents
        contents = nil
        
        longPress?.minimumPressDuration = 0.0
        
        effectView.isHidden = false
        
        if animated {
            UIView.animate(withDuration: 0.2, animations: {
                contentsView?.alpha = 0.0
            }) {
                finished in
                contentsView?.removeFromSuperview()
            }
        } else {
            contentsView?.removeFromSuperview()
        }
    }
    
    private var isShowingContents: Bool {
        return contents != nil
    }
    
    //MARK: - Relayout
    
    private func relayoutGestureBar() {
        gestureBarView.snp.remakeConstraints {
            make in
            
            make.centerX.equalToSuperview()
            make.height.equalTo(2)
            make.width.equalTo(20)
            switch verticalContentAlignment {
            case .bottom:
                make.bottom.equalToSuperview().inset(3)
            case .top:
                make.top.equalToSuperview().inset(3)
            }
        }
        
        imageView.snp.remakeConstraints { maker in
            maker.left.right.equalToSuperview().inset(12)
            maker.width.greaterThanOrEqualTo(imageView.snp.height)
            switch verticalContentAlignment {
            case .bottom:
                maker.top.equalToSuperview().offset(8)
                maker.bottom.equalToSuperview().offset(-12)
            case .top:
                maker.top.equalToSuperview().offset(12)
                maker.bottom.equalToSuperview().offset(-8)
            }
        }
    }
    
    private func relayoutContents() {
        if let contents = contents {
            setNeedsLayout()
            layoutIfNeeded()
            
            contents.generateMaskAndShadow(horizontalAlignment: horizontalContentAlignment, verticalAlignment: verticalContentAlignment)
        }
    }
    
    //MARK: - Hit Testing
    
    open override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard let contents = contents else {
            return super.point(inside: point, with: event)
        }
        
        let contentsPoint = convert(point, to: contents)
        
        if !contents.pointInsideMenuShape(contentsPoint) {
            hideContents(animated: true)
        }
        
        return contents.pointInsideMenuShape(contentsPoint)
    }
    
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let contents = contents else {
            return super.hitTest(point, with: event)
        }
        
        let contentsPoint = convert(point, to: contents)
        
        if !contents.pointInsideMenuShape(contentsPoint) {
            hideContents(animated: true)
        } else {
            return contents.hitTest(contentsPoint, with: event)
        }
        
        return super.hitTest(point, with: event)
    }
    
    //MARK: - Theming
    
    public func applyTheme(_ theme: MenuTheme) {
        self.theme = theme
        
        titleLabel.font = theme.font
        titleLabel.textColor = theme.darkTintColor
        gestureBarView.backgroundColor = theme.gestureBarTint
        tintView.backgroundColor = theme.backgroundTint
        effectView.effect = theme.blurEffect
        
        contents?.applyTheme(theme)
    }
}
