import UIKit
import AsyncDisplayKit
import NotificationBannerSwift
import SwiftyBeaver
import Rswift

final class AddTagWorkflowThreeVC: ASDKViewController<ASTableNode> {
    // MARK: - Properties

    private var transaction: TransactionResource

    private var tags: [TagResource]

    private let tableNode = ASTableNode(style: .grouped)

    private var tagIds: String {
        return tags.map { $0.id }.joined(separator: ", ")
    }

    private var dateStyleObserver: NSKeyValueObservation?

    // MARK: - Life Cycle

    init(transaction: TransactionResource, tags: [TagResource]) {
        self.transaction = transaction
        self.tags = tags
        super.init(node: tableNode)
        log.debug("init(transaction: \(transaction.attributes.transactionDescription), tags: \(tags.count.description))")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        log.debug("deinit")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        log.debug("viewDidLoad")
        configureProperties()
        configureNavigation()
        configureTableNode()
    }
}

// MARK: - Configuration

private extension AddTagWorkflowThreeVC {
    private func configureProperties() {
        log.verbose("configureProperties")

        title = "Add Tag Confirmation"

        dateStyleObserver = appDefaults.observe(\.dateStyle, options: .new) { [self] _, _ in
            DispatchQueue.main.async {
                tableNode.reloadData()
            }
        }
    }

    private func configureNavigation() {
        log.verbose("configureNavigation")

        navigationItem.title = "Confirmation"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: R.image.checkmark(), style: .plain, target: self, action: #selector(addTag))
    }

    private func configureTableNode() {
        log.verbose("configureTableNode")

        tableNode.dataSource = self
        tableNode.view.showsVerticalScrollIndicator = false
    }
}

// MARK: - Actions

private extension AddTagWorkflowThreeVC {
    @objc private func addTag() {
        log.verbose("addTag")

        let activityIndicator: UIActivityIndicatorView = {
            let aiv = UIActivityIndicatorView()
            aiv.startAnimating()
            return aiv
        }()

        navigationItem.setRightBarButton(UIBarButtonItem(customView: activityIndicator), animated: false)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
            Up.modifyTags(adding: tags, to: transaction) { error in
                DispatchQueue.main.async {
                    switch error {
                    case .none:
                        let nb = GrowingNotificationBanner(title: "Success", subtitle: "\(tagIds) was added to \(transaction.attributes.transactionDescription).", style: .success)

                        nb.duration = 2

                        nb.show()

                        navigationController?.popViewController(animated: true)
                    default:
                        let nb = GrowingNotificationBanner(title: "Failed", subtitle: errorString(for: error!), style: .danger)

                        nb.duration = 2

                        nb.show()

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
        let section = indexPath.section

        let cell = ASTextCellNode(attributes: [NSAttributedString.Key.font: R.font.circularStdBook(size: UIFont.labelFontSize), NSAttributedString.Key.foregroundColor: UIColor.label], insets: UIEdgeInsets(top: 13, left: 16, bottom: 13, right: 16))

        cell.selectionStyle = .none

        let tcell = TransactionCellNode(transaction: transaction)

        tcell.selectionStyle = .none

        let tag = tags[indexPath.row].id

        return {
            switch section {
            case 0:
                cell.text = tag

                return cell
            case 1:
                return tcell
            case 2:
                cell.text = "You are adding the \(self.tags.count == 1 ? "tag" : "tags") \"\(self.tagIds)\" to the transaction \"\(self.transaction.attributes.transactionDescription)\", which was \(appDefaults.dateStyle == "Absolute" ? "created on" : "created") \(self.transaction.attributes.creationDate)."

                return cell
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
