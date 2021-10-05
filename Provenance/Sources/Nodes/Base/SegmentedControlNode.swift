import AsyncDisplayKit

final class SegmentedControlNode: ASControlNode {
  private let segmentedControlViewBlock: ASDisplayNodeViewBlock = {
    return UISegmentedControl()
  }
  
  private var segmentedControl: UISegmentedControl {
    return view as! UISegmentedControl
  }
  
  override init() {
    super.init()
    setViewBlock(segmentedControlViewBlock)
  }
  
  override func addTarget(_ target: Any?, action: Selector, forControlEvents controlEvents: ASControlNodeEvent) {
    super.addTarget(target, action: action, forControlEvents: controlEvents)
    segmentedControl.addTarget(target, action: action, for: UIControl.Event(rawValue: controlEvents.rawValue))
  }
  
  override func removeTarget(_ target: Any?, action: Selector?, forControlEvents controlEvents: ASControlNodeEvent) {
    super.removeTarget(target, action: action, forControlEvents: controlEvents)
    segmentedControl.removeTarget(target, action: action, for: UIControl.Event(rawValue: controlEvents.rawValue))
  }
  
  override func actions(forTarget target: Any, forControlEvent controlEvent: ASControlNodeEvent) -> [String]? {
    return segmentedControl.actions(forTarget: target, forControlEvent: UIControl.Event(rawValue: controlEvent.rawValue))
  }
  
  override func beginTracking(with touch: UITouch, with touchEvent: UIEvent?) -> Bool {
    super.beginTracking(with: touch, with: touchEvent)
    return segmentedControl.beginTracking(touch, with: touchEvent)
  }
  
  override func continueTracking(with touch: UITouch, with touchEvent: UIEvent?) -> Bool {
    super.continueTracking(with: touch, with: touchEvent)
    return segmentedControl.continueTracking(touch, with: touchEvent)
  }
  
  override func endTracking(with touch: UITouch?, with touchEvent: UIEvent?) {
    super.endTracking(with: touch, with: touchEvent)
    segmentedControl.endTracking(touch, with: touchEvent)
  }
  
  override func cancelTracking(with touchEvent: UIEvent?) {
    super.cancelTracking(with: touchEvent)
    segmentedControl.cancelTracking(with: touchEvent)
  }
  
  override var isEnabled: Bool {
    didSet {
      segmentedControl.isEnabled = isEnabled
    }
  }
  
  override var isSelected: Bool {
    didSet {
      segmentedControl.isSelected = isSelected
    }
  }
  
  override var isHighlighted: Bool {
    didSet {
      segmentedControl.isHighlighted = isHighlighted
    }
  }
  
  override func calculateSizeThatFits(_ constrainedSize: CGSize) -> CGSize {
    return CGSize(width: 200, height: 30)
  }
}

extension SegmentedControlNode: SegmentedControlNodeProtocol {
  var state: UIControl.State {
    return segmentedControl.state
  }
  
  var contentHorizontalAlignment: UIControl.ContentHorizontalAlignment {
    get {
      return segmentedControl.contentHorizontalAlignment
    }
    set {
      segmentedControl.contentHorizontalAlignment = newValue
    }
  }
  
  var effectiveContentHorizontalAlignment: UIControl.ContentHorizontalAlignment {
    return segmentedControl.effectiveContentHorizontalAlignment
  }
  
  var contentVerticalAlignment: UIControl.ContentVerticalAlignment {
    get {
      return segmentedControl.contentVerticalAlignment
    }
    set {
      segmentedControl.contentVerticalAlignment = newValue
    }
  }
  
  @available(iOS 14.0, *)
  func insertSegment(action: UIAction, at segment: Int, animated: Bool) {
    segmentedControl.insertSegment(action: action, at: segment, animated: animated)
  }
  
  @available(iOS 14.0, *)
  func setAction(_ action: UIAction, forSegmentAt segment: Int) {
    segmentedControl.setAction(action, forSegmentAt: segment)
  }
  
  @available(iOS 14.0, *)
  func actionForSegment(at segment: Int) -> UIAction? {
    return segmentedControl.actionForSegment(at: segment)
  }
  
  @available(iOS 14.0, *)
  func segmentIndex(identifiedBy actionIdentifier: UIAction.Identifier) -> Int {
    return segmentedControl.segmentIndex(identifiedBy: actionIdentifier)
  }
  
  var isMomentary: Bool {
    get {
      return segmentedControl.isMomentary
    }
    set {
      segmentedControl.isMomentary = newValue
    }
  }
  
  var numberOfSegments: Int {
    return segmentedControl.numberOfSegments
  }
  
  var apportionsSegmentWidthsByContent: Bool {
    get {
      return segmentedControl.apportionsSegmentWidthsByContent
    }
    set {
      segmentedControl.apportionsSegmentWidthsByContent = newValue
    }
  }
  
  func insertSegment(withTitle title: String?, at segment: Int, animated: Bool) {
    segmentedControl.insertSegment(withTitle: title, at: segment, animated: animated)
  }
  
  func insertSegment(with image: UIImage?, at segment: Int, animated: Bool) {
    segmentedControl.insertSegment(with: image, at: segment, animated: animated)
  }
  
  func removeSegment(at segment: Int, animated: Bool) {
    segmentedControl.removeSegment(at: segment, animated: animated)
  }
  
  func removeAllSegments() {
    segmentedControl.removeAllSegments()
  }
  
  func setTitle(_ title: String?, forSegmentAt segment: Int) {
    segmentedControl.setTitle(title, forSegmentAt: segment)
  }
  
  func titleForSegment(at segment: Int) -> String? {
    return segmentedControl.titleForSegment(at: segment)
  }
  
  func setImage(_ image: UIImage?, forSegmentAt segment: Int) {
    segmentedControl.setImage(image, forSegmentAt: segment)
  }
  
  func imageForSegment(at segment: Int) -> UIImage? {
    return segmentedControl.imageForSegment(at: segment)
  }
  
  func setWidth(_ width: CGFloat, forSegmentAt segment: Int) {
    segmentedControl.setWidth(width, forSegmentAt: segment)
  }
  
  func widthForSegment(at segment: Int) -> CGFloat {
    return segmentedControl.widthForSegment(at: segment)
  }
  
  func setContentOffset(_ offset: CGSize, forSegmentAt segment: Int) {
    segmentedControl.setContentOffset(offset, forSegmentAt: segment)
  }
  
  func contentOffsetForSegment(at segment: Int) -> CGSize {
    return segmentedControl.contentOffsetForSegment(at: segment)
  }
  
  func setEnabled(_ enabled: Bool, forSegmentAt segment: Int) {
    segmentedControl.setEnabled(enabled, forSegmentAt: segment)
  }
  
  func isEnabledForSegment(at segment: Int) -> Bool {
    return segmentedControl.isEnabledForSegment(at: segment)
  }
  
  var selectedSegmentIndex: Int {
    get {
      return segmentedControl.selectedSegmentIndex
    }
    set {
      segmentedControl.selectedSegmentIndex = newValue
    }
  }
  
  var selectedSegmentTintColor: UIColor? {
    get {
      return segmentedControl.selectedSegmentTintColor
    }
    set {
      segmentedControl.selectedSegmentTintColor = newValue
    }
  }
  
  func setBackgroundImage(_ backgroundImage: UIImage?, for state: UIControl.State, barMetrics: UIBarMetrics) {
    segmentedControl.setBackgroundImage(backgroundImage, for: state, barMetrics: barMetrics)
  }
  
  func backgroundImage(for state: UIControl.State, barMetrics: UIBarMetrics) -> UIImage? {
    return segmentedControl.backgroundImage(for: state, barMetrics: barMetrics)
  }
  
  func setDividerImage(_ dividerImage: UIImage?, forLeftSegmentState leftState: UIControl.State, rightSegmentState rightState: UIControl.State, barMetrics: UIBarMetrics) {
    segmentedControl.setDividerImage(dividerImage, forLeftSegmentState: leftState, rightSegmentState: rightState, barMetrics: barMetrics)
  }
  
  func dividerImage(forLeftSegmentState leftState: UIControl.State, rightSegmentState rightState: UIControl.State, barMetrics: UIBarMetrics) -> UIImage? {
    return segmentedControl.dividerImage(forLeftSegmentState: leftState, rightSegmentState: rightState, barMetrics: barMetrics)
  }
  
  func setTitleTextAttributes(_ attributes: [NSAttributedString.Key: Any]?, for state: UIControl.State) {
    segmentedControl.setTitleTextAttributes(attributes, for: state)
  }
  
  func titleTextAttributes(for state: UIControl.State) -> [NSAttributedString.Key: Any]? {
    return segmentedControl.titleTextAttributes(for: state)
  }
  
  func setContentPositionAdjustment(_ adjustment: UIOffset, forSegmentType leftCenterRightOrAlone: UISegmentedControl.Segment, barMetrics: UIBarMetrics) {
    segmentedControl.setContentPositionAdjustment(adjustment, forSegmentType: leftCenterRightOrAlone, barMetrics: barMetrics)
  }
  
  func contentPositionAdjustment(forSegmentType leftCenterRightOrAlone: UISegmentedControl.Segment, barMetrics: UIBarMetrics) -> UIOffset {
    return segmentedControl.contentPositionAdjustment(forSegmentType: leftCenterRightOrAlone, barMetrics: barMetrics)
  }
}
