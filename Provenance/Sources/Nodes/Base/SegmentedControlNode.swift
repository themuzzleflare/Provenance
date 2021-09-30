import AsyncDisplayKit

final class SegmentedControlNode: ASControlNode {
  private let segmentedControlViewBlock: ASDisplayNodeViewBlock = {
    return UISegmentedControl()
  }
  
  private var segmentedControlView: UISegmentedControl {
    return view as! UISegmentedControl
  }
  
  override init() {
    super.init()
    setViewBlock(segmentedControlViewBlock)
  }
  
  override func addTarget(_ target: Any?, action: Selector, forControlEvents controlEvents: ASControlNodeEvent) {
    super.addTarget(target, action: action, forControlEvents: controlEvents)
    segmentedControlView.addTarget(target, action: action, for: UIControl.Event(rawValue: controlEvents.rawValue))
  }
  
  override func removeTarget(_ target: Any?, action: Selector?, forControlEvents controlEvents: ASControlNodeEvent) {
    super.removeTarget(target, action: action, forControlEvents: controlEvents)
    segmentedControlView.removeTarget(target, action: action, for: UIControl.Event(rawValue: controlEvents.rawValue))
  }
  
  override func actions(forTarget target: Any, forControlEvent controlEvent: ASControlNodeEvent) -> [String]? {
    return segmentedControlView.actions(forTarget: target, forControlEvent: UIControl.Event(rawValue: controlEvent.rawValue))
  }
  
  override func beginTracking(with touch: UITouch, with touchEvent: UIEvent?) -> Bool {
    super.beginTracking(with: touch, with: touchEvent)
    return segmentedControlView.beginTracking(touch, with: touchEvent)
  }
  
  override func continueTracking(with touch: UITouch, with touchEvent: UIEvent?) -> Bool {
    super.continueTracking(with: touch, with: touchEvent)
    return segmentedControlView.continueTracking(touch, with: touchEvent)
  }
  
  override func endTracking(with touch: UITouch?, with touchEvent: UIEvent?) {
    super.endTracking(with: touch, with: touchEvent)
    segmentedControlView.endTracking(touch, with: touchEvent)
  }
  
  override func cancelTracking(with touchEvent: UIEvent?) {
    super.cancelTracking(with: touchEvent)
    segmentedControlView.cancelTracking(with: touchEvent)
  }
  
  override var isEnabled: Bool {
    didSet {
      segmentedControlView.isEnabled = isEnabled
    }
  }
  
  override var isSelected: Bool {
    didSet {
      segmentedControlView.isSelected = isSelected
    }
  }
  
  override var isHighlighted: Bool {
    didSet {
      segmentedControlView.isHighlighted = isHighlighted
    }
  }
  
  override func calculateSizeThatFits(_ constrainedSize: CGSize) -> CGSize {
    return CGSize(width: 200, height: 30)
  }
}

extension SegmentedControlNode: SegmentedControlNodeProtocol {
  var state: UIControl.State {
    return segmentedControlView.state
  }
  
  var contentHorizontalAlignment: UIControl.ContentHorizontalAlignment {
    get {
      return segmentedControlView.contentHorizontalAlignment
    }
    set {
      segmentedControlView.contentHorizontalAlignment = newValue
    }
  }
  
  var effectiveContentHorizontalAlignment: UIControl.ContentHorizontalAlignment {
    return segmentedControlView.effectiveContentHorizontalAlignment
  }
  
  var contentVerticalAlignment: UIControl.ContentVerticalAlignment {
    get {
      return segmentedControlView.contentVerticalAlignment
    }
    set {
      segmentedControlView.contentVerticalAlignment = newValue
    }
  }
  
  @available(iOS 14.0, *)
  func insertSegment(action: UIAction, at segment: Int, animated: Bool) {
    segmentedControlView.insertSegment(action: action, at: segment, animated: animated)
  }
  
  @available(iOS 14.0, *)
  func setAction(_ action: UIAction, forSegmentAt segment: Int) {
    segmentedControlView.setAction(action, forSegmentAt: segment)
  }
  
  @available(iOS 14.0, *)
  func actionForSegment(at segment: Int) -> UIAction? {
    return segmentedControlView.actionForSegment(at: segment)
  }
  
  @available(iOS 14.0, *)
  func segmentIndex(identifiedBy actionIdentifier: UIAction.Identifier) -> Int {
    return segmentedControlView.segmentIndex(identifiedBy: actionIdentifier)
  }
  
  var isMomentary: Bool {
    get {
      return segmentedControlView.isMomentary
    }
    set {
      segmentedControlView.isMomentary = newValue
    }
  }
  
  var numberOfSegments: Int {
    return segmentedControlView.numberOfSegments
  }
  
  var apportionsSegmentWidthsByContent: Bool {
    get {
      return segmentedControlView.apportionsSegmentWidthsByContent
    }
    set {
      segmentedControlView.apportionsSegmentWidthsByContent = newValue
    }
  }
  
  func insertSegment(withTitle title: String?, at segment: Int, animated: Bool) {
    segmentedControlView.insertSegment(withTitle: title, at: segment, animated: animated)
  }
  
  func insertSegment(with image: UIImage?, at segment: Int, animated: Bool) {
    segmentedControlView.insertSegment(with: image, at: segment, animated: animated)
  }
  
  func removeSegment(at segment: Int, animated: Bool) {
    segmentedControlView.removeSegment(at: segment, animated: animated)
  }
  
  func removeAllSegments() {
    segmentedControlView.removeAllSegments()
  }
  
  func setTitle(_ title: String?, forSegmentAt segment: Int) {
    segmentedControlView.setTitle(title, forSegmentAt: segment)
  }
  
  func titleForSegment(at segment: Int) -> String? {
    return segmentedControlView.titleForSegment(at: segment)
  }
  
  func setImage(_ image: UIImage?, forSegmentAt segment: Int) {
    segmentedControlView.setImage(image, forSegmentAt: segment)
  }
  
  func imageForSegment(at segment: Int) -> UIImage? {
    return segmentedControlView.imageForSegment(at: segment)
  }
  
  func setWidth(_ width: CGFloat, forSegmentAt segment: Int) {
    segmentedControlView.setWidth(width, forSegmentAt: segment)
  }
  
  func widthForSegment(at segment: Int) -> CGFloat {
    return segmentedControlView.widthForSegment(at: segment)
  }
  
  func setContentOffset(_ offset: CGSize, forSegmentAt segment: Int) {
    segmentedControlView.setContentOffset(offset, forSegmentAt: segment)
  }
  
  func contentOffsetForSegment(at segment: Int) -> CGSize {
    return segmentedControlView.contentOffsetForSegment(at: segment)
  }
  
  func setEnabled(_ enabled: Bool, forSegmentAt segment: Int) {
    segmentedControlView.setEnabled(enabled, forSegmentAt: segment)
  }
  
  func isEnabledForSegment(at segment: Int) -> Bool {
    return segmentedControlView.isEnabledForSegment(at: segment)
  }
  
  var selectedSegmentIndex: Int {
    get {
      return segmentedControlView.selectedSegmentIndex
    }
    set {
      segmentedControlView.selectedSegmentIndex = newValue
    }
  }
  
  var selectedSegmentTintColor: UIColor? {
    get {
      return segmentedControlView.selectedSegmentTintColor
    }
    set {
      segmentedControlView.selectedSegmentTintColor = newValue
    }
  }
  
  func setBackgroundImage(_ backgroundImage: UIImage?, for state: UIControl.State, barMetrics: UIBarMetrics) {
    segmentedControlView.setBackgroundImage(backgroundImage, for: state, barMetrics: barMetrics)
  }
  
  func backgroundImage(for state: UIControl.State, barMetrics: UIBarMetrics) -> UIImage? {
    return segmentedControlView.backgroundImage(for: state, barMetrics: barMetrics)
  }
  
  func setDividerImage(_ dividerImage: UIImage?, forLeftSegmentState leftState: UIControl.State, rightSegmentState rightState: UIControl.State, barMetrics: UIBarMetrics) {
    segmentedControlView.setDividerImage(dividerImage, forLeftSegmentState: leftState, rightSegmentState: rightState, barMetrics: barMetrics)
  }
  
  func dividerImage(forLeftSegmentState leftState: UIControl.State, rightSegmentState rightState: UIControl.State, barMetrics: UIBarMetrics) -> UIImage? {
    return segmentedControlView.dividerImage(forLeftSegmentState: leftState, rightSegmentState: rightState, barMetrics: barMetrics)
  }
  
  func setTitleTextAttributes(_ attributes: [NSAttributedString.Key: Any]?, for state: UIControl.State) {
    segmentedControlView.setTitleTextAttributes(attributes, for: state)
  }
  
  func titleTextAttributes(for state: UIControl.State) -> [NSAttributedString.Key: Any]? {
    return segmentedControlView.titleTextAttributes(for: state)
  }
  
  func setContentPositionAdjustment(_ adjustment: UIOffset, forSegmentType leftCenterRightOrAlone: UISegmentedControl.Segment, barMetrics: UIBarMetrics) {
    segmentedControlView.setContentPositionAdjustment(adjustment, forSegmentType: leftCenterRightOrAlone, barMetrics: barMetrics)
  }
  
  func contentPositionAdjustment(forSegmentType leftCenterRightOrAlone: UISegmentedControl.Segment, barMetrics: UIBarMetrics) -> UIOffset {
    return segmentedControlView.contentPositionAdjustment(forSegmentType: leftCenterRightOrAlone, barMetrics: barMetrics)
  }
}
