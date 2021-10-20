import AsyncDisplayKit

final class StickerCellNode: ASCellNode {
  private let stickerImageNode = ASImageNode()

  init(sticker: ASAnimatedImageProtocol) {
    super.init()
    automaticallyManagesSubnodes = true
    stickerImageNode.animatedImage = sticker
    borderWidth = 0.5
    borderColor = .separator
  }

  override func didLoad() {
    super.didLoad()
    stickerImageNode.animatedImagePaused = false
  }

  override func asyncTraitCollectionDidChange(withPreviousTraitCollection previousTraitCollection: ASPrimitiveTraitCollection) {
    super.asyncTraitCollectionDidChange(withPreviousTraitCollection: previousTraitCollection)
    guard previousTraitCollection.userInterfaceStyle != primitiveTraitCollection().userInterfaceStyle else { return }
    borderColor = .separator
  }

  override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
    return ASInsetLayoutSpec(insets: .zero, child: stickerImageNode)
  }
}
