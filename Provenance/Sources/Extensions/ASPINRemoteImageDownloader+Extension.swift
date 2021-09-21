import Foundation
import UIKit
import AsyncDisplayKit
import PINRemoteImage

extension ASPINRemoteImageDownloader {
  static var stickerTwo: ASAnimatedImageProtocol {
    return try! ASPINRemoteImageDownloader.shared().animatedImage(with: Data(contentsOf: .stickerTwo))!
  }
  
  static var stickerThree: ASAnimatedImageProtocol {
    return try! ASPINRemoteImageDownloader.shared().animatedImage(with: Data(contentsOf: .stickerThree))!
  }
  
  static var stickerSix: ASAnimatedImageProtocol {
    return try! ASPINRemoteImageDownloader.shared().animatedImage(with: Data(contentsOf: .stickerSix))!
  }
  
  static var stickerSeven: ASAnimatedImageProtocol {
    return try! ASPINRemoteImageDownloader.shared().animatedImage(with: Data(contentsOf: .stickerSeven))!
  }
  
  static var upLogoDrawMidnightYellowTransparentBackground: ASAnimatedImageProtocol {
    return try! ASPINRemoteImageDownloader.shared().animatedImage(with: Data(contentsOf: .upLogoDrawMidnightYellowTransparentBackground))!
  }
}
