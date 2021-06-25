import UIKit
import NotificationBannerSwift
import Rswift

class AddTagWorkflowThreeVC: TableViewController {
    // MARK: - Properties

    var transaction: TransactionResource!
    var tags: [TagResource]!

    private var tagIds: String {
        tags.map { tag in
            tag.id
        }.joined(separator: ", ")
    }
    private var dateStyleObserver: NSKeyValueObservation?

    // MARK: - View Life Cycle
    
    override init(style: UITableView.Style) {
        super.init(style: style)
        configureProperties()
        configureNavigation()
        configureTableView()
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
}

// MARK: - Configuration

private extension AddTagWorkflowThreeVC {
    private func configureProperties() {
        title = "Add Tag Confirmation"
        dateStyleObserver = appDefaults.observe(\.dateStyle, options: .new) { object, change in
            self.tableView.reloadData()
        }
    }

    private func configureNavigation() {
        navigationItem.title = "Confirmation"
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: R.image.checkmark(), style: .plain, target: self, action: #selector(addTag))
    }

    private func configureTableView() {
        tableView.register(BasicTableViewCell.self, forCellReuseIdentifier: "attributeCell")
        tableView.register(TransactionTableViewCell.self, forCellReuseIdentifier: TransactionTableViewCell.reuseIdentifier)
    }
}

// MARK: - Actions

private extension AddTagWorkflowThreeVC {
    @objc private func addTag() {
        let activityIndicator = ActivityIndicator(style: .medium)
        activityIndicator.startAnimating()
        navigationItem.setRightBarButton(UIBarButtonItem(customView: activityIndicator), animated: false)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            upApi.modifyTags(adding: self.tags, to: self.transaction) { error in
                switch error {
                    case .none:
                        DispatchQueue.main.async {
                            let notificationBanner = NotificationBanner(title: "Success", subtitle: "\(self.tagIds) was added to \(self.transaction.attributes.description).", style: .success)
                            notificationBanner.duration = 2
                            notificationBanner.show()
                            self.navigationController?.popViewController(animated: true)
                        }
                    default:
                        DispatchQueue.main.async {
                            let notificationBanner = NotificationBanner(title: "Failed", subtitle: errorString(for: error!), style: .danger)
                            notificationBanner.duration = 2
                            notificationBanner.show()
                            switch error {
                                case .transportError:
                                    self.navigationController?.popToRootViewController(animated: true)
                                default:
                                    self.navigationController?.popViewController(animated: true)
                            }
                        }
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource

extension AddTagWorkflowThreeVC {
    override func numberOfSections(in tableView: UITableView) -> Int {
        3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        let cell = tableView.dequeueReusableCell(withIdentifier: "attributeCell", for: indexPath) as! BasicTableViewCell
        let transactionCell = tableView.dequeueReusableCell(withIdentifier: TransactionTableViewCell.reuseIdentifier, for: indexPath) as! TransactionTableViewCell
        cell.selectionStyle = .none
        cell.separatorInset = .zero
        cell.textLabel?.font = R.font.circularStdBook(size: UIFont.labelFontSize)
        cell.textLabel?.textAlignment = .left
        cell.textLabel?.numberOfLines = 0
        transactionCell.selectionStyle = .none
        switch section {
            case 0:
                cell.textLabel?.text = tags[indexPath.row].id
                return cell
            case 1:
                transactionCell.transaction = transaction
                return transactionCell
            case 2:
                cell.textLabel?.text = "You are adding the \(tags.count == 1 ? "tag" : "tags") \"\(tagIds)\" to the transaction \"\(transaction.attributes.description)\", which was \(appDefaults.dateStyle == "Absolute" ? "created on" : "created") \(transaction.attributes.creationDate)."
                return cell
            default:
                fatalError("Unknown section")
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
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

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
            case 2:
                return "No more than 6 tags may be present on any single transaction. Duplicate tags are silently ignored."
            default:
                return nil
        }
    }
}
