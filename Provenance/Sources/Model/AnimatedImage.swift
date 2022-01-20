import Foundation
import UIKit
import AsyncDisplayKit

enum AnimatedImage {
  case stickerTwo
  case stickerThree
  case stickerSix
  case stickerSeven
  case upLogoDrawMidnightYellowTransparentBackground
}

// MARK: -

extension AnimatedImage {
  var asAnimatedImage: ASAnimatedImageProtocol {
    switch self {
    case .stickerTwo:
      return try! ASPINRemoteImageDownloader.shared().animatedImage(with: Data(contentsOf: .stickerTwo))!
    case .stickerThree:
      return try! ASPINRemoteImageDownloader.shared().animatedImage(with: Data(contentsOf: .stickerThree))!
    case .stickerSix:
      return try! ASPINRemoteImageDownloader.shared().animatedImage(with: Data(contentsOf: .stickerSix))!
    case .stickerSeven:
      return try! ASPINRemoteImageDownloader.shared().animatedImage(with: Data(contentsOf: .stickerSeven))!
    case .upLogoDrawMidnightYellowTransparentBackground:
      return try! ASPINRemoteImageDownloader.shared().animatedImage(with: Data(contentsOf: .upLogoDrawMidnightYellowTransparentBackground))!
    }
  }
}
