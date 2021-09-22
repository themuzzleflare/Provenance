import UIKit
import AsyncDisplayKit
import MarqueeLabel

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
    let view = MarqueeLabel()
    view.speed = .rate(65)
    view.fadeLength = 10
    view.textAlignment = .left
    view.font = .circularStdBook(size: UIFont.labelFontSize)
    view.textColor = self.apiKeyDisplay == "None" ? .placeholderText : .label
    view.text = self.apiKeyDisplay
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
