import AsyncDisplayKit

final class TransactionCellNode: ASCellNode {
  private let descriptionTextNode = ASTextNode()
  private let creationDateTextNode = ASTextNode()
  private let amountTextNode = ASTextNode()
  
  init(transaction: TransactionResource) {
    super.init()
    
    automaticallyManagesSubnodes = true
    
    descriptionTextNode.attributedText = transaction.attributes.description.styled(with: .transactionDescription)
    
    creationDateTextNode.attributedText = transaction.attributes.creationDate.styled(with: .transactionCreationDate)
    
    amountTextNode.attributedText = transaction.attributes.amount.valueShort.styled(with: .transactionAmount, .color(transaction.attributes.amount.transactionType.colour.uiColour))
  }
  
  override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
    let verticalStack = ASStackLayoutSpec(
      direction: .vertical,
      spacing: 0,
      justifyContent: .start,
      alignItems: .start,
      children: [
        descriptionTextNode,
        creationDateTextNode
      ]
    )
    
    verticalStack.style.flexShrink = 1.0
    verticalStack.style.flexGrow = 1.0
    
    let horizontalStack = ASStackLayoutSpec(
      direction: .horizontal,
      spacing: 5,
      justifyContent: .spaceBetween,
      alignItems: .center,
      children: [
        verticalStack,
        amountTextNode
      ]
    )
    
    return ASInsetLayoutSpec(insets: .cellNode, child: horizontalStack)
  }
}
