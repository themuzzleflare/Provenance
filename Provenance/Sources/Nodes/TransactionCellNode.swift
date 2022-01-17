import UIKit
import AsyncDisplayKit

final class TransactionCellNode: ASCellNode {
  private let descriptionTextNode = ASTextNode()
  private let creationDateTextNode = ASTextNode()
  private let amountTextNode = ASTextNode()

  private var usingContextMenu: Bool
  private var selection: Bool
  private var transactionDescription: String
  private var creationDate: String
  private var amount: String
  private var colour: TransactionColourEnum

  init(transaction: TransactionResource, contextMenu: Bool = true, selection: Bool = true) {
    self.usingContextMenu = contextMenu
    self.selection = selection
    self.transactionDescription = transaction.attributes.description
    self.creationDate = transaction.attributes.creationDate
    self.amount = transaction.attributes.amount.valueShort
    self.colour = transaction.attributes.amount.transactionType.colour
    super.init()
    automaticallyManagesSubnodes = true
    descriptionTextNode.attributedText = transactionDescription.styled(with: .transactionDescription)
    creationDateTextNode.attributedText = creationDate.styled(with: .transactionCreationDate)
    amountTextNode.attributedText = amount.styled(with: .transactionAmount, .color(colour.uiColour))
  }

  init(transaction: TransactionCellModel?, contextMenu: Bool = true, selection: Bool = true) {
    self.usingContextMenu = contextMenu
    self.selection = selection
    self.transactionDescription = transaction?.transactionDescription ?? ""
    self.creationDate = transaction?.creationDate ?? ""
    self.amount = transaction?.amount ?? ""
    self.colour = transaction?.colour ?? .unknown
    super.init()
    automaticallyManagesSubnodes = true
    descriptionTextNode.attributedText = transactionDescription.styled(with: .transactionDescription)
    creationDateTextNode.attributedText = creationDate.styled(with: .transactionCreationDate)
    amountTextNode.attributedText = amount.styled(with: .transactionAmount, .color(colour.uiColour))
  }

  override func didLoad() {
    super.didLoad()
    if usingContextMenu {
      view.addInteraction(UIContextMenuInteraction(delegate: self))
    }
  }

  override var isSelected: Bool {
    didSet {
      backgroundColor = selection && isSelected ? .gray.withAlphaComponent(0.3) : .clear
    }
  }

  override var isHighlighted: Bool {
    didSet {
      backgroundColor = selection && isHighlighted ? .gray.withAlphaComponent(0.3) : .clear
    }
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

// MARK: - UIContextMenuInteractionDelegate

extension TransactionCellNode: UIContextMenuInteractionDelegate {
  func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
    return UIContextMenuConfiguration(elements: [
      .copyTransactionDescription(transaction: transactionDescription),
      .copyTransactionCreationDate(transaction: creationDate),
      .copyTransactionAmount(transaction: amount)
    ])
  }
}
