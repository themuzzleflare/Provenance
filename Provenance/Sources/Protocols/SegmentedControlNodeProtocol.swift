import Foundation
import UIKit

protocol SegmentedControlNodeProtocol: AnyObject {
  /// Insert a segment with the given action at the given index. Segments will prefer images over titles when both are provided. When the segment is selected UIAction.actionHandler is called. If a segment already exists with the action's identifier that segment will either be updated (if the index is the same) or it will be removed (if different).
  @available(iOS 14.0, *)
  func insertSegment(action: UIAction, at segment: Int, animated: Bool)

  /// Reconfigures the given segment with this action. Segments will prefer images over titles when both are provided. When the segment is selected UIAction.actionHandler is called. UIAction.identifier must either match the action of the existing segment at this index, or be unique within all actions associated with the segmented control, or this method will assert.
  @available(iOS 14.0, *)
  func setAction(_ action: UIAction, forSegmentAt segment: Int)

  /// Fetch the action for the given segment, if one has been assigned to that segment
  @available(iOS 14.0, *)
  func actionForSegment(at segment: Int) -> UIAction?

  /// Returns the index of the segment associated with the given actionIdentifier, or NSNotFound if the identifier could not be found.
  @available(iOS 14.0, *)
  func segmentIndex(identifiedBy actionIdentifier: UIAction.Identifier) -> Int

  var isMomentary: Bool { get set } // if set, then we don't keep showing selected state after tracking ends. default is NO

  var numberOfSegments: Int { get }

  // For segments whose width value is 0, setting this property to YES attempts to adjust segment widths based on their content widths. Default is NO.

  var apportionsSegmentWidthsByContent: Bool { get set }

  func insertSegment(withTitle title: String?, at segment: Int, animated: Bool) // insert before segment number. 0..#segments. value pinned

  func insertSegment(with image: UIImage?, at segment: Int, animated: Bool)

  func removeSegment(at segment: Int, animated: Bool)

  func removeAllSegments()

  func setTitle(_ title: String?, forSegmentAt segment: Int) // can only have image or title, not both. must be 0..#segments - 1 (or ignored). default is nil

  func titleForSegment(at segment: Int) -> String?

  func setImage(_ image: UIImage?, forSegmentAt segment: Int) // can only have image or title, not both. must be 0..#segments - 1 (or ignored). default is nil

  func imageForSegment(at segment: Int) -> UIImage?

  func setWidth(_ width: CGFloat, forSegmentAt segment: Int) // set to 0.0 width to autosize. default is 0.0

  func widthForSegment(at segment: Int) -> CGFloat

  func setContentOffset(_ offset: CGSize, forSegmentAt segment: Int) // adjust offset of image or text inside the segment. default is (0,0)

  func contentOffsetForSegment(at segment: Int) -> CGSize

  func setEnabled(_ enabled: Bool, forSegmentAt segment: Int) // default is YES

  func isEnabledForSegment(at segment: Int) -> Bool

  // ignored in momentary mode. returns last segment pressed. default is UISegmentedControlNoSegment until a segment is pressed
  // the UIControlEventValueChanged action is invoked when the segment changes via a user event. set to UISegmentedControlNoSegment to turn off selection
  var selectedSegmentIndex: Int { get set }

  // The color to use for highlighting the currently selected segment.
  @available(iOS 13.0, *)
  var selectedSegmentTintColor: UIColor? { get set }

  /* If backgroundImage is an image returned from -[UIImage resizableImageWithCapInsets:] the cap widths will be calculated from that information, otherwise, the cap width will be calculated by subtracting one from the image's width then dividing by 2. The cap widths will also be used as the margins for text placement. To adjust the margin use the margin adjustment methods.

   In general, you should specify a value for the normal state to be used by other states which don't have a custom value set.

   Similarly, when a property is dependent on the bar metrics, be sure to specify a value for UIBarMetricsDefault.
   In the case of the segmented control, appearance properties for UIBarMetricsCompact are only respected for segmented controls in the smaller navigation and toolbars.
   */

  func setBackgroundImage(_ backgroundImage: UIImage?, for state: UIControl.State, barMetrics: UIBarMetrics)

  func backgroundImage(for state: UIControl.State, barMetrics: UIBarMetrics) -> UIImage?

  /* To customize the segmented control appearance you will need to provide divider images to go between two unselected segments (leftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateNormal), selected on the left and unselected on the right (leftSegmentState:UIControlStateSelected rightSegmentState:UIControlStateNormal), and unselected on the left and selected on the right (leftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateSelected).
   */

  func setDividerImage(_ dividerImage: UIImage?, forLeftSegmentState leftState: UIControl.State, rightSegmentState rightState: UIControl.State, barMetrics: UIBarMetrics)

  func dividerImage(forLeftSegmentState leftState: UIControl.State, rightSegmentState rightState: UIControl.State, barMetrics: UIBarMetrics) -> UIImage?

  /* You may specify the font, text color, and shadow properties for the title in the text attributes dictionary, using the keys found in NSAttributedString.h.
   */

  func setTitleTextAttributes(_ attributes: [NSAttributedString.Key: Any]?, for state: UIControl.State)

  func titleTextAttributes(for state: UIControl.State) -> [NSAttributedString.Key: Any]?

  /* For adjusting the position of a title or image within the given segment of a segmented control.
   */

  func setContentPositionAdjustment(_ adjustment: UIOffset, forSegmentType leftCenterRightOrAlone: UISegmentedControl.Segment, barMetrics: UIBarMetrics)

  func contentPositionAdjustment(forSegmentType leftCenterRightOrAlone: UISegmentedControl.Segment, barMetrics: UIBarMetrics) -> UIOffset

  var contentVerticalAlignment: UIControl.ContentVerticalAlignment { get set }

  var contentHorizontalAlignment: UIControl.ContentHorizontalAlignment { get set }

  var effectiveContentHorizontalAlignment: UIControl.ContentHorizontalAlignment { get }

  var state: UIControl.State { get }
}
