import AsyncDisplayKit

final class SubtitleCellNode: ASCellNode {
  private let topTextNode = ASTextNode()
  private let bottomTextNode = ASTextNode()
  
  init(text: String, detailText: String) {
    super.init()
    
    automaticallyManagesSubnodes = true
    
    selectionStyle = .none
    
    topTextNode.attributedText = text.styled(with: .provenance)
    
    bottomTextNode.attributedText = detailText.styled(with: .bottomText)
  }
  
  override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
    let horizontalStack = ASStackLayoutSpec(
      direction: .vertical,
      spacing: 0,
      justifyContent: .start,
      alignItems: .start,
      children: (bottomTextNode.attributedText?.string.isEmpty)! ? [topTextNode] : [topTextNode, bottomTextNode]
    )
    
    return ASInsetLayoutSpec(insets: .cellNode, child: horizontalStack)
  }
}
