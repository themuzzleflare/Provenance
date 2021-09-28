import AsyncDisplayKit
import SwiftDate

final class HeaderCellNode: ASCellNode {
  private let dateTextNode = ASTextNode()
  
  init(object: SortedTransactionModel?) {
    super.init()
    
    automaticallyManagesSubnodes = true
    
    dateTextNode.attributedText = object?.id.toString(.date(.medium)).styled(with: .provenance)
    
    backgroundColor = .secondarySystemGroupedBackground
  }
  
  override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
    return ASInsetLayoutSpec(insets: .sectionHeader, child: dateTextNode)
  }
}
