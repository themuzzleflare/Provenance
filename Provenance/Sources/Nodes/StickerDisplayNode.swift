import UIKit
import AsyncDisplayKit

final class StickerDisplayNode: ASDisplayNode {
  private let imageNode = ASImageNode()

  private var sticker: AnimatedImage

  init(sticker: AnimatedImage) {
    self.sticker = sticker
    super.init()
    automaticallyManagesSubnodes = true
    imageNode.animatedImage = sticker.asAnimatedImage
    imageNode.style.width = ASDimension(unit: .points, value: 300)
    imageNode.style.height = ASDimension(unit: .points, value: 300)
  }

  override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
    return ASCenterLayoutSpec(centeringOptions: .XY, sizingOptions: .minimumXY, child: imageNode)
  }
}
