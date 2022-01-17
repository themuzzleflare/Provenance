import UIKit

extension URL {
  static var settingsBundle: URL {
    return Bundle.main.url(forResource: "Settings", withExtension: "bundle")!
  }

  static var settingsApp: URL {
    return URL(string: UIApplication.openSettingsURLString)!
  }

  static var stickerTwo: URL {
    return Bundle.main.url(forResource: "StickerTwo", withExtension: "gif")!
  }

  static var stickerThree: URL {
    return Bundle.main.url(forResource: "StickerThree", withExtension: "gif")!
  }

  static var stickerSix: URL {
    return Bundle.main.url(forResource: "StickerSix", withExtension: "gif")!
  }

  static var stickerSeven: URL {
    return Bundle.main.url(forResource: "StickerSeven", withExtension: "gif")!
  }

  static var upLogoWhiteSunsetTransparentBackground: URL {
    return Bundle.main.url(forResource: "up-logo-white-sunset-transparent-bg", withExtension: "gif")!
  }

  static var upLogoDrawMidnightYellowTransparentBackground: URL {
    return Bundle.main.url(forResource: "up-logo-draw-midnight-yellow-transparent-bg", withExtension: "gif")!
  }

  static var upZapSpinTransparentBackground: URL {
    return Bundle.main.url(forResource: "up-zap-spin-transparent-bg", withExtension: "gif")!
  }

  static var feedback: URL {
    return URL(string: "mailto:feedback@tavitian.cloud?subject=Feedback%20for%20Provenance")!
  }

  static var github: URL {
    return URL(string: "https://github.com/themuzzleflare/Provenance")!
  }
}
