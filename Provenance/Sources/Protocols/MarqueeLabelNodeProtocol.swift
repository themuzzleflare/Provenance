import UIKit
import MarqueeLabel

protocol MarqueeLabelNodeProtocol: AnyObject {
  /**
   Defines the speed of the `MarqueeLabel` scrolling animation.
   
   The speed is set by specifying a case of the `SpeedLimit` enum along with an associated value.
   
   - SeeAlso: SpeedLimit
   */
  var speed: MarqueeLabel.SpeedLimit { get set }

  /**
   Defines the direction and method in which the `MarqueeLabel` instance scrolls.
   `MarqueeLabel` supports six default types of scrolling: `Left`, `LeftRight`, `Right`, `RightLeft`, `Continuous`, and `ContinuousReverse`.
   
   Given the nature of how text direction works, the options for the `type` property require specific text alignments
   and will set the textAlignment property accordingly.
   
   - `LeftRight` and `Left` types are ONLY compatible with a label text alignment of `NSTextAlignment.left`.
   - `RightLeft` and `Right` types are ONLY compatible with a label text alignment of `NSTextAlignment.right`.
   - `Continuous` and `ContinuousReverse` allow the use of `NSTextAlignment.left`, `.right`, or `.center` alignments,
   however the text alignment only has an effect when label text is short enough that scrolling is not required.
   When scrolling, the labels are effectively center-aligned.
   
   Defaults to `Continuous`.
   
   - Note: Note that any `leadingBuffer` value will affect the text alignment location relative to the frame position,
   including  with `.center` alignment, where the center alignment location will be shifted left (for `.continuous`) or
   right (for `.continuousReverse`) by one-half (1/2) the `.leadingBuffer` amount. Use the `.trailingBuffer` property to
   add a buffer between text "loops" without affecting alignment location.
   
   - SeeAlso: textAlignment
   - SeeAlso: leadingBuffer
   */
  var type: MarqueeLabel.MarqueeType { get set }

  /**
   An optional custom scroll "sequence", defined by an array of `ScrollStep` or `FadeStep` instances. A sequence
   defines a single scroll/animation loop, which will continue to be automatically repeated like the default types.
   
   A `type` value is still required when using a custom sequence. The `type` value defines the `home` and `away`
   values used in the `ScrollStep` instances, and the `type` value determines which way the label will scroll.
   
   When a custom sequence is not supplied, the default sequences are used per the defined `type`.
   
   `ScrollStep` steps are the primary step types, and define the position of the label at a given time in the sequence.
   `FadeStep` steps are secondary steps that define the edge fade state (leading, trailing, or both) around the `ScrollStep`
   steps.
   
   Defaults to nil.
   
   - Attention: Use of the `scrollSequence` property requires understanding of how MarqueeLabel works for effective
   use. As a reference, it is suggested to review the methodology used to build the sequences for the default types.
   
   - SeeAlso: type
   - SeeAlso: ScrollStep
   - SeeAlso: FadeStep
   */
  var scrollSequence: [MarqueeStep]? { get set }

  /**
   A boolean property that sets whether the `MarqueeLabel` should behave like a normal `UILabel`.
   
   When set to `true` the `MarqueeLabel` will behave and look like a normal `UILabel`, and  will not begin any scrolling animations.
   Changes to this property take effect immediately, removing any in-flight animation as well as any edge fade. Note that `MarqueeLabel`
   will respect the current values of the `lineBreakMode` and `textAlignment`properties while labelized.
   
   To simply prevent automatic scrolling, use the `holdScrolling` property.
   
   Defaults to `false`.
   
   - SeeAlso: holdScrolling
   - SeeAlso: lineBreakMode
   - Note: The label will not automatically scroll when this property is set to `true`.
   - Warning: The UILabel default setting for the `lineBreakMode` property is `NSLineBreakByTruncatingTail`, which truncates
   the text adds an ellipsis glyph (...). Set the `lineBreakMode` property to `NSLineBreakByClipping` in order to avoid the
   ellipsis, especially if using an edge transparency fade.
   */
  var labelize: Bool { get set }

  /**
   A boolean property that sets whether the `MarqueeLabel` should hold (prevent) automatic label scrolling.
   
   When set to `true`, `MarqueeLabel` will not automatically scroll even its text is larger than the specified frame,
   although the specified edge fades will remain.
   
   To set `MarqueeLabel` to act like a normal UILabel, use the `labelize` property.
   
   Defaults to `false`.
   
   - Note: The label will not automatically scroll when this property is set to `true`.
   - SeeAlso: labelize
   */
  var holdScrolling: Bool { get set }

  /**
   Specifies the animation curve used in the scrolling motion of the labels.
   Allowable options:
   
   - `UIViewAnimationOptionCurveEaseInOut`
   - `UIViewAnimationOptionCurveEaseIn`
   - `UIViewAnimationOptionCurveEaseOut`
   - `UIViewAnimationOptionCurveLinear`
   
   Defaults to `UIViewAnimationOptionCurveEaseInOut`.
   */
  var animationCurve: UIView.AnimationCurve { get set }

  /**
   A boolean property that sets whether the `MarqueeLabel` should only begin a scroll when tapped.
   
   If this property is set to `true`, the `MarqueeLabel` will only begin a scroll animation cycle when tapped. The label will
   not automatically being a scroll. This setting overrides the setting of the `holdScrolling` property.
   
   Defaults to `false`.
   
   - Note: The label will not automatically scroll when this property is set to `false`.
   - SeeAlso: holdScrolling
   */
  var tapToScroll: Bool { get set }

  /**
   A read-only boolean property that indicates if the label's scroll animation has been paused.
   
   - SeeAlso: pauseLabel
   - SeeAlso: unpauseLabel
   */
  var isPaused: Bool { get }

  /**
   A boolean property that indicates if the label is currently away from the home location.
   
   The "home" location is the traditional location of `UILabel` text. This property essentially reflects if a scroll animation is underway.
   */
  var awayFromHome: Bool { get }

  /**
   A buffer (offset) between the leading edge of the label text and the label frame.
   
   This property adds additional space between the leading edge of the label text and the label frame. The
   leading edge is the edge of the label text facing the direction of scroll (i.e. the edge that animates
   offscreen first during scrolling).
   
   Defaults to `0`.
   
   - Note: The value set to this property affects label positioning at all times (including when `labelize` is set to `true`),
   including when the text string length is short enough that the label does not need to scroll.
   - Note: For Continuous-type labels, the smallest value of `leadingBuffer`, `trailingBuffer`, and `fadeLength`
   is used as spacing between the two label instances. Zero is an allowable value for all three properties.
   
   - SeeAlso: trailingBuffer
   */
  var leadingBuffer: CGFloat { get set }

  /**
   A buffer (offset) between the trailing edge of the label text and the label frame.
   
   This property adds additional space (buffer) between the trailing edge of the label text and the label frame. The
   trailing edge is the edge of the label text facing away from the direction of scroll (i.e. the edge that animates
   offscreen last during scrolling).
   
   Defaults to `0`.
   
   - Note: The value set to this property has no effect when the `labelize` property is set to `true`.
   
   - Note: For Continuous-type labels, the smallest value of `leadingBuffer`, `trailingBuffer`, and `fadeLength`
   is used as spacing between the two label instances. Zero is an allowable value for all three properties.
   
   - SeeAlso: leadingBuffer
   */
  var trailingBuffer: CGFloat { get set }

  /**
   The length of transparency fade at the left and right edges of the frame.
   
   This propery sets the size (in points) of the view edge transparency fades on the left and right edges of a `MarqueeLabel`. The
   transparency fades from an alpha of 1.0 (fully visible) to 0.0 (fully transparent) over this distance. Values set to this property
   will be sanitized to prevent a fade length greater than 1/2 of the frame width.
   
   Defaults to `0`.
   */
  var fadeLength: CGFloat { get set }

  /**
   The length of delay in seconds that the label pauses at the completion of a scroll.
   */
  var animationDelay: CGFloat { get set }

  /** The read-only/computed duration of the scroll animation (not including delay).
   
   The value of this property is calculated from the value set to the `speed` property. If a duration-type speed is
   used to set the label animation speed, `animationDuration` will be equivalent to that value.
   */
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
