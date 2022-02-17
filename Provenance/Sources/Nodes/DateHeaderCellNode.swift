import UIKit
import AsyncDisplayKit

final class DateHeaderCellNode: CellNode {
  private let textNode = ASTextNode()

  private var model: DateHeaderModel

  init(model: DateHeaderModel) {
    self.model = model
    super.init()
    automaticallyManagesSubnodes = true
    textNode.attributedText = model.displayString.styled(with: .provenance)
    backgroundColor = .secondarySystemBackground
  }

  override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
    return ASInsetLayoutSpec(insets: .sectionHeader, child: textNode)
  }
}
