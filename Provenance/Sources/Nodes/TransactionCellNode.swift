import UIKit
import AsyncDisplayKit

final class TransactionCellNode: ASCellNode {
  private let descriptionTextNode = ASTextNode()
  private let creationDateTextNode = ASTextNode()
  private let amountTextNode = ASTextNode()
  
  init(transaction: TransactionResource) {
    super.init()
    
    automaticallyManagesSubnodes = true
    
    descriptionTextNode.attributedText = NSAttributedString(
      text: transaction.attributes.description,
      font: .circularStdBold(size: UIFont.labelFontSize)
    )
    
    creationDateTextNode.attributedText = NSAttributedString(
      text: transaction.attributes.creationDate,
      font: .circularStdBookItalic(size: UIFont.smallSystemFontSize),
      colour: .secondaryLabel
    )
    
    amountTextNode.attributedText = NSAttributedString(
      text: transaction.attributes.amount.valueShort,
      colour: transaction.attributes.amount.valueInBaseUnits.signum() == -1 ? .label : .greenColour,
      alignment: .rightAligned
    )
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
