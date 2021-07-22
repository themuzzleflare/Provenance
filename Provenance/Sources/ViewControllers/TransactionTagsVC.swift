import UIKit
import NotificationBannerSwift
import SwiftyBeaver
import Rswift

final class TransactionTagsVC: UIViewController {
    // MARK: - Properties

    private var transaction: TransactionResource {
        didSet {
            log.info("didSet transaction: \(transaction.attributes.transactionDescription)")

            if transaction.relationships.tags.data.isEmpty {
                navigationController?.popViewController(animated: true)
            } else {
                applySnapshot()
                updateToolbarItems()
                tableView.refreshControl?.endRefreshing()
            }
        }
    }

    private enum Section {
        case main
    }

    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, RelationshipData>

    private lazy var dataSource = makeDataSource()

    private lazy var addBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(openAddWorkflow))

    private lazy var selectionBarButtonItem = UIBarButtonItem(title: "Select All" , style: .plain, target: self, action: #selector(selectionAction))

    private lazy var removeAllBarButtonItem = UIBarButtonItem(title: "Remove All" , style: .plain, target: self, action: #selector(removeAllTags))

    private lazy var removeBarButtonItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(removeTags))

    private let tableView = UITableView(frame: .zero, style: .grouped)

    private let tableRefreshControl: UIRefreshControl = {
        let rc = UIRefreshControl()
        rc.addTarget(self, action: #selector(refreshTags), for: .valueChanged)
        return rc
    }()

    // UITableViewDiffableDataSource
    private class DataSource: UITableViewDiffableDataSource<Section, RelationshipData> {
        weak var parent: TransactionTagsVC! = nil

        override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
            return true
        }

        override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            log.debug("tableView(commit editingStyle: \(editingStyle.rawValue), forRowAt indexPath: \(indexPath))")

            guard let tag = itemIdentifier(for: indexPath) else { return }

            switch editingStyle {
                case .delete:
                    let ac = UIAlertController(title: nil, message: "Are you sure you want to remove \"\(tag.id)\" from \"\(parent.transaction.attributes.transactionDescription)\"?", preferredStyle: .actionSheet)

                    let confirmAction = UIAlertAction(title: "Remove", style: .destructive) { [self] _ in
                        let tagObject = TagResource(id: tag.id)

                        Up.modifyTags(removing: tagObject, from: parent.transaction) { error in
                            DispatchQueue.main.async {
                                switch error {
                                    case .none:
                                        let nb = GrowingNotificationBanner(title: "Success", subtitle: "\(tag.id) was removed from \(parent.transaction.attributes.transactionDescription).", style: .success)

                                        nb.duration = 2

                                        nb.show()

                                        parent.fetchTransaction()
                                    default:
                                        let nb = GrowingNotificationBanner(title: "Failed", subtitle: errorString(for: error!), style: .danger)

                                        nb.duration = 2

                                        nb.show()
                                }
                            }
                        }
                    }

                    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

                    cancelAction.setValue(R.color.accentColor(), forKey: "titleTextColor")

                    ac.addAction(confirmAction)
                    ac.addAction(cancelAction)

                    parent.present(ac, animated: true)
                default:
                    break
            }
        }
    }

    // MARK: - Life Cycle

    init(transaction: TransactionResource) {
        self.transaction = transaction
        super.init(nibName: nil, bundle: nil)
        log.debug("init(transaction: \(transaction.attributes.transactionDescription))")
        dataSource.parent = self
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
        configureToolbar()
        configureTableView()
        applySnapshot()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        log.debug("viewDidLayoutSubviews")
        tableView.frame = view.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        log.debug("viewWillAppear(animated: \(animated.description))")
        fetchTransaction()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        log.debug("viewDidAppear(animated: \(animated.description))")
        navigationController?.setToolbarHidden(!isEditing, animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        log.debug("viewWillDisappear(animated: \(animated.description))")
        navigationController?.setToolbarHidden(true, animated: false)
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        log.debug("setEditing(editing: \(editing.description), animated: \(animated.description))")
        tableView.setEditing(editing, animated: animated)

        updateToolbarItems()
        addBarButtonItem.isEnabled = !editing

        navigationController?.setToolbarHidden(!editing, animated: true)
    }
}

// MARK: - Configuration

private extension TransactionTagsVC {
    private func configureProperties() {
        log.verbose("configureProperties")

        title = "Transaction Tags"

        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    private func configureNavigation() {
        log.verbose("configureNavigation")

        navigationItem.title = "Tags"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.backBarButtonItem = UIBarButtonItem(image: R.image.tag())
        navigationItem.rightBarButtonItems = [addBarButtonItem, editButtonItem]
    }

    private func configureToolbar() {
        log.verbose("configureToolbar")

        setToolbarItems([selectionBarButtonItem, removeAllBarButtonItem, .flexibleSpace(), removeBarButtonItem], animated: false)
    }

    private func configureTableView() {
        log.verbose("configureTableView")

        tableView.dataSource = dataSource
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "tagCell")
        tableView.refreshControl = tableRefreshControl
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        tableView.showsVerticalScrollIndicator = false
        tableView.tintColor = R.color.accentColor()
    }
}

// MARK: - Actions

private extension TransactionTagsVC {
    @objc private func appMovedToForeground() {
        log.verbose("appMovedToForeground")

        fetchTransaction()
    }

    @objc private func openAddWorkflow() {
        log.verbose("openAddWorkflow")

        let vcNav = NavigationController(rootViewController: AddTagWorkflowTwoVC(transaction: transaction, fromTransactionTags: true))

        vcNav.modalPresentationStyle = .fullScreen

        present(vcNav, animated: true)
    }

    @objc private func refreshTags() {
        log.verbose("refreshTags")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
            fetchTransaction()
        }
    }

    @objc private func selectionAction() {
        log.verbose("selectionAction")

        switch tableView.indexPathsForSelectedRows?.count {
            case transaction.relationships.tags.data.count:
                tableView.indexPathsForSelectedRows?.forEach { tableView.deselectRow(at: $0, animated: false) }
            default:
                let indexes = transaction.relationships.tags.data.map { dataSource.indexPath(for: $0) }

                indexes.forEach { tableView.selectRow(at: $0, animated: false, scrollPosition: .none) }
        }

        updateToolbarItems()
    }

    @objc private func removeTags() {
        log.verbose("removeTags")

        if let tags = tableView.indexPathsForSelectedRows?.map { dataSource.itemIdentifier(for: $0) } {
            let tagIds = tags.map { $0!.id }.joined(separator: ", ")

            let ac = UIAlertController(title: nil, message: "Are you sure you want to remove \"\(tagIds)\" from \"\(transaction.attributes.transactionDescription)\"?", preferredStyle: .actionSheet)

            let confirmAction = UIAlertAction(title: "Remove", style: .destructive) { [self] _ in
                let tagsObject = tags.map { TagResource(id: $0!.id) }

                Up.modifyTags(removing: tagsObject, from: transaction) { error in
                    DispatchQueue.main.async {
                        switch error {
                            case .none:
                                let nb = GrowingNotificationBanner(title: "Success", subtitle: "\(tagIds) was removed from \(transaction.attributes.transactionDescription).", style: .success)

                                nb.duration = 2

                                nb.show()

                                fetchTransaction()
                            default:
                                let nb = GrowingNotificationBanner(title: "Failed", subtitle: errorString(for: error!), style: .danger)

                                nb.duration = 2

                                nb.show()
                        }
                    }
                }
            }

            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

            cancelAction.setValue(R.color.accentColor(), forKey: "titleTextColor")

            ac.addAction(confirmAction)
            ac.addAction(cancelAction)

            present(ac, animated: true)
        }
    }

    @objc private func removeAllTags() {
        log.verbose("removeAllTags")

        let tags = transaction.relationships.tags.data

        let tagIds = tags.map { $0.id }.joined(separator: ", ")

        let ac = UIAlertController(title: nil, message: "Are you sure you want to remove \"\(tagIds)\" from \"\(transaction.attributes.transactionDescription)\"?", preferredStyle: .actionSheet)

        let confirmAction = UIAlertAction(title: "Remove", style: .destructive) { [self] _ in
            let tagsObject = tags.map { TagResource(id: $0.id) }

            Up.modifyTags(removing: tagsObject, from: transaction) { error in
                DispatchQueue.main.async {
                    switch error {
                        case .none:
                            let nb = GrowingNotificationBanner(title: "Success", subtitle: "\(tagIds) was removed from \(transaction.attributes.transactionDescription).", style: .success)

                            nb.duration = 2

                            nb.show()

                            fetchTransaction()
                        default:
                            let nb = GrowingNotificationBanner(title: "Failed", subtitle: errorString(for: error!), style: .danger)

                            nb.duration = 2

                            nb.show()
                    }
                }
            }
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

        cancelAction.setValue(R.color.accentColor(), forKey: "titleTextColor")

        ac.addAction(confirmAction)
        ac.addAction(cancelAction)

        present(ac, animated: true)
    }

    private func updateToolbarItems() {
        log.verbose("updateToolbarItems")

        selectionBarButtonItem.title = tableView.indexPathsForSelectedRows?.count == transaction.relationships.tags.data.count ? "Deselect All" : "Select All"
        removeAllBarButtonItem.isEnabled = tableView.indexPathsForSelectedRows?.count != transaction.relationships.tags.data.count
        removeBarButtonItem.isEnabled = tableView.indexPathsForSelectedRows != nil
    }

    private func makeDataSource() -> DataSource {
        log.verbose("makeDataSource")

        let dataSource = DataSource(
            tableView: tableView,
            cellProvider: { tableView, indexPath, tag in
                let cell = tableView.dequeueReusableCell(withIdentifier: "tagCell", for: indexPath)

                cell.selectedBackgroundView = selectedBackgroundCellView
                cell.accessoryType = .disclosureIndicator
                cell.textLabel?.font = R.font.circularStdBook(size: UIFont.labelFontSize)
                cell.textLabel?.textAlignment = .left
                cell.textLabel?.numberOfLines = 0
                cell.textLabel?.text = tag.id

                return cell
            }
        )
        dataSource.defaultRowAnimation = .automatic
        return dataSource
    }

    private func applySnapshot(animate: Bool = true) {
        log.verbose("applySnapshot(animate: \(animate.description))")

        var snapshot = Snapshot()

        snapshot.appendSections([.main])

        snapshot.appendItems(transaction.relationships.tags.data, toSection: .main)

        dataSource.apply(snapshot, animatingDifferences: animate)
    }

    private func fetchTransaction() {
        log.verbose("fetchTransaction")

        Up.retrieveTransaction(for: transaction) { result in
            DispatchQueue.main.async {
                switch result {
                    case .success(let transaction):
                        self.transaction = transaction
                    case .failure(let error):
                        self.tableView.refreshControl?.endRefreshing()
                }
            }
        }
    }
}

// MARK: - UITableViewDelegate

extension TransactionTagsVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        log.debug("tableView(didSelectRowAt indexPath: \(indexPath))")

        switch isEditing {
            case true:
                updateToolbarItems()
            case false:
                tableView.deselectRow(at: indexPath, animated: true)

                if let tag = dataSource.itemIdentifier(for: indexPath)?.id {
                    navigationController?.pushViewController(TransactionsByTagVC(tag: TagResource(id: tag)), animated: true)
                }
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        log.debug("didDeselectRowAt indexPath: \(indexPath))")

        switch isEditing {
            case true:
                updateToolbarItems()
            case false:
                break
        }
    }

    func tableView(_ tableView: UITableView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        return isEditing
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }

    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Remove"
    }

    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        switch isEditing {
            case true:
                return nil
            case false:
                guard let tag = dataSource.itemIdentifier(for: indexPath) else { return nil }

                return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                    UIMenu(children: [
                        UIAction(title: "Copy", image: R.image.docOnClipboard()) { _ in
                            UIPasteboard.general.string = tag.id
                        },
                        UIAction(title: "Remove", image: R.image.trash(), attributes: .destructive) { [self] _ in
                            let ac = UIAlertController(title: nil, message: "Are you sure you want to remove \"\(tag.id)\" from \"\(transaction.attributes.transactionDescription)\"?", preferredStyle: .actionSheet)

                            let confirmAction = UIAlertAction(title: "Remove", style: .destructive) { _ in
                                let tagObject = TagResource(id: tag.id)

                                Up.modifyTags(removing: tagObject, from: transaction) { error in
                                    DispatchQueue.main.async {
                                        switch error {
                                            case .none:
                                                let nb = GrowingNotificationBanner(title: "Success", subtitle: "\(tag.id) was removed from \(transaction.attributes.transactionDescription).", style: .success)
                                                
                                                nb.duration = 2

                                                nb.show()

                                                fetchTransaction()
                                            default:
                                                let nb = GrowingNotificationBanner(title: "Failed", subtitle: errorString(for: error!), style: .danger)

                                                nb.duration = 2

                                                nb.show()
                                        }
                                    }
                                }
                            }

                            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

                            cancelAction.setValue(R.color.accentColor(), forKey: "titleTextColor")
                            
                            ac.addAction(confirmAction)
                            ac.addAction(cancelAction)

                            present(ac, animated: true)
                        }
                    ])
                }
        }
    }
}
