import UIKit
import MarqueeLabel
import AsyncDisplayKit

final class APIKeyCellNode: ASCellNode {
  // MARK: - Properties

  private let marqueeLabelNode = MarqueeLabelNode()

  private var apiKeyDisplay: String {
    return UserDefaults.provenance.apiKey.isEmpty ? "None" : UserDefaults.provenance.apiKey
  }

  // MARK: - Life Cycle

  override init() {
    super.init()
    automaticallyManagesSubnodes = true
  }

  deinit {
    print("\(#function) \(String(describing: type(of: self)))")
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
