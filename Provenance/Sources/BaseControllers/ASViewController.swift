import UIKit
import AsyncDisplayKit

class ASViewController: ASDKViewController<ASDisplayNode> {
  override func viewDidLoad() {
    super.viewDidLoad()
    configureNode()
  }

  private func configureNode() {
    node.backgroundColor = .systemBackground
  }
}
