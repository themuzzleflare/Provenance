import UIKit
import AsyncDisplayKit

final class WidgetsVC: ASViewController {
  // MARK: - Properties

  private let widgetsScrollNode = WidgetsNode()

  // MARK: - Life Cycle

  override init() {
    super.init(node: widgetsScrollNode)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.title = "Widgets"
  }
}
