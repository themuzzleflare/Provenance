import UIKit
import AsyncDisplayKit

final class CategoryCellNode: ASCellNode {
  private let categoryTextNode = ASTextNode()

  private var model: CategoryCellModel

  init(category: CategoryCellModel) {
    self.model = category
    super.init()
    automaticallyManagesSubnodes = true
    categoryTextNode.attributedText = category.name.styled(with: .categoryName)
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
    guard previousTraitCollection.userInterfaceStyle != primitiveTraitCollection().userInterfaceStyle else { return }
    borderColor = .separator
  }

  override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
    let textCentreSpec = ASCenterLayoutSpec(centeringOptions: .XY, sizingOptions: .minimumXY, child: categoryTextNode)
    return ASInsetLayoutSpec(insets: .cellNode, child: textCentreSpec)
  }
}
