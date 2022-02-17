import UIKit
import MarqueeLabel
import AsyncDisplayKit

final class APIKeyCellNode: CellNode {
  // MARK: - Properties

  private let marqueeLabelNode = MarqueeLabelNode()

  private var apiKeyDisplay: String {
    return Store.provenance.apiKey.isEmpty ? "None" : Store.provenance.apiKey
  }

  // MARK: - Life Cycle

  override init() {
    super.init()
    automaticallyManagesSubnodes = true
  }

  override func didLoad() {
    super.didLoad()
    marqueeLabelNode.fadeLength = 30
    marqueeLabelNode.speed = .rate(100)
    marqueeLabelNode.font = .circularStdBook(size: .labelFontSize)
    marqueeLabelNode.textColor = apiKeyDisplay == "None" ? .placeholderText : .label
    marqueeLabelNode.text = apiKeyDisplay
  }

  override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
    return ASInsetLayoutSpec(insets: .cellNode, child: marqueeLabelNode)
  }
}
