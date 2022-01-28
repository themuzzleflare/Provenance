import UIKit
import AsyncDisplayKit

final class WidgetsVC: ASViewController {
  // MARK: - Properties

  private let widgetsScrollNode = WidgetsNode()

  // MARK: - Life Cycle

  override init() {
    super.init(node: widgetsScrollNode)
  }

  deinit {
    print("\(#function) \(String(describing: type(of: self)))")
  }

  required init?(coder: NSCoder) {
    fatalError("Not implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.title = "Widgets"
  }
}
