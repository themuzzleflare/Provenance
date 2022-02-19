import UIKit
import AsyncDisplayKit
import NotificationBannerSwift

final class SettingsVC: ASViewController {
  // MARK: - Properties

  private var displayBanner: GrowingNotificationBanner?

  private var apiKeyObserver: NSKeyValueObservation?

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

extension SettingsVC {
  private func configureSelf() {
    title = "Settings"
  }

  private func configureObserver() {
    apiKeyObserver = Store.provenance.observe(\.apiKey, options: .new) { [weak self] (_, change) in
      ASPerformBlockOnMainThread {
        if let alertController = self?.presentedViewController as? UIAlertController {
          alertController.textFields?.first?.text = change.newValue
          alertController.actions.last?.isEnabled = false
        }
        self?.tableNode.reloadData()
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

extension SettingsVC {
  @objc
  private func closeWorkflow() {
    navigationController?.dismiss(animated: true)
  }

  @objc
  private func textChanged() {
    guard let alert = presentedViewController as? UIAlertController,
          let action = alert.actions.last,
          let text = alert.textFields?.first?.text
    else { return }
    action.isEnabled = text.count >= 1 && text != Store.provenance.apiKey
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
    return {
      switch indexPath.section {
      case 0:
        return APIKeyCellNode()
      case 1:
        return DateStyleCellNode()
      case 2:
        return ASTextCellNode(text: "Settings", accessoryType: .disclosureIndicator)
      default:
        fatalError("Unknown section")
      }
    }
  }

  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    switch section {
    case 0:
      return "API Key"
    case 1:
      return "Date Style"
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
      return UIView()
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
      let alertController = UIAlertController.saveApiKey(self, selector: #selector(self.textChanged))
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
      return Store.provenance.apiKey.isEmpty ? nil : UIContextMenuConfiguration(elements: [
        .copyGeneric(title: "API Key", string: Store.provenance.apiKey)
      ])
    default:
      return nil
    }
  }
}
