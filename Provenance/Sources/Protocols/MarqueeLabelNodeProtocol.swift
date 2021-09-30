import UIKit
import MarqueeLabel

protocol MarqueeLabelNodeProtocol: AnyObject {
  var speed: MarqueeLabel.SpeedLimit { get set }
  
  var type: MarqueeLabel.MarqueeType { get set }
  
  var scrollSequence: [MarqueeStep]? { get set }
  
  var labelize: Bool { get set }
  
  var holdScrolling: Bool { get set }
  
  var animationCurve: UIView.AnimationCurve { get set }
  
  var tapToScroll: Bool { get set }
  
  var isPaused: Bool { get }
  
  var awayFromHome: Bool { get }
  
  var leadingBuffer: CGFloat { get set }
  
  var trailingBuffer: CGFloat { get set }
  
  var fadeLength: CGFloat { get set }
  
  var animationDelay: CGFloat { get set }
  
  var animationDuration: CGFloat { get }
  
  var text: String? { get set } // default is nil
  
  var font: UIFont! { get set } // default is nil (system font 17 plain)
  
  var textColor: UIColor! { get set } // default is labelColor
  
  var shadowOffset: CGSize { get set } // default is CGSizeMake(0, -1) -- a top shadow
  
  var textAlignment: NSTextAlignment { get set } // default is NSTextAlignmentNatural (before iOS 9, the default was NSTextAlignmentLeft)
  
  var lineBreakMode: NSLineBreakMode { get set } // default is NSLineBreakByTruncatingTail. used for single and multiple lines of text
  
    // the underlying attributed string drawn by the label, if set, the label ignores the properties above.
  var attributedText: NSAttributedString? { get set } // default is nil
  
    // the 'highlight' property is used by subclasses for such things as pressed states. it's useful to make it part of the base class as a user property
  
  var highlightedTextColor: UIColor? { get set } // default is nil
  
  var isHighlighted: Bool { get set } // default is NO
  
  var isUserInteractionEnabled: Bool { get set } // default is NO
  
  var isEnabled: Bool { get set } // default is YES. changes how the label is drawn
  
    // this determines the number of lines to draw and what to do when sizeToFit is called. default value is 1 (single line). A value of 0 means no limit
    // if the height of the text reaches the # of lines or the height of the view is less than the # of lines allowed, the text will be
    // truncated using the line break mode.
  
  var numberOfLines: Int { get set }
  
    // these next 3 properties allow the label to be autosized to fit a certain width by scaling the font size(s) by a scaling factor >= the minimum scaling factor
    // and to specify how the text baseline moves when it needs to shrink the font.
  
  var adjustsFontSizeToFitWidth: Bool { get set } // default is NO
  
  var baselineAdjustment: UIBaselineAdjustment { get set } // default is UIBaselineAdjustmentAlignBaselines
  
  var minimumScaleFactor: CGFloat { get set } // default is 0.0
  
    // Tightens inter-character spacing in attempt to fit lines wider than the available space if the line break mode is one of the truncation modes before starting to truncate.
    // The maximum amount of tightening performed is determined by the system based on contexts such as font, line width, etc.
  var allowsDefaultTighteningForTruncation: Bool { get set } // default is NO
  
    // Specifies the line break strategies that may be used for laying out the text in this label.
    // If this property is not set, the default value is NSLineBreakStrategyStandard.
    // If the label contains an attributed text with paragraph style(s) that specify a set of line break strategies, the set of strategies in the paragraph style(s) will be used instead of the set of strategies defined by this property.
  var lineBreakStrategy: NSParagraphStyle.LineBreakStrategy { get set }
  
    // override points. can adjust rect before calling super.
    // label has default content mode of UIViewContentModeRedraw
  
  func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect
  
  func drawText(in rect: CGRect)
  
    // Support for constraint-based layout (auto layout)
    // If nonzero, this is used when determining -intrinsicContentSize for multiline labels
  var preferredMaxLayoutWidth: CGFloat { get set }
  
    /// Indicates whether expansion text will be shown when the view is too small to show all the contents. Defaults to NO.
  var showsExpansionTextWhenTruncated: Bool { get set }
}
