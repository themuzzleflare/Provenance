import UIKit
import AsyncDisplayKit

final class StatusIconHelpNode: ASDisplayNode {
  private let heldImageNode = ASImageNode()
  private let settledImageNode = ASImageNode()
  private let heldTextNode = ASTextNode()
  private let settledTextNode = ASTextNode()

  override init() {
    super.init()
    automaticallyManagesSubnodes = true
    heldImageNode.image = .clock
    heldImageNode.imageModificationBlock = ASImageNodeTintColorModificationBlock(.systemYellow)
    settledImageNode.image = .checkmarkCircle
    settledImageNode.imageModificationBlock = ASImageNodeTintColorModificationBlock(.systemGreen)
    heldTextNode.attributedText = "Held".styled(with: .provenance, .font(.circularStdMedium(size: 23)))
    settledTextNode.attributedText = "Settled".styled(with: .provenance, .font(.circularStdMedium(size: 23)))
  }

  override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
    let heldStack = ASStackLayoutSpec(
      direction: .horizontal,
      spacing: 5,
      justifyContent: .center,
      alignItems: .center,
      children: [
        heldImageNode,
        heldTextNode
      ]
    )

    let settledStack = ASStackLayoutSpec(
      direction: .horizontal,
      spacing: 5,
      justifyContent: .center,
      alignItems: .center,
      children: [
        settledImageNode,
        settledTextNode
      ]
    )

    let finalStack = ASStackLayoutSpec(
      direction: .vertical,
      spacing: 15,
      justifyContent: .center,
      alignItems: .center,
      children: [
        heldStack,
        settledStack
      ]
    )

    return ASCenterLayoutSpec(centeringOptions: .XY, sizingOptions: .minimumXY, child: finalStack)
  }
}
