import UIKit
import AsyncDisplayKit

class ASViewController: ASDKViewController<ASDisplayNode> {
  deinit {
#if DEBUG
    print("\(#function) \(String(describing: type(of: self)))")
#endif
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    configureNode()
  }

  private func configureNode() {
    node.backgroundColor = .systemBackground
  }
}
