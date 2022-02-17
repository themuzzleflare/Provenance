import UIKit
import NotificationBannerSwift

extension GrowingNotificationBanner {
  convenience init(
    title: String? = nil,
    subtitle: String? = nil,
    leftView: UIView? = nil,
    rightView: UIView? = nil,
    style: BannerStyle = .info,
    colors: BannerColorsProtocol? = nil,
    iconPosition: IconPosition = .center,
    sideViewSize: CGFloat = 24.0,
    duration: TimeInterval = 2.0
  ) {
    self.init(
      title: title,
      subtitle: subtitle,
      leftView: leftView,
      rightView: rightView,
      style: style,
      colors: colors,
      iconPosition: iconPosition,
      sideViewSize: sideViewSize
    )
    self.duration = duration
  }
}
