import UIKit
import NotificationBannerSwift
import SwiftyBeaver
import Rswift

final class AddTagWorkflowThreeVC: UIViewController {
    // MARK: - Properties

    private var transaction: TransactionResource
    private var tags: [TagResource]

    private let tableView = UITableView(frame: .zero, style: .grouped)

    private var tagIds: String {
        tags.map { tag in
            tag.id
        }.joined(separator: ", ")
    }

    private var dateStyleObserver: NSKeyValueObservation?

    // MARK: - Life Cycle

    init(transaction: TransactionResource, tags: [TagResource]) {
        self.transaction = transaction
        self.tags = tags
        super.init(nibName: nil, bundle: nil)
        log.debug("init(transaction: \(transaction.attributes.description), tags: \(tags.count.description))")
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
        view.addSubview(tableView)
        configureProperties()
        configureNavigation()
        configureTableView()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        log.debug("viewDidLayoutSubviews")
        tableView.frame = view.bounds
    }
}

// MARK: - Configuration

private extension AddTagWorkflowThreeVC {
    private func configureProperties() {
        log.verbose("configureProperties")

        title = "Add Tag Confirmation"

        dateStyleObserver = appDefaults.observe(\.dateStyle, options: .new) { [self] object, change in
            DispatchQueue.main.async {
                tableView.reloadData()
            }
        }
    }

    private func configureNavigation() {
        log.verbose("configureNavigation")

        navigationItem.title = "Confirmation"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: R.image.checkmark(), style: .plain, target: self, action: #selector(addTag))
    }

    private func configureTableView() {
        log.verbose("configureTableView")

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "attributeCell")
        tableView.register(TransactionTableViewCell.self, forCellReuseIdentifier: TransactionTableViewCell.reuseIdentifier)
        tableView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
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
                            let notificationBanner = NotificationBanner(title: "Success", subtitle: "\(tagIds) was added to \(transaction.attributes.description).", style: .success)

                            notificationBanner.duration = 2

                            notificationBanner.show()

                            navigationController?.popViewController(animated: true)
                        default:
                            let notificationBanner = NotificationBanner(title: "Failed", subtitle: errorString(for: error!), style: .danger)

                            notificationBanner.duration = 2

                            notificationBanner.show()

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

// MARK: - UITableViewDataSource

extension AddTagWorkflowThreeVC: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section

        let cell = tableView.dequeueReusableCell(withIdentifier: "attributeCell", for: indexPath)
        let transactionCell = tableView.dequeueReusableCell(withIdentifier: TransactionTableViewCell.reuseIdentifier, for: indexPath) as! TransactionTableViewCell

        cell.selectionStyle = .none
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

// MARK: - UITableViewDelegate

extension AddTagWorkflowThreeVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
