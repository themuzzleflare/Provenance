import MarqueeLabel
import AsyncDisplayKit

final class APIKeyCellNode: ASCellNode {
    // MARK: - Properties
  
  private var apiKeyDisplay: String {
    switch ProvenanceApp.userDefaults.apiKey {
    case .emptyString:
      return "None"
    default:
      return ProvenanceApp.userDefaults.apiKey
    }
  }
  
  private lazy var marqueeLabel = ASDisplayNode { () -> UIView in
    let view = MarqueeLabel(text: self.apiKeyDisplay)
    view.textColor = self.apiKeyDisplay == "None" ? .placeholderText : .label
    return view
  }
  
    // MARK: - Life Cycle
  
  override init() {
    super.init()
    automaticallyManagesSubnodes = true
    marqueeLabel.style.preferredSize = CGSize(width: 200, height: 30)
  }
  
  override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
    return ASInsetLayoutSpec(insets: .cellNode, child: marqueeLabel)
  }
}
