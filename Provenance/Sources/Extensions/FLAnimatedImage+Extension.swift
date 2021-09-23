import FLAnimatedImage

extension FLAnimatedImage {
  static var upLogoWhiteSunsetTransparentBackground: FLAnimatedImage {
    return try! FLAnimatedImage(animatedGIFData: Data(contentsOf: .upLogoWhiteSunsetTransparentBackground))!
  }
  
  static var upLogoDrawMidnightYellowTransparentBackground: FLAnimatedImage {
    return try! FLAnimatedImage(animatedGIFData: Data(contentsOf: .upLogoDrawMidnightYellowTransparentBackground))!
  }
  
  static var upZapSpinTransparentBackground: FLAnimatedImage {
    return try! FLAnimatedImage(animatedGIFData: Data(contentsOf: .upZapSpinTransparentBackground))!
  }
}
