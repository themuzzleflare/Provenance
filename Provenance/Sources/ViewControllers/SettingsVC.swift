import NotificationBannerSwift
import AsyncDisplayKit

final class SettingsVC: ASViewController {
    // MARK: - Properties
  
  private var displayBanner: GrowingNotificationBanner?
  
  var submitActionProxy: UIAlertAction!
  
  private var apiKeyObserver: NSKeyValueObservation?
  
  var textDidChangeObserver: NSObjectProtocol!
  
  let tableNode = ASTableNode(style: .grouped)
  
    // MARK: - Life Cycle
  
  init(displayBanner: GrowingNotificationBanner? = nil) {
    self.displayBanner = displayBanner
    super.init(node: tableNode)
  }
  
  deinit {
    removeObserver()
  }
  
  required init?(coder: NSCoder) {
    fatalError("Not implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    configureObserver()
    configureSelf()
    configureNavigation()
    configureTableNode()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if let displayBanner = displayBanner {
      displayBanner.show()
    }
  }
}

  // MARK: - Configuration

private extension SettingsVC {
  private func configureSelf() {
    title = "Settings"
  }
  
  private func configureObserver() {
    apiKeyObserver = ProvenanceApp.userDefaults.observe(\.apiKey, options: .new) { [weak self] (_, _) in
      guard let weakSelf = self else { return }
      DispatchQueue.main.async {
        if let alert = weakSelf.presentedViewController as? UIAlertController {
          alert.dismiss(animated: true)
        }
        weakSelf.tableNode.reloadData()
      }
    }
  }
  
  private func removeObserver() {
    apiKeyObserver?.invalidate()
    apiKeyObserver = nil
  }
  
  private func configureNavigation() {
    navigationItem.title = "Settings"
    navigationItem.largeTitleDisplayMode = .never
    navigationItem.leftBarButtonItem = .close(self, action: #selector(closeWorkflow))
  }
  
  private func configureTableNode() {
    tableNode.dataSource = self
    tableNode.delegate = self
    tableNode.view.showsVerticalScrollIndicator = false
  }
}

  // MARK: - Actions

private extension SettingsVC {
  @objc private func closeWorkflow() {
    navigationController?.dismiss(animated: true)
  }
}

  // MARK: - ASTableDataSource

extension SettingsVC: ASTableDataSource {
  func numberOfSections(in tableNode: ASTableNode) -> Int {
    return 3
  }
  
  func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
    return 1
  }
  
  func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
    let settingsNode = ASTextCellNode(text: "Settings", selectionStyle: .default, accessoryType: .disclosureIndicator)
    return {
      switch indexPath.section {
      case 0:
        return .apiKey
      case 1:
        return .dateStyle
      case 2:
        return settingsNode
      default:
        fatalError("Unknown section")
      }
    }
  }
  
  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    switch section {
    case 0:
      return "API Key"
    default:
      return nil
    }
  }
  
  func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
    switch section {
    case 0:
      return "The personal access token used to communicate with the Up Banking Developer API."
    case 1:
      return "The styling of dates displayed thoughout the application."
    case 2:
      return "Open in the Settings application."
    default:
      return nil
    }
  }
}

  // MARK: - ASTableDelegate

extension SettingsVC: ASTableDelegate {
  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    switch section {
    case 2:
      return .plainView
    default:
      return nil
    }
  }
  
  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    switch section {
    case 2:
      return 80
    default:
      return UITableView.automaticDimension
    }
  }
  
  func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
    switch indexPath.section {
    case 0:
      tableNode.deselectRow(at: indexPath, animated: true)
      let alertController = UIAlertController.saveApiKey(self)
      present(alertController, animated: true)
    case 2:
      tableNode.deselectRow(at: indexPath, animated: true)
      UIApplication.shared.open(.settingsApp)
    default:
      break
    }
  }
  
  func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
    switch indexPath.section {
    case 0:
      return ProvenanceApp.userDefaults.apiKey == .emptyString ? nil : UIContextMenuConfiguration(elements: [
        .copyGeneric(title: "API Key", string: ProvenanceApp.userDefaults.apiKey)
      ])
    default:
      return nil
    }
  }
}
