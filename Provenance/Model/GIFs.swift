import Foundation
import FLAnimatedImage

private let stickerTwo = try! FLAnimatedImage(animatedGIFData: Data(contentsOf: Bundle.main.url(forResource: "StickerTwo", withExtension: "gif")!))
private let stickerThree = try! FLAnimatedImage(animatedGIFData: Data(contentsOf: Bundle.main.url(forResource: "StickerThree", withExtension: "gif")!))
private let stickerSix = try! FLAnimatedImage(animatedGIFData: Data(contentsOf: Bundle.main.url(forResource: "StickerSix", withExtension: "gif")!))
private let stickerSeven = try! FLAnimatedImage(animatedGIFData: Data(contentsOf: Bundle.main.url(forResource: "StickerSeven", withExtension: "gif")!))

let stickerGifs = [stickerTwo, stickerThree, stickerSix, stickerSeven]
let upLogoWhiteSunsetTransparentBackground = try! FLAnimatedImage(animatedGIFData: Data(contentsOf: Bundle.main.url(forResource: "up-logo-white-sunset-transparent-bg", withExtension: "gif")!))
let upLogoDrawMidnightYellowTransparentBackground = try! FLAnimatedImage(animatedGIFData: Data(contentsOf: Bundle.main.url(forResource: "up-logo-draw-midnight-yellow-transparent-bg", withExtension: "gif")!))
let upZapSpinTransparentBackground = try! FLAnimatedImage(animatedGIFData: Data(contentsOf: Bundle.main.url(forResource: "up-zap-spin-transparent-bg", withExtension: "gif")!))
