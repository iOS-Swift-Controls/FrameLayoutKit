//
//  FrameLayout.swift
//  FrameLayoutKit
//
//  Created by Nam Kennic on 7/12/18.
//

import UIKit

public enum NKContentVerticalAlignment {
	case center
	case top
	case bottom
	case fill
	case fit
}

public enum NKContentHorizontalAlignment {
	case center
	case left
	case right
	case fill
	case fit
}

/**
A single frameLayout handles size and position of a view
*/
open class FrameLayout: UIView {
	/// Target view that handled by this frameLayout
	public var targetView: UIView? = nil
	/// If set to `true`, sizeThatFits(size:) will returns `.zero` if `targetView` is hidden.
	public var ignoreHiddenView = true
	/// Padding edge insets
	public var edgeInsets: UIEdgeInsets = .zero
	/// Minimum size of frameLayout
	public var minSize: CGSize = .zero
	/// Maximum size of frameLayout
	public var maxSize: CGSize = .zero
	/// Minimum size of targetView
	public var minContentSize: CGSize = .zero
	/// Maximum size of targetView
	public var maxContentSize: CGSize = .zero
	public var verticalAlignment: NKContentVerticalAlignment = .fill
	public var horizontalAlignment: NKContentHorizontalAlignment = .fill
	/// The width of targetView will stretchs out to fill frameLayout if the width of this frameLayout is larger than targetView's width
	public var allowContentVerticalGrowing = false
	/// The width of targetView will shrinking down to fit frameLayout if the width of this frameLayout is smaller than targetView's width
	public var allowContentVerticalShrinking = false
	/// The height of targetView will stretchs out to fill frameLayout if the height of this frameLayout is larger than targetView's height
	public var allowContentHorizontalGrowing = false
	/// The height of targetView will shrinking down to fit frameLayout if the height of this frameLayout is smaller than targetView's height
	public var allowContentHorizontalShrinking = false
	/// Value of sizeThatFits will be cached based on targetView's memory address
	public var shouldCacheSize = false
	/// Make it flexible in a `StackFrameLayout`, that means when it was added to a stack, this flexible stack will be stretched base on the stack size
	public var isFlexible = false
	/// if `true`, sizeThatFits will returns the intrinsic width of targetView
	public var isIntrinsicSizeEnabled = true
	/// Returns height from sizeThatFits base on ratio of width. For example setting `1.0` will returns a square size from sizeThatFits
	public var heightRatio: CGFloat = 0 {
		didSet {
			if heightRatio > 0 {
				isIntrinsicSizeEnabled = false
			}
		}
	}
	
	/// Show the dash line of the frameLayout for debugging. This works in development mode only, release version will ignore this
	@available(*, deprecated, renamed: "debug")
	public var showFrameDebug: Bool {
		get { debug }
		set { debug = newValue}
	}
	
	/// Show the dash line of the frameLayout for debugging. This works in development mode only, release version will ignore this
	public var debug: Bool = false {
		didSet {
			setNeedsDisplay()
		}
	}
	
	/// Set the color of debug line
	public var debugColor: UIColor? = nil {
		didSet {
			setNeedsDisplay()
		}
	}
	
	/// Set the fix size of frameLayout
	public var fixSize: CGSize = .zero {
		didSet {
			minSize = fixSize
			maxSize = fixSize
		}
	}
	
	/// Set the fix size of targetView
	public var fixContentSize: CGSize = .zero {
		didSet {
			minContentSize = fixContentSize
			maxContentSize = fixContentSize
		}
	}
	
	@available(*, deprecated, renamed: "alignment")
	public var contentAlignment: (vertical: NKContentVerticalAlignment, horizontal: NKContentHorizontalAlignment) = (.fill, .fill) {
		didSet {
			verticalAlignment = contentAlignment.vertical
			horizontalAlignment = contentAlignment.horizontal
			
			setNeedsLayout()
		}
	}
	
	public var alignment: (vertical: NKContentVerticalAlignment, horizontal: NKContentHorizontalAlignment) = (.fill, .fill) {
		didSet {
			verticalAlignment = alignment.vertical
			horizontalAlignment = alignment.horizontal
			
			setNeedsLayout()
		}
	}
	
	@available(*, deprecated, message: "use `with` instead")
	public var configurationBlock: ((_ frameLayout: FrameLayout) -> Void)? = nil {
		didSet {
			configurationBlock?(self)
		}
	}
	
	/// Block will be called before calling sizeThatFits
	public var preSizeThatFitsConfigurationBlock: ((FrameLayout, CGSize) -> Void)?
	/// Block will be called before calling layoutSubviews
	public var preLayoutConfigurationBlock: ((FrameLayout) -> Void)?
	
	override open var frame: CGRect {
		get { super.frame }
		set {
			if newValue.isInfinite || newValue.isNull || newValue.origin.x.isNaN || newValue.origin.y.isNaN || newValue.size.width.isNaN || newValue.size.height.isNaN {
				return
			}
			
			super.frame = newValue
			setNeedsLayout()
			#if DEBUG
			if debug {
				setNeedsDisplay()
			}
			#endif
			
			if superview == nil {
				layoutIfNeeded()
			}
		}
	}
	
	override open var bounds: CGRect {
		get { super.bounds }
		set {
			if newValue.isInfinite || newValue.isNull || newValue.origin.x.isNaN || newValue.origin.y.isNaN || newValue.size.width.isNaN || newValue.size.height.isNaN {
				return
			}
			
			super.bounds = newValue
			setNeedsLayout()
			#if DEBUG
			if debug {
				setNeedsDisplay()
			}
			#endif
			
			if superview == nil {
				layoutIfNeeded()
			}
		}
	}
	
	open override var description: String {
		return "[\(super.description)]-targetView: \(String(describing: targetView))"
	}
	
	lazy fileprivate var sizeCacheData: [String: CGSize] = {
		return [:]
	}()
	
	internal var isEmpty: Bool {
		return ((targetView?.isHidden ?? false || isHidden) && ignoreHiddenView)
	}
	
	open override var intrinsicContentSize: CGSize {
		return contentSizeThatFits(size: bounds.size)
	}
	
	// MARK: -
	
	@discardableResult
	public convenience init(_ block: (FrameLayout) throws -> Void) rethrows {
		self.init()
		try block(self)
	}
	
	convenience public init(targetView: UIView? = nil) {
		self.init()
		self.targetView = targetView
	}
	
	public init() {
		super.init(frame: .zero)
		
		backgroundColor = .clear
		isUserInteractionEnabled = false
		isIntrinsicSizeEnabled = true
	}
	
	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	// MARK: -
	
	open func flexible() {
		isFlexible = true
	}
	
	open func padding(top: CGFloat = 0, left: CGFloat = 0, bottom: CGFloat = 0, right: CGFloat = 0) {
		edgeInsets = UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
	}
	
	open func addPadding(top: CGFloat = 0, left: CGFloat = 0, bottom: CGFloat = 0, right: CGFloat = 0) {
		edgeInsets = UIEdgeInsets(top: edgeInsets.top + top, left: edgeInsets.left + left, bottom: edgeInsets.bottom + bottom, right: edgeInsets.right + right)
	}
	
	#if DEBUG
	override open func draw(_ rect: CGRect) {
		guard debug else {
			super.draw(rect)
			return
		}
		
		if debugColor == nil {
			debugColor = randomColor()
		}
		
		guard let context = UIGraphicsGetCurrentContext() else { return }
		context.saveGState()
		context.setStrokeColor(debugColor!.cgColor)
		context.setLineDash(phase: 0, lengths: [4.0, 2.0])
		context.stroke(bounds)
		context.restoreGState()
	}
	
	fileprivate func randomColor() -> UIColor {
		let colors: [UIColor] = [.red, .green, .blue, .brown, .gray, .yellow, .magenta, .black, .orange, .purple, .cyan]
		let randomIndex = Int(arc4random()) % colors.count
		return colors[randomIndex]
	}
	#endif
	
	public func sizeThatFits(_ size: CGSize, intrinsic: Bool = true) -> CGSize {
		isIntrinsicSizeEnabled = intrinsic
		return sizeThatFits(size)
	}
	
	override open func sizeThatFits(_ size: CGSize) -> CGSize {
		preSizeThatFitsConfigurationBlock?(self, size)
		guard isEmpty == false else { return .zero }
		
		if minSize == maxSize && minSize.width > 0 && minSize.height > 0 { return minSize }
		
		var result: CGSize = .zero
		let verticalEdgeValues = edgeInsets.left + edgeInsets.right
		let horizontalEdgeValues = edgeInsets.top + edgeInsets.bottom
		let contentSize = CGSize(width: max(size.width - verticalEdgeValues, 0), height: max(size.height - horizontalEdgeValues, 0))
		
		if heightRatio > 0 {
			result.width = isIntrinsicSizeEnabled ? contentSizeThatFits(size: contentSize).width : contentSize.width
			result.height = result.width * heightRatio
		}
		else {
			result = contentSizeThatFits(size: contentSize)
			
			if !isIntrinsicSizeEnabled {
				result.width = contentSize.width
			}
		}
		
		result.width = max(minSize.width, result.width)
		result.height = max(minSize.height, result.height)
		
		if maxSize.width > 0 && maxSize.width >= minSize.width {
			result.width = min(maxSize.width, result.width)
		}
		if maxSize.height > 0 && maxSize.height >= minSize.height {
			result.height = min(maxSize.height, result.height)
		}
		
		if result.width > 0 {
			result.width += verticalEdgeValues
		}
		if result.height > 0 {
			result.height += horizontalEdgeValues
		}
		
		result.width = min(result.width, size.width)
		result.height = min(result.height, size.height)
		
		return result
	}
	
	override open func layoutSubviews() {
		preLayoutConfigurationBlock?(self)
		super.layoutSubviews()
		
		guard let targetView = targetView, !targetView.isHidden, !isHidden, bounds.size.width > 0, bounds.size.height > 0 else { return }
		
		var targetFrame: CGRect = .zero
		#if swift(>=4.2)
		let containerFrame = bounds.inset(by: edgeInsets)
		#else
		let containerFrame = UIEdgeInsetsInsetRect(bounds, edgeInsets)
		#endif
		var contentSize = horizontalAlignment != .fill || verticalAlignment != .fill ? contentSizeThatFits(size: containerFrame.size) : .zero
		if heightRatio > 0 {
			contentSize.height = contentSize.width * heightRatio
		}
		
		switch horizontalAlignment {
		case .left:
			if allowContentHorizontalGrowing {
				targetFrame.size.width = max(containerFrame.size.width, contentSize.width)
			}
			else if allowContentHorizontalShrinking {
				targetFrame.size.width = min(containerFrame.size.width, contentSize.width)
			}
			else {
				targetFrame.size.width = contentSize.width
			}
			
			targetFrame.origin.x = containerFrame.origin.x
			break
			
		case .right:
			if allowContentHorizontalGrowing {
				targetFrame.size.width = max(containerFrame.size.width, contentSize.width)
			}
			else if allowContentHorizontalShrinking {
				targetFrame.size.width = min(containerFrame.size.width, contentSize.width)
			}
			else {
				targetFrame.size.width = contentSize.width
			}
			
			targetFrame.origin.x = containerFrame.maxX - contentSize.width
			break
			
		case .center:
			if allowContentHorizontalGrowing {
				targetFrame.size.width = max(containerFrame.size.width, contentSize.width)
			}
			else if allowContentHorizontalShrinking {
				targetFrame.size.width = min(containerFrame.size.width, contentSize.width)
			}
			else {
				targetFrame.size.width = contentSize.width
			}
			
			targetFrame.origin.x = containerFrame.origin.x + (containerFrame.size.width - contentSize.width) / 2
			break
			
		case .fill:
			targetFrame.origin.x = containerFrame.origin.x
			targetFrame.size.width = containerFrame.size.width
			break
			
		case .fit:
			if allowContentHorizontalGrowing {
				targetFrame.size.width = max(containerFrame.size.width, contentSize.width)
			}
			else {
				targetFrame.size.width = min(containerFrame.size.width, contentSize.width)
			}
			
			targetFrame.origin.x = containerFrame.origin.x + (containerFrame.size.width - targetFrame.size.width) / 2
			break
			
		}
		
		switch verticalAlignment {
		case .top:
			if allowContentVerticalGrowing {
				targetFrame.size.height = max(containerFrame.size.height, contentSize.height)
			}
			else if allowContentVerticalShrinking {
				targetFrame.size.height = min(containerFrame.size.height, contentSize.height)
			}
			else {
				targetFrame.size.height = contentSize.height
			}
			
			targetFrame.origin.y = containerFrame.origin.y
			break
		
		case .bottom:
			if allowContentVerticalGrowing {
				targetFrame.size.height = max(containerFrame.size.height, contentSize.height)
			}
			else if allowContentVerticalShrinking {
				targetFrame.size.height = min(containerFrame.size.height, contentSize.height)
			}
			else {
				targetFrame.size.height = contentSize.height
			}
			
			targetFrame.origin.y = containerFrame.maxY - contentSize.height
			break
			
		case .center:
			if allowContentVerticalGrowing {
				targetFrame.size.height = max(containerFrame.size.height, contentSize.height)
			}
			else if allowContentVerticalShrinking {
				targetFrame.size.height = min(containerFrame.size.height, contentSize.height)
			}
			else {
				targetFrame.size.height = contentSize.height
			}
			
			targetFrame.origin.y = containerFrame.origin.y + (containerFrame.size.height - contentSize.height) / 2
			break
			
		case .fill:
			targetFrame.origin.y = containerFrame.origin.y
			targetFrame.size.height = containerFrame.size.height
			break
			
		case .fit:
			if allowContentVerticalGrowing {
				targetFrame.size.height = max(containerFrame.size.height, contentSize.height)
			}
			else {
				targetFrame.size.height = min(containerFrame.size.height, contentSize.height)
			}
			
			targetFrame.origin.y = containerFrame.origin.y + (containerFrame.size.height - targetFrame.size.height) / 2
			break
		}
	
		targetFrame = targetFrame.integral
		
		if targetView.superview == self {
			targetView.frame = targetFrame
		}
		else {
			if superview == nil || window == nil  {
				targetFrame.origin.x = frame.origin.x
				targetFrame.origin.y = frame.origin.y
				
				var superView: UIView? = superview
				while superView != nil && (superView is FrameLayout) {
					targetFrame.origin.x += superView!.frame.origin.x
					targetFrame.origin.y += superView!.frame.origin.y
					superView = superView!.superview
				}
				
				targetView.frame = targetFrame
			}
			else {
				targetView.frame = convert(targetFrame, to: targetView.superview)
			}
		}
	}
	
	open override func didMoveToWindow() {
		setNeedsLayout()
	}
	
	open override func didMoveToSuperview() {
		setNeedsLayout()
	}
	
	override open func setNeedsLayout() {
		super.setNeedsLayout()
		targetView?.setNeedsLayout()
	}
	
	override open func layoutIfNeeded() {
		super.layoutIfNeeded()
		targetView?.layoutIfNeeded()
	}
	
	// MARK: -
	
	fileprivate func addressOf<T: AnyObject>(_ o: T) -> String {
		let addr = unsafeBitCast(o, to: Int.self)
		return String(format: "%p", addr)
	}
	
	fileprivate func contentSizeThatFits(size: CGSize) -> CGSize {
		guard let targetView = targetView else { return .zero }
		
		if minContentSize == maxContentSize && minContentSize.width > 0 && minContentSize.height > 0 { return minContentSize }
		
		var result: CGSize
		
		if minSize == maxSize && minSize.width > 0 && minSize.height > 0 {
			result = minSize // fixSize
		}
		else {
			if shouldCacheSize {
				let key = "\(addressOf(targetView))_\(size)"
				if let value = sizeCacheData[key] {
					return value
				}
				else {
					result = targetView.sizeThatFits(size)
					sizeCacheData[key] = result
				}
			}
			else {
				result = targetView.sizeThatFits(size)
			}
			
			result.width = max(minSize.width, result.width)
			result.height = max(minSize.height, result.height)
			
			if maxSize.width > 0 && maxSize.width >= minSize.width {
				result.width = min(maxSize.width, result.width)
			}
			if maxSize.height > 0 && maxSize.height >= minSize.height {
				result.height = min(maxSize.height, result.height)
			}
		}
		
		result.width = max(minContentSize.width, result.width)
		result.height = max(minContentSize.height, result.height)
		
		if maxContentSize.width > 0 && maxContentSize.width >= minContentSize.width {
			result.width = min(maxContentSize.width, result.width)
		}
		if maxContentSize.height > 0 && maxContentSize.height >= minContentSize.height {
			result.height = min(maxContentSize.height, result.height)
		}
		
		return result
	}
	
}
