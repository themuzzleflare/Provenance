import UIKit
import AsyncDisplayKit

final class CategoryCellNode: ASCellNode {
  private let categoryTextNode = ASTextNode()

  init(category: CategoryResource) {
    super.init()

    automaticallyManagesSubnodes = true

    categoryTextNode.attributedText = NSAttributedString(
      text: category.attributes.name,
      alignment: .centreAligned
    )

    cornerRadius = 12.5
    borderColor = .separator
    borderWidth = 1.0
    backgroundColor = .secondarySystemGroupedBackground
  }

  override var isHighlighted: Bool {
    didSet {
      backgroundColor = isHighlighted ? .systemGray4 : .secondarySystemGroupedBackground
    }
  }

  override var isSelected: Bool {
    didSet {
      backgroundColor = isSelected ? .systemGray4 : .secondarySystemGroupedBackground
    }
  }

  override func asyncTraitCollectionDidChange(withPreviousTraitCollection previousTraitCollection: ASPrimitiveTraitCollection) {
    super.asyncTraitCollectionDidChange(withPreviousTraitCollection: previousTraitCollection)
    borderColor = .separator
  }

  override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
    let textCentreSpec = ASCenterLayoutSpec(centeringOptions: .XY, sizingOptions: .minimumXY, child: categoryTextNode)
    return ASInsetLayoutSpec(insets: .cellNode, child: textCentreSpec)
  }
}
