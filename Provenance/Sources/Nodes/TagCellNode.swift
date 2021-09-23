import AsyncDisplayKit

final class TagCellNode: ASCellNode {
  private let tagTextNode = ASTextNode()
  
  init(tag: TagResource) {
    super.init()
    
    automaticallyManagesSubnodes = true
    
    accessoryType = .disclosureIndicator
    
    tagTextNode.attributedText = tag.id.styled(with: .provenance)
  }
  
  override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
    return ASInsetLayoutSpec(insets: .cellNode, child: tagTextNode)
  }
}
