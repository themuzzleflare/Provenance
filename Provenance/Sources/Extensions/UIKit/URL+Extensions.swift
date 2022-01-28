import Foundation
import UIKit

extension URL {
  static let settingsBundle = Bundle.main.url(forResource: "Settings", withExtension: "bundle")!

  static let settingsApp = URL(string: UIApplication.openSettingsURLString)!

  static let stickerTwo = Bundle.main.url(forResource: "StickerTwo", withExtension: "gif")!

  static let stickerThree = Bundle.main.url(forResource: "StickerThree", withExtension: "gif")!

  static let stickerSix = Bundle.main.url(forResource: "StickerSix", withExtension: "gif")!

  static let stickerSeven = Bundle.main.url(forResource: "StickerSeven", withExtension: "gif")!

  static let upLogoWhiteSunsetTransparentBackground = Bundle.main.url(forResource: "up-logo-white-sunset-transparent-bg", withExtension: "gif")!

  static let upLogoDrawMidnightYellowTransparentBackground = Bundle.main.url(forResource: "up-logo-draw-midnight-yellow-transparent-bg", withExtension: "gif")!

  static let upZapSpinTransparentBackground = Bundle.main.url(forResource: "up-zap-spin-transparent-bg", withExtension: "gif")!

  static let feedback = URL(string: "mailto:feedback@tavitian.cloud?subject=Feedback%20for%20Provenance")!

  static let github = URL(string: "https://github.com/themuzzleflare/Provenance")!
}
