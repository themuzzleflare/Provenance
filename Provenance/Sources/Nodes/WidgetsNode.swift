import UIKit
import AsyncDisplayKit

final class WidgetsNode: ASScrollNode {
  private let accountBalanceImageNode = ASImageNode()
  private let latestTransactionImageNode = ASImageNode()
  private let titleTextNode = ASTextNode()
  private let instructionsTextNode = ASTextNode()

  override init() {
    super.init()
    automaticallyManagesSubnodes = true
    automaticallyManagesContentSize = true
    accountBalanceImageNode.image = .actbalsmall
    accountBalanceImageNode.style.width = ASDimension(unit: .points, value: 150)
    accountBalanceImageNode.style.height = ASDimension(unit: .points, value: 150)
    latestTransactionImageNode.image = .lttrnssmall
    latestTransactionImageNode.style.width = ASDimension(unit: .points, value: 150)
    latestTransactionImageNode.style.height = ASDimension(unit: .points, value: 150)
    titleTextNode.attributedText = "Adding a Widget".styled(with: .addingWidgetTitle)
    instructionsTextNode.attributedText = "1. Long-press an empty area on your Home Screen until the apps jiggle.\n\n2. Tap the plus button in the upper-right corner to bring up the widget picker.\n\n3. Find Provenance in the list.\n\n4. Tap the Add Widget button or drag the widget to the desired spot on your Home Screen.".styled(with: .provenance)
  }

  override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
    let horizontalStack = ASStackLayoutSpec(direction: .horizontal,
                                            spacing: 20,
                                            justifyContent: .center,
                                            alignItems: .center,
                                            children: [accountBalanceImageNode, latestTransactionImageNode])

    let verticalStack = ASStackLayoutSpec(direction: .vertical,
                                          spacing: 15,
                                          justifyContent: .center,
                                          alignItems: .center,
                                          children: [horizontalStack, titleTextNode, instructionsTextNode])

    return ASInsetLayoutSpec(insets: .cellNode, child: verticalStack)
  }
}
