import AsyncDisplayKit

final class StickerImageNode: ASDisplayNode {
  private let imageNode = ASImageNode()

  init(sticker: ASAnimatedImageProtocol) {
    super.init()
    automaticallyManagesSubnodes = true
    imageNode.animatedImage = sticker
    imageNode.style.maxWidth = ASDimension(unit: .points, value: 300)
    imageNode.style.maxHeight = ASDimension(unit: .points, value: 300)
  }

  override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
    let image = ASCenterLayoutSpec(centeringOptions: .XY, sizingOptions: .minimumXY, child: imageNode)
    return ASInsetLayoutSpec(insets: .cellNode, child: image)
  }
}
