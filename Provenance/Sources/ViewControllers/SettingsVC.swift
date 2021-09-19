import UIKit
import AsyncDisplayKit
import NotificationBannerSwift

final class SettingsVC: ASViewController {
  // MARK: - Properties

  private var displayBanner: GrowingNotificationBanner?
  private var submitActionProxy: UIAlertAction!
  private var apiKeyObserver: NSKeyValueObservation?
  private var textDidChangeObserver: NSObjectProtocol!
  private let tableNode = ASTableNode(style: .grouped)

  // MARK: - Life Cycle

  init(displayBanner: GrowingNotificationBanner? = nil) {
    self.displayBanner = displayBanner
    super.init(node: tableNode)
  }

  required init?(coder: NSCoder) {
    fatalError("Not implemented")
  }

  deinit {
    removeObserver()
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    configureObserver()
    configureProperties()
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
  private func configureProperties() {
    title = "Settings"
  }

  private func configureObserver() {
    apiKeyObserver = appDefaults.observe(\.apiKey, options: .new) { [weak self] (_, change) in
      guard let weakSelf = self, let value = change.newValue else { return }
      DispatchQueue.main.async {
        if let alert = weakSelf.presentedViewController as? UIAlertController {
          alert.dismiss(animated: true)
        }
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
    navigationItem.leftBarButtonItem = UIBarButtonItem(
      barButtonSystemItem: .close,
      target: self,
      action: #selector(closeWorkflow)
    )
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
    let settingsCell = ASTextCellNode(text: "Settings", selectionStyle: .default, accessoryType: .disclosureIndicator)
    return {
      switch indexPath.section {
      case 0:
        return APIKeyCellNode()
      case 1:
        return DateStyleCellNode()
      case 2:
        return settingsCell
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
      let alertController = UIAlertController(
        title: "API Key",
        message: "Enter a new API Key.",
        preferredStyle: .alert
      )
      alertController.addTextField { [self] (textField) in
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.text = appDefaults.apiKey
        textDidChangeObserver = NotificationCenter.default.addObserver(
          forName: UITextField.textDidChangeNotification,
          object: textField,
          queue: .main,
          using: { (notification) in
            if let change = notification.object as? UITextField, let text = change.text {
              submitActionProxy.isEnabled = text.count >= 1 && text != appDefaults.apiKey
            } else {
              submitActionProxy.isEnabled = false
            }
          }
        )
      }
      let submitAction = UIAlertAction(
        title: "Save",
        style: .default,
        handler: { (_) in
          if let answer = alertController.textFields?.first?.text {
            if !answer.isEmpty && answer != appDefaults.apiKey {
              UpFacade.ping(with: answer) { (error) in
                DispatchQueue.main.async {
                  switch error {
                  case .none:
                    GrowingNotificationBanner(
                      title: "Success",
                      subtitle: "The API Key was verified and saved.",
                      style: .success
                    ).show()
                    appDefaults.apiKey = answer
                  default:
                    GrowingNotificationBanner(
                      title: "Failed",
                      subtitle: error!.description,
                      style: .danger
                    ).show()
                  }
                }
              }
            } else {
              GrowingNotificationBanner(
                title: "Failed",
                subtitle: "The provided API Key was the same as the current one.",
                style: .danger
              ).show()
            }
          }
        }
      )
      submitAction.isEnabled = false
      submitActionProxy = submitAction
      alertController.addAction(.cancel)
      alertController.addAction(submitAction)
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
      switch appDefaults.apiKey {
      case "":
        return nil
      default:
        return UIContextMenuConfiguration(
          identifier: nil,
          previewProvider: nil,
          actionProvider: { (_) in
            UIMenu(children: [
              UIAction(
                title: "Copy API Key",
                image: .docOnClipboard,
                handler: { (_) in
                  UIPasteboard.general.string = appDefaults.apiKey
                }
              )
            ])
          }
        )
      }
    default:
      return nil
    }
  }
}
