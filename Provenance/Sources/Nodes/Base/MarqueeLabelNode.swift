import MarqueeLabel
import AsyncDisplayKit

final class MarqueeLabelNode: ASDisplayNode {
  private let marqueeLabelViewBlock: ASDisplayNodeViewBlock = {
    return MarqueeLabel()
  }
  
  private var marqueeLabel: MarqueeLabel {
    return view as! MarqueeLabel
  }
  
  override init() {
    super.init()
    setViewBlock(marqueeLabelViewBlock)
  }
  
  override func calculateSizeThatFits(_ constrainedSize: CGSize) -> CGSize {
    return .cellNode(height: 45)
  }
}

// MARK: - MarqueeLabelNodeProtocol

extension MarqueeLabelNode: MarqueeLabelNodeProtocol {
  var type: MarqueeLabel.MarqueeType {
    get {
      return marqueeLabel.type
    }
    set {
      marqueeLabel.type = newValue
    }
  }
  
  var scrollSequence: [MarqueeStep]? {
    get {
      return marqueeLabel.scrollSequence
    }
    set {
      marqueeLabel.scrollSequence = newValue
    }
  }
  
  var labelize: Bool {
    get {
      return marqueeLabel.labelize
    }
    set {
      marqueeLabel.labelize = newValue
    }
  }
  
  var holdScrolling: Bool {
    get {
      return marqueeLabel.holdScrolling
    }
    set {
      marqueeLabel.holdScrolling = newValue
    }
  }
  
  var animationCurve: UIView.AnimationCurve {
    get {
      return marqueeLabel.animationCurve
    }
    set {
      marqueeLabel.animationCurve = newValue
    }
  }
  
  var tapToScroll: Bool {
    get {
      return marqueeLabel.tapToScroll
    }
    set {
      marqueeLabel.tapToScroll = newValue
    }
  }
  
  var isPaused: Bool {
    return marqueeLabel.isPaused
  }
  
  var awayFromHome: Bool {
    return marqueeLabel.awayFromHome
  }
  
  var leadingBuffer: CGFloat {
    get {
      return marqueeLabel.leadingBuffer
    }
    set {
      marqueeLabel.leadingBuffer = newValue
    }
  }
  
  var trailingBuffer: CGFloat {
    get {
      return marqueeLabel.trailingBuffer
    }
    set {
      marqueeLabel.trailingBuffer = newValue
    }
  }
  
  var fadeLength: CGFloat {
    get {
      return marqueeLabel.fadeLength
    }
    set {
      marqueeLabel.fadeLength = newValue
    }
  }
  
  var animationDelay: CGFloat {
    get {
      return marqueeLabel.animationDelay
    }
    set {
      marqueeLabel.animationDelay = newValue
    }
  }
  
  var animationDuration: CGFloat {
    return marqueeLabel.animationDuration
  }
  
  var speed: MarqueeLabel.SpeedLimit {
    get {
      return marqueeLabel.speed
    }
    set {
      marqueeLabel.speed = newValue
    }
  }
  
  var font: UIFont! {
    get {
      return marqueeLabel.font
    }
    set {
      marqueeLabel.font = newValue
    }
  }
  
  var textColor: UIColor! {
    get {
      return marqueeLabel.textColor
    }
    set {
      marqueeLabel.textColor = newValue
    }
  }
  
  var textAlignment: NSTextAlignment {
    get {
      return marqueeLabel.textAlignment
    }
    set {
      marqueeLabel.textAlignment = newValue
    }
  }
  
  var lineBreakMode: NSLineBreakMode {
    get {
      return marqueeLabel.lineBreakMode
    }
    set {
      marqueeLabel.lineBreakMode = newValue
    }
  }
  
  var attributedText: NSAttributedString? {
    get {
      return marqueeLabel.attributedText
    }
    set {
      marqueeLabel.attributedText = newValue
    }
  }
  
  var highlightedTextColor: UIColor? {
    get {
      return marqueeLabel.highlightedTextColor
    }
    set {
      marqueeLabel.highlightedTextColor = newValue
    }
  }
  
  var isHighlighted: Bool {
    get {
      return marqueeLabel.isHighlighted
    }
    set {
      marqueeLabel.isHighlighted = newValue
    }
  }
  
  var isEnabled: Bool {
    get {
      return marqueeLabel.isEnabled
    }
    set {
      marqueeLabel.isEnabled = newValue
    }
  }
  
  var numberOfLines: Int {
    get {
      return marqueeLabel.numberOfLines
    }
    set {
      marqueeLabel.numberOfLines = newValue
    }
  }
  
  var adjustsFontSizeToFitWidth: Bool {
    get {
      return marqueeLabel.adjustsFontSizeToFitWidth
    }
    set {
      marqueeLabel.adjustsFontSizeToFitWidth = newValue
    }
  }
  
  var baselineAdjustment: UIBaselineAdjustment {
    get {
      return marqueeLabel.baselineAdjustment
    }
    set {
      marqueeLabel.baselineAdjustment = newValue
    }
  }
  
  var minimumScaleFactor: CGFloat {
    get {
      return marqueeLabel.minimumScaleFactor
    }
    set {
      marqueeLabel.minimumScaleFactor = newValue
    }
  }
  
  var allowsDefaultTighteningForTruncation: Bool {
    get {
      return marqueeLabel.allowsDefaultTighteningForTruncation
    }
    set {
      marqueeLabel.allowsDefaultTighteningForTruncation = newValue
    }
  }
  
  var lineBreakStrategy: NSParagraphStyle.LineBreakStrategy {
    get {
      return marqueeLabel.lineBreakStrategy
    }
    set {
      marqueeLabel.lineBreakStrategy = newValue
    }
  }
  
  func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
    return marqueeLabel.textRect(forBounds: bounds, limitedToNumberOfLines: numberOfLines)
  }
  
  func drawText(in rect: CGRect) {
    marqueeLabel.drawText(in: rect)
  }
  
  var preferredMaxLayoutWidth: CGFloat {
    get {
      return marqueeLabel.preferredMaxLayoutWidth
    }
    set {
      marqueeLabel.preferredMaxLayoutWidth = newValue
    }
  }
  
  var showsExpansionTextWhenTruncated: Bool {
    get {
      return marqueeLabel.showsExpansionTextWhenTruncated
    }
    set {
      marqueeLabel.showsExpansionTextWhenTruncated = newValue
    }
  }
  
  var text: String? {
    get {
      return marqueeLabel.text
    }
    set {
      marqueeLabel.text = newValue
    }
  }
}
