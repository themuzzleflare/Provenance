import AsyncDisplayKit

final class StatusIconHelpView: ASViewController {
    // MARK: - Properties
  
  private let statusIconHelpDisplayNode = StatusIconHelpNode()
  
    // MARK: - Life Cycle
  
  override init() {
    super.init(node: statusIconHelpDisplayNode)
  }
  
  required init?(coder: NSCoder) {
    fatalError("Not implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    configure()
  }
}

  // MARK: - Configuration

private extension StatusIconHelpView {
  private func configure() {
    title = "Transaction Status Icons"
    navigationItem.title = "Transaction Status Icons"
    navigationItem.largeTitleDisplayMode = .never
    navigationItem.leftBarButtonItem = .close(self, action: #selector(closeWorkflow))
  }
}

  // MARK: - Actions

private extension StatusIconHelpView {
  @objc private func closeWorkflow() {
    navigationController?.dismiss(animated: true)
  }
}
