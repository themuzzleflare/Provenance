import UIKit
import AsyncDisplayKit

final class TransactionCellNode: ASCellNode {
  private let descriptionTextNode = ASTextNode()
  private let creationDateTextNode = ASTextNode()
  private let amountTextNode = ASTextNode()

  private var model: TransactionCellModel
  private var usingContextMenu: Bool
  private var selection: Bool

  init(transaction: TransactionCellModel, contextMenu: Bool = true, selection: Bool = true) {
    self.model = transaction
    self.usingContextMenu = contextMenu
    self.selection = selection
    super.init()
    automaticallyManagesSubnodes = true
    descriptionTextNode.attributedText = transaction.transactionDescription.styled(with: .transactionDescription)
    descriptionTextNode.maximumNumberOfLines = 2
    descriptionTextNode.truncationMode = .byTruncatingTail
    creationDateTextNode.attributedText = transaction.creationDate.styled(with: .transactionCreationDate)
    amountTextNode.attributedText = transaction.amount.styled(with: .transactionAmount, .color(transaction.colour.uiColour))
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
    let verticalStack = ASStackLayoutSpec.vertical()
    verticalStack.style.flexShrink = 1.0
    verticalStack.style.flexGrow = 1.0
    verticalStack.children = [descriptionTextNode, creationDateTextNode]

    let horizontalStack = ASStackLayoutSpec(
      direction: .horizontal,
      spacing: 40,
      justifyContent: .start,
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
      .copyTransactionDescription(transaction: model.transactionDescription),
      .copyTransactionCreationDate(transaction: model.creationDate),
      .copyTransactionAmount(transaction: model.amount)
    ])
  }
}
