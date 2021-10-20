import AsyncDisplayKit
import SwiftDate

final class HeaderCellNode: ASCellNode {
  private let textNode = ASTextNode()

  init(object: SortedTransactionModel?) {
    super.init()
    automaticallyManagesSubnodes = true
    textNode.attributedText = object?.id.toString(.date(.medium)).styled(with: .provenance)
    backgroundColor = .secondarySystemBackground
  }

  init(object: SortedSectionModel?) {
    super.init()
    automaticallyManagesSubnodes = true
    textNode.attributedText = object?.id.toString(.date(.medium)).styled(with: .provenance)
    backgroundColor = .secondarySystemBackground
  }

  init(object: TagSectionModel?) {
    super.init()
    automaticallyManagesSubnodes = true
    textNode.attributedText = object?.id.uppercased().styled(with: .provenance)
    backgroundColor = .secondarySystemBackground
  }

  init(object: SortedTagSectionModel?) {
    super.init()
    automaticallyManagesSubnodes = true
    textNode.attributedText = object?.id.uppercased().styled(with: .provenance)
    backgroundColor = .secondarySystemBackground
  }

  override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
    return ASInsetLayoutSpec(insets: .sectionHeader, child: textNode)
  }
}
