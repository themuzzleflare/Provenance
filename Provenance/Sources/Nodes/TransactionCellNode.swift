import UIKit
import AsyncDisplayKit
import Rswift

final class TransactionCellNode: ASCellNode {
    let descriptionNode = ASTextNode()
    let creationDateNode = ASTextNode()
    let amountNode = ASTextNode()

    init(transaction: TransactionResource) {
        super.init()

        automaticallyManagesSubnodes = true

        descriptionNode.attributedText = NSAttributedString(
            string: transaction.attributes.transactionDescription,
            attributes: [
                .font: R.font.circularStdBold(size: UIFont.labelFontSize),
                .foregroundColor: UIColor.label
            ]
        )

        creationDateNode.attributedText = NSAttributedString(
            string: transaction.attributes.creationDate,
            attributes: [
                .font: R.font.circularStdBookItalic(size: UIFont.smallSystemFontSize),
                .foregroundColor: UIColor.secondaryLabel
            ]
        )

        amountNode.attributedText = NSAttributedString(
            string: transaction.attributes.amount.valueShort,
            attributes: [
                .font: R.font.circularStdBook(size: UIFont.labelFontSize),
                .foregroundColor: transaction.attributes.amount.valueInBaseUnits.signum() == -1
                    ? .label : R.color.greenColour()
            ]
        )
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let vStack = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 0,
            justifyContent: .start,
            alignItems: .start,
            children: [
                descriptionNode,
                creationDateNode
            ]
        )

        vStack.style.flexShrink = 1.0
        vStack.style.flexGrow = 1.0

        let hStack = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 0,
            justifyContent: .spaceBetween,
            alignItems: .center,
            children: [
                vStack,
                amountNode
            ]
        )

        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(
                top: 13,
                left: 16,
                bottom: 13,
                right: 16
            ),
            child: hStack
        )
    }
}
