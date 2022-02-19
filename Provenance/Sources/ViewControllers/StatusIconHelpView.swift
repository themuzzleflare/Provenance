import UIKit
import AsyncDisplayKit

final class StatusIconHelpView: ASViewController {
  // MARK: - Properties

  private let statusIconHelpDisplayNode: StatusIconHelpNode

  // MARK: - Life Cycle

  init(status: TransactionStatusEnum) {
    self.statusIconHelpDisplayNode = StatusIconHelpNode(status: status)
    super.init(node: statusIconHelpDisplayNode)
  }

  required init?(coder: NSCoder) {
    fatalError("Not implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    configureSelf()
    configureNavigation()
  }
}

// MARK: - Configuration

extension StatusIconHelpView {
  private func configureSelf() {
    title = "Transaction Status Icons"
  }

  private func configureNavigation() {
    navigationItem.title = "Transaction Status Icons"
    navigationItem.largeTitleDisplayMode = .never
    navigationItem.leftBarButtonItem = .close(self, action: #selector(closeWorkflow))
  }
}

// MARK: - Actions

extension StatusIconHelpView {
  @objc
  private func closeWorkflow() {
    navigationController?.dismiss(animated: true)
  }
}
