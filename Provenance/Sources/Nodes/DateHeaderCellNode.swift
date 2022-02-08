import UIKit
import AsyncDisplayKit
import SwiftDate

final class DateHeaderCellNode: ASCellNode {
  private let textNode = ASTextNode()

  init(object: DateHeaderModel) {
    super.init()
    automaticallyManagesSubnodes = true
    textNode.attributedText = object.displayString.styled(with: .provenance)
    backgroundColor = .secondarySystemBackground
  }

  override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
    return ASInsetLayoutSpec(insets: .sectionHeader, child: textNode)
  }
}
