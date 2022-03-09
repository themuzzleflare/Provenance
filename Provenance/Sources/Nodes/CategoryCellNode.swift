import UIKit
import AsyncDisplayKit
import BonMot

final class CategoryCellNode: CellNode {
  private let textNode = ASTextNode()

  private var model: CategoryCellModel

  init(model: CategoryCellModel) {
    self.model = model
    super.init()
    automaticallyManagesSubnodes = true
    textNode.attributedText = model.name.styled(with: .categoryName)
    cornerRadius = 12.5
    borderColor = .separator
    borderWidth = 1.0
    backgroundColor = .secondarySystemBackground
  }

  override var isSelected: Bool {
    didSet {
      backgroundColor = isSelected ? .gray.withAlphaComponent(0.3) : .secondarySystemBackground
    }
  }

  override var isHighlighted: Bool {
    didSet {
      backgroundColor = isHighlighted ? .gray.withAlphaComponent(0.3) : .secondarySystemBackground
    }
  }

  override func asyncTraitCollectionDidChange(withPreviousTraitCollection previousTraitCollection: ASPrimitiveTraitCollection) {
    super.asyncTraitCollectionDidChange(withPreviousTraitCollection: previousTraitCollection)
    guard previousTraitCollection.userInterfaceStyle != asyncTraitCollection().userInterfaceStyle else { return }
    borderColor = .separator
  }

  override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
    let centerSpec = ASCenterLayoutSpec(centeringOptions: .XY, sizingOptions: .minimumXY, child: textNode)
    return ASInsetLayoutSpec(insets: .cellNode, child: centerSpec)
  }
}
