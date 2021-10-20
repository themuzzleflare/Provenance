import NotificationBannerSwift
import AsyncDisplayKit

final class AddTagConfirmationVC: ASViewController {
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

  convenience init(transaction: TransactionResource, tag: TagResource) {
    self.init(transaction: transaction, tags: .singleTag(with: tag))
  }

  deinit {
    removeObserver()
    print("deinit")
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
}

// MARK: - Configuration

private extension AddTagConfirmationVC {
  private func configureSelf() {
    title = "Add Tag Confirmation"
  }

  private func configureObserver() {
    dateStyleObserver = App.userDefaults.observe(\.dateStyle, options: .new) { [weak self] (_, _) in
      guard let weakSelf = self else { return }
      weakSelf.tableNode.reloadData()
    }
  }

  private func removeObserver() {
    dateStyleObserver?.invalidate()
    dateStyleObserver = nil
  }

  private func configureNavigation() {
    navigationItem.title = "Confirmation"
    navigationItem.largeTitleDisplayMode = .never
    navigationItem.rightBarButtonItem = .confirmAddTags(self, action: #selector(addTags))
  }

  private func configureTableNode() {
    tableNode.dataSource = self
    tableNode.allowsSelection = false
    tableNode.view.showsVerticalScrollIndicator = false
  }
}

// MARK: - Actions

private extension AddTagConfirmationVC {
  @objc
  private func addTags() {
    navigationItem.setRightBarButton(.activityIndicator, animated: false)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
      Up.modifyTags(adding: tags, to: transaction) { (error) in
        DispatchQueue.main.async {
          if let error = error {
            GrowingNotificationBanner(
              title: "Failed",
              subtitle: error.errorDescription ?? error.localizedDescription,
              style: .danger,
              duration: 2.0
            ).show()
          } else {
            GrowingNotificationBanner(
              title: "Success",
              subtitle: "\(tags.joinedWithComma) \(tags.count == 1 ? "was" : "were") added to \(transaction.attributes.description).",
              style: .success,
              duration: 2.0
            ).show()
          }
          navigationController?.popViewController(animated: true)
        }
      }
    }
  }
}

// MARK: - ASTableDataSource

extension AddTagConfirmationVC: ASTableDataSource {
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
    let transactionCellNode = TransactionCellNode(transaction: transaction, contextMenu: false)
    return {
      switch indexPath.section {
      case 0:
        return ASTextCellNode(text: tag.id, selectionStyle: UITableViewCell.SelectionStyle.none)
      case 1:
        return transactionCellNode
      case 2:
        return ASTextCellNode(text: "You are adding \(self.tags.joinedWithComma) to \(self.transaction.attributes.description), which was \(App.userDefaults.appDateStyle == .absolute ? "created on" : "created") \(self.transaction.attributes.creationDate).", selectionStyle: UITableViewCell.SelectionStyle.none)
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
