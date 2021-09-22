import UIKit
import AsyncDisplayKit
import NotificationBannerSwift

final class AddTagWorkflowThreeVC: ASViewController {
    // MARK: - Properties
  
  private var transaction: TransactionResource
  
  private var tags: [TagResource]
  
  private let tableNode = ASTableNode(style: .grouped)
  
  private var dateStyleObserver: NSKeyValueObservation?
  
    // MARK: - Life Cycle
  
  init(transaction: TransactionResource, tags: [TagResource]) {
    self.transaction = transaction
    self.tags = tags
    super.init(node: tableNode)
  }
  
  init(transaction: TransactionResource, tag: TagResource) {
    self.transaction = transaction
    self.tags = [tag]
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
    configureProperties()
    configureNavigation()
    configureTableNode()
  }
}

  // MARK: - Configuration

private extension AddTagWorkflowThreeVC {
  private func configureProperties() {
    title = "Add Tag Confirmation"
  }
  
  private func configureObserver() {
    dateStyleObserver = ProvenanceApp.userDefaults.observe(\.dateStyle, options: .new) { [weak self] (_, _) in
      guard let weakSelf = self else { return }
      DispatchQueue.main.async {
        weakSelf.tableNode.reloadData()
      }
    }
  }
  
  private func removeObserver() {
    dateStyleObserver?.invalidate()
    dateStyleObserver = nil
  }
  
  private func configureNavigation() {
    navigationItem.title = "Confirmation"
    navigationItem.largeTitleDisplayMode = .never
    navigationItem.rightBarButtonItem = UIBarButtonItem(image: .checkmark, style: .plain, target: self, action: #selector(addTag))
  }
  
  private func configureTableNode() {
    tableNode.dataSource = self
    tableNode.view.showsVerticalScrollIndicator = false
  }
}

  // MARK: - Actions

private extension AddTagWorkflowThreeVC {
  @objc private func addTag() {
    let activityIndicator = UIActivityIndicatorView.mediumAnimating
    let barButtonItem = UIBarButtonItem(customView: activityIndicator)
    navigationItem.setRightBarButton(barButtonItem, animated: false)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
      UpFacade.modifyTags(adding: tags, to: transaction) { (error) in
        DispatchQueue.main.async {
          switch error {
          case .none:
            GrowingNotificationBanner(
              title: "Success",
              subtitle: "\(tags.joinedWithComma) was added to \(transaction.attributes.description).",
              style: .success
            ).show()
            navigationController?.popViewController(animated: true)
          default:
            GrowingNotificationBanner(
              title: "Failed",
              subtitle: error!.description,
              style: .danger
            ).show()
            switch error {
            case .transportError:
              navigationController?.popToRootViewController(animated: true)
            default:
              navigationController?.popViewController(animated: true)
            }
          }
        }
      }
    }
  }
}

  // MARK: - ASTableDataSource

extension AddTagWorkflowThreeVC: ASTableDataSource {
  func numberOfSections(in tableNode: ASTableNode) -> Int {
    return 3
  }
  
  func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
    switch section {
    case 0:
      return tags.count
    case 1:
      return 1
    case 2:
      return 1
    default:
      fatalError("Unknown section")
    }
  }
  
  func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
    let tag = tags[indexPath.row]
    let transactionCellNode = TransactionCellNode(transaction: transaction)
    transactionCellNode.selectionStyle = .none
    return {
      switch indexPath.section {
      case 0:
        return ASTextCellNode(text: tag.id, selectionStyle: .none)
      case 1:
        return transactionCellNode
      case 2:
        return ASTextCellNode(text: "You are adding the \(self.tags.count == 1 ? "tag" : "tags") \"\(self.tags.joinedWithComma)\" to the transaction \"\(self.transaction.attributes.description)\", which was \(ProvenanceApp.userDefaults.appDateStyle == .absolute ? "created on" : "created") \(self.transaction.attributes.creationDate).", selectionStyle: .none)
      default:
        fatalError("Unknown section")
      }
    }
  }
  
  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    switch section {
    case 0:
      return "Adding \(tags.count == 1 ? "Tag" : "Tags")"
    case 1:
      return "To Transaction"
    case 2:
      return "Summary"
    default:
      return nil
    }
  }
  
  func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
    switch section {
    case 2:
      return "No more than 6 tags may be present on any single transaction. Duplicate tags are silently ignored."
    default:
      return nil
    }
  }
}
