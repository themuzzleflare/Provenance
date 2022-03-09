import UIKit
import AsyncDisplayKit
import BonMot

final class DateHeaderCellNode: CellNode {
  private let dateTextNode = ASTextNode()
  private let spendTotalTextNode = ASTextNode()

  private var model: DateHeaderModel

  init(model: DateHeaderModel) {
    self.model = model
    super.init()
    automaticallyManagesSubnodes = true
    dateTextNode.attributedText = model.dateString.styled(with: .provenance)
    spendTotalTextNode.attributedText = model.spendTotal.styled(with: .provenance, .color(.secondaryLabel))
    backgroundColor = .secondarySystemBackground
  }

  override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
    let horizontalStack = ASStackLayoutSpec(direction: .horizontal,
                                            spacing: 0,
                                            justifyContent: .spaceBetween,
                                            alignItems: .center,
                                            children: [dateTextNode, spendTotalTextNode])

    return ASInsetLayoutSpec(insets: .sectionHeader, child: horizontalStack)
  }
}
