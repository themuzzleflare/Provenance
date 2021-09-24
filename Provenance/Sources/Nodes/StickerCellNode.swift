import AsyncDisplayKit

final class StickerCellNode: ASCellNode {
  private let stickerImageNode = ASImageNode()
  
  init(sticker: ASAnimatedImageProtocol) {
    super.init()
    
    automaticallyManagesSubnodes = true
    
    stickerImageNode.animatedImage = sticker
    borderWidth = 1
    borderColor = .separator
  }
  
  override func didLoad() {
    super.didLoad()
    stickerImageNode.animatedImagePaused = false
  }
  
  override func asyncTraitCollectionDidChange(withPreviousTraitCollection previousTraitCollection: ASPrimitiveTraitCollection) {
    super.asyncTraitCollectionDidChange(withPreviousTraitCollection: previousTraitCollection)
    borderColor = .separator
  }
  
  override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
    return ASInsetLayoutSpec(insets: .zero, child: stickerImageNode)
  }
}
