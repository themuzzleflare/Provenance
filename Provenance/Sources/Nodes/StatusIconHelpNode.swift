import UIKit
import AsyncDisplayKit

final class StatusIconHelpNode: ASDisplayNode {
  private let heldImageNode = ASImageNode()
  private let settledImageNode = ASImageNode()
  private let heldTextNode = ASTextNode()
  private let settledTextNode = ASTextNode()
  private let cornerNode = ASImageNode()

  private var status: TransactionStatusEnum

  init(status: TransactionStatusEnum) {
    self.status = status
    super.init()
    automaticallyManagesSubnodes = true
    heldImageNode.image = .clock
    heldImageNode.imageModificationBlock = ASImageNodeTintColorModificationBlock(.systemYellow)
    settledImageNode.image = .checkmarkCircle
    settledImageNode.imageModificationBlock = ASImageNodeTintColorModificationBlock(.systemGreen)
    heldTextNode.attributedText = "Held".styled(with: .provenance, .font(.circularStdMedium(size: 23)))
    settledTextNode.attributedText = "Settled".styled(with: .provenance, .font(.circularStdMedium(size: 23)))
    cornerNode.image = .checkmarkCircleFill
    cornerNode.imageModificationBlock = ASImageNodeTintColorModificationBlock(.systemGreen)
  }

  override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
    let heldStack = ASStackLayoutSpec(direction: .horizontal,
                                      spacing: 5,
                                      justifyContent: .center,
                                      alignItems: .center,
                                      children: [heldImageNode, heldTextNode])

    let settledStack = ASStackLayoutSpec(direction: .horizontal,
                                         spacing: 5,
                                         justifyContent: .center,
                                         alignItems: .center,
                                         children: [settledImageNode, settledTextNode])

    let cornerSpec = ASCornerLayoutSpec(child: status == .held ? heldStack : settledStack, corner: cornerNode, location: .topRight)
    cornerSpec.offset = CGPoint(x: -3, y: 3)

    let finalStack = ASStackLayoutSpec(direction: .vertical,
                                       spacing: 15,
                                       justifyContent: .center,
                                       alignItems: .center,
                                       children: [])

    if status == .held {
      finalStack.children?.append(contentsOf: [cornerSpec, settledStack])
    } else {
      finalStack.children?.append(contentsOf: [heldStack, cornerSpec])
    }

    return ASCenterLayoutSpec(centeringOptions: .XY, sizingOptions: .minimumXY, child: finalStack)
  }
}
