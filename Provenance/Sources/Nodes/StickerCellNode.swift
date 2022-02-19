import UIKit
import AsyncDisplayKit

final class StickerCellNode: CellNode {
  private let stickerImageNode = ASImageNode()

  private var sticker: AnimatedImage

  init(sticker: AnimatedImage) {
    self.sticker = sticker
    super.init()
    automaticallyManagesSubnodes = true
    stickerImageNode.animatedImage = sticker.asAnimatedImage
    borderWidth = 0.5
    borderColor = .separator
  }

  override func asyncTraitCollectionDidChange(withPreviousTraitCollection previousTraitCollection: ASPrimitiveTraitCollection) {
    super.asyncTraitCollectionDidChange(withPreviousTraitCollection: previousTraitCollection)
    guard previousTraitCollection.userInterfaceStyle != asyncTraitCollection().userInterfaceStyle else { return }
    borderColor = .separator
  }

  override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
    return ASWrapperLayoutSpec(layoutElement: stickerImageNode)
  }
}
