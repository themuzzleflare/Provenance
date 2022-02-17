import UIKit
import AsyncDisplayKit

final class TransactionCellNode: CellNode {
  private let descriptionTextNode = ASTextNode()
  private let creationDateTextNode = ASTextNode()
  private let amountTextNode = ASTextNode()

  private var model: TransactionCellModel
  private var contextMenu: Bool
  private var selection: Bool

  init(model: TransactionCellModel, contextMenu: Bool = true, selection: Bool = true) {
    self.model = model
    self.contextMenu = contextMenu
    self.selection = selection
    super.init()
    automaticallyManagesSubnodes = true
    descriptionTextNode.attributedText = model.transactionDescription.styled(with: .transactionDescription)
    descriptionTextNode.maximumNumberOfLines = 2
    descriptionTextNode.truncationMode = .byTruncatingTail
    creationDateTextNode.attributedText = model.creationDate.styled(with: .transactionCreationDate)
    amountTextNode.attributedText = model.amount.styled(with: .transactionAmount, .color(model.colour.uiColour))
  }

  override func didLoad() {
    super.didLoad()
    if contextMenu {
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

    let horizontalStack = ASStackLayoutSpec(direction: .horizontal,
                                            spacing: 40,
                                            justifyContent: .start,
                                            alignItems: .center,
                                            children: [verticalStack, amountTextNode])

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
