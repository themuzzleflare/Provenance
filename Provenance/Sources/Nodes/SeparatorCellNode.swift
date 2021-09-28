import AsyncDisplayKit

final class SeparatorCellNode: ASCellNode {
  override init() {
    super.init()
    
    automaticallyManagesSubnodes = true
    
    backgroundColor = .separator
  }
}
